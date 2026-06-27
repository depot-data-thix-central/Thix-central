import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/market/models/market_cart_item.dart';
import 'package:thix_central/market/widgets/market_product_thumb.dart';
import 'package:thix_central/market/services/market_cart_service.dart';
import 'package:thix_central/market/services/market_order_service.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class MarketCartPage extends StatefulWidget {
  const MarketCartPage({super.key});

  @override
  State<MarketCartPage> createState() => _MarketCartPageState();
}

class _MarketCartPageState extends State<MarketCartPage> {
  final MarketCartService _cart = const MarketCartService();
  final MarketOrderService _orders = const MarketOrderService();
  bool _checkingOut = false;

  Future<void> _checkout() async {
    if (SupabaseClientProvider.clientOrNull?.auth.currentUser == null) {
      context.push('/auth/login?next=/market/cart');
      return;
    }
    setState(() => _checkingOut = true);
    try {
      await _orders.checkoutNoPayment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commande créée (paiement non activé)')));
      context.go('/market/orders');
    } catch (e) {
      debugPrint('checkout failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'Panier',
        subtitle: 'Récapitulatif',
        onMenuTap: () => context.pop(),
        trailing: IconButton(
          onPressed: () => context.push('/market/orders'),
          icon: Icon(Icons.receipt_long, color: cs.onSurface),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      body: FutureBuilder<List<MarketCartItem>>(
        future: SupabaseClientProvider.clientOrNull?.auth.currentUser == null ? Future.value(const []) : _cart.listMyCart(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Erreur: ${snap.error}'));
          final items = snap.data ?? const [];
          final subtotal = items.fold<int>(0, (sum, it) => sum + it.lineTotalCents);
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 140),
            children: [
              if (SupabaseClientProvider.clientOrNull?.auth.currentUser == null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Connecte-toi pour voir ton panier.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
                      TextButton(onPressed: () => context.push('/auth/login?next=/market/cart'), child: const Text('Connexion')),
                    ],
                  ),
                )
              else if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, color: cs.onSurfaceVariant),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Ton panier est vide.')),
                      TextButton(onPressed: () => context.go('/market'), child: const Text('Explorer')),
                    ],
                  ),
                )
              else ...[
                for (final it in items) ...[
                  _CartItemTile(
                    item: it,
                    onMinus: () async {
                      await _cart.setQuantity(productId: it.productId, quantity: it.quantity - 1);
                      if (mounted) setState(() {});
                    },
                    onPlus: () async {
                      await _cart.setQuantity(productId: it.productId, quantity: it.quantity + 1);
                      if (mounted) setState(() {});
                    },
                    onRemove: () async {
                      await _cart.remove(productId: it.productId);
                      if (mounted) setState(() {});
                    },
                    onOpen: () => context.push('/market/product/${it.productId}'),
                  ),
                  const SizedBox(height: 10),
                ],
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Sous-total', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                          Text('${(subtotal / 100).toStringAsFixed(2)} ${items.first.product.currency}', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(gradient: AppColors.primaryBlueGradient, borderRadius: BorderRadius.circular(AppRadius.button)),
                          child: TextButton(
                            onPressed: _checkingOut ? null : _checkout,
                            style: TextButton.styleFrom(foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))),
                            child: _checkingOut
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.verified_outlined, color: Colors.white, size: 18),
                                      SizedBox(width: 10),
                                      Text('Valider la commande (sans paiement)'),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({required this.item, required this.onMinus, required this.onPlus, required this.onRemove, required this.onOpen});
  final MarketCartItem item;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: MarketProductThumb(url: item.product.coverUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${(item.product.priceCents / 100).toStringAsFixed(2)} ${item.product.currency}', style: context.textStyles.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _QtyBtn(icon: Icons.remove, onTap: onMinus),
                    const SizedBox(width: 10),
                    Text('${item.quantity}', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 10),
                    _QtyBtn(icon: Icons.add, onTap: onPlus),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.delete_outline, color: cs.error),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.outline.withValues(alpha: 0.12))),
        child: Icon(icon, color: cs.onPrimaryContainer, size: 18),
      ),
    );
  }
}
