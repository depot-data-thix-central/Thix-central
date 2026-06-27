import 'package:flutter/foundation.dart';

@immutable
class MarketShop {
  const MarketShop({required this.userId, required this.displayName, required this.avatarUrl, required this.productCount});

  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int productCount;

  MarketShop copyWith({String? userId, String? displayName, String? avatarUrl, int? productCount}) =>
      MarketShop(userId: userId ?? this.userId, displayName: displayName ?? this.displayName, avatarUrl: avatarUrl ?? this.avatarUrl, productCount: productCount ?? this.productCount);
}
