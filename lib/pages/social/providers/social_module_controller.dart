import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/pages/social/models/social_models.dart';
import 'package:thix_central/pages/social/repositories/social_repository.dart';
import 'package:thix_central/pages/social/services/social_feed_service.dart';

class SocialModuleController extends ChangeNotifier {
  SocialModuleController({
    required SocialRepository repository,
    SocialFeedService? feedService,
  })  : _repository = repository,
        _feedService = feedService ?? const SocialFeedService();

  final SocialRepository _repository;
  final SocialFeedService _feedService;

  SocialModuleSnapshot _snapshot = const SocialModuleSnapshot();
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isCreatingStory = false;
  String _searchQuery = '';
  String? _error;
  SocialFeedSort _sort = SocialFeedSort.smart;

  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isCreatingStory => _isCreatingStory;
  String get searchQuery => _searchQuery;
  String? get error => _error;
  SocialFeedSort get sort => _sort;
  SocialModuleSnapshot get snapshot => _snapshot;

  int get unreadNotificationCount => _snapshot.notifications.where((item) => item.isUnread).length;

  List<SocialPost> get visiblePosts {
    final filtered = _snapshot.feed.where((post) => _feedService.matchesQuery(post, _searchQuery)).toList();
    return _feedService.sortPosts(filtered, _sort);
  }

  List<String> get mentionSuggestions {
    final handles = <String>{};
    for (final post in _snapshot.feed) {
      handles.add(post.author.name.split(' ').first.toLowerCase());
      handles.addAll(post.mentions);
    }
    final trigger = _activeMentionToken;
    if (trigger == null || trigger.isEmpty) return handles.take(4).toList();
    return handles.where((handle) => handle.contains(trigger)).take(5).toList();
  }

  String? get _activeMentionToken {
    final tokens = _searchQuery.split(RegExp(r'\s+'));
    final last = tokens.isEmpty ? '' : tokens.last;
    if (!last.startsWith('@')) return null;
    return last.replaceFirst('@', '').toLowerCase();
  }

  // --- Initialisation et rafraîchissement ---

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _snapshot = await _repository.loadModule();
    } catch (error) {
      _error = 'Impossible de charger le module social.';
      debugPrint('SocialModuleController.refresh error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge uniquement les stories (sans recharger tout le module).
  Future<void> fetchStories() async {
    try {
      final stories = await _repository.fetchStories();
      _snapshot = _snapshot.copyWith(stories: stories);
      notifyListeners();
    } catch (error) {
      debugPrint('SocialModuleController.fetchStories error: $error');
    }
  }

  // --- Actions sur les posts ---

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSort(SocialFeedSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  Future<void> createPost(SocialComposerInput input) async {
    _isCreating = true;
    notifyListeners();
    try {
      final post = await _repository.createPost(input);
      _snapshot = _snapshot.copyWith(feed: [post, ..._snapshot.feed]);
    } catch (error) {
      _error = 'Publication impossible pour le moment.';
      debugPrint('SocialModuleController.createPost error: $error');
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      final post = await _repository.toggleLike(postId);
      _updatePost(post);
    } catch (error) {
      debugPrint('SocialModuleController.toggleLike error: $error');
    }
  }

  Future<void> toggleBookmark(String postId) async {
    try {
      final post = await _repository.toggleBookmark(postId);
      _updatePost(post);
    } catch (error) {
      debugPrint('SocialModuleController.toggleBookmark error: $error');
    }
  }

  Future<void> addComment(String postId, String text) async {
    if (text.trim().isEmpty) return;
    try {
      final post = await _repository.addComment(postId, text);
      _updatePost(post);
    } catch (error) {
      debugPrint('SocialModuleController.addComment error: $error');
    }
  }

  Future<void> repostPost(String postId, String quote) async {
    try {
      final repost = await _repository.repostPost(postId, quote);
      _snapshot = _snapshot.copyWith(feed: [repost, ..._snapshot.feed]);
      notifyListeners();
    } catch (error) {
      debugPrint('SocialModuleController.repostPost error: $error');
    }
  }

  // --- Suggestions et notifications ---

  Future<void> toggleConnection(String suggestionId) async {
    try {
      final suggestions = await _repository.toggleConnection(suggestionId);
      _snapshot = _snapshot.copyWith(suggestions: suggestions);
      notifyListeners();
    } catch (error) {
      debugPrint('SocialModuleController.toggleConnection error: $error');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final notifications = await _repository.markNotificationAsRead(notificationId);
      _snapshot = _snapshot.copyWith(notifications: notifications);
      notifyListeners();
    } catch (error) {
      debugPrint('SocialModuleController.markNotificationAsRead error: $error');
    }
  }

  // --- Stories ---

  /// Crée une story en téléchargeant le fichier média vers Supabase Storage,
  /// puis enregistre la story dans la base de données.
  Future<void> createStory({required File mediaFile, String? caption}) async {
    _isCreatingStory = true;
    notifyListeners();

    try {
      // 1. Upload du fichier vers Supabase Storage
      final client = SupabaseClientProvider.clientOrNull;
      if (client == null) throw Exception('Supabase client not available');
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final bucket = 'stories'; // Nom du bucket
      final path = 'stories/$userId/${DateTime.now().millisecondsSinceEpoch}_${mediaFile.path.split('/').last}';
      await client.storage.from(bucket).upload(path, mediaFile);
      final mediaUrl = client.storage.from(bucket).getPublicUrl(path);

      // 2. Enregistrer la story en base
      await _repository.createStory(mediaUrl: mediaUrl, caption: caption);

      // 3. Recharger les stories
      await fetchStories();

      if (!kIsWeb) {
        // Optionnel : notifier l'utilisateur
      }
    } catch (error) {
      debugPrint('SocialModuleController.createStory error: $error');
      rethrow; // On propage l'erreur pour que l'UI puisse l'afficher
    } finally {
      _isCreatingStory = false;
      notifyListeners();
    }
  }

  // --- Helpers ---

  void _updatePost(SocialPost updated) {
    _snapshot = _snapshot.copyWith(
      feed: _snapshot.feed.map((post) => post.id == updated.id ? updated : post).toList(),
    );
    notifyListeners();
  }
}
