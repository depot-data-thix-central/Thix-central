import 'package:flutter_test/flutter_test.dart';
import 'package:thix_central/pages/social/models/social_models.dart';
import 'package:thix_central/pages/social/services/social_feed_service.dart';

void main() {
  const service = SocialFeedService();
  const author = SocialAuthor(
    id: 'author-1',
    name: 'Aïcha Diop',
    role: 'Designer',
    mutualConnections: 10,
  );

  test('extract hashtags and mentions from composer text', () {
    expect(service.extractHashtags('Bonjour #Product #design #product'), ['design', 'product']);
    expect(service.extractMentions('Salut @aicha et @nathan @aicha'), ['aicha', 'nathan']);
  });

  test('smart sorting keeps pinned posts first and then scores by engagement', () {
    final posts = [
      SocialPost(
        id: 'recent',
        author: author,
        content: 'Recent',
        kind: SocialPostKind.text,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likeCount: 1,
        commentCount: 1,
      ),
      SocialPost(
        id: 'popular',
        author: author,
        content: 'Popular',
        kind: SocialPostKind.reel,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likeCount: 40,
        commentCount: 12,
        shareCount: 7,
      ),
      SocialPost(
        id: 'pinned',
        author: author,
        content: 'Pinned',
        kind: SocialPostKind.text,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isPinned: true,
      ),
    ];

    final sorted = service.sortPosts(posts, SocialFeedSort.smart);

    expect(sorted.first.id, 'pinned');
    expect(sorted[1].id, 'popular');
  });

  test('query matching searches author, text, hashtags and community', () {
    final post = SocialPost(
      id: 'query-post',
      author: author,
      content: 'Construire un meilleur feed pour la communauté.',
      kind: SocialPostKind.text,
      createdAt: DateTime.now(),
      hashtags: const ['feed'],
      communityName: 'Builders Club',
    );

    expect(service.matchesQuery(post, 'aïcha'), isTrue);
    expect(service.matchesQuery(post, 'feed'), isTrue);
    expect(service.matchesQuery(post, 'builders'), isTrue);
    expect(service.matchesQuery(post, 'finance'), isFalse);
  });
}
