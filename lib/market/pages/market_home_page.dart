import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/market/models/market_product.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/market/services/market_product_service.dart';
import 'package:thix_central/market/widgets/auth_required_panel.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class MarketHomePage extends StatefulWidget {
  const MarketHomePage({super.key});

  @override
  State<MarketHomePage> createState() => _MarketHomePageState();
}

class _MarketHomePageState extends State<MarketHomePage> {
  final MarketProductService _service = const MarketProductService();
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX Market',
        subtitle: 'Acheter • Vendre • Social-commerce',
        onMenuTap: () => context.pop(),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => context.push('/market/orders'),
              icon: Icon(Icons.receipt_long, color: cs.onSurface),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              tooltip: 'Commandes',
            ),
            IconButton(
              onPressed: () => context.push('/market/cart'),
              icon: Icon(Icons.shopping_bag_outlined, color: cs.onSurface),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              tooltip: 'Panier',
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 110),
        children: [
          AuthRequiredPanel(
            message: 'Connecte-toi pour ajouter au panier et passer commande.',
            afterLoginRoute: '/market',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Rechercher un produit…',
              prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: Icon(Icons.close, color: cs.onSurfaceVariant),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<MarketProduct>>(
            future: _service.listActive(query: _query),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: Text('Erreur chargement produits: ${snap.error}', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                );
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: Text(
                    'Aucun produit pour le moment. Ajoute des produits dans la table Supabase market_products (et optionnellement market_product_media).',
                    style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                  ),
                );
              }
              return Column(
                children: [
                  for (final p in items) ...[
                    MarketProductCard(
                      product: p,
                      onTap: () => context.push('/market/product/${p.id}'),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          if (SupabaseClientProvider.clientOrNull?.auth.currentUser == null)
            Text('Connecte-toi pour acheter. Les produits restent visibles en public.', style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class MarketProductCard extends StatelessWidget {
  const MarketProductCard({super.key, required this.product, required this.onTap});
  final MarketProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.mainCard),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              MarketProductThumb(url: product.coverUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      '${(product.priceCents / 100).toStringAsFixed(2)} ${product.currency}',
                      style: context.textStyles.bodyMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(product.stock > 0 ? 'Stock: ${product.stock}' : 'Rupture de stock', style: context.textStyles.labelSmall?.copyWith(color: product.stock > 0 ? cs.onSurfaceVariant : cs.error)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class MarketProductThumb extends StatelessWidget {
  const MarketProductThumb({super.key, required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: 74,
        height: 74,
        child: url == null
            ? DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.promoGradient, borderRadius: borderRadius),
                child: const Icon(Icons.shopping_bag, color: Colors.white, size: 30),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: borderRadius),
                  child: Icon(Icons.image_not_supported_outlined, color: cs.onPrimaryContainer),
                ),
              ),
      ),
    );
  }
}
