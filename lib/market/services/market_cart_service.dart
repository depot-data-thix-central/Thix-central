import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/market/models/market_cart_item.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';

class MarketCartService {
  const MarketCartService();

  String _requireUserId() {
    final user = SupabaseClientProvider.client.auth.currentUser;
    if (user == null) throw const AuthException('Not signed in');
    return user.id;
  }

  Future<List<MarketCartItem>> listMyCart() async {
    final userId = _requireUserId();
    try {
      final rows = await SupabaseClientProvider.client
          .from('market_cart_items')
          .select(
            'id,user_id,product_id,quantity,created_at,updated_at,market_products(id,seller_id,title,description,price_cents,currency,stock,is_active,created_at,updated_at,market_product_media(url,sort_order))',
          )
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      return (rows as List)
          .whereType<Map>()
          .map((e) => MarketCartItem.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('listMyCart failed: $e');
      rethrow;
    }
  }

  Future<void> setQuantity({required String productId, required int quantity}) async {
    final userId = _requireUserId();
    try {
      if (quantity <= 0) {
        await remove(productId: productId);
        return;
      }
      await SupabaseClientProvider.client.from('market_cart_items').upsert(
        {'user_id': userId, 'product_id': productId, 'quantity': quantity},
        onConflict: 'user_id,product_id',
      );
    } catch (e) {
      debugPrint('setQuantity failed: $e');
      rethrow;
    }
  }

  Future<void> addOne({required String productId}) async {
    final items = await listMyCart();
    final existing = items.where((e) => e.productId == productId).toList();
    final nextQty = existing.isEmpty ? 1 : (existing.first.quantity + 1);
    await setQuantity(productId: productId, quantity: nextQty);
  }

  Future<void> remove({required String productId}) async {
    final userId = _requireUserId();
    try {
      await SupabaseClientProvider.client
          .from('market_cart_items')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      debugPrint('remove cart item failed: $e');
      rethrow;
    }
  }

  Future<void> clear() async {
    final userId = _requireUserId();
    try {
      await SupabaseClientProvider.client.from('market_cart_items').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('clear cart failed: $e');
      rethrow;
    }
  }
}
