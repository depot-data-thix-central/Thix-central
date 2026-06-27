import 'package:flutter/foundation.dart';
import 'package:thix_central/market/models/market_shop.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';

class MarketShopService {
  const MarketShopService();

  /// Returns "recommended" shops derived from active products.
  /// No mock data: if you have no products, this returns an empty list.
  Future<List<MarketShop>> listRecommended({int limit = 6}) async {
    try {
      final rows = await SupabaseClientProvider.client
          .from('market_products')
          .select('seller_id')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(200);

      final counts = <String, int>{};
      for (final r in (rows as List).whereType<Map>()) {
        final id = r['seller_id'] as String?;
        if (id == null) continue;
        counts[id] = (counts[id] ?? 0) + 1;
      }

      final sellerIds = counts.keys.toList()
        ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
      final top = sellerIds.take(limit).toList();
      if (top.isEmpty) return const [];

      final profiles = await SupabaseClientProvider.client
          .from('profiles')
          .select('user_id,display_name,avatar_url')
          .inFilter('user_id', top);

      final byId = <String, Map<String, dynamic>>{};
      for (final p in (profiles as List).whereType<Map>()) {
        final id = p['user_id'] as String?;
        if (id != null) byId[id] = p.cast<String, dynamic>();
      }

      return top
          .map((id) {
            final profile = byId[id];
            final rawName = profile?['display_name'] as String?;
            final name = (rawName == null || rawName.trim().isEmpty) ? 'Boutique ${id.substring(0, 4).toUpperCase()}' : rawName.trim();
            return MarketShop(userId: id, displayName: name, avatarUrl: profile?['avatar_url'] as String?, productCount: counts[id] ?? 0);
          })
          .toList(growable: false);
    } catch (e) {
      debugPrint('listRecommended shops failed: $e');
      rethrow;
    }
  }
}
