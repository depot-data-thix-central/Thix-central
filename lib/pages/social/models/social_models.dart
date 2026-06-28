import 'package:flutter/foundation.dart';

@immutable
class SocialAuthor {
  const SocialAuthor({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.isVerified = false,
    this.mutualConnections = 0,
  });

  final String id;
  final String name;
  final String role;
  final String? avatarUrl;
  final bool isVerified;
  final int mutualConnections;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'TH';
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  SocialAuthor copyWith({
    String? id,
    String? name,
    String? role,
    String? avatarUrl,
    bool? isVerified,
    int? mutualConnections,
  }) {
    return SocialAuthor(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      mutualConnections: mutualConnections ?? this.mutualConnections,
    );
  }

  factory SocialAuthor.fromJson(Map<String, dynamic> json) {
    return SocialAuthor(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['author_name'] ?? 'Membre THIX').toString(),
      role: (json['role'] ?? json['author_role'] ?? 'Professionnel').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      isVerified: json['is_verified'] as bool? ?? false,
      mutualConnections: (json['mutual_connections'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'avatar_url': avatarUrl,
        'is_verified': isVerified,
        'mutual_connections': mutualConnections,
      };
}

enum SocialFeedSort { smart, recent, popular }

enum SocialPostKind { text, image, video, reel, poll, challenge, repost }

enum SocialVisibility { public, community, followers }

@immutable
class SocialPollOption {
  const SocialPollOption({
    required this.id,
    required this.label,
    required this.votes,
    this.isSelected = false,
  });

  final String id;
  final String label;
  final int votes;
  final bool isSelected;

  SocialPollOption copyWith({
    String? id,
    String? label,
    int? votes,
    bool? isSelected,
  }) {
    return SocialPollOption(
      id: id ?? this.id,
      label: label ?? this.label,
      votes: votes ?? this.votes,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  factory SocialPollOption.fromJson(Map<String, dynamic> json) {
    return SocialPollOption(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      isSelected: json['is_selected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'votes': votes,
        'is_selected': isSelected,
      };
}

@immutable
class SocialPoll {
  const SocialPoll({
    required this.question,
    required this.options,
    this.expiresAt,
    this.hasVoted = false,
  });

  final String question;
  final List<SocialPollOption> options;
  final DateTime? expiresAt;
  final bool hasVoted;

  int get totalVotes => options.fold(0, (sum, option) => sum + option.votes);

  SocialPoll copyWith({
    String? question,
    List<SocialPollOption>? options,
    DateTime? expiresAt,
    bool? hasVoted,
  }) {
    return SocialPoll(
      question: question ?? this.question,
      options: options ?? this.options,
      expiresAt: expiresAt ?? this.expiresAt,
      hasVoted: hasVoted ?? this.hasVoted,
    );
  }

  factory SocialPoll.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List? ?? const [];
    return SocialPoll(
      question: (json['question'] ?? '').toString(),
      options: rawOptions.whereType<Map>().map((option) => SocialPollOption.fromJson(option.cast<String, dynamic>())).toList(),
      expiresAt: json['expires_at'] is String ? DateTime.tryParse(json['expires_at'] as String) : null,
      hasVoted: json['has_voted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options.map((option) => option.toJson()).toList(),
        'expires_at': expiresAt?.toIso8601String(),
        'has_voted': hasVoted,
      };
}

@immutable
class SocialChallenge {
  const SocialChallenge({
    required this.title,
    required this.prize,
    required this.participants,
    required this.leaderboardPreview,
    this.deadline,
  });

  final String title;
  final String prize;
  final int participants;
  final List<String> leaderboardPreview;
  final DateTime? deadline;

  SocialChallenge copyWith({
    String? title,
    String? prize,
    int? participants,
    List<String>? leaderboardPreview,
    DateTime? deadline,
  }) {
    return SocialChallenge(
      title: title ?? this.title,
      prize: prize ?? this.prize,
      participants: participants ?? this.participants,
      leaderboardPreview: leaderboardPreview ?? this.leaderboardPreview,
      deadline: deadline ?? this.deadline,
    );
  }

  factory SocialChallenge.fromJson(Map<String, dynamic> json) {
    return SocialChallenge(
      title: (json['title'] ?? '').toString(),
      prize: (json['prize'] ?? '').toString(),
      participants: (json['participants'] as num?)?.toInt() ?? 0,
      leaderboardPreview: (json['leaderboard_preview'] as List? ?? const []).map((item) => item.toString()).toList(),
      deadline: json['deadline'] is String ? DateTime.tryParse(json['deadline'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'prize': prize,
        'participants': participants,
        'leaderboard_preview': leaderboardPreview,
        'deadline': deadline?.toIso8601String(),
      };
}

@immutable
class SocialComment {
  const SocialComment({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final SocialAuthor author;
  final String text;
  final DateTime createdAt;

  SocialComment copyWith({
    String? id,
    SocialAuthor? author,
    String? text,
    DateTime? createdAt,
  }) {
    return SocialComment(
      id: id ?? this.id,
      author: author ?? this.author,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    return SocialComment(
      id: (json['id'] ?? '').toString(),
      author: SocialAuthor.fromJson({
        'id': json['author_id'],
        'author_name': json['author_name'],
        'author_role': json['author_role'],
        'avatar_url': json['author_avatar_url'],
      }),
      text: (json['text'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_id': author.id,
        'author_name': author.name,
        'author_role': author.role,
        'author_avatar_url': author.avatarUrl,
        'text': text,
        'created_at': createdAt.toIso8601String(),
      };
}

@immutable
class SocialPost {
  const SocialPost({
    required this.id,
    required this.author,
    required this.content,
    required this.kind,
    required this.createdAt,
    this.updatedAt,
    this.visibility = SocialVisibility.public,
    this.mediaUrls = const <String>[],
    this.hashtags = const <String>[],
    this.mentions = const <String>[],
    this.comments = const <SocialComment>[],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.viewCount = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isPinned = false,
    this.communityName,
    this.quote,
    this.poll,
    this.challenge,
    this.repostOfPostId,
    this.repostAuthorName,
  });

  final String id;
  final SocialAuthor author;
  final String content;
  final SocialPostKind kind;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final SocialVisibility visibility;
  final List<String> mediaUrls;
  final List<String> hashtags;
  final List<String> mentions;
  final List<SocialComment> comments;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewCount;
  final bool isLiked;
  final bool isBookmarked;
  final bool isPinned;
  final String? communityName;
  final String? quote;
  final SocialPoll? poll;
  final SocialChallenge? challenge;
  final String? repostOfPostId;
  final String? repostAuthorName;

  double get engagementScore => likeCount * 2 + commentCount * 3 + shareCount * 2 + (viewCount / 25);

  SocialPost copyWith({
    String? id,
    SocialAuthor? author,
    String? content,
    SocialPostKind? kind,
    DateTime? createdAt,
    DateTime? updatedAt,
    SocialVisibility? visibility,
    List<String>? mediaUrls,
    List<String>? hashtags,
    List<String>? mentions,
    List<SocialComment>? comments,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    int? viewCount,
    bool? isLiked,
    bool? isBookmarked,
    bool? isPinned,
    String? communityName,
    String? quote,
    SocialPoll? poll,
    SocialChallenge? challenge,
    String? repostOfPostId,
    String? repostAuthorName,
  }) {
    return SocialPost(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      visibility: visibility ?? this.visibility,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      comments: comments ?? this.comments,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      viewCount: viewCount ?? this.viewCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isPinned: isPinned ?? this.isPinned,
      communityName: communityName ?? this.communityName,
      quote: quote ?? this.quote,
      poll: poll ?? this.poll,
      challenge: challenge ?? this.challenge,
      repostOfPostId: repostOfPostId ?? this.repostOfPostId,
      repostAuthorName: repostAuthorName ?? this.repostAuthorName,
    );
  }

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final rawComments = json['comments'] as List? ?? const [];
    final rawMedia = json['media_urls'] as List? ?? const [];
    final rawHashtags = json['hashtags'] as List? ?? const [];
    final rawMentions = json['mentions'] as List? ?? const [];
    final kind = switch ((json['kind'] ?? 'text').toString()) {
      'image' => SocialPostKind.image,
      'video' => SocialPostKind.video,
      'reel' => SocialPostKind.reel,
      'poll' => SocialPostKind.poll,
      'challenge' => SocialPostKind.challenge,
      'repost' => SocialPostKind.repost,
      _ => SocialPostKind.text,
    };
    final visibility = switch ((json['visibility'] ?? 'public').toString()) {
      'community' => SocialVisibility.community,
      'followers' => SocialVisibility.followers,
      _ => SocialVisibility.public,
    };
    return SocialPost(
      id: (json['id'] ?? '').toString(),
      author: SocialAuthor.fromJson({
        'id': json['author_id'],
        'author_name': json['author_name'],
        'author_role': json['author_role'],
        'avatar_url': json['author_avatar_url'],
        'is_verified': json['author_is_verified'],
        'mutual_connections': json['author_mutual_connections'],
      }),
      content: (json['content'] ?? '').toString(),
      kind: kind,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: json['updated_at'] is String ? DateTime.tryParse(json['updated_at'] as String) : null,
      visibility: visibility,
      mediaUrls: rawMedia.map((item) => item.toString()).where((item) => item.isNotEmpty).toList(),
      hashtags: rawHashtags.map((item) => item.toString()).where((item) => item.isNotEmpty).toList(),
      mentions: rawMentions.map((item) => item.toString()).where((item) => item.isNotEmpty).toList(),
      comments: rawComments.whereType<Map>().map((item) => SocialComment.fromJson(item.cast<String, dynamic>())).toList(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? rawComments.length,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      isPinned: json['is_pinned'] as bool? ?? false,
      communityName: json['community_name']?.toString(),
      quote: json['quote']?.toString(),
      poll: json['poll'] is Map ? SocialPoll.fromJson((json['poll'] as Map).cast<String, dynamic>()) : null,
      challenge: json['challenge'] is Map ? SocialChallenge.fromJson((json['challenge'] as Map).cast<String, dynamic>()) : null,
      repostOfPostId: json['repost_of_post_id']?.toString(),
      repostAuthorName: json['repost_author_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_id': author.id,
        'author_name': author.name,
        'author_role': author.role,
        'author_avatar_url': author.avatarUrl,
        'author_is_verified': author.isVerified,
        'author_mutual_connections': author.mutualConnections,
        'content': content,
        'kind': kind.name,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'visibility': visibility.name,
        'media_urls': mediaUrls,
        'hashtags': hashtags,
        'mentions': mentions,
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'like_count': likeCount,
        'comment_count': commentCount,
        'share_count': shareCount,
        'view_count': viewCount,
        'is_liked': isLiked,
        'is_bookmarked': isBookmarked,
        'is_pinned': isPinned,
        'community_name': communityName,
        'quote': quote,
        'poll': poll?.toJson(),
        'challenge': challenge?.toJson(),
        'repost_of_post_id': repostOfPostId,
        'repost_author_name': repostAuthorName,
      };
}

@immutable
class SocialStory {
  const SocialStory({
    required this.id,
    required this.author,
    required this.createdAt,
    required this.expiresAt,
    this.mediaUrl,
    this.caption,
    this.isVideo = false,
    this.viewCount = 0,
    this.isViewed = false,
  });

  final String id;
  final SocialAuthor author;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? mediaUrl;
  final String? caption;
  final bool isVideo;
  final int viewCount;
  final bool isViewed;

  SocialStory copyWith({
    String? id,
    SocialAuthor? author,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? mediaUrl,
    String? caption,
    bool? isVideo,
    int? viewCount,
    bool? isViewed,
  }) {
    return SocialStory(
      id: id ?? this.id,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      caption: caption ?? this.caption,
      isVideo: isVideo ?? this.isVideo,
      viewCount: viewCount ?? this.viewCount,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  factory SocialStory.fromJson(Map<String, dynamic> json) {
    final authorJson = (json['author'] is Map) ? (json['author'] as Map).cast<String, dynamic>() : <String, dynamic>{};
    return SocialStory(
      id: (json['id'] ?? '').toString(),
      author: SocialAuthor.fromJson({
        'id': json['user_id'] ?? authorJson['id'],
        'author_name': authorJson['display_name'] ?? authorJson['name'] ?? json['author_name'],
        'author_role': authorJson['occupation'] ?? authorJson['role'] ?? json['author_role'],
        'avatar_url': authorJson['avatar_url'] ?? json['author_avatar_url'],
        'is_verified': authorJson['is_verified'] ?? json['author_is_verified'],
      }),
      mediaUrl: json['media_url']?.toString() ?? json['mediaUrl']?.toString(),
      caption: json['caption']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: DateTime.tryParse((json['expires_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      isVideo: (json['is_video'] as bool?) ?? false,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      isViewed: (json['is_viewed'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': author.id,
        'media_url': mediaUrl,
        'caption': caption,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_video': isVideo,
        'view_count': viewCount,
        'is_viewed': isViewed,
      };
}

@immutable
class SocialHighlight {
  const SocialHighlight({
    required this.id,
    required this.title,
    required this.storyCount,
  });

  final String id;
  final String title;
  final int storyCount;
}

@immutable
class SocialCommunity {
  const SocialCommunity({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    this.isPrivate = false,
    this.role = 'member',
    this.isJoined = false,
  });

  final String id;
  final String name;
  final String description;
  final int memberCount;
  final bool isPrivate;
  final String role;
  final bool isJoined;
}

@immutable
class SocialConnectionSuggestion {
  const SocialConnectionSuggestion({
    required this.id,
    required this.name,
    required this.role,
    required this.mutualConnections,
    this.isRequested = false,
    this.isConnected = false,
    this.isBlocked = false,
  });

  final String id;
  final String name;
  final String role;
  final int mutualConnections;
  final bool isRequested;
  final bool isConnected;
  final bool isBlocked;

  SocialConnectionSuggestion copyWith({
    String? id,
    String? name,
    String? role,
    int? mutualConnections,
    bool? isRequested,
    bool? isConnected,
    bool? isBlocked,
  }) {
    return SocialConnectionSuggestion(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      mutualConnections: mutualConnections ?? this.mutualConnections,
      isRequested: isRequested ?? this.isRequested,
      isConnected: isConnected ?? this.isConnected,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}

@immutable
class SocialNotificationItem {
  const SocialNotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isUnread = true,
    this.type = 'general',
  });

  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isUnread;
  final String type;

  SocialNotificationItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    bool? isUnread,
    String? type,
  }) {
    return SocialNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isUnread: isUnread ?? this.isUnread,
      type: type ?? this.type,
    );
  }
}

@immutable
class SocialConversation {
  const SocialConversation({
    required this.id,
    required this.peerName,
    required this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
    this.attachmentCount = 0,
    this.isSeen = true,
  });

  final String id;
  final String peerName;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount;
  final int attachmentCount;
  final bool isSeen;
}

@immutable
class SocialAnalyticsSnapshot {
  const SocialAnalyticsSnapshot({
    required this.profileViews,
    required this.contentViews,
    required this.likes,
    required this.comments,
  });

  final int profileViews;
  final int contentViews;
  final int likes;
  final int comments;
}

@immutable
class SocialModerationSnapshot {
  const SocialModerationSnapshot({
    required this.hiddenPosts,
    required this.reportedPosts,
    required this.blockedUsers,
    required this.rlsReady,
  });

  final int hiddenPosts;
  final int reportedPosts;
  final int blockedUsers;
  final bool rlsReady;
}

@immutable
class SocialModuleSnapshot {
  const SocialModuleSnapshot({
    this.feed = const <SocialPost>[],
    this.stories = const <SocialStory>[],
    this.highlights = const <SocialHighlight>[],
    this.communities = const <SocialCommunity>[],
    this.suggestions = const <SocialConnectionSuggestion>[],
    this.notifications = const <SocialNotificationItem>[],
    this.conversations = const <SocialConversation>[],
    this.trendingHashtags = const <String>[],
    this.analytics = const SocialAnalyticsSnapshot(profileViews: 0, contentViews: 0, likes: 0, comments: 0),
    this.moderation = const SocialModerationSnapshot(hiddenPosts: 0, reportedPosts: 0, blockedUsers: 0, rlsReady: false),
  });

  final List<SocialPost> feed;
  final List<SocialStory> stories;
  final List<SocialHighlight> highlights;
  final List<SocialCommunity> communities;
  final List<SocialConnectionSuggestion> suggestions;
  final List<SocialNotificationItem> notifications;
  final List<SocialConversation> conversations;
  final List<String> trendingHashtags;
  final SocialAnalyticsSnapshot analytics;
  final SocialModerationSnapshot moderation;

  SocialModuleSnapshot copyWith({
    List<SocialPost>? feed,
    List<SocialStory>? stories,
    List<SocialHighlight>? highlights,
    List<SocialCommunity>? communities,
    List<SocialConnectionSuggestion>? suggestions,
    List<SocialNotificationItem>? notifications,
    List<SocialConversation>? conversations,
    List<String>? trendingHashtags,
    SocialAnalyticsSnapshot? analytics,
    SocialModerationSnapshot? moderation,
  }) {
    return SocialModuleSnapshot(
      feed: feed ?? this.feed,
      stories: stories ?? this.stories,
      highlights: highlights ?? this.highlights,
      communities: communities ?? this.communities,
      suggestions: suggestions ?? this.suggestions,
      notifications: notifications ?? this.notifications,
      conversations: conversations ?? this.conversations,
      trendingHashtags: trendingHashtags ?? this.trendingHashtags,
      analytics: analytics ?? this.analytics,
      moderation: moderation ?? this.moderation,
    );
  }
}

@immutable
class SocialComposerInput {
  const SocialComposerInput({
    required this.content,
    this.kind = SocialPostKind.text,
    this.mediaUrls = const <String>[],
    this.communityName,
    this.quote,
    this.pollQuestion,
    this.pollOptions = const <String>[],
    this.challengeTitle,
    this.challengePrize,
    this.repostSource,
  });

  final String content;
  final SocialPostKind kind;
  final List<String> mediaUrls;
  final String? communityName;
  final String? quote;
  final String? pollQuestion;
  final List<String> pollOptions;
  final String? challengeTitle;
  final String? challengePrize;
  final SocialPost? repostSource;
}
