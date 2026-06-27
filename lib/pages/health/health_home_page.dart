import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class HealthHomePage extends StatelessWidget {
  const HealthHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX Santé',
        subtitle: 'Votre santé, notre priorité.',
        onMenuTap: () {},
        trailing: IconButton(onPressed: () {}, icon: Icon(Icons.chat_bubble_outline, color: cs.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _HealthHero(),
          SizedBox(height: AppSpacing.md),
          _HealthShortcuts(),
          SizedBox(height: AppSpacing.lg),
          _HealthSummary(),
          SizedBox(height: AppSpacing.lg),
          _HealthServices(),
          SizedBox(height: AppSpacing.lg),
          _InsuranceCards(),
        ],
      ),
    );
  }
}

class _HealthHero extends StatelessWidget {
  const _HealthHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0BA360), Color(0xFF3CBA92)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Votre santé entre de bonnes mains', style: context.textStyles.headlineSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text('Consultez, suivez et protégez votre santé au quotidien.', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: const Color(0xFF0BA360), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
          child: const Text('Dossier de santé'),
        ),
      ]),
    );
  }
}

class _HealthShortcuts extends StatelessWidget {
  const _HealthShortcuts();

  static final items = [
    {'icon': Icons.medical_information_outlined, 'label': 'Ordonnances'},
    {'icon': Icons.local_hospital_outlined, 'label': 'Consultation'},
    {'icon': Icons.science_outlined, 'label': 'Examens'},
    {'icon': Icons.medication_outlined, 'label': 'Médicaments'},
    {'icon': Icons.favorite_border, 'label': 'Urgences'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 120,
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              CircleAvatar(radius: 20, backgroundColor: const Color(0xFF0BA360).withValues(alpha: 0.12), child: Icon(item['icon'] as IconData, color: const Color(0xFF0BA360))),
              const SizedBox(height: AppSpacing.xs),
              Text(item['label'] as String, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          );
        },
      ),
    );
  }
}

class _HealthSummary extends StatelessWidget {
  const _HealthSummary();

  static const summary = [
    {'label': 'Consultations', 'value': '12'},
    {'label': 'Examens', 'value': '7'},
    {'label': 'Médicaments', 'value': '3'},
    {'label': 'Rendez-vous', 'value': '2'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Résumé de santé', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('Voir tout')),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          for (int i = 0; i < summary.length; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == summary.length - 1 ? 0 : AppSpacing.sm),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(color: const Color(0xFF0BA360).withValues(alpha: 0.06), borderRadius: BorderRadius.circular(AppRadius.serviceCard)),
                child: Column(children: [
                  Text(summary[i]['value']!, style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF0BA360))),
                  Text(summary[i]['label']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }
}

class _HealthServices extends StatelessWidget {
  const _HealthServices();

  static final services = [
    {'title': 'Téléconsultation', 'desc': 'Médecins 24/7', 'icon': Icons.video_call},
    {'title': 'Soins à domicile', 'desc': 'Infirmiers & aides', 'icon': Icons.local_hospital},
    {'title': 'Assistance santé', 'desc': 'Urgences guidées', 'icon': Icons.support_agent},
    {'title': 'Assurance santé', 'desc': 'Vos garanties', 'icon': Icons.health_and_safety},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Services santé', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Voir tout')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.35, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm),
        itemBuilder: (context, index) {
          final svc = services[index];
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 20, backgroundColor: cs.primary.withValues(alpha: 0.08), child: Icon(svc['icon'] as IconData, color: cs.primary)),
              const SizedBox(height: AppSpacing.sm),
              Text(svc['title'] as String, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(svc['desc'] as String, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
            ]),
          );
        },
      ),
    ]);
  }
}

class _InsuranceCards extends StatelessWidget {
  const _InsuranceCards();

  static final items = [
    {'title': 'Assurance santé', 'desc': 'Couverture médicale', 'color': Color(0xFF0BA360)},
    {'title': 'Assurance vie', 'desc': 'Protection familiale', 'color': Color(0xFF1C64F2)},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Assurance', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: AppSpacing.sm),
      ...items.map(
        (item) => Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(color: (item['color'] as Color).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(AppRadius.serviceCard)),
          child: Row(children: [
            CircleAvatar(radius: 22, backgroundColor: (item['color'] as Color), child: const Icon(Icons.shield_moon_outlined, color: AppColors.white)),
            const SizedBox(width: AppSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['title']! as String, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(item['desc']! as String, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
            ]),
            const Spacer(),
            TextButton(onPressed: () {}, child: const Text('Voir')),
          ]),
        ),
      ),
    ]);
  }
}