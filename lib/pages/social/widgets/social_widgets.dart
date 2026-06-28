import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:thix_central/pages/social/models/social_models.dart';
import 'package:thix_central/pages/social/providers/social_module_controller.dart';
import 'package:thix_central/pages/social/widgets/story_viewer_page.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';
import 'package:provider/provider.dart';

// ============================================================
// Carte de section générique
// ============================================================
class SocialSectionCard extends StatelessWidget {
  const SocialSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [AppShadows.secondary],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(subtitle!, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// Stripe des stories (avec création)
// ============================================================
class SocialStoryStrip extends StatelessWidget {
  const SocialStoryStrip({super.key, required this.stories, required this.highlights});

  final List<SocialStory> stories;
  final List<SocialHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SocialModuleController>();
    return SocialSectionCard(
      title: 'Stories & highlights',
      subtitle: 'Stories 24h, vues et collections épinglées.',
      trailing: TextButton.icon(
        onPressed: () => _showCreateStorySheet(context, controller),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Créer'),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length + 1, // +1 pour le bouton "Créer"
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _StoryCreateButton(onTap: () => _showCreateStorySheet(context, controller));
                }
                final story = stories[index - 1];
                return _StoryTile(
                  story: story,
                  onTap: () => _openStory(context, story),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: highlights
                .map(
                  (highlight) => Chip(
                    label: Text('${highlight.title} · ${highlight.storyCount}'),
                    avatar: const Icon(Icons.auto_awesome, size: 16),
                    backgroundColor: AppColors.lightGrayBackground,
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showCreateStorySheet(BuildContext context, SocialModuleController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    try {
      await controller.createStory(mediaFile: file);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Story publiée')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  void _openStory(BuildContext context, SocialStory story) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryViewerPage(story: story)),
    );
  }
}

class _StoryCreateButton extends StatelessWidget {
  const _StoryCreateButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.lightGrayBackground,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.primaryBlue, size: 28),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Créer', style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.story, required this.onTap});
  final SocialStory story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = story.isViewed ? AppColors.cardBorder : AppColors.primaryBlue;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
            ),
            child: ThixAvatar(initials: story.author.initials),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(story.author.name, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
          Text('${story.viewCount} vues', style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ============================================================
// Statistiques
// ============================================================
class SocialStatsRow extends StatelessWidget {
  const SocialStatsRow({super.key, required this.analytics, required this.unreadNotifications, required this.unreadMessages});

  final SocialAnalyticsSnapshot analytics;
  final int unreadNotifications;
  final int unreadMessages;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.visibility_outlined,
            label: 'Visites profil',
            value: analytics.profileViews.toString(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.favorite_border,
            label: 'Likes',
            value: analytics.likes.toString(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.notifications_none,
            label: 'Badges live',
            value: '${unreadNotifications + unreadMessages}',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.serviceCard),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ============================================================
// Sélecteur de tri
// ============================================================
class SocialSortSelector extends StatelessWidget {
  const SocialSortSelector({super.key, required this.sort, required this.onChanged});

  final SocialFeedSort sort;
  final ValueChanged<SocialFeedSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: SocialFeedSort.values
          .map(
            (value) => ChoiceChip(
              label: Text(
                switch (value) {
                  SocialFeedSort.smart => 'Feed intelligent',
                  SocialFeedSort.recent => 'Récent',
                  SocialFeedSort.popular => 'Populaire',
                },
              ),
              selected: value == sort,
              onSelected: (_) => onChanged(value),
            ),
          )
          .toList(),
    );
  }
}

// ============================================================
// Carte d'un post (complète)
// ============================================================
class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onBookmark,
    required this.onShare,
    required this.onRepost,
    required this.onPollVote,
  });

  final SocialPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onRepost;
  final ValueChanged<String> onPollVote;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SocialSectionCard(
      title: post.author.name,
      subtitle: '${post.author.role} · ${_timeAgo(post.createdAt)}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (post.isPinned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightGrayBackground,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Text('Épinglé', style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: AppSpacing.sm),
          ThixAvatar(initials: post.author.initials),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.communityName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Chip(
                label: Text(post.communityName!),
                avatar: const Icon(Icons.groups_outlined, size: 16),
                backgroundColor: AppColors.lightGrayBackground,
                side: const BorderSide(color: AppColors.cardBorder),
              ),
            ),
          if (post.kind == SocialPostKind.repost && post.repostAuthorName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Repost de ${post.repostAuthorName}',
                style: context.textStyles.labelMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          if (post.quote != null && post.quote!.trim().isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.lightGrayBackground,
                borderRadius: BorderRadius.circular(AppRadius.serviceCard),
              ),
              child: Text('“${post.quote!}”', style: context.textStyles.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
            ),
          Text(post.content, style: context.textStyles.bodyLarge?.copyWith(color: cs.onSurface)),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: post.mediaUrls.map((url) => _MediaPreview(url: url, kind: post.kind)).toList(),
            ),
          ],
          if (post.poll != null) ...[
            const SizedBox(height: AppSpacing.md),
            _PollWidget(
              poll: post.poll!,
              onVote: (optionId) {
                if (!post.poll!.hasVoted) {
                  onPollVote(optionId);
                }
              },
            ),
          ],
          if (post.challenge != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ChallengeWidget(challenge: post.challenge!),
          ],
          if (post.hashtags.isNotEmpty || post.mentions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ...post.hashtags.map((tag) => Chip(label: Text('#$tag'))),
                ...post.mentions.map((mention) => Chip(label: Text('@$mention'))),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _ActionButton(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                color: post.isLiked ? AppColors.dangerRed : AppColors.textSecondary,
                label: '${post.likeCount}',
                onTap: onLike,
              ),
              _ActionButton(icon: Icons.mode_comment_outlined, label: '${post.commentCount}', onTap: onComment),
              _ActionButton(icon: Icons.repeat, label: '${post.shareCount}', onTap: onRepost),
              _ActionButton(icon: post.isBookmarked ? Icons.bookmark : Icons.bookmark_border, label: 'Sauvegarder', onTap: onBookmark),
              _ActionButton(icon: Icons.share_outlined, label: 'Partager', onTap: onShare),
            ],
          ),
          if (post.comments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            ...post.comments.take(2).map(
                  (comment) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ThixAvatar(size: 28, initials: comment.author.initials),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(comment.author.name, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                              Text(comment.text),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 60) return 'il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'il y a ${difference.inHours} h';
    return 'il y a ${difference.inDays} j';
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.url, required this.kind});
  final String url;
  final SocialPostKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 80,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.serviceCard),
        gradient: AppColors.primaryBlueGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            kind == SocialPostKind.video || kind == SocialPostKind.reel ? Icons.play_circle_fill : Icons.image_outlined,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            url.split('/').last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PollWidget extends StatelessWidget {
  const _PollWidget({required this.poll, required this.onVote});
  final SocialPoll poll;
  final ValueChanged<String> onVote;

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.totalVotes == 0 ? 1 : poll.totalVotes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(poll.question, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        ...poll.options.map(
          (option) {
            final progress = option.votes / totalVotes;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: poll.hasVoted ? null : () => onVote(option.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (option.isSelected)
                              const Icon(Icons.check_circle, size: 16, color: AppColors.primaryBlue),
                            const SizedBox(width: 4),
                            Text(option.label),
                          ],
                        ),
                        Text(
                          poll.hasVoted ? '${option.votes} votes (${(progress * 100).round()}%)' : '',
                          style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.lightGrayBackground,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          option.isSelected ? AppColors.primaryBlue : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (!poll.hasVoted)
          Text(
            '${poll.options.first.votes + poll.options.last.votes + 1} votes reçus · Sondage actif',
            style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
      ],
    );
  }
}

class _ChallengeWidget extends StatelessWidget {
  const _ChallengeWidget({required this.challenge});
  final SocialChallenge challenge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightGrayBackground,
        borderRadius: BorderRadius.circular(AppRadius.serviceCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(challenge.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text('Prix : ${challenge.prize}'),
          Text('${challenge.participants} participants'),
          Text('Fin : ${_formatDate(challenge.deadline)}'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: challenge.leaderboardPreview.map((item) => Chip(label: Text(item))).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color = AppColors.textSecondary});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 1, end: color == AppColors.dangerRed ? 1.15 : 1),
              duration: const Duration(milliseconds: 220),
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 6),
            Text(label, style: context.textStyles.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Sidebar (communautés, suggestions, notifications, messages)
// ============================================================
class SocialSidebarSection extends StatelessWidget {
  const SocialSidebarSection({
    super.key,
    required this.snapshot,
    required this.onToggleConnection,
    required this.onNotificationTap,
    required this.onCommunityJoin,
    required this.onMessageTap,
  });

  final SocialModuleSnapshot snapshot;
  final Future<void> Function(String) onToggleConnection;
  final Future<void> Function(String) onNotificationTap;
  final void Function(SocialCommunity) onCommunityJoin;
  final void Function(SocialConversation) onMessageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Communautés
        SocialSectionCard(
          title: 'Communautés',
          subtitle: 'Création, rôles et visibilité public/privé.',
          child: Column(
            children: snapshot.communities
                .map(
                  (community) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.lightGrayBackground,
                      child: Icon(community.isPrivate ? Icons.lock_outline : Icons.groups_outlined),
                    ),
                    title: Text(community.name),
                    subtitle: Text('${community.memberCount} membres · ${community.isPrivate ? 'Privé' : 'Public'}'),
                    trailing: TextButton(
                      onPressed: () => onCommunityJoin(community),
                      child: Text(community.isJoined ? community.role : 'Rejoindre'),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Suggestions de connexions
        SocialSectionCard(
          title: 'Connexions suggérées',
          subtitle: 'Demandes, amis et abonnements.',
          child: Column(
            children: snapshot.suggestions
                .map(
                  (suggestion) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.lightGrayBackground,
                      child: Text(suggestion.name.substring(0, 1)),
                    ),
                    title: Text(suggestion.name),
                    subtitle: Text('${suggestion.role} · ${suggestion.mutualConnections} relations communes'),
                    trailing: TextButton(
                      onPressed: () => onToggleConnection(suggestion.id),
                      child: Text(
                        suggestion.isConnected
                            ? 'Connecté'
                            : suggestion.isRequested
                                ? 'Accepter'
                                : suggestion.isBlocked
                                    ? 'Débloquer'
                                    : 'Inviter',
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Notifications
        SocialSectionCard(
          title: 'Notifications',
          subtitle: 'Centre centralisé et badges temps réel.',
          child: Column(
            children: snapshot.notifications
                .map(
                  (notification) => ListTile(
                    onTap: () => onNotificationTap(notification.id),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: notification.isUnread ? AppColors.primaryBlue.withOpacity(0.12) : AppColors.lightGrayBackground,
                      child: Icon(
                        switch (notification.type) {
                          'like' => Icons.favorite_border,
                          'comment' => Icons.mode_comment_outlined,
                          'connection' => Icons.person_add_alt_1_outlined,
                          _ => Icons.notifications_none,
                        },
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    title: Text(notification.title),
                    subtitle: Text(notification.description),
                    trailing: notification.isUnread ? const Icon(Icons.circle, size: 10, color: AppColors.primaryBlue) : null,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Messages privés
        SocialSectionCard(
          title: 'Messages privés',
          subtitle: 'Temps réel, pièces jointes et accusés de lecture.',
          child: Column(
            children: snapshot.conversations
                .map(
                  (conversation) => ListTile(
                    onTap: () => onMessageTap(conversation),
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.lightGrayBackground,
                      child: Text(conversation.peerName.substring(0, 1)),
                    ),
                    title: Text(conversation.peerName),
                    subtitle: Text(conversation.lastMessage, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (conversation.attachmentCount > 0) const Icon(Icons.attach_file, size: 16),
                        if (conversation.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(999)),
                            child: Text('${conversation.unreadCount}', style: context.textStyles.labelSmall?.copyWith(color: Colors.white)),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Tendances
        SocialSectionCard(
          title: 'Recherche & tendances',
          subtitle: 'Hashtags tendances et navigation par mots-clés.',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: snapshot.trendingHashtags.map((hashtag) => Chip(label: Text(hashtag))).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Modération
        SocialSectionCard(
          title: 'Modération & sécurité',
          subtitle: 'Signalement, masquage, blocages et RLS Supabase.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bullet(context, 'Posts masqués : ${snapshot.moderation.hiddenPosts}'),
              _bullet(context, 'Signalements : ${snapshot.moderation.reportedPosts}'),
              _bullet(context, 'Utilisateurs bloqués : ${snapshot.moderation.blockedUsers}'),
              _bullet(context, 'RLS déployée : ${snapshot.moderation.rlsReady ? 'Oui' : 'Non'}'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Prochain lot prévu : notifications email et thèmes personnalisés pour la messagerie.',
                style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.successGreen),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: context.textStyles.bodySmall)),
        ],
      ),
    );
  }
}

// ============================================================
// Widget d'upload (réutilisable)
// ============================================================
class SocialUploadButton extends StatelessWidget {
  const SocialUploadButton({
    super.key,
    required this.label,
    required this.onUpload,
    this.icon = Icons.upload_file,
    this.fileType = FileType.media,
    this.allowedExtensions,
  });

  final String label;
  final Future<void> Function(File file) onUpload;
  final IconData icon;
  final FileType fileType;
  final List<String>? allowedExtensions;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles(
          type: fileType,
          allowedExtensions: allowedExtensions,
          withData: true,
        );
        if (result == null || result.files.isEmpty) return;
        final file = File(result.files.single.path!);
        try {
          await onUpload(file);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label uploadé avec succès')),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
