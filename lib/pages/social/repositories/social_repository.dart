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

    // 1) Posts
    final postsRows = await client
        .from('social_posts')
        .select('*')
        .order('created_at', ascending: false)
        .limit(30);
    final posts = (postsRows as List).whereType<Map>().map((row) => SocialPost.fromJson(row.cast<String, dynamic>())).toList();

    // 2) Likes / bookmarks / comments (pour enrichissement UI)
    final postIds = posts.map((p) => p.id).toList();
    final likedIds = <String>{};
    final bookmarkedIds = <String>{};
    final latestCommentsByPostId = <String, List<SocialComment>>{};
    if (postIds.isNotEmpty) {
      try {
        final likeRows = await client
            .from('social_post_likes')
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

      try {
        final bookmarkRows = await client
            .from('social_post_bookmarks')
            .select('post_id')
            .eq('user_id', currentUserId)
            .inFilter('post_id', postIds);
        bookmarkedIds.addAll((bookmarkRows as List)
            .whereType<Map>()
            .map((row) => (row['post_id'] ?? '').toString()));
      } catch (e) {
        debugPrint('Failed to load bookmarks: $e');
      }

      try {
        final commentRows = await client
            .from('social_post_comments')
            .select('*')
            .inFilter('post_id', postIds)
            .order('created_at', ascending: false)
            .limit(60);
        for (final row in (commentRows as List).whereType<Map>()) {
          final postId = (row['post_id'] ?? '').toString();
          if (postId.isEmpty) continue;
          latestCommentsByPostId.putIfAbsent(postId, () => <SocialComment>[]);
          if (latestCommentsByPostId[postId]!.length >= 2) continue;
          latestCommentsByPostId[postId]!.add(SocialComment.fromJson(row.cast<String, dynamic>()));
        }
      } catch (e) {
        debugPrint('Failed to load comments: $e');
      }
    }

    final enrichedPosts = posts
        .map(
          (p) => p.copyWith(
            isLiked: likedIds.contains(p.id),
            isBookmarked: bookmarkedIds.contains(p.id),
            comments: latestCommentsByPostId[p.id] ?? const <SocialComment>[],
          ),
        )
        .toList();

    // 3) Stories
    final stories = await fetchStories();

    // 4) Suggestions (sans mock) + statut connexion réel
    final suggestions = await _fetchSuggestions(client: client, currentUserId: currentUserId);

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

    // 6) Snapshot
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

    final nowIso = DateTime.now().toIso8601String();
    final rows = await client
        .from('social_stories')
        .select('*')
        .gt('expires_at', nowIso)
        .order('created_at', ascending: false)
        .limit(20);

    final rawStories = (rows as List).whereType<Map>().map((row) => row.cast<String, dynamic>()).toList();
    final authorIds = rawStories.map((row) => (row['author_id'] ?? '').toString()).where((id) => id.isNotEmpty).toSet().toList();
    final profilesByUserId = await _fetchProfilesByUserId(client: client, userIds: authorIds);

    var stories = rawStories.map((row) {
      final authorId = (row['author_id'] ?? '').toString();
      final profile = profilesByUserId[authorId];
      return SocialStory.fromJson({
        ...row,
        'author': profile ?? <String, dynamic>{},
        // SocialStory.fromJson attend parfois user_id
        'user_id': authorId,
      });
    }).toList();

    // Déterminer les stories vues
    if (stories.isNotEmpty) {
      try {
        final viewedRows = await client
            .from('social_story_views')
            .select('story_id')
            .eq('viewer_id', currentUserId);
        final viewedIds = (viewedRows as List).whereType<Map>().map((row) => (row['story_id'] ?? '').toString()).toSet();
        stories = stories.map((s) => s.copyWith(isViewed: viewedIds.contains(s.id))).toList();
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

    final profile = await _fetchProfile(client: client, userId: userId);
    await client.from('social_stories').insert({
      'author_id': userId,
      'author_name': (profile?['display_name'] ?? profile?['full_name'] ?? 'Membre THIX').toString(),
      'media_url': mediaUrl,
      if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
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

    final profile = await _fetchProfile(client: client, userId: currentUser.id);
    final author = SocialAuthor(
      id: currentUser.id,
      name: (profile?['display_name'] ?? profile?['full_name'] ?? 'Membre THIX').toString(),
      role: (profile?['headline'] ?? profile?['role'] ?? 'Professionnel').toString(),
      avatarUrl: profile?['avatar_url']?.toString(),
      isVerified: (profile?['is_verified'] as bool?) ?? false,
      mutualConnections: 0,
    );
    final now = DateTime.now();
    final base = SocialPost(
      id: '',
      author: author,
      content: input.content.trim(),
      kind: input.kind,
      createdAt: now,
      updatedAt: now,
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      viewCount: 0,
      isPinned: false,
    );
    final composed = _feedService.applyComposerData(base: base, input: input);

    final insertPayload = <String, dynamic>{
      'author_id': currentUser.id,
      'author_name': composed.author.name,
      'author_role': composed.author.role,
      'author_avatar_url': composed.author.avatarUrl,
      'author_is_verified': composed.author.isVerified,
      'author_mutual_connections': composed.author.mutualConnections,
      'content': composed.content,
      'kind': composed.kind.name,
      'visibility': composed.visibility.name,
      'community_name': composed.communityName,
      'quote': composed.quote,
      'media_urls': composed.mediaUrls,
      'hashtags': composed.hashtags,
      'mentions': composed.mentions,
      'poll': composed.poll?.toJson(),
      'challenge': composed.challenge?.toJson(),
      'repost_of_post_id': composed.repostOfPostId,
      'repost_author_name': composed.repostAuthorName,
    };

    final inserted = await client.from('social_posts').insert(insertPayload).select('*').single();
    final post = SocialPost.fromJson((inserted as Map).cast<String, dynamic>());

    // Enrich with viewer state
    final enriched = post.copyWith(isLiked: false, isBookmarked: false, comments: const <SocialComment>[]);
    _cache = _snapshot.copyWith(feed: [enriched, ..._snapshot.feed]);
    return enriched;
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

      // Garder le compteur cohérent même si les triggers ne sont pas encore installés
      await client.from('social_posts').update({'like_count': newLikeCount}).eq('id', postId);

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

      await client.from('social_posts').update({'comment_count': updated.commentCount}).eq('id', postId);

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
    // Comportement:
    // - Non connecté -> créer une demande (pending)
    // - Demande envoyée -> annuler (delete)
    // - Déjà connecté -> se déconnecter (delete)
    final action = current.isConnected
        ? 'disconnect'
        : current.isRequested
            ? 'cancel'
            : 'request';

    final optimistic = current.copyWith(
      isConnected: action == 'disconnect' ? false : current.isConnected,
      isRequested: action == 'request' ? true : false,
      isBlocked: false,
    );
    final updatedList = List<SocialConnectionSuggestion>.from(_snapshot.suggestions)
      ..[suggestionIndex] = optimistic;
    _cache = _snapshot.copyWith(suggestions: updatedList);

    try {
      if (action == 'request') {
        await client.from('social_connections').upsert({
          'requester_id': currentUserId,
          'receiver_id': suggestionId,
          'status': 'pending',
        });
      } else {
        await client
            .from('social_connections')
            .delete()
            .or('and(requester_id.eq.$currentUserId,receiver_id.eq.$suggestionId),and(requester_id.eq.$suggestionId,receiver_id.eq.$currentUserId)');
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

  Future<Map<String, dynamic>?> _fetchProfile({required SupabaseClient client, required String userId}) async {
    try {
      final profile = await client.from('profiles').select('user_id, display_name, avatar_url').eq('user_id', userId).maybeSingle();
      final details = await client.from('profile_details').select('user_id, full_name').eq('user_id', userId).maybeSingle();
      return {
        if (profile != null) ...((profile as Map).cast<String, dynamic>()),
        if (details != null) ...((details as Map).cast<String, dynamic>()),
      };
    } catch (e) {
      debugPrint('Failed to load profile for $userId: $e');
      return null;
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByUserId({
    required SupabaseClient client,
    required List<String> userIds,
  }) async {
    if (userIds.isEmpty) return {};
    try {
      final rows = await client.from('profiles').select('user_id, display_name, avatar_url').inFilter('user_id', userIds);
      final map = <String, Map<String, dynamic>>{};
      for (final row in (rows as List).whereType<Map>()) {
        final id = (row['user_id'] ?? '').toString();
        if (id.isEmpty) continue;
        map[id] = row.cast<String, dynamic>();
      }
      return map;
    } catch (e) {
      debugPrint('Failed to batch load profiles: $e');
      return {};
    }
  }

  Future<List<SocialConnectionSuggestion>> _fetchSuggestions({
    required SupabaseClient client,
    required String currentUserId,
  }) async {
    try {
      final profileRows = await client
          .from('profiles')
          .select('user_id, display_name, avatar_url')
          .neq('user_id', currentUserId)
          .limit(10);
      final profiles = (profileRows as List).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      if (profiles.isEmpty) return [];

      final suggestedIds = profiles.map((p) => (p['user_id'] ?? '').toString()).where((id) => id.isNotEmpty).toList();

      // Connexions de l'utilisateur courant (accepted)
      final currentAcceptedRows = await client
          .from('social_connections')
          .select('requester_id, receiver_id')
          .eq('status', 'accepted')
          .or('requester_id.eq.$currentUserId,receiver_id.eq.$currentUserId');
      final currentConnections = <String>{};
      for (final row in (currentAcceptedRows as List).whereType<Map>()) {
        final a = (row['requester_id'] ?? '').toString();
        final b = (row['receiver_id'] ?? '').toString();
        if (a == currentUserId && b.isNotEmpty) currentConnections.add(b);
        if (b == currentUserId && a.isNotEmpty) currentConnections.add(a);
      }

      // Statut connexion (pending/accepted) entre l'utilisateur courant et les suggestions
      final inList = suggestedIds.map((id) => '"$id"').join(',');
      final relationRows = await client
          .from('social_connections')
          .select('requester_id, receiver_id, status')
          .or('and(requester_id.eq.$currentUserId,receiver_id.in.($inList)),and(receiver_id.eq.$currentUserId,requester_id.in.($inList))');

      Map<String, Map<String, dynamic>> relationByOther = {};
      for (final row in (relationRows as List).whereType<Map>()) {
        final r = (row['requester_id'] ?? '').toString();
        final v = (row['receiver_id'] ?? '').toString();
        final other = r == currentUserId ? v : r;
        if (other.isEmpty) continue;
        relationByOther[other] = row.cast<String, dynamic>();
      }

      // Mutual connections (réel): nombre de connexions acceptées entre la suggestion et les connexions de l'utilisateur.
      Future<int> mutualCountFor(String suggestedId) async {
        if (currentConnections.isEmpty) return 0;
        final peersIn = currentConnections.map((id) => '"$id"').join(',');
        try {
          final rows = await client
              .from('social_connections')
              .select('id')
              .eq('status', 'accepted')
              .or('and(requester_id.eq.$suggestedId,receiver_id.in.($peersIn)),and(receiver_id.eq.$suggestedId,requester_id.in.($peersIn))');
          return (rows as List).length;
        } catch (e) {
          debugPrint('Failed to compute mutual connections for $suggestedId: $e');
          return 0;
        }
      }

      final out = <SocialConnectionSuggestion>[];
      for (final p in profiles) {
        final id = (p['user_id'] ?? '').toString();
        final displayName = (p['display_name'] ?? 'Membre THIX').toString();
        final relation = relationByOther[id];
        final status = (relation?['status'] ?? '').toString();
        final isConnected = status == 'accepted';
        final isRequested = status == 'pending' && (relation?['requester_id'] ?? '').toString() == currentUserId;
        final mutual = await mutualCountFor(id);
        out.add(
          SocialConnectionSuggestion(
            id: id,
            name: displayName,
            role: 'Professionnel',
            mutualConnections: mutual,
            isConnected: isConnected,
            isRequested: isRequested,
          ),
        );
      }
      return out;
    } catch (e) {
      debugPrint('Failed to load suggestions: $e');
      return [];
    }
  }
}
