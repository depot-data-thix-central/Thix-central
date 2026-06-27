import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/market/models/market_product.dart';
import 'package:thix_central/market/models/market_shop.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/market/services/market_product_service.dart';
import 'package:thix_central/market/services/market_shop_service.dart';
import 'package:thix_central/market/widgets/auth_required_panel.dart';
import 'package:thix_central/theme.dart';

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  final MarketProductService _service = const MarketProductService();
  final MarketShopService _shopService = const MarketShopService();
  final TextEditingController _search = TextEditingController();
  String _query = '';
  int _bottomIndex = 0;
  int _filterIndex = 0;

  final PageController _banner = PageController();
  int _bannerIndex = 0;

  @override
  void dispose() {
    _search.dispose();
    _banner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.lightGrayBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 96),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              MarketHeaderRow(
                onBack: () => context.pop(),
                onOrders: () => context.push('/market/orders'),
                onCart: () => context.push('/market/cart'),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AuthRequiredPanel(message: 'Connecte-toi pour ajouter au panier et passer commande.', afterLoginRoute: '/market'),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MarketSearchBar(
                  controller: _search,
                  query: _query,
                  onChanged: (v) => setState(() => _query = v),
                  onClear: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MarketPromoBanner(
                  controller: _banner,
                  index: _bannerIndex,
                  onIndexChanged: (i) => setState(() => _bannerIndex = i),
                ),
              ),
              const SizedBox(height: 10),
              const MarketCategoryRow(),
              const SizedBox(height: 14),
              MarketSectionHeader(title: 'Offres Flash', onSeeAll: () => _scrollToTop()),
              FutureBuilder<List<MarketProduct>>(
                future: _service.listActive(query: _query, limit: 10, orderBy: 'created_at', ascending: false),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const MarketHorizontalSkeleton(height: 190);
                  if (snap.hasError) return MarketInlineError(message: 'Erreur offres flash: ${snap.error}');
                  final items = (snap.data ?? const []).take(8).toList();
                  if (items.isEmpty) return const MarketEmptyHintCard(message: 'Aucune offre flash pour le moment.');
                  return MarketFlashHorizontalList(items: items);
                },
              ),
              const SizedBox(height: 6),
              MarketSectionHeader(title: 'Boutiques recommandées', onSeeAll: () {}),
              FutureBuilder<List<MarketShop>>(
                future: _shopService.listRecommended(limit: 8),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const MarketHorizontalSkeleton(height: 132);
                  if (snap.hasError) return MarketInlineError(message: 'Erreur boutiques: ${snap.error}');
                  final shops = snap.data ?? const [];
                  if (shops.isEmpty) return const MarketEmptyHintCard(message: 'Pas encore de boutiques. Ajoute des produits pour générer des boutiques.');
                  return MarketShopHorizontalList(shops: shops);
                },
              ),
              const SizedBox(height: 6),
              MarketSectionHeader(title: 'Lives en cours', onSeeAll: () {}),
              const MarketEmptyHintCard(message: 'Aucun live en cours. (Live commerce à activer côté backend)') ,
              const SizedBox(height: 6),
              MarketSectionHeader(title: 'Tous les produits', onSeeAll: () {}),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: MarketFilterChips(
                  selected: _filterIndex,
                  onSelected: (i) => setState(() => _filterIndex = i),
                ),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<MarketProduct>>(
                future: _service.listActive(
                  query: _query,
                  limit: 40,
                  orderBy: _filterIndex == 1 ? 'price_cents' : 'created_at',
                  ascending: _filterIndex == 1,
                ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(padding: EdgeInsets.only(top: 16), child: Center(child: CircularProgressIndicator()));
                  }
                  if (snap.hasError) return MarketInlineError(message: 'Erreur produits: ${snap.error}');
                  final items = snap.data ?? const [];
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: MarketEmptyHintCard(message: 'Aucun produit. Ajoute des lignes dans market_products.'),
                    );
                  }
                  return MarketProductsGrid(items: items);
                },
              ),
              const SizedBox(height: 10),
              if (SupabaseClientProvider.clientOrNull?.auth.currentUser == null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Connecte-toi pour acheter. Les produits restent visibles en public.', style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: MarketBottomNav(
        onTap: (i) {
          if (i == 2) {
            context.push('/market/sell');
            return;
          }
          setState(() => _bottomIndex = i);
          if (i == 0) context.go('/market');
          if (i == 3) context.go('/messages');
          if (i == 4) context.go('/profile');
        },
      ),
    );
  }

  void _scrollToTop() {
    // No-op for now; kept for "Voir tout" consistency.
  }
}

class MarketHeaderRow extends StatelessWidget {
  const MarketHeaderRow({super.key, required this.onBack, required this.onOrders, required this.onCart});
  final VoidCallback onBack;
  final VoidCallback onOrders;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface), splashColor: Colors.transparent, highlightColor: Colors.transparent),
              const SizedBox(width: 2),
              Text('THIX MARKET', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.4)),
            ],
          ),
          Row(
            children: [
              _HeaderPill(icon: Icons.location_on_outlined, label: 'Abidjan', onTap: () {}),
              const SizedBox(width: 10),
              IconButton(onPressed: onOrders, icon: Icon(Icons.notifications_none_rounded, color: cs.onSurface), splashColor: Colors.transparent, highlightColor: Colors.transparent),
              IconButton(onPressed: onCart, icon: Icon(Icons.shopping_cart_outlined, color: cs.onSurface), splashColor: Colors.transparent, highlightColor: Colors.transparent),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: cs.outline.withValues(alpha: 0.16))),
        child: Row(
          children: [
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

class MarketSearchBar extends StatelessWidget {
  const MarketSearchBar({super.key, required this.controller, required this.query, required this.onChanged, required this.onClear});
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.search), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(
        children: [
          Icon(Icons.search, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Rechercher un produit, une boutique…', isDense: true, contentPadding: EdgeInsets.zero),
            ),
          ),
          if (query.isNotEmpty)
            IconButton(onPressed: onClear, icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant), splashColor: Colors.transparent, highlightColor: Colors.transparent),
          Icon(Icons.camera_alt_outlined, size: 20, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class MarketPromoBanner extends StatelessWidget {
  const MarketPromoBanner({super.key, required this.controller, required this.index, required this.onIndexChanged});
  final PageController controller;
  final int index;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 132,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: PageView(
              controller: controller,
              onPageChanged: onIndexChanged,
              children: const [
                _PromoCard(titleTop: 'SOLDES FLASH', titleMain: 'Jusqu\'à -70%', subtitle: 'Découvrir les offres', accent: AppColors.accentOrange),
                _PromoCard(titleTop: 'NOUVEAUTÉS', titleMain: 'Produits tendance', subtitle: 'Voir les nouveautés', accent: AppColors.thixCyanGlow),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 2; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: i == index ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(color: i == index ? cs.primary : cs.outline.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(99)),
              ),
          ],
        ),
      ],
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.titleTop, required this.titleMain, required this.subtitle, required this.accent});
  final String titleTop;
  final String titleMain;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.darkNavy, AppColors.marketBannerBlue]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleTop, style: context.textStyles.labelSmall?.copyWith(color: accent, fontWeight: FontWeight.w900, letterSpacing: 0.4)),
                  const SizedBox(height: 8),
                  Text(titleMain, style: context.textStyles.titleLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.w900, height: 1.05)),
                  const Spacer(),
                  Text(subtitle, style: context.textStyles.labelSmall?.copyWith(color: AppColors.white.withValues(alpha: 0.72), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF121B3B), Color(0xFF18265C)]),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.flash_on_rounded, color: AppColors.accentOrange, size: 38),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketCategoryRow extends StatelessWidget {
  const MarketCategoryRow({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const items = [
      ('Offres', Icons.grid_view_rounded),
      ('Mode', Icons.checkroom_outlined),
      ('Électro', Icons.phone_iphone_rounded),
      ('Maison', Icons.chair_outlined),
      ('Beauté', Icons.spa_outlined),
      ('Sports', Icons.sports_basketball_outlined),
      ('Auto', Icons.directions_car_outlined),
      ('Services', Icons.handyman_outlined),
    ];

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) {
          final item = items[i];
          return SizedBox(
            width: 72,
            child: Column(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: Icon(item.$2, color: cs.onSurface, size: 22),
                ),
                const SizedBox(height: 6),
                Text(item.$1, style: context.textStyles.labelSmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: items.length,
      ),
    );
  }
}

class MarketSectionHeader extends StatelessWidget {
  const MarketSectionHeader({super.key, required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface)),
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Text('Voir tout', style: context.textStyles.labelSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 18, color: cs.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarketFlashHorizontalList extends StatelessWidget {
  const MarketFlashHorizontalList({super.key, required this.items});
  final List<MarketProduct> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => MarketMiniProductCard(product: items[i], onTap: () => context.push('/market/product/${items[i].id}')),
      ),
    );
  }
}

class MarketMiniProductCard extends StatelessWidget {
  const MarketMiniProductCard({super.key, required this.product, required this.onTap});
  final MarketProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isNew = DateTime.now().difference(product.createdAt).inDays <= 3;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                MarketThumb(url: product.coverUrl, height: 92),
                Positioned(
                  left: 8,
                  top: 8,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: isNew ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accentOrange, borderRadius: BorderRadius.circular(99)),
                      child: Text('NEW', style: context.textStyles.labelSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w900, height: 1.0)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(product.title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.15), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text('${(product.priceCents / 100).toStringAsFixed(0)} ${product.currency}', style: context.textStyles.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w900)),
            const Spacer(),
            Text(product.stock > 0 ? 'Stock ${product.stock}' : 'Rupture', style: context.textStyles.labelSmall?.copyWith(color: product.stock > 0 ? cs.onSurfaceVariant : cs.error, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class MarketThumb extends StatelessWidget {
  const MarketThumb({super.key, required this.url, required this.height});
  final String? url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = BorderRadius.circular(14);
    return ClipRRect(
      borderRadius: r,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: url == null
            ? DecoratedBox(decoration: BoxDecoration(gradient: AppColors.promoGradient, borderRadius: r), child: const Icon(Icons.shopping_bag, color: AppColors.white, size: 30))
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: r),
                  child: Icon(Icons.image_not_supported_outlined, color: cs.onPrimaryContainer),
                ),
              ),
      ),
    );
  }
}

class MarketShopHorizontalList extends StatelessWidget {
  const MarketShopHorizontalList({super.key, required this.shops});
  final List<MarketShop> shops;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: shops.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = shops[i];
          return InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Container(
              width: 164,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: s.avatarUrl == null
                          ? DecoratedBox(decoration: BoxDecoration(gradient: AppColors.primaryBlueGradient, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.storefront_rounded, color: AppColors.white))
                          : Image.network(
                              s.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => DecoratedBox(decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.storefront_rounded, color: cs.onPrimaryContainer)),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(s.displayName, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Text('${s.productCount} produits', style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class MarketFilterChips extends StatelessWidget {
  const MarketFilterChips({super.key, required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = const ['Nouveau', 'Prix', 'Populaire', 'Pour toi'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final isSelected = i == selected;
          return InkWell(
            onTap: () => onSelected(i),
            borderRadius: BorderRadius.circular(99),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : cs.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              ),
              child: Text(items[i], style: context.textStyles.labelSmall?.copyWith(color: isSelected ? cs.onPrimary : cs.onSurface, fontWeight: FontWeight.w900)),
            ),
          );
        },
      ),
    );
  }
}

class MarketProductsGrid extends StatelessWidget {
  const MarketProductsGrid({super.key, required this.items});
  final List<MarketProduct> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final p = items[i];
        return InkWell(
          onTap: () => context.push('/market/product/${p.id}'),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarketThumb(url: p.coverUrl, height: 110),
                const SizedBox(height: 10),
                Text(p.title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.15), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('${(p.priceCents / 100).toStringAsFixed(0)} ${p.currency}', style: context.textStyles.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w900)),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: AppColors.accentOrange),
                    const SizedBox(width: 4),
                    Text('—', style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Icon(Icons.local_shipping_outlined, size: 16, color: cs.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MarketBottomNav extends StatelessWidget {
  const MarketBottomNav({super.key, required this.onTap});
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    const barHeight = 82.0;
    return SizedBox(
      height: barHeight + bottom,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.bottomNav)),
              child: Container(
                height: barHeight + bottom,
                padding: EdgeInsets.only(bottom: bottom),
                decoration: const BoxDecoration(color: AppColors.white, boxShadow: [AppShadows.secondary], border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MarketNavItem(label: 'Accueil', icon: Icons.home_rounded, onTap: () => onTap(0)),
                    _MarketNavItem(label: 'Catégories', icon: Icons.grid_view_rounded, onTap: () => onTap(1)),
                    const SizedBox(width: 64),
                    _MarketNavItem(label: 'Messages', icon: Icons.chat_bubble_outline, onTap: () => onTap(3)),
                    _MarketNavItem(label: 'Compte', icon: Icons.person_outline, onTap: () => onTap(4)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: bottom + 18,
            child: _MarketCenterSellButton(onTap: () => onTap(2)),
          ),
        ],
      ),
    );
  }
}

class _MarketCenterSellButton extends StatelessWidget {
  const _MarketCenterSellButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        scale: 1.0,
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(gradient: AppColors.primaryBlueGradient, shape: BoxShape.circle, boxShadow: [AppShadows.main]),
          child: const Icon(Icons.add, size: 28, color: AppColors.white),
        ),
      ),
    );
  }
}

class _MarketNavItem extends StatelessWidget {
  const _MarketNavItem({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: -0.2);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 82,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class MarketInlineError extends StatelessWidget {
  const MarketInlineError({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Text(message, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ),
    );
  }
}

class MarketEmptyHintCard extends StatelessWidget {
  const MarketEmptyHintCard({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35))),
          ],
        ),
      ),
    );
  }
}

class MarketHorizontalSkeleton extends StatelessWidget {
  const MarketHorizontalSkeleton({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i) => Container(
          width: 150,
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: cs.outline.withValues(alpha: 0.10))),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: 6,
      ),
    );
  }
}
