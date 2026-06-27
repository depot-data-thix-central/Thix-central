import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';

/// Shared thumbnail widget used across Market pages (cart, lists, etc.).
class MarketProductThumb extends StatelessWidget {
  const MarketProductThumb({super.key, required this.url, this.size = 74});
  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(16);
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? DecoratedBox(decoration: BoxDecoration(gradient: AppColors.promoGradient, borderRadius: borderRadius), child: const Icon(Icons.shopping_bag, color: Colors.white, size: 30))
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: borderRadius),
                  child: Icon(Icons.image_not_supported_outlined, color: cs.onPrimaryContainer),
                ),
              ),
      ),
    );
  }
}
