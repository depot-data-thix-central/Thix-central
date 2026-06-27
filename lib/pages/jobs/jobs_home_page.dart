import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class JobsHomePage extends StatelessWidget {
  const JobsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX Emploi',
        subtitle: 'Des opportunités pour tous.',
        onMenuTap: () {},
        trailing: IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none, color: cs.onSurface)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _JobSearchBar(),
          SizedBox(height: AppSpacing.md),
          _JobHero(),
          SizedBox(height: AppSpacing.lg),
          _JobCategories(),
          SizedBox(height: AppSpacing.lg),
          _RecentJobs(),
          SizedBox(height: AppSpacing.lg),
          _AiBoostCard(),
        ],
      ),
    );
  }
}

class _JobSearchBar extends StatelessWidget {
  const _JobSearchBar();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Rechercher un poste, une entreprise, un mot-clé…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _JobHero extends StatelessWidget {
  const _JobHero();

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(colors: [Color(0xFF6D5CFF), Color(0xFF9A6BFF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(AppRadius.mainCard)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Trouvez le job qui vous correspond', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.white)),
            const SizedBox(height: 6),
            Text('Des milliers d’opportunités sélectionnées pour vous.', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: const Color(0xFF6D5CFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
              child: const Text('Voir les offres'),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _JobCategories extends StatelessWidget {
  const _JobCategories();

  static final cats = [
    {'label': 'Tech & IT', 'count': '1 425 offres', 'icon': Icons.code},
    {'label': 'Marketing', 'count': '952 offres', 'icon': Icons.campaign_outlined},
    {'label': 'Design', 'count': '720 offres', 'icon': Icons.palette_outlined},
    {'label': 'Finance', 'count': '712 offres', 'icon': Icons.attach_money},
    {'label': 'Commercial', 'count': '423 offres', 'icon': Icons.handshake},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Explorer par catégorie', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Voir tout')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cats.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final cat = cats[index];
            return Container(
              width: 160,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(radius: 18, backgroundColor: cs.primary.withValues(alpha: 0.08), child: Icon(cat['icon'] as IconData, color: cs.primary)),
                const Spacer(),
                Text(cat['label'] as String, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(cat['count'] as String, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

class _RecentJobs extends StatelessWidget {
  const _RecentJobs();

  static final jobs = [
    {'title': 'Product Designer', 'company': 'Google', 'location': 'Paris, France · Hybride', 'type': 'CDI', 'time': 'il y a 2 h'},
    {'title': 'Développeur Full Stack', 'company': 'Stripe', 'location': 'Abidjan, Côte d’Ivoire · Hybrid', 'type': 'CDI', 'time': 'il y a 5 h'},
    {'title': 'Chef de Projet Marketing', 'company': 'Orange Digital Center', 'location': 'Dakar, Sénégal · Hybrid', 'type': 'CDI', 'time': 'il y a 1 j'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Offres récentes', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Voir tout')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      ...jobs.map(
        (job) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 18, backgroundColor: cs.primary.withValues(alpha: 0.08), child: Text(job['company']!.characters.first, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.primary))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(job['title']!, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              Text(job['time']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 6),
            Text(job['company']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(job['location']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(job['type']!, style: context.textStyles.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Postuler')),
            ]),
          ]),
        ),
      ),
    ]);
  }
}

class _AiBoostCard extends StatelessWidget {
  const _AiBoostCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.mainCard)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlue), child: const Icon(Icons.auto_awesome, color: AppColors.white)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Booste vos chances avec THIX AI', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Générez CV, lettre et recommandations personnalisées en 1 clic.', style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
        TextButton(onPressed: () {}, child: const Text('Découvrir')),
      ]),
    );
  }
}