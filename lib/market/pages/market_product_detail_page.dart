import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/market/models/market_product.dart';
import 'package:thix_central/market/services/market_cart_service.dart';
import 'package:thix_central/market/services/market_product_service.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class MarketProductDetailPage extends StatefulWidget {
  const MarketProductDetailPage({super.key, required this.productId});
  final String productId;

  @override
  State<MarketProductDetailPage> createState() => _MarketProductDetailPageState();
}

class _MarketProductDetailPageState extends State<MarketProductDetailPage> {
  final MarketProductService _products = const MarketProductService();
  final MarketCartService _cart = const MarketCartService();
  bool _adding = false;

  Future<void> _addToCart(MarketProduct p) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      context.push('/login?next=/market/product/${p.id}');
      return;
    }
    setState(() => _adding = true);
    try {
      await _cart.addOne(productId: p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajouté au panier')));
    } catch (e) {
      debugPrint('addToCart failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'Produit',
        subtitle: 'Détails',
        onMenuTap: () => context.pop(),
        trailing: IconButton(
          onPressed: () => context.push('/market/cart'),
          icon: Icon(Icons.shopping_bag_outlined, color: cs.onSurface),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      body: FutureBuilder<MarketProduct>(
        future: _products.getById(widget.productId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Erreur: ${snap.error}'));
          final p = snap.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 120),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.mainCard),
                child: SizedBox(
                  height: 220,
                  child: p.coverUrl == null
                      ? const DecoratedBox(
                          decoration: BoxDecoration(gradient: AppColors.promoGradient),
                          child: Center(child: Icon(Icons.shopping_bag, color: Colors.white, size: 64)),
                        )
                      : Image.network(
                          p.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => DecoratedBox(
                            decoration: BoxDecoration(color: cs.primaryContainer),
                            child: Icon(Icons.broken_image_outlined, color: cs.onPrimaryContainer, size: 40),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(p.title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(999)),
                    child: Text('${(p.priceCents / 100).toStringAsFixed(2)} ${p.currency}', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 10),
                  Text(p.stock > 0 ? 'Stock: ${p.stock}' : 'Rupture', style: context.textStyles.labelSmall?.copyWith(color: p.stock > 0 ? cs.onSurfaceVariant : cs.error)),
                ],
              ),
              const SizedBox(height: 12),
              if ((p.description ?? '').trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: Text(p.description!, style: context.textStyles.bodyMedium?.copyWith(height: 1.45, color: cs.onSurfaceVariant)),
                ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: AppColors.primaryBlueGradient, borderRadius: BorderRadius.circular(AppRadius.button)),
                  child: TextButton(
                    onPressed: (_adding || p.stock <= 0) ? null : () => _addToCart(p),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.white,
                      disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    ),
                    child: _adding
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(p.stock > 0 ? Icons.add_shopping_cart : Icons.block, color: Colors.white, size: 18),
                              const SizedBox(width: 10),
                              Text(p.stock > 0 ? 'Ajouter au panier' : 'Indisponible'),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
