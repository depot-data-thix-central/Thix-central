import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/pages/social/models/social_models.dart';
import 'package:thix_central/pages/social/services/social_feed_service.dart';

abstract class SocialRepository {
  Future<SocialModuleSnapshot> loadModule();

  Future<SocialPost> createPost(SocialComposerInput input);

  Future<SocialPost> toggleLike(String postId);

  Future<SocialPost> toggleBookmark(String postId);

  Future<SocialPost> addComment(String postId, String text);

  Future<SocialPost> repostPost(String postId, String quote);

  Future<List<SocialConnectionSuggestion>> toggleConnection(String suggestionId);

  Future<List<SocialNotificationItem>> markNotificationAsRead(String notificationId);
}

class ThixSocialRepository implements SocialRepository {
  ThixSocialRepository({SocialFeedService? feedService}) : _feedService = feedService ?? const SocialFeedService();

  final SocialFeedService _feedService;

  static SocialModuleSnapshot? _cache;

  SocialModuleSnapshot get _snapshot => _cache ??= _buildSeedSnapshot();

  @override
  Future<SocialModuleSnapshot> loadModule() async {
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) {
      return _snapshot;
    }
    try {
      final currentUserId = client.auth.currentUser?.id;

      final rows = await client.from('social_posts').select('*').order('created_at', ascending: false).limit(30);
      final posts = (rows as List)
          .map(_asJsonMap)
          .whereType<Map<String, dynamic>>()
          .map(SocialPost.fromJson)
          .toList();

      if (posts.isEmpty) return _snapshot;

      final postIds = posts.map((post) => post.id).toList();
      final likedIds = <String>{};
      if (currentUserId != null) {
        try {
          final likeRows = await client.from('social_post_likes').select('post_id').eq('user_id', currentUserId).inFilter('post_id', postIds);
          likedIds.addAll((likeRows as List).whereType<Map>().map((row) => (row['post_id'] ?? '').toString()));
        } catch (error) {
          debugPrint('social likes preload failed: $error');
        }
      }

      final enriched = posts
          .map(
            (post) => post.copyWith(
              isLiked: likedIds.contains(post.id),
            ),
          )
          .toList();

      _cache = _snapshot.copyWith(feed: enriched);
      return _cache!;
    } catch (error) {
      debugPrint('social load fallback: $error');
      return _snapshot;
    }
  }

  @override
  Future<SocialPost> createPost(SocialComposerInput input) async {
    final currentUser = SupabaseClientProvider.clientOrNull?.auth.currentUser;
    final author = SocialAuthor(
      id: currentUser?.id ?? 'local-user',
      name: currentUser?.userMetadata?['display_name']?.toString() ?? 'Vous',
      role: currentUser?.userMetadata?['headline']?.toString() ?? 'Membre THIX CENTRAL',
      isVerified: true,
      mutualConnections: 24,
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
    final updatedFeed = [post, ..._snapshot.feed];
    _cache = _snapshot.copyWith(feed: updatedFeed);
    final client = SupabaseClientProvider.clientOrNull;
    if (client != null) {
      try {
        await client.from('social_posts').insert(post.toJson());
      } catch (error) {
        debugPrint('social create fallback: $error');
      }
    }
    return post;
  }

  @override
  Future<SocialPost> toggleLike(String postId) async {
    final target = _snapshot.feed.firstWhere((post) => post.id == postId);
    final client = SupabaseClientProvider.clientOrNull;
    final currentUserId = client?.auth.currentUser?.id;

    final optimistic = target.copyWith(
      isLiked: !target.isLiked,
      likeCount: target.isLiked ? max(0, target.likeCount - 1) : target.likeCount + 1,
    );
    _replacePost(optimistic);

    if (client == null || currentUserId == null) return optimistic;
    try {
      if (optimistic.isLiked) {
        await client.from('social_post_likes').insert({'post_id': postId, 'user_id': currentUserId});
      } else {
        await client.from('social_post_likes').delete().eq('post_id', postId).eq('user_id', currentUserId);
      }
      final refreshed = await client.from('social_posts').select('*').eq('id', postId).maybeSingle();
      final refreshedJson = _asJsonMap(refreshed);
      if (refreshedJson != null) {
        final updated = SocialPost.fromJson(refreshedJson).copyWith(isLiked: optimistic.isLiked);
        _replacePost(updated);
        return updated;
      }
    } catch (error) {
      debugPrint('social like failed: $error');
    }
    return optimistic;
  }

  @override
  Future<SocialPost> toggleBookmark(String postId) async {
    final target = _snapshot.feed.firstWhere((post) => post.id == postId);
    final client = SupabaseClientProvider.clientOrNull;
    final currentUserId = client?.auth.currentUser?.id;
    final optimistic = target.copyWith(isBookmarked: !target.isBookmarked);
    _replacePost(optimistic);

    if (client == null || currentUserId == null) return optimistic;
    try {
      if (optimistic.isBookmarked) {
        await client.from('social_post_bookmarks').insert({'post_id': postId, 'user_id': currentUserId});
      } else {
        await client.from('social_post_bookmarks').delete().eq('post_id', postId).eq('user_id', currentUserId);
      }
    } catch (error) {
      debugPrint('social bookmark failed: $error');
    }
    return optimistic;
  }

  @override
  Future<SocialPost> addComment(String postId, String text) async {
    final target = _snapshot.feed.firstWhere((post) => post.id == postId);
    final now = DateTime.now();
    final client = SupabaseClientProvider.clientOrNull;
    final currentUser = client?.auth.currentUser;
    final author = SocialAuthor(
      id: currentUser?.id ?? 'local-user',
      name: currentUser?.userMetadata?['display_name']?.toString() ?? 'Vous',
      role: currentUser?.userMetadata?['headline']?.toString() ?? 'Membre THIX CENTRAL',
      isVerified: true,
      mutualConnections: 0,
    );
    final comment = SocialComment(id: 'comment-${now.microsecondsSinceEpoch}', author: author, text: text.trim(), createdAt: now);

    final updated = target.copyWith(
      comments: [...target.comments, comment],
      commentCount: target.commentCount + 1,
    );
    _replacePost(updated);

    if (client != null && currentUser != null) {
      try {
        await client.from('social_post_comments').insert({
          'post_id': postId,
          'author_id': author.id,
          'author_name': author.name,
          'author_role': author.role,
          'author_avatar_url': author.avatarUrl,
          'text': comment.text,
        });
        final refreshed = await client.from('social_posts').select('*').eq('id', postId).maybeSingle();
        final refreshedJson = _asJsonMap(refreshed);
        if (refreshedJson != null) {
          final next = SocialPost.fromJson(refreshedJson).copyWith(
            isLiked: updated.isLiked,
            isBookmarked: updated.isBookmarked,
            comments: updated.comments,
          );
          _replacePost(next);
          return next;
        }
      } catch (error) {
        debugPrint('social comment failed: $error');
      }
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
    // Local-first behaviour (and used as fallback if Supabase isn't ready).
    final updated = _snapshot.suggestions.map((suggestion) {
      if (suggestion.id != suggestionId) return suggestion;
      if (suggestion.isBlocked) return suggestion.copyWith(isBlocked: false);
      if (suggestion.isConnected) return suggestion.copyWith(isConnected: false);
      if (suggestion.isRequested) {
        return suggestion.copyWith(isRequested: false, isConnected: true);
      }
      return suggestion.copyWith(isRequested: true);
    }).toList();
    _cache = _snapshot.copyWith(suggestions: updated);

    final client = SupabaseClientProvider.clientOrNull;
    final currentUserId = client?.auth.currentUser?.id;
    if (client != null && currentUserId != null) {
      try {
        final target = updated.firstWhere((item) => item.id == suggestionId);
        final status = target.isConnected
            ? 'accepted'
            : target.isRequested
                ? 'requested'
                : 'none';
        if (status == 'none') {
          await client.from('social_connections').delete().eq('requester_id', currentUserId).eq('addressee_id', suggestionId);
        } else {
          await client.from('social_connections').upsert({'requester_id': currentUserId, 'addressee_id': suggestionId, 'status': status});
        }
      } catch (error) {
        debugPrint('social connection sync failed: $error');
      }
    }
    return updated;
  }

  @override
  Future<List<SocialNotificationItem>> markNotificationAsRead(String notificationId) async {
    final updated = _snapshot.notifications
        .map((notification) => notification.id == notificationId ? notification.copyWith(isUnread: false) : notification)
        .toList();
    _cache = _snapshot.copyWith(notifications: updated);
    return updated;
  }

  void _replacePost(SocialPost post) {
    final updatedFeed = _snapshot.feed.map((item) => item.id == post.id ? post : item).toList();
    _cache = _snapshot.copyWith(feed: updatedFeed);
  }

  static SocialModuleSnapshot _buildSeedSnapshot() {
    final now = DateTime.now();
    final aicha = const SocialAuthor(
      id: 'aicha',
      name: 'Aïcha Diop',
      role: 'Product Designer · TechNova',
      isVerified: true,
      mutualConnections: 18,
    );
    final mamadou = const SocialAuthor(
      id: 'mamadou',
      name: 'Mamadou Camara',
      role: 'Growth Lead · StartupLab',
      mutualConnections: 12,
    );
    final nathan = const SocialAuthor(
      id: 'nathan',
      name: 'Nathan Kouamé',
      role: 'Founder · Thix Builders Community',
      isVerified: true,
      mutualConnections: 31,
    );

    final feed = <SocialPost>[
      SocialPost(
        id: 'seed-1',
        author: aicha,
        content: 'Très fière de partager notre nouveau projet UI/UX pour une solution SaaS. Merci à @nathan pour la confiance. #design #product',
        kind: SocialPostKind.image,
        createdAt: now.subtract(const Duration(hours: 3)),
        mediaUrls: const ['https://storage.thix.example/mock/design-cover.png'],
        hashtags: const ['design', 'product'],
        mentions: const ['nathan'],
        likeCount: 128,
        commentCount: 33,
        shareCount: 11,
        viewCount: 740,
        isPinned: true,
        communityName: 'Design Leaders',
        comments: [
          SocialComment(
            id: 'comment-a1',
            author: mamadou,
            text: 'Super clair, bravo pour le teasing 👏',
            createdAt: now.subtract(const Duration(hours: 2, minutes: 10)),
          ),
        ],
      ),
      SocialPost(
        id: 'seed-2',
        author: mamadou,
        content: 'Webinar gratuit jeudi : 5 actions pour améliorer vos KPI produit. Inscription ouverte ! #growth #analytics',
        kind: SocialPostKind.poll,
        createdAt: now.subtract(const Duration(hours: 5)),
        hashtags: const ['growth', 'analytics'],
        likeCount: 92,
        commentCount: 18,
        shareCount: 25,
        viewCount: 640,
        poll: SocialPoll(
          question: 'Quel sujet prioriser pour le webinar ?',
          options: const [
            SocialPollOption(id: 'poll-1', label: 'Activation', votes: 34, isSelected: true),
            SocialPollOption(id: 'poll-2', label: 'Rétention', votes: 28),
            SocialPollOption(id: 'poll-3', label: 'Pricing', votes: 14),
          ],
          expiresAt: now.add(const Duration(days: 2)),
          hasVoted: true,
        ),
      ),
      SocialPost(
        id: 'seed-3',
        author: nathan,
        content: 'Challenge ouvert : montrez votre meilleure landing page no-code et remportez une session mentorat + 250 000 XOF. #challenge #nocode',
        kind: SocialPostKind.challenge,
        createdAt: now.subtract(const Duration(hours: 9)),
        hashtags: const ['challenge', 'nocode'],
        likeCount: 74,
        commentCount: 12,
        shareCount: 29,
        viewCount: 1220,
        challenge: SocialChallenge(
          title: 'No-Code Launch Sprint',
          prize: '250 000 XOF + mentorat',
          participants: 38,
          leaderboardPreview: const ['Studio Sahel', 'Flow Dakar', 'UI Tribe'],
          deadline: now.add(const Duration(days: 5)),
        ),
      ),
      SocialPost(
        id: 'seed-4',
        author: aicha,
        content: 'Repost de la check-list product ops de @mamadou — ultra utile pour structurer les rituels d’équipe.',
        kind: SocialPostKind.repost,
        createdAt: now.subtract(const Duration(hours: 18)),
        quote: 'À diffuser à tous les PMs 👇',
        repostOfPostId: 'seed-2',
        repostAuthorName: mamadou.name,
        likeCount: 36,
        commentCount: 6,
        shareCount: 7,
        viewCount: 241,
      ),
    ];

    return SocialModuleSnapshot(
      feed: feed,
      stories: [
        SocialStory(
          id: 'story-me',
          author: const SocialAuthor(id: 'me', name: 'Ma Story', role: 'Votre réseau'),
          createdAt: now.subtract(const Duration(hours: 1)),
          expiresAt: now.add(const Duration(hours: 23)),
          viewCount: 0,
        ),
        SocialStory(
          id: 'story-1',
          author: nathan,
          createdAt: now.subtract(const Duration(hours: 4)),
          expiresAt: now.add(const Duration(hours: 20)),
          isViewed: false,
          viewCount: 138,
        ),
        SocialStory(
          id: 'story-2',
          author: mamadou,
          createdAt: now.subtract(const Duration(hours: 7)),
          expiresAt: now.add(const Duration(hours: 17)),
          isVideo: true,
          isViewed: true,
          viewCount: 92,
        ),
      ],
      highlights: const [
        SocialHighlight(id: 'highlight-1', title: 'Lancements', storyCount: 6),
        SocialHighlight(id: 'highlight-2', title: 'Meetups', storyCount: 9),
      ],
      communities: const [
        SocialCommunity(
          id: 'community-1',
          name: 'Design Leaders',
          description: 'Partage UX, audits et mentorat entre designers francophones.',
          memberCount: 1240,
          role: 'admin',
          isJoined: true,
        ),
        SocialCommunity(
          id: 'community-2',
          name: 'Growth Club',
          description: 'Expériences acquisition, CRM et activation produit.',
          memberCount: 860,
          isPrivate: true,
          isJoined: true,
        ),
        SocialCommunity(
          id: 'community-3',
          name: 'No-Code Africa',
          description: 'Tutoriels, feedback et challenges builders.',
          memberCount: 2320,
        ),
      ],
      suggestions: const [
        SocialConnectionSuggestion(id: 'suggestion-1', name: 'Fatou Sy', role: 'Data Analyst · Wave', mutualConnections: 14),
        SocialConnectionSuggestion(id: 'suggestion-2', name: 'Nora Bamba', role: 'Community Builder · Seedstars', mutualConnections: 8, isRequested: true),
        SocialConnectionSuggestion(id: 'suggestion-3', name: 'Jean Koné', role: 'CTO · Flow Dakar', mutualConnections: 19, isConnected: true),
      ],
      notifications: [
        SocialNotificationItem(
          id: 'notif-1',
          title: 'Nouveau like',
          description: 'Aïcha a aimé votre post sur #product.',
          createdAt: now.subtract(const Duration(minutes: 16)),
          type: 'like',
        ),
        SocialNotificationItem(
          id: 'notif-2',
          title: 'Commentaire reçu',
          description: 'Mamadou a commenté votre reel.',
          createdAt: now.subtract(const Duration(hours: 2)),
          type: 'comment',
        ),
        SocialNotificationItem(
          id: 'notif-3',
          title: 'Nouvelle connexion',
          description: 'Jean a accepté votre invitation.',
          createdAt: now.subtract(const Duration(hours: 5)),
          isUnread: false,
          type: 'connection',
        ),
      ],
      conversations: [
        SocialConversation(
          id: 'conv-1',
          peerName: 'Nora Bamba',
          lastMessage: 'Je t’envoie la présentation + les pièces jointes tout de suite.',
          updatedAt: now.subtract(const Duration(minutes: 8)),
          unreadCount: 2,
          attachmentCount: 1,
          isSeen: false,
        ),
        SocialConversation(
          id: 'conv-2',
          peerName: 'Design Leaders',
          lastMessage: 'Le brief du prochain challenge est publié.',
          updatedAt: now.subtract(const Duration(hours: 1, minutes: 12)),
          attachmentCount: 0,
        ),
      ],
      trendingHashtags: const ['#product', '#design', '#growth', '#nocode', '#communauté'],
      analytics: const SocialAnalyticsSnapshot(profileViews: 1248, contentViews: 8921, likes: 527, comments: 143),
      moderation: const SocialModerationSnapshot(hiddenPosts: 3, reportedPosts: 1, blockedUsers: 2, rlsReady: true),
    );
  }

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
