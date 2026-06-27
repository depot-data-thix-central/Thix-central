import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class SocialHomePage extends StatelessWidget {
  const SocialHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'DreamFlow Réseau Pro',
        subtitle: 'Partagez, networkez, découvrez.',
        onMenuTap: () {},
        trailing: IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none, color: cs.onSurface)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: cs.primary,
        onPressed: () {},
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _StoryStrip(),
          SizedBox(height: AppSpacing.md),
          _ShareComposer(),
          SizedBox(height: AppSpacing.md),
          _FeedPost(
            author: 'Aïcha Diop',
            role: 'Product Designer · TechNova',
            timeAgo: 'il y a 3 h',
            content: 'Très fière de partager notre nouveau projet UI/UX pour une solution SaaS qui va révolutionner la gestion d’équipe !',
            stats: '128 likes · 33 commentaires',
          ),
          SizedBox(height: AppSpacing.sm),
          _FeedPost(
            author: 'Mamadou Camara',
            role: 'Growth Lead · StartupLab',
            timeAgo: 'il y a 5 h',
            content: 'Webinar gratuit jeudi : 5 actions pour améliorer vos KPI produit. Inscription ouverte !',
            stats: '92 likes · 18 commentaires',
          ),
        ],
      ),
    );
  }
}

class _StoryStrip extends StatelessWidget {
  const _StoryStrip();

  static final avatars = [
    {'name': 'Ma Story', 'color': AppColors.primaryBlue},
    {'name': 'Nathan', 'color': Color(0xFF8B5CFF)},
    {'name': 'Samir', 'color': Color(0xFF1BC47D)},
    {'name': 'Startup Lab', 'color': Color(0xFFFF9F0A)},
    {'name': 'CEO Wanda', 'color': Color(0xFF02134F)},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: avatars.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = avatars[index];
          return Column(children: [
            CircleAvatar(radius: 28, backgroundColor: item['color'] as Color, child: const Icon(Icons.person, color: AppColors.white)),
            const SizedBox(height: AppSpacing.xs),
            Text(item['name'] as String, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
          ]);
        },
      ),
    );
  }
}

class _ShareComposer extends StatelessWidget {
  const _ShareComposer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
      child: Column(children: [
        Row(children: [
          const CircleAvatar(radius: 22, backgroundColor: AppColors.primaryBlue, child: Icon(Icons.person, color: AppColors.white)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Quoi de neuf dans votre monde pro ?', style: context.textStyles.labelLarge?.copyWith(color: AppColors.textSecondary))),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
          _ComposerChip(icon: Icons.text_snippet_outlined, label: 'Post'),
          _ComposerChip(icon: Icons.play_circle_outline, label: 'Vidéo'),
          _ComposerChip(icon: Icons.camera_alt_outlined, label: 'Photo'),
          _ComposerChip(icon: Icons.insert_chart_outlined, label: 'Short'),
        ]),
      ]),
    );
  }
}

class _ComposerChip extends StatelessWidget {
  const _ComposerChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.lightGrayBackground, borderRadius: BorderRadius.circular(AppRadius.button)),
      child: Row(children: [Icon(icon, size: 16, color: AppColors.primaryBlue), const SizedBox(width: 6), Text(label, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700))]),
    );
  }
}

class _FeedPost extends StatelessWidget {
  const _FeedPost({required this.author, required this.role, required this.timeAgo, required this.content, required this.stats});
  final String author;
  final String role;
  final String timeAgo;
  final String content;
  final String stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const CircleAvatar(radius: 22, backgroundColor: AppColors.primaryBlue, child: Icon(Icons.person, color: AppColors.white)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(author, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              Text(role, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
          Text(timeAgo, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(content, style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(color: AppColors.lightGrayBackground, borderRadius: BorderRadius.circular(AppRadius.serviceCard)),
          child: Row(children: [
            Expanded(child: Text(stats, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary))),
            Row(children: const [
              Icon(Icons.thumb_up_alt_outlined, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 12),
              Icon(Icons.mode_comment_outlined, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 12),
              Icon(Icons.share_outlined, size: 18, color: AppColors.textSecondary),
            ]),
          ]),
        ),
      ]),
    );
  }
}