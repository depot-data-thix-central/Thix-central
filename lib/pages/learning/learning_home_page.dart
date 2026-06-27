import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class LearningHomePage extends StatelessWidget {
  const LearningHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX Formation',
        subtitle: 'Apprenez aujourd’hui, réussissez demain.',
        onMenuTap: () {},
        trailing: IconButton(onPressed: () {}, icon: Icon(Icons.search, color: cs.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _LearningHero(),
          SizedBox(height: AppSpacing.md),
          _LearningFilters(),
          SizedBox(height: AppSpacing.lg),
          _CategoryChips(),
          SizedBox(height: AppSpacing.md),
          _RecommendedCourses(),
          SizedBox(height: AppSpacing.lg),
          _CertificationBanner(),
        ],
      ),
    );
  }
}

class _LearningHero extends StatelessWidget {
  const _LearningHero();

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(colors: [Color(0xFF6D5CFF), Color(0xFF8B5CFF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(AppRadius.mainCard)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Text('À la une', style: context.textStyles.labelSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Développez vos compétences, changez votre avenir.', style: context.textStyles.headlineSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text('Des milliers de cours, certificats et mentors pour booster votre carrière.', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: const Color(0xFF6D5CFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
          child: const Text('Explorer les formations'),
        ),
      ]),
    );
  }
}

class _LearningFilters extends StatelessWidget {
  const _LearningFilters();

  static final filters = [
    {'icon': Icons.view_module, 'label': 'Toutes'},
    {'icon': Icons.verified, 'label': 'Certifiantes'},
    {'icon': Icons.trending_up, 'label': 'Populaires'},
    {'icon': Icons.new_releases, 'label': 'Nouvelles'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.1, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm),
      itemBuilder: (context, index) {
        final filter = filters[index];
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(filter['icon'] as IconData, color: AppColors.primaryBlue),
            const SizedBox(height: AppSpacing.xs),
            Text(filter['label'] as String, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        );
      },
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  static const cats = ['Design', 'No-Code', 'Product', 'Data', 'Marketing', 'Leadership'];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: cats
          .map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.search)),
                child: Text(c, style: context.textStyles.labelMedium?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
              ))
          .toList(),
    );
  }
}

class _RecommendedCourses extends StatelessWidget {
  const _RecommendedCourses();

  static final courses = [
    {'title': 'Flutter & Dart', 'price': '25.000 FC', 'author': 'Dev Mobile', 'rating': '4.8', 'tag': 'Mobile'},
    {'title': 'Excel Avancé', 'price': '15.000 FC', 'author': 'Data Pro', 'rating': '4.6', 'tag': 'Data'},
    {'title': 'UI/UX Design', 'price': '30.000 FC', 'author': 'Design Lab', 'rating': '4.9', 'tag': 'Design'},
    {'title': 'Leadership', 'price': '20.000 FC', 'author': 'Business Coach', 'rating': '4.7', 'tag': 'Business'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm),
      itemBuilder: (context, index) {
        final course = courses[index];
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
              child: Text(course['tag']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(course['title']!, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(course['author']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
            const Spacer(),
            Row(children: [
              Row(children: [
                const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 16),
                Text(course['rating']!, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
              ]),
              const Spacer(),
              Text(course['price']!, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))), child: const Text('S’inscrire')),
          ]),
        );
      },
    );
  }
}

class _CertificationBanner extends StatelessWidget {
  const _CertificationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.mainCard)),
      child: Row(children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryBlue),
          child: const Icon(Icons.workspace_premium_outlined, color: AppColors.white),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Obtenez des certificats reconnus', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Validez vos compétences et avancez dans votre carrière.', style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
        TextButton(onPressed: () {}, child: const Text('Découvrir')),
      ]),
    );
  }
}