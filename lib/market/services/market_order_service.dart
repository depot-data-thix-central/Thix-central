import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/market/models/market_cart_item.dart';
import 'package:thix_central/market/models/market_order.dart';
import 'package:thix_central/market/services/market_cart_service.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';

class MarketOrderService {
  const MarketOrderService({this.cartService = const MarketCartService()});
  final MarketCartService cartService;

  String _requireUserId() {
    final user = SupabaseClientProvider.client.auth.currentUser;
    if (user == null) throw const AuthException('Not signed in');
    return user.id;
  }

  Future<List<MarketOrder>> listMyOrders({int limit = 30}) async {
    final userId = _requireUserId();
    try {
      final rows = await SupabaseClientProvider.client
          .from('market_orders')
          .select('id,buyer_id,status,currency,subtotal_cents,shipping_cents,total_cents,created_at,updated_at')
          .eq('buyer_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (rows as List)
          .whereType<Map>()
          .map((e) => MarketOrder.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      debugPrint('listMyOrders failed: $e');
      rethrow;
    }
  }

  Future<MarketOrder> checkoutNoPayment({int shippingCents = 0}) async {
    final userId = _requireUserId();
    final cart = await cartService.listMyCart();
    if (cart.isEmpty) throw Exception('Cart is empty');

    final currency = cart.first.product.currency;
    final subtotal = cart.fold<int>(0, (sum, it) => sum + it.lineTotalCents);
    final total = subtotal + shippingCents;

    try {
      final orderRow = await SupabaseClientProvider.client
          .from('market_orders')
          .insert({
            'buyer_id': userId,
            'status': 'pending',
            'currency': currency,
            'subtotal_cents': subtotal,
            'shipping_cents': shippingCents,
            'total_cents': total,
          })
          .select('id,buyer_id,status,currency,subtotal_cents,shipping_cents,total_cents,created_at,updated_at')
          .single();

      final orderId = (orderRow as Map)['id'] as String;

      final itemsPayload = cart
          .map(
            (MarketCartItem it) => {
              'order_id': orderId,
              'product_id': it.productId,
              'seller_id': it.product.sellerId,
              'title': it.product.title,
              'unit_price_cents': it.product.priceCents,
              'quantity': it.quantity,
              'line_total_cents': it.lineTotalCents,
            },
          )
          .toList();

      await SupabaseClientProvider.client.from('market_order_items').insert(itemsPayload);
      await cartService.clear();

      return MarketOrder.fromJson(orderRow.cast<String, dynamic>());
    } catch (e) {
      debugPrint('checkoutNoPayment failed: $e');
      rethrow;
    }
  }
}
