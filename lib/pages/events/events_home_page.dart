import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class EventsHomePage extends StatelessWidget {
  const EventsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX Événement',
        subtitle: 'Découvrez, réservez, vivez l’exceptionnel.',
        onMenuTap: () {},
        trailing: IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none, color: cs.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _HeroBanner(),
          SizedBox(height: AppSpacing.md),
          _CategoryStrip(),
          SizedBox(height: AppSpacing.md),
          _SectionHeader(title: 'Événements recommandés', action: 'Voir tout'),
          SizedBox(height: AppSpacing.sm),
          _RecommendedGrid(),
          SizedBox(height: AppSpacing.lg),
          _SectionHeader(title: 'Prochains événements', action: 'Voir tout'),
          SizedBox(height: AppSpacing.sm),
          _UpcomingList(),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A1FFF), Color(0xFF9013FE)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        boxShadow: const [AppShadows.main],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Vivez des moments inoubliables.', style: context.textStyles.headlineSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.sm),
        Text('Concerts, festivals, conférences, spectacles et plus encore.', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.85))),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: cs.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: const Text('Découvrir les événements'),
        ),
      ]),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip();

  static final List<Map<String, dynamic>> categories = [
    {'icon': Icons.music_note, 'label': 'Concerts'},
    {'icon': Icons.theaters_outlined, 'label': 'Spectacles'},
    {'icon': Icons.mic_none_rounded, 'label': 'Conférences'},
    {'icon': Icons.emoji_events_outlined, 'label': 'Sport'},
    {'icon': Icons.local_activity_outlined, 'label': 'Festivals'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = categories[index];
          return Container(
            width: 120,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.serviceCard),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              CircleAvatar(radius: 18, backgroundColor: cs.primary.withValues(alpha: 0.08), child: Icon(item['icon'] as IconData, color: cs.primary)),
              const Spacer(),
              Text(item['label'] as String, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          );
        },
      ),
    );
  }
}

class _RecommendedGrid extends StatelessWidget {
  const _RecommendedGrid();

  static final List<Map<String, String>> events = [
    {'title': 'TAYC en concert', 'date': '25 Mai 2024 · 20h00', 'place': 'Palais des Congrès', 'price': '15.000 FC', 'tag': 'Concert', 'image': 'https://images.unsplash.com/photo-1489515217757-5fd1be406fef?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Africa Business Summit', 'date': '12 Juin 2024 · 09h00', 'place': 'Hôtel 2 Février', 'price': '35.000 FC', 'tag': 'Conférence', 'image': 'https://images.unsplash.com/photo-1545239351-1141bd82e8a6?auto=format&fit=crop&w=600&q=60'},
    {'title': 'AS Douanes vs Jaraaf', 'date': '18 Mai 2024 · 16h00', 'place': 'Stade Léopold Sédar', 'price': '5.000 FC', 'tag': 'Match', 'image': 'https://images.unsplash.com/photo-1509021436665-8f07dbf5bf1d?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Afro Vibes Festival', 'date': '30 Juin 2024 · 18h00', 'place': 'Place de l’Indépendance', 'price': '20.000 FC', 'tag': 'Festival', 'image': 'https://images.unsplash.com/photo-1464375117522-1311d6a5b81f?auto=format&fit=crop&w=600&q=60'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm),
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(
          title: event['title']!,
          tag: event['tag']!,
          date: event['date']!,
          place: event['place']!,
          price: event['price']!,
          image: event['image']!,
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.title, required this.tag, required this.date, required this.place, required this.price, required this.image});
  final String title;
  final String tag;
  final String date;
  final String place;
  final String price;
  final String image;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.mainCard)),
          child: AspectRatio(aspectRatio: 16 / 10, child: Image.network(image, fit: BoxFit.cover)),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(tag.toUpperCase(), style: context.textStyles.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(date, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.place_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(place, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary))),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Text(price, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: cs.primary)),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 38), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
                child: const Text('Réserver'),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList();

  static final List<Map<String, String>> items = [
    {'title': 'Spectacle : Le Rire du Continent', 'date': '22 Mai 2024 · 20h00', 'place': 'Institut Français', 'price': '10.000 FC'},
    {'title': 'Salon International de l’Auto', 'date': '05 Août 2024 · 10h00', 'place': 'Parc des Expositions', 'price': '7.500 FC'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: items
          .map(
            (e) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
              child: Row(children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.event_available, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e['title']!, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${e['date']} · ${e['place']}', style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(e['price']!, style: context.textStyles.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 12)), child: const Text('Réserver')),
                ]),
              ]),
            ),
          )
          .toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Text(title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const Spacer(),
      if (action != null)
        TextButton(onPressed: () {}, child: Text(action!, style: context.textStyles.labelMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700))),
    ]);
  }
}