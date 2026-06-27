import 'package:flutter/foundation.dart';
import 'package:thix_central/market/models/market_product.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';

class MarketProductService {
  const MarketProductService();

  Future<List<MarketProduct>> listActive({String? query, int limit = 30, String orderBy = 'created_at', bool ascending = false}) async {
    try {
      final q = (query ?? '').trim();
      var builder = SupabaseClientProvider.client
          .from('market_products')
          .select('id,seller_id,title,description,price_cents,currency,stock,is_active,created_at,updated_at,market_product_media(url,sort_order)')
          .eq('is_active', true);
      if (q.isNotEmpty) builder = builder.filter('title', 'ilike', '%$q%');
      final rows = await builder.order(orderBy, ascending: ascending).limit(limit);
      return (rows as List)
          .whereType<Map>()
          .map((e) => MarketProduct.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('listActive products failed: $e');
      rethrow;
    }
  }

  Future<MarketProduct> getById(String id) async {
    try {
      final row = await SupabaseClientProvider.client
          .from('market_products')
          .select('id,seller_id,title,description,price_cents,currency,stock,is_active,created_at,updated_at,market_product_media(url,sort_order)')
          .eq('id', id)
          .maybeSingle();
      if (row == null) throw Exception('Product not found');
      return MarketProduct.fromJson((row as Map).cast<String, dynamic>());
    } catch (e) {
      debugPrint('getById product failed: $e');
      rethrow;
    }
  }
}
