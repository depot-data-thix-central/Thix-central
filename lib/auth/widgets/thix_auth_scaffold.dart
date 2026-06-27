import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/theme.dart';

/// Premium auth scaffold used across THIX ID screens.
/// Provides a futuristic dark gradient background + subtle glow + safe area.
class ThixAuthScaffold extends StatelessWidget {
  const ThixAuthScaffold({super.key, required this.child, this.showBack = false});
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: Column(
              children: [
                if (showBack)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(Icons.arrow_back, color: cs.onSurface),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThixGlassPanel extends StatelessWidget {
  const ThixGlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.mainCard),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(AppRadius.mainCard),
            border: Border.all(color: cs.outline.withValues(alpha: 0.20)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.thixIdDarkGradient),
      child: Stack(
        children: const [
          Positioned(top: -140, left: -120, child: _GlowBlob(color: AppColors.thixCyanGlow, size: 340)),
          Positioned(bottom: -160, right: -120, child: _GlowBlob(color: AppColors.thixPurpleGlow, size: 360)),
          Positioned.fill(child: _NoiseOverlay(opacity: 0.035)),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0.0)]),
        ),
      ),
    );
  }
}

class _NoiseOverlay extends StatelessWidget {
  const _NoiseOverlay({required this.opacity});
  final double opacity;

  @override
  Widget build(BuildContext context) {
    // Lightweight pseudo-noise using a repeated semi-transparent pattern.
    // (No external assets needed.)
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(painter: _NoisePainter()),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    const step = 6.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final v = ((x + y) % 18) / 18.0;
        paint.color = Colors.white.withValues(alpha: 0.04 + v * 0.04);
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
