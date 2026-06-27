import 'package:flutter/foundation.dart';

@immutable
class Money {
  const Money({required this.cents, required this.currency});
  final int cents;
  final String currency;

  String format() {
    final value = (cents / 100).toStringAsFixed(2);
    return '$value $currency';
  }
}
