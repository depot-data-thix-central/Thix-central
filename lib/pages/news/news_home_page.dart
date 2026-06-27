import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class NewsHomePage extends StatelessWidget {
  const NewsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX Info',
        subtitle: 'Informations en temps réel.',
        onMenuTap: () {},
        trailing: IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none, color: cs.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _NewsHero(),
          SizedBox(height: AppSpacing.md),
          _NewsTabs(),
          SizedBox(height: AppSpacing.lg),
          _HeadlineGrid(),
          SizedBox(height: AppSpacing.lg),
          _RecentNews(),
          SizedBox(height: AppSpacing.lg),
          _VideoStrip(),
        ],
      ),
    );
  }
}

class _NewsHero extends StatelessWidget {
  const _NewsHero();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1505761671935-60b3a7427bad?auto=format&fit=crop&w=1200&q=60'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(AppRadius.mainCard)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
            child: Text('À la une', style: context.textStyles.labelSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('RDC : le gouvernement lance un plan de relance économique', style: context.textStyles.headlineSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xs),
          Text('Un programme massif pour dynamiser l’emploi et l’innovation locale.', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.9))),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: cs.onPrimary), child: const Text('Lire l’article')),
        ]),
      ),
    );
  }
}

class _NewsTabs extends StatelessWidget {
  const _NewsTabs();

  static const tabs = ['Politique', 'Économie', 'Tech', 'Sport', 'International'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (int i = 0; i < tabs.length; i++) _TabChip(label: tabs[i], selected: i == 0),
      ]),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected});
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryBlue : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: selected ? AppColors.primaryBlue.withValues(alpha: 0.1) : AppColors.white, borderRadius: BorderRadius.circular(AppRadius.search), border: Border.all(color: AppColors.cardBorder)),
      child: Text(label, style: context.textStyles.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _HeadlineGrid extends StatelessWidget {
  const _HeadlineGrid();

  static final headlines = [
    {'title': 'Finance : le franc en hausse', 'tag': 'Économie', 'image': 'https://images.unsplash.com/photo-1567427017947-545c5f8d16ad?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Innovation : 10 start-ups africaines à suivre', 'tag': 'Tech', 'image': 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=600&q=60'},
    {'title': 'CAN : le match à ne pas manquer', 'tag': 'Sport', 'image': 'https://images.unsplash.com/photo-1471295253337-3ceaaedca402?auto=format&fit=crop&w=600&q=60'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: headlines.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.9, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm),
      itemBuilder: (context, index) {
        final h = headlines[index];
        return Container(
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.mainCard)), child: Image.network(h['image']!, height: 110, width: double.infinity, fit: BoxFit.cover)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(h['tag']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 6),
                Text(h['title']!, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _RecentNews extends StatelessWidget {
  const _RecentNews();

  static final news = [
    {'title': 'Investissements étrangers en hausse', 'tag': 'Business', 'time': 'il y a 1 h'},
    {'title': 'Tech : nouvelle réglementation IA', 'tag': 'Tech', 'time': 'il y a 3 h'},
    {'title': 'Afrique : croissance 2025 estimée à 5%', 'tag': 'Économie', 'time': 'il y a 6 h'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Actualités récentes', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Voir tout')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      ...news.map(
        (n) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.article_outlined, color: AppColors.primaryBlue)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n['title']!, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(n['tag']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
            ])),
            Text(n['time']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
      ),
    ]);
  }
}

class _VideoStrip extends StatelessWidget {
  const _VideoStrip();

  static final videos = [
    {'title': 'Interview exclusive', 'duration': '05:20'},
    {'title': 'Reportage terrain', 'duration': '08:45'},
    {'title': 'Décryptage économique', 'duration': '04:10'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Vidéos à la une', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Voir tout')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: videos.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final v = videos[index];
            return Container(
              width: 200,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.darkNavy.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(AppRadius.serviceCard)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [Icon(Icons.play_circle_fill, color: AppColors.white), SizedBox(width: 6), Text('Vidéo', style: TextStyle(color: AppColors.white))]),
                const Spacer(),
                Text(v['title']!, style: context.textStyles.titleSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(v['duration']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}