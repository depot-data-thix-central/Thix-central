import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thix_central/pages/social/models/social_models.dart';
import 'package:thix_central/pages/social/providers/social_module_controller.dart';
import 'package:thix_central/pages/social/repositories/social_repository.dart';
import 'package:thix_central/pages/social/widgets/social_widgets.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class SocialHomePage extends StatelessWidget {
  const SocialHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SocialModuleController(repository: ThixSocialRepository())..initialize(),
      child: const _SocialHomeView(),
    );
  }
}

class _SocialHomeView extends StatelessWidget {
  const _SocialHomeView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SocialModuleController>();
    final unreadMessages = controller.snapshot.conversations.where((item) => item.unreadCount > 0).length;
    final body = controller.isLoading && controller.snapshot.feed.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1080;
              final feedColumn = _FeedColumn(controller: controller);
              final sidebar = SocialSidebarSection(
                snapshot: controller.snapshot,
                onToggleConnection: controller.toggleConnection,
                onNotificationTap: controller.markNotificationAsRead,
              );
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: feedColumn),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: sidebar),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  feedColumn,
                  const SizedBox(height: AppSpacing.md),
                  sidebar,
                ],
              );
            },
          );
    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX RÉSEAU PRO',
        subtitle: 'Feed, communautés, stories et messagerie.',
        onMenuTap: () {},
        trailing: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
            if (controller.unreadNotificationCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${controller.unreadNotificationCount}',
                    style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => _showComposer(context, controller),
        icon: const Icon(Icons.add, color: AppColors.white),
        label: const Text('Créer', style: TextStyle(color: AppColors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: controller.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              SocialStatsRow(
                analytics: controller.snapshot.analytics,
                unreadNotifications: controller.unreadNotificationCount,
                unreadMessages: unreadMessages,
              ),
              const SizedBox(height: AppSpacing.md),
              if (controller.error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.serviceCard),
                  ),
                  child: Text(controller.error!, style: context.textStyles.bodyMedium?.copyWith(color: AppColors.dangerRed)),
                ),
              body,
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showComposer(BuildContext context, SocialModuleController controller, {SocialPost? repostSource}) async {
    final contentController = TextEditingController(text: repostSource?.content ?? '');
    final mediaController = TextEditingController();
    final pollQuestionController = TextEditingController();
    final pollOptionsController = TextEditingController(text: 'Option 1\nOption 2');
    final challengeTitleController = TextEditingController();
    final challengePrizeController = TextEditingController();
    final quoteController = TextEditingController();
    var selectedKind = repostSource == null ? SocialPostKind.text : SocialPostKind.repost;
    var communityName = controller.snapshot.communities.isNotEmpty ? controller.snapshot.communities.first.name : 'Fil public';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final mentionSuggestions = const ['@aicha', '@mamadou', '@nathan', '@fatou'];
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Créer un contenu', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<SocialPostKind>(
                      value: selectedKind,
                      items: const [
                        DropdownMenuItem(value: SocialPostKind.text, child: Text('Post texte')),
                        DropdownMenuItem(value: SocialPostKind.image, child: Text('Image')),
                        DropdownMenuItem(value: SocialPostKind.video, child: Text('Vidéo')),
                        DropdownMenuItem(value: SocialPostKind.reel, child: Text('Reel')),
                        DropdownMenuItem(value: SocialPostKind.poll, child: Text('Sondage')),
                        DropdownMenuItem(value: SocialPostKind.challenge, child: Text('Challenge')),
                        DropdownMenuItem(value: SocialPostKind.repost, child: Text('Repost avec citation')),
                      ],
                      onChanged: (value) => setState(() => selectedKind = value ?? SocialPostKind.text),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: communityName,
                      items: const [
                        DropdownMenuItem(value: 'Design Leaders', child: Text('Design Leaders')),
                        DropdownMenuItem(value: 'Growth Club', child: Text('Growth Club')),
                        DropdownMenuItem(value: 'Fil public', child: Text('Fil public')),
                      ],
                      onChanged: (value) => setState(() => communityName = value ?? 'Fil public'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: contentController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        labelText: 'Texte du post',
                        hintText: 'Utilisez @mentions et #hashtags pour enrichir votre publication.',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: mentionSuggestions.map((item) => ActionChip(label: Text(item), onPressed: () => contentController.text = '${contentController.text} $item'.trim())).toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: mediaController,
                      decoration: const InputDecoration(
                        labelText: 'URL image/vidéo (Supabase Storage ou CDN)',
                        hintText: 'https://...',
                      ),
                    ),
                    if (selectedKind == SocialPostKind.poll) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextField(controller: pollQuestionController, decoration: const InputDecoration(labelText: 'Question du sondage')),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: pollOptionsController,
                        minLines: 2,
                        maxLines: 6,
                        decoration: const InputDecoration(labelText: 'Options (une par ligne)'),
                      ),
                    ],
                    if (selectedKind == SocialPostKind.challenge) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextField(controller: challengeTitleController, decoration: const InputDecoration(labelText: 'Titre du challenge')),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(controller: challengePrizeController, decoration: const InputDecoration(labelText: 'Prix / récompense')),
                    ],
                    if (selectedKind == SocialPostKind.repost) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: quoteController,
                        decoration: const InputDecoration(labelText: 'Citation / commentaire'),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.isCreating
                            ? null
                            : () async {
                                final input = SocialComposerInput(
                                  content: contentController.text,
                                  kind: selectedKind,
                                  communityName: communityName == 'Fil public' ? null : communityName,
                                  mediaUrls: mediaController.text.trim().isEmpty ? const [] : [mediaController.text.trim()],
                                  pollQuestion: pollQuestionController.text.trim().isEmpty ? null : pollQuestionController.text.trim(),
                                  pollOptions: pollOptionsController.text.split('\n'),
                                  challengeTitle: challengeTitleController.text.trim().isEmpty ? null : challengeTitleController.text.trim(),
                                  challengePrize: challengePrizeController.text.trim().isEmpty ? null : challengePrizeController.text.trim(),
                                  quote: quoteController.text.trim().isEmpty ? null : quoteController.text.trim(),
                                  repostSource: repostSource,
                                );
                                await controller.createPost(input);
                                if (context.mounted) Navigator.of(context).pop();
                              },
                        child: Text(controller.isCreating ? 'Publication…' : 'Publier'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FeedColumn extends StatelessWidget {
  const _FeedColumn({required this.controller});

  final SocialModuleController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SocialStoryStrip(stories: controller.snapshot.stories, highlights: controller.snapshot.highlights),
        const SizedBox(height: AppSpacing.md),
        SocialSectionCard(
          title: 'Feed d’actualité',
          subtitle: 'Scoring intelligent, tri, bookmarks, reposts, hashtags et analytics.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                onChanged: controller.updateSearchQuery,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Rechercher utilisateurs, posts, communautés ou hashtags',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SocialSortSelector(sort: controller.sort, onChanged: controller.setSort),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: const [
                  Chip(label: Text('Pull-to-refresh')),
                  Chip(label: Text('Responsive mobile & tablet')),
                  Chip(label: Text('Animations likes')),
                  Chip(label: Text('RLS Supabase')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (controller.visiblePosts.isEmpty)
          const SocialSectionCard(
            title: 'Aucun post',
            subtitle: 'Essayez un autre mot-clé ou créez votre première publication.',
            child: SizedBox.shrink(),
          )
        else
          ...controller.visiblePosts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: SocialPostCard(
                post: post,
                onLike: () => controller.toggleLike(post.id),
                onComment: () => _showCommentModal(context, controller, post),
                onBookmark: () => controller.toggleBookmark(post.id),
                onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lien du post ${post.id} copié / partage prêt à être branché.')),
                ),
                onRepost: () => _showRepostDialog(context, controller, post),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showCommentModal(BuildContext context, SocialModuleController controller, SocialPost post) async {
    final textController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Commentaires', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            ...post.comments.map(
              (comment) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('${comment.author.name} · ${comment.text}'),
              ),
            ),
            TextField(controller: textController, decoration: const InputDecoration(labelText: 'Ajouter un commentaire')),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await controller.addComment(post.id, textController.text);
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('Envoyer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRepostDialog(BuildContext context, SocialModuleController controller, SocialPost post) async {
    final textController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repost avec citation'),
        content: TextField(
          controller: textController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Ajoutez votre commentaire'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              await controller.repostPost(post.id, textController.text);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }
}
