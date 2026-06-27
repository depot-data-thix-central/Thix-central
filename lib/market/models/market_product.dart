import 'package:flutter/foundation.dart';

@immutable
class MarketProduct {
  const MarketProduct({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.priceCents,
    required this.currency,
    required this.stock,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.mediaUrls,
  });

  final String id;
  final String sellerId;
  final String title;
  final String? description;
  final int priceCents;
  final String currency;
  final int stock;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> mediaUrls;

  String? get coverUrl => mediaUrls.isEmpty ? null : mediaUrls.first;

  MarketProduct copyWith({
    String? id,
    String? sellerId,
    String? title,
    String? description,
    int? priceCents,
    String? currency,
    int? stock,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? mediaUrls,
  }) =>
      MarketProduct(
        id: id ?? this.id,
        sellerId: sellerId ?? this.sellerId,
        title: title ?? this.title,
        description: description ?? this.description,
        priceCents: priceCents ?? this.priceCents,
        currency: currency ?? this.currency,
        stock: stock ?? this.stock,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        mediaUrls: mediaUrls ?? this.mediaUrls,
      );

  factory MarketProduct.fromJson(Map<String, dynamic> json) {
    final media = (json['market_product_media'] as List?)
            ?.whereType<Map>()
            .map((e) => e['url'] as String?)
            .whereType<String>()
            .toList() ??
        const <String>[];
    return MarketProduct(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priceCents: (json['price_cents'] as num).toInt(),
      currency: (json['currency'] as String?) ?? 'XOF',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      mediaUrls: media,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'seller_id': sellerId,
        'title': title,
        'description': description,
        'price_cents': priceCents,
        'currency': currency,
        'stock': stock,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
