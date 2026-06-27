import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';

class ThixSplashPage extends StatefulWidget {
  const ThixSplashPage({super.key});

  @override
  State<ThixSplashPage> createState() => _ThixSplashPageState();
}

class _ThixSplashPageState extends State<ThixSplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _glow;
  late final Animation<double> _rot;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1850));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic)));
    _rot = Tween<double>(begin: -0.06, end: 0.03).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic));
    _c.forward();

    _timer = Timer(const Duration(milliseconds: 2600), _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    final client = SupabaseClientProvider.clientOrNull;
    final session = client?.auth.currentSession;
    if (session != null) {
      context.go('/');
    } else {
      context.go('/auth/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.thixIdDarkGradient),
        child: Stack(
          children: [
            const Positioned(top: -140, left: -120, child: _SplashBlob(color: AppColors.thixCyanGlow, size: 360)),
            const Positioned(bottom: -160, right: -120, child: _SplashBlob(color: AppColors.thixPurpleGlow, size: 380)),
            Center(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final glowAlpha = (0.20 + _glow.value * 0.45).clamp(0.0, 0.65);
                  final scale = 0.98 + (_glow.value * 0.03);
                  return Opacity(
                    opacity: _fade.value,
                    child: Transform.rotate(
                      angle: _rot.value,
                      child: Transform.scale(
                        scale: scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.thixIdCyanGradient,
                                boxShadow: [
                                  BoxShadow(color: AppColors.thixCyanGlow.withValues(alpha: glowAlpha), blurRadius: 26, spreadRadius: 2),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text('T', style: context.textStyles.displaySmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(height: 18),
                            Text('THIX ID', style: context.textStyles.titleLarge?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
                            const SizedBox(height: 6),
                            Text(
                              'Your Secure Digital Identity',
                              style: context.textStyles.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.70), height: 1.35),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: 110,
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                backgroundColor: cs.onSurface.withValues(alpha: 0.12),
                                valueColor: const AlwaysStoppedAnimation(AppColors.thixCyanGlow),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashBlob extends StatelessWidget {
  const _SplashBlob({required this.color, required this.size});
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
