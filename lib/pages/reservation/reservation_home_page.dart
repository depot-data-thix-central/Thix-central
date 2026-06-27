import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class ReservationHomePage extends StatelessWidget {
  const ReservationHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX Réservation',
        subtitle: 'Réservez tout, partout.',
        onMenuTap: () {},
        trailing: IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none, color: cs.onSurface)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          _PromoHero(),
          SizedBox(height: AppSpacing.md),
          _TransportGrid(),
          SizedBox(height: AppSpacing.lg),
          _ReservationStats(),
          SizedBox(height: AppSpacing.lg),
          _SpecialOffers(),
          SizedBox(height: AppSpacing.lg),
          _NearbyRestaurants(),
          SizedBox(height: AppSpacing.lg),
          _Classifieds(),
        ],
      ),
    );
  }
}

class _PromoHero extends StatelessWidget {
  const _PromoHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
          child: Text('Promo flash', style: context.textStyles.labelSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('Jusqu’à -40% sur vos réservations de bus & vols', style: context.textStyles.headlineSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800)),
        const SizedBox(height: AppSpacing.xs),
        Text('Valable jusqu’au 30 Juin 2025', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.white.withValues(alpha: 0.8))),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.white, foregroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
          child: const Text('Profiter maintenant'),
        ),
      ]),
    );
  }
}

class _TransportGrid extends StatelessWidget {
  const _TransportGrid();

  static final List<Map<String, dynamic>> items = [
    {'icon': Icons.directions_bus, 'label': 'Bus'},
    {'icon': Icons.flight_takeoff, 'label': 'Vol'},
    {'icon': Icons.hotel, 'label': 'Hôtel'},
    {'icon': Icons.local_taxi, 'label': 'Taxi'},
    {'icon': Icons.pedal_bike, 'label': 'Livraison'},
    {'icon': Icons.more_horiz, 'label': 'Plus'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.05, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircleAvatar(radius: 22, backgroundColor: cs.primary.withValues(alpha: 0.08), child: Icon(item['icon'] as IconData, color: cs.primary)),
            const SizedBox(height: AppSpacing.xs),
            Text(item['label'] as String, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        );
      },
    );
  }
}

class _ReservationStats extends StatelessWidget {
  const _ReservationStats();

  static const stats = [
    {'label': 'À venir', 'value': '3', 'icon': Icons.schedule},
    {'label': 'En cours', 'value': '1', 'icon': Icons.timelapse},
    {'label': 'Terminées', 'value': '8', 'icon': Icons.check_circle_outline},
    {'label': 'Annulées', 'value': '0', 'icon': Icons.cancel_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Mes réservations', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          TextButton(onPressed: () {}, child: const Text('Voir tout')),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (int i = 0; i < stats.length; i++)
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == stats.length - 1 ? 0 : AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(AppRadius.serviceCard)),
                  child: Column(children: [
                    Icon(stats[i]['icon'] as IconData, color: cs.primary),
                    const SizedBox(height: AppSpacing.xs),
                    Text(stats[i]['value']!, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    Text(stats[i]['label']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
              ),
          ],
        ),
      ]),
    );
  }
}

class _SpecialOffers extends StatelessWidget {
  const _SpecialOffers();

  static final offers = [
    {'title': 'Hôtels -30%', 'desc': 'Séjournez plus, payez moins', 'image': 'https://images.unsplash.com/photo-1501117716987-c8e1ecb210af?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Vols -20%', 'desc': 'Sur tous les vols', 'image': 'https://images.unsplash.com/photo-1529074963764-98f45c47344b?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Bus -15%', 'desc': 'Voyagez en confiance', 'image': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Livraison -10%', 'desc': 'Envoi express', 'image': 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=600&q=60'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Offres spéciales pour vous', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Voir tout')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: offers.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final offer = offers[index];
            return Container(
              width: 220,
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
              child: Row(children: [
                ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.serviceCard)), child: Image.network(offer['image']!, width: 100, height: 140, fit: BoxFit.cover)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(offer['title']!, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(offer['desc']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
                    ]),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

class _NearbyRestaurants extends StatelessWidget {
  const _NearbyRestaurants();

  static final restos = [
    {'title': 'Le Goût d’Ici', 'type': 'Africaine', 'time': '20-30 min', 'rating': '4.6', 'image': 'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Fast & Good', 'type': 'Fast Food', 'time': '15-25 min', 'rating': '4.8', 'image': 'https://images.unsplash.com/photo-1606756790122-47e9ba02f7b5?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Pizza Time', 'type': 'Italienne', 'time': '20-30 min', 'rating': '4.5', 'image': 'https://images.unsplash.com/photo-1548365328-9c5c52307007?auto=format&fit=crop&w=600&q=60'},
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Restaurants à proximité', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Voir tout')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 200,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: restos.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final resto = restos[index];
            return Container(
              width: 180,
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.mainCard)),
                  child: Image.network(resto['image']!, height: 110, width: double.infinity, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(resto['title']!, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Row(children: [
                        const Icon(Icons.star_rate_rounded, color: Colors.amber, size: 16),
                        Text(resto['rating']!, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                      ]),
                    ]),
                    const SizedBox(height: 2),
                    Text('${resto['type']} · ${resto['time']}', style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

class _Classifieds extends StatelessWidget {
  const _Classifieds();

  static final items = [
    {'title': 'Toyota RAV4 2021', 'price': '25.000.000 FC', 'badge': 'À vendre', 'image': 'https://images.unsplash.com/photo-1503736334956-4c8f8e92946d?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Appartement 3 pièces', 'price': '600.000 FC / mois', 'badge': 'À louer', 'image': 'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=600&q=60'},
    {'title': 'Ménage à domicile', 'price': 'Dès 10.000 FC', 'badge': 'Service', 'image': 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=600&q=60'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Annonces', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('Voir tout')),
      ]),
      const SizedBox(height: AppSpacing.sm),
      SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              width: 200,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
              child: Row(children: [
                ClipRRect(borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.serviceCard)), child: Image.network(item['image']!, width: 80, height: 140, fit: BoxFit.cover)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                        child: Text(item['badge']!, style: context.textStyles.labelSmall?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 6),
                      Text(item['title']!, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(item['price']!, style: context.textStyles.labelMedium?.copyWith(color: AppColors.textSecondary)),
                    ]),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}