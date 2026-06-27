import 'package:flutter/material.dart';
import 'package:thix_central/pages/social/models/social_models.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

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

class SocialStoryStrip extends StatelessWidget {
  const SocialStoryStrip({super.key, required this.stories, required this.highlights});

  final List<SocialStory> stories;
  final List<SocialHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    return SocialSectionCard(
      title: 'Stories & highlights',
      subtitle: 'Stories 24h, vues et collections épinglées.',
      child: Column(
        children: [
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: stories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final story = stories[index];
                final borderColor = story.isViewed ? AppColors.cardBorder : AppColors.primaryBlue;
                return Column(
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
}

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

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onBookmark,
    required this.onShare,
    required this.onRepost,
  });

  final SocialPost post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onRepost;

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
              child: Text('Repost de ${post.repostAuthorName}', style: context.textStyles.labelMedium?.copyWith(color: AppColors.textSecondary)),
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
              children: post.mediaUrls
                  .map(
                    (url) => Container(
                      width: 180,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.serviceCard),
                        gradient: AppColors.primaryBlueGradient,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(post.kind == SocialPostKind.video || post.kind == SocialPostKind.reel ? Icons.play_circle_fill : Icons.image_outlined, color: Colors.white),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            url,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.bodySmall?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (post.poll != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(post.poll!.question, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            ...post.poll!.options.map(
              (option) {
                final totalVotes = post.poll!.totalVotes == 0 ? 1 : post.poll!.totalVotes;
                final progress = option.votes / totalVotes;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(option.label),
                          Text('${option.votes} votes', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(value: progress, minHeight: 8),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          if (post.challenge != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.lightGrayBackground,
                borderRadius: BorderRadius.circular(AppRadius.serviceCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.challenge!.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Prix : ${post.challenge!.prize}'),
                  Text('${post.challenge!.participants} participants'),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: post.challenge!.leaderboardPreview.map((item) => Chip(label: Text(item))).toList(),
                  ),
                ],
              ),
            ),
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

class SocialSidebarSection extends StatelessWidget {
  const SocialSidebarSection({super.key, required this.snapshot, required this.onToggleConnection, required this.onNotificationTap});

  final SocialModuleSnapshot snapshot;
  final Future<void> Function(String) onToggleConnection;
  final Future<void> Function(String) onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SocialSectionCard(
          title: 'Communautés',
          subtitle: 'Création, rôles et visibilité public/privé.',
          child: Column(
            children: snapshot.communities
                .map(
                  (community) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: AppColors.lightGrayBackground, child: Icon(community.isPrivate ? Icons.lock_outline : Icons.groups_outlined)),
                    title: Text(community.name),
                    subtitle: Text('${community.memberCount} membres · ${community.isPrivate ? 'Privé' : 'Public'}'),
                    trailing: Text(community.isJoined ? community.role : 'Rejoindre', style: context.textStyles.labelMedium?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SocialSectionCard(
          title: 'Connexions suggérées',
          subtitle: 'Demandes, amis et abonnements.',
          child: Column(
            children: snapshot.suggestions
                .map(
                  (suggestion) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: AppColors.lightGrayBackground, child: Text(suggestion.name.substring(0, 1))),
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
        SocialSectionCard(
          title: 'Messages privés',
          subtitle: 'Temps réel, pièces jointes et accusés de lecture.',
          child: Column(
            children: snapshot.conversations
                .map(
                  (conversation) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: AppColors.lightGrayBackground, child: Text(conversation.peerName.substring(0, 1))),
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
