import 'package:flutter/foundation.dart';
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
  String _searchQuery = '';
  String? _error;
  SocialFeedSort _sort = SocialFeedSort.smart;

  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    final post = await _repository.toggleLike(postId);
    _updatePost(post);
  }

  Future<void> toggleBookmark(String postId) async {
    final post = await _repository.toggleBookmark(postId);
    _updatePost(post);
  }

  Future<void> addComment(String postId, String text) async {
    if (text.trim().isEmpty) return;
    final post = await _repository.addComment(postId, text);
    _updatePost(post);
  }

  Future<void> repostPost(String postId, String quote) async {
    final repost = await _repository.repostPost(postId, quote);
    _snapshot = _snapshot.copyWith(feed: [repost, ..._snapshot.feed]);
    notifyListeners();
  }

  Future<void> toggleConnection(String suggestionId) async {
    final suggestions = await _repository.toggleConnection(suggestionId);
    _snapshot = _snapshot.copyWith(suggestions: suggestions);
    notifyListeners();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final notifications = await _repository.markNotificationAsRead(notificationId);
    _snapshot = _snapshot.copyWith(notifications: notifications);
    notifyListeners();
  }

  void _updatePost(SocialPost updated) {
    _snapshot = _snapshot.copyWith(
      feed: _snapshot.feed.map((post) => post.id == updated.id ? updated : post).toList(),
    );
    notifyListeners();
  }
}
