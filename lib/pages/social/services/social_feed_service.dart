import 'dart:math' as math;

import 'package:thix_central/pages/social/models/social_models.dart';

class SocialFeedService {
  const SocialFeedService();

  static final RegExp _hashtagRegExp = RegExp(r'(?:^|\s)#([A-Za-z0-9_]+)');
  static final RegExp _mentionRegExp = RegExp(r'(?:^|\s)@([A-Za-z0-9_.]+)');

  List<String> extractHashtags(String input) {
    return _hashtagRegExp.allMatches(input).map((match) => match.group(1)!.toLowerCase()).toSet().toList()..sort();
  }

  List<String> extractMentions(String input) {
    return _mentionRegExp.allMatches(input).map((match) => match.group(1)!.toLowerCase()).toSet().toList()..sort();
  }

  bool matchesQuery(SocialPost post, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return post.author.name.toLowerCase().contains(normalized) ||
        post.author.role.toLowerCase().contains(normalized) ||
        post.content.toLowerCase().contains(normalized) ||
        post.hashtags.any((tag) => tag.toLowerCase().contains(normalized)) ||
        post.mentions.any((mention) => mention.toLowerCase().contains(normalized)) ||
        (post.communityName?.toLowerCase().contains(normalized) ?? false);
  }

  List<SocialPost> sortPosts(List<SocialPost> posts, SocialFeedSort sort) {
    final sorted = [...posts];
    sorted.sort((left, right) {
      if (left.isPinned != right.isPinned) {
        return left.isPinned ? -1 : 1;
      }
      switch (sort) {
        case SocialFeedSort.recent:
          return right.createdAt.compareTo(left.createdAt);
        case SocialFeedSort.popular:
          final engagementOrder = right.engagementScore.compareTo(left.engagementScore);
          if (engagementOrder != 0) return engagementOrder;
          return right.createdAt.compareTo(left.createdAt);
        case SocialFeedSort.smart:
          final smartOrder = buildSmartScore(right).compareTo(buildSmartScore(left));
          if (smartOrder != 0) return smartOrder;
          return right.createdAt.compareTo(left.createdAt);
      }
    });
    return sorted;
  }

  double buildSmartScore(SocialPost post) {
    final ageHours = math.max(1, DateTime.now().difference(post.createdAt).inHours);
    final freshnessBoost = 120 / ageHours;
    final connectionBoost = post.author.mutualConnections * 8;
    final mediaBoost = post.mediaUrls.isEmpty ? 0 : 12;
    final formatBoost = switch (post.kind) {
      SocialPostKind.reel => 16,
      SocialPostKind.challenge => 14,
      SocialPostKind.poll => 10,
      SocialPostKind.video => 8,
      SocialPostKind.image => 6,
      SocialPostKind.repost => 5,
      SocialPostKind.text => 0,
    };
    final pinnedBoost = post.isPinned ? 1000 : 0;
    return pinnedBoost + post.engagementScore + freshnessBoost + connectionBoost + mediaBoost + formatBoost;
  }

  SocialPost applyComposerData({
    required SocialPost base,
    required SocialComposerInput input,
  }) {
    final poll = input.kind == SocialPostKind.poll && input.pollQuestion != null
        ? SocialPoll(
            question: input.pollQuestion!,
            options: input.pollOptions
                .where((option) => option.trim().isNotEmpty)
                .map((option) => SocialPollOption(id: option, label: option.trim(), votes: 0))
                .toList(),
            expiresAt: DateTime.now().add(const Duration(days: 3)),
          )
        : null;
    final challenge = input.kind == SocialPostKind.challenge && input.challengeTitle != null
        ? SocialChallenge(
            title: input.challengeTitle!,
            prize: input.challengePrize ?? 'Prix à annoncer',
            participants: 0,
            leaderboardPreview: const <String>[],
            deadline: DateTime.now().add(const Duration(days: 7)),
          )
        : null;
    return base.copyWith(
      kind: input.kind,
      mediaUrls: input.mediaUrls,
      communityName: input.communityName,
      quote: input.quote,
      poll: poll,
      challenge: challenge,
      hashtags: extractHashtags(input.content),
      mentions: extractMentions(input.content),
      repostOfPostId: input.repostSource?.id,
      repostAuthorName: input.repostSource?.author.name,
    );
  }
}
