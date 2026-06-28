import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/pages/social/models/social_models.dart';
import 'package:thix_central/pages/social/services/social_feed_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class SocialRepository {
  Future<SocialModuleSnapshot> loadModule();

  Future<SocialPost> createPost(SocialComposerInput input);

  Future<SocialPost> toggleLike(String postId);

  Future<SocialPost> toggleBookmark(String postId);

  Future<SocialPost> addComment(String postId, String text);

  Future<SocialPost> repostPost(String postId, String quote);

  Future<List<SocialConnectionSuggestion>> toggleConnection(String suggestionId);

  Future<List<SocialNotificationItem>> markNotificationAsRead(String notificationId);

  Future<List<SocialStory>> fetchStories();

  Future<void> createStory({required String mediaUrl, String? caption});
}

class ThixSocialRepository implements SocialRepository {
  ThixSocialRepository({SocialFeedService? feedService}) : _feedService = feedService ?? const SocialFeedService();

  final SocialFeedService _feedService;
  static SocialModuleSnapshot? _cache;

  SocialModuleSnapshot get _snapshot {
    if (_cache == null) throw StateError('Repository not initialized. Call loadModule() first.');
    return _cache!;
  }

  @override
  Future<SocialModuleSnapshot> loadModule() async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) {
      throw Exception('Supabase client not available');
    }
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // 1. Récupérer les posts
    final postsRows = await client.from('social_posts')
        .select('*')
        .order('created_at', ascending: false)
        .limit(30);
    final posts = (postsRows as List)
        .map((row) => SocialPost.fromJson(row))
        .toList();

    // 2. Récupérer les likes de l'utilisateur
    final postIds = posts.map((p) => p.id).toList();
    final likedIds = <String>{};
    if (postIds.isNotEmpty) {
      try {
        final likeRows = await client.from('social_post_likes')
            .select('post_id')
            .eq('user_id', currentUserId)
            .inFilter('post_id', postIds);
        likedIds.addAll((likeRows as List)
            .whereType<Map>()
            .map((row) => (row['post_id'] ?? '').toString()));
      } catch (e) {
        debugPrint('Failed to load likes: $e');
        // On ne propage pas l'erreur ici, on continue sans likes
      }
    }
    final enrichedPosts = posts.map((p) => p.copyWith(isLiked: likedIds.contains(p.id))).toList();

    // 3. Récupérer les stories
    final stories = await fetchStories();

    // 4. Récupérer les suggestions (profil utilisateurs non connectés)
    List<SocialConnectionSuggestion> suggestions = [];
    try {
      final profileRows = await client.from('profiles')
          .select('id, display_name, occupation')
          .neq('id', currentUserId)
          .limit(10);
      suggestions = (profileRows as List).map((row) {
        final name = row['display_name'] ?? 'Inconnu';
        final firstName = name.split(' ').first;
        return SocialConnectionSuggestion(
          id: row['id'].toString(),
          name: name,
          role: row['occupation'] ?? 'Membre',
          mutualConnections: Random().nextInt(15) + 1,
        );
      }).toList();
    } catch (e) {
      debugPrint('Failed to load suggestions: $e');
      // On laisse la liste vide, pas de fallback
    }

    // 5. Récupérer les notifications
    List<SocialNotificationItem> notifications = [];
    try {
      final notifRows = await client.from('social_notifications')
          .select('*')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(20);
      notifications = (notifRows as List).map((row) => SocialNotificationItem(
            id: row['id'].toString(),
            title: row['title'] ?? 'Notification',
            description: row['description'] ?? '',
            createdAt: DateTime.parse(row['created_at']),
            type: row['type'] ?? 'generic',
            isUnread: row['is_unread'] ?? true,
          )).toList();
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
      // On laisse liste vide
    }

    // 6. Construire le snapshot complet avec des données par défaut pour les parties non encore implémentées
    _cache = SocialModuleSnapshot(
      feed: enrichedPosts,
      stories: stories,
      suggestions: suggestions,
      notifications: notifications,
      communities: const [],           // À charger depuis une table plus tard
      highlights: const [],            // À implémenter
      conversations: const [],         // À charger depuis messages
      trendingHashtags: const [],      // À calculer
      analytics: const SocialAnalyticsSnapshot(profileViews: 0, contentViews: 0, likes: 0, comments: 0),
      moderation: const SocialModerationSnapshot(hiddenPosts: 0, reportedPosts: 0, blockedUsers: 0, rlsReady: true),
    );
    return _cache!;
  }

  @override
  Future<List<SocialStory>> fetchStories() async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) throw Exception('Supabase client not available');
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final now = DateTime.now().toIso8601String();
    final rows = await client.from('social_stories')
        .select('*, author:profiles(*)')
        .gt('expires_at', now)
        .order('created_at', ascending: false)
        .limit(20);

    final stories = (rows as List).map((row) => SocialStory.fromJson(row)).toList();

    // Marquer les stories déjà vues
    if (stories.isNotEmpty) {
      try {
        final viewedRows = await client.from('social_story_views')
            .select('story_id')
            .eq('user_id', currentUserId);
        final viewedIds = (viewedRows as List).map((row) => row['story_id'].toString()).toSet();
        return stories.map((s) => s.copyWith(isViewed: viewedIds.contains(s.id))).toList();
      } catch (e) {
        debugPrint('Failed to load story views: $e');
      }
    }
    return stories;
  }

  @override
  Future<void> createStory({required String mediaUrl, String? caption}) async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) throw Exception('Supabase client not available');
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await client.from('social_stories').insert({
      'user_id': userId,
      'media_url': mediaUrl,
      'caption': caption,
      'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
    });

    // Invalider le cache pour recharger les stories
    _cache = null;
  }

  @override
  Future<SocialPost> createPost(SocialComposerInput input) async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) throw Exception('Supabase client not available');
    final currentUser = client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final author = SocialAuthor(
      id: currentUser.id,
      name: currentUser.userMetadata?['display_name']?.toString() ?? 'Utilisateur',
      role: currentUser.userMetadata?['headline']?.toString() ?? 'Membre',
      isVerified: true,
    );
    final now = DateTime.now();
    final id = 'post-${now.microsecondsSinceEpoch}';
    final base = SocialPost(
      id: id,
      author: author,
      content: input.content.trim(),
      kind: input.kind,
      createdAt: now,
      updatedAt: now,
      likeCount: 0,
      commentCount: 0,
      shareCount: input.repostSource == null ? 0 : 1,
      viewCount: 1,
      isPinned: false,
    );
    final post = _feedService.applyComposerData(base: base, input: input);

    // Insérer dans Supabase
    final json = post.toJson();
    // On retire les champs calculés (likeCount, commentCount, etc.) car ils seront mis à jour par triggers
    json.remove('like_count');
    json.remove('comment_count');
    json.remove('share_count');
    json.remove('view_count');
    json.remove('is_pinned');
    json.remove('is_liked');
    json.remove('is_bookmarked');
    json.remove('comments');
    json['user_id'] = currentUser.id;
    await client.from('social_posts').insert(json);

    // Mettre à jour le cache
    final updatedFeed = [post, ..._snapshot.feed];
    _cache = _snapshot.copyWith(feed: updatedFeed);
    return post;
  }

  @override
  Future<SocialPost> toggleLike(String postId) async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) throw Exception('Supabase client not available');
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final target = _snapshot.feed.firstWhere((post) => post.id == postId);
    final isLiked = !target.isLiked;
    final newLikeCount = isLiked ? target.likeCount + 1 : target.likeCount - 1;

    // Optimistic update
    final optimistic = target.copyWith(isLiked: isLiked, likeCount: newLikeCount);
    _replacePost(optimistic);

    try {
      if (isLiked) {
        await client.from('social_post_likes').insert({'post_id': postId, 'user_id': currentUserId});
      } else {
        await client.from('social_post_likes').delete().eq('post_id', postId).eq('user_id', currentUserId);
      }
      // Récupérer le post mis à jour depuis Supabase
      final refreshed = await client.from('social_posts').select('*').eq('id', postId).maybeSingle();
      if (refreshed != null) {
        final updated = SocialPost.fromJson(refreshed).copyWith(isLiked: isLiked);
        _replacePost(updated);
        return updated;
      }
    } catch (e) {
      // En cas d'erreur, annuler l'optimistic update
      final revert = target.copyWith(isLiked: !isLiked, likeCount: target.likeCount);
      _replacePost(revert);
      rethrow;
    }
    return optimistic;
  }

  @override
  Future<SocialPost> toggleBookmark(String postId) async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) throw Exception('Supabase client not available');
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    final target = _snapshot.feed.firstWhere((post) => post.id == postId);
    final isBookmarked = !target.isBookmarked;
    final optimistic = target.copyWith(isBookmarked: isBookmarked);
    _replacePost(optimistic);

    try {
      if (isBookmarked) {
        await client.from('social_post_bookmarks').insert({'post_id': postId, 'user_id': currentUserId});
      } else {
        await client.from('social_post_bookmarks').delete().eq('post_id', postId).eq('user_id', currentUserId);
      }
    } catch (e) {
      final revert = target.copyWith(isBookmarked: !isBookmarked);
      _replacePost(revert);
      rethrow;
    }
    return optimistic;
  }

  @override
  Future<SocialPost> addComment(String postId, String text) async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) throw Exception('Supabase client not available');
    final currentUser = client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final target = _snapshot.feed.firstWhere((post) => post.id == postId);
    final now = DateTime.now();
    final author = SocialAuthor(
      id: currentUser.id,
      name: currentUser.userMetadata?['display_name']?.toString() ?? 'Utilisateur',
      role: currentUser.userMetadata?['headline']?.toString() ?? 'Membre',
      isVerified: true,
    );
    final comment = SocialComment(
      id: 'comment-${now.microsecondsSinceEpoch}',
      author: author,
      text: text.trim(),
      createdAt: now,
    );

    final updated = target.copyWith(
      comments: [...target.comments, comment],
      commentCount: target.commentCount + 1,
    );
    _replacePost(updated);

    try {
      await client.from('social_post_comments').insert({
        'post_id': postId,
        'author_id': author.id,
        'author_name': author.name,
        'author_role': author.role,
        'author_avatar_url': author.avatarUrl,
        'text': comment.text,
      });
      // Rafraîchir le post pour mettre à jour commentCount
      final refreshed = await client.from('social_posts').select('*').eq('id', postId).maybeSingle();
      if (refreshed != null) {
        final next = SocialPost.fromJson(refreshed).copyWith(
          isLiked: updated.isLiked,
          isBookmarked: updated.isBookmarked,
          comments: updated.comments,
        );
        _replacePost(next);
        return next;
      }
    } catch (e) {
      // Annuler l'optimistic update
      final revert = target.copyWith(
        comments: target.comments,
        commentCount: target.commentCount,
      );
      _replacePost(revert);
      rethrow;
    }
    return updated;
  }

  @override
  Future<SocialPost> repostPost(String postId, String quote) async {
    final source = _snapshot.feed.firstWhere((post) => post.id == postId);
    return createPost(
      SocialComposerInput(
        content: source.content,
        kind: SocialPostKind.repost,
        mediaUrls: source.mediaUrls,
        quote: quote.trim().isEmpty ? null : quote.trim(),
        repostSource: source,
      ),
    );
  }

  @override
  Future<List<SocialConnectionSuggestion>> toggleConnection(String suggestionId) async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) throw Exception('Supabase client not available');
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    // Trouver la suggestion dans le cache
    final suggestionIndex = _snapshot.suggestions.indexWhere((s) => s.id == suggestionId);
    if (suggestionIndex == -1) throw Exception('Suggestion not found');

    final current = _snapshot.suggestions[suggestionIndex];
    final newStatus = current.isConnected
        ? 'none'
        : current.isRequested
            ? 'accepted'
            : 'requested';

    // Optimistic update
    final updatedSuggestion = current.copyWith(
      isConnected: newStatus == 'accepted' || newStatus == 'none' && current.isConnected,
      isRequested: newStatus == 'requested' || newStatus == 'accepted' && current.isRequested,
      isBlocked: false,
    );
    final updatedList = List<SocialConnectionSuggestion>.from(_snapshot.suggestions)
      ..[suggestionIndex] = updatedSuggestion;
    _cache = _snapshot.copyWith(suggestions: updatedList);

    try {
      if (newStatus == 'none') {
        await client.from('social_connections')
            .delete()
            .eq('requester_id', currentUserId)
            .eq('addressee_id', suggestionId);
      } else {
        await client.from('social_connections').upsert({
          'requester_id': currentUserId,
          'addressee_id': suggestionId,
          'status': newStatus,
        });
      }
    } catch (e) {
      // Revert
      final revertList = List<SocialConnectionSuggestion>.from(_snapshot.suggestions)
        ..[suggestionIndex] = current;
      _cache = _snapshot.copyWith(suggestions: revertList);
      rethrow;
    }
    return _snapshot.suggestions;
  }

  @override
  Future<List<SocialNotificationItem>> markNotificationAsRead(String notificationId) async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) throw Exception('Supabase client not available');
    final currentUserId = client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not authenticated');

    // Optimistic update
    final updatedNotifications = _snapshot.notifications.map((n) {
      return n.id == notificationId ? n.copyWith(isUnread: false) : n;
    }).toList();
    _cache = _snapshot.copyWith(notifications: updatedNotifications);

    try {
      await client.from('social_notifications')
          .update({'is_unread': false})
          .eq('id', notificationId)
          .eq('user_id', currentUserId);
    } catch (e) {
      // Revert
      final revertList = _snapshot.notifications.map((n) {
        return n.id == notificationId ? n.copyWith(isUnread: true) : n;
      }).toList();
      _cache = _snapshot.copyWith(notifications: revertList);
      rethrow;
    }
    return _snapshot.notifications;
  }

  // Helper pour remplacer un post dans le cache
  void _replacePost(SocialPost post) {
    final updatedFeed = _snapshot.feed.map((p) => p.id == post.id ? post : p).toList();
    _cache = _snapshot.copyWith(feed: updatedFeed);
  }

  // Helper pour convertir les données JSON (inchangé)
  static Map<String, dynamic>? _asJsonMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (error) {
        debugPrint('social_repository: invalid map payload: $error');
        return null;
      }
    }
    return null;
  }
}
