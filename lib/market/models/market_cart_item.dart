import 'package:flutter/foundation.dart';
import 'package:thix_central/market/models/market_product.dart';

@immutable
class MarketCartItem {
  const MarketCartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    required this.product,
  });

  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MarketProduct product;

  int get lineTotalCents => product.priceCents * quantity;

  factory MarketCartItem.fromJson(Map<String, dynamic> json) => MarketCartItem(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        productId: json['product_id'] as String,
        quantity: (json['quantity'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        product: MarketProduct.fromJson((json['market_products'] as Map).cast<String, dynamic>()),
      );
}
