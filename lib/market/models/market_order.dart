import 'package:flutter/foundation.dart';

@immutable
class MarketOrder {
  const MarketOrder({
    required this.id,
    required this.buyerId,
    required this.status,
    required this.currency,
    required this.subtotalCents,
    required this.shippingCents,
    required this.totalCents,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String buyerId;
  final String status;
  final String currency;
  final int subtotalCents;
  final int shippingCents;
  final int totalCents;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MarketOrder.fromJson(Map<String, dynamic> json) => MarketOrder(
        id: json['id'] as String,
        buyerId: json['buyer_id'] as String,
        status: json['status'] as String,
        currency: (json['currency'] as String?) ?? 'XOF',
        subtotalCents: (json['subtotal_cents'] as num?)?.toInt() ?? 0,
        shippingCents: (json['shipping_cents'] as num?)?.toInt() ?? 0,
        totalCents: (json['total_cents'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
