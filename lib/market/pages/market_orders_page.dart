import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/market/models/market_order.dart';
import 'package:thix_central/market/services/market_order_service.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class MarketOrdersPage extends StatelessWidget {
  const MarketOrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final service = const MarketOrderService();
    return Scaffold(
      appBar: ThixTopBar(
        title: 'Commandes',
        subtitle: 'Historique',
        onMenuTap: () => context.pop(),
        trailing: IconButton(
          onPressed: () => context.push('/market/cart'),
          icon: Icon(Icons.shopping_bag_outlined, color: cs.onSurface),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      body: SupabaseClientProvider.clientOrNull?.auth.currentUser == null
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Connecte-toi pour voir tes commandes.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
                      TextButton(onPressed: () => context.push('/auth/login?next=/market/orders'), child: const Text('Connexion')),
                    ],
                  ),
                ),
              ],
            )
          : FutureBuilder<List<MarketOrder>>(
              future: service.listMyOrders(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snap.hasError) return Center(child: Text('Erreur: ${snap.error}'));
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                        child: Text('Aucune commande pour le moment.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                    ],
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 110),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _OrderTile(order: items[i]),
                );
              },
            ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final MarketOrder order;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = switch (order.status) {
      'pending' => AppColors.accentOrange,
      'confirmed' => AppColors.accentBlue2,
      'shipped' => AppColors.accentPurple,
      'delivered' => AppColors.successGreen,
      'cancelled' => cs.error,
      _ => cs.onSurfaceVariant,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(16), border: Border.all(color: statusColor.withValues(alpha: 0.20))),
            child: Icon(Icons.receipt_long, color: statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commande', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Statut: ${order.status}', style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(
            '${(order.totalCents / 100).toStringAsFixed(2)} ${order.currency}',
            style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.primary),
          ),
        ],
      ),
    );
  }
}
