import 'dart:async';

import 'package:flutter/foundation.dart';
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
  late final Animation<double> _pulse;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1850));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _glow = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic)));
    _rot = Tween<double>(begin: -0.06, end: 0.03).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic));
    _pulse = Tween<double>(begin: 0.985, end: 1.02).animate(CurvedAnimation(parent: _c, curve: const Interval(0.10, 1.0, curve: Curves.easeInOutCubic)));
    _c.forward();

    _timer = Timer(const Duration(milliseconds: 2600), () {
      // ignore: discarded_futures
      _goNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    if (!mounted) return;

    // Make sure Supabase is initialized (or fails fast) in published builds.
    // This prevents routing decisions from happening while init is still in-flight.
    if (!SupabaseClientProvider.isInitialized) {
      try {
        await SupabaseClientProvider.initializeFromEnv().timeout(const Duration(seconds: 6));
      } catch (e) {
        debugPrint('Splash supabase init timeout/failure: $e');
      }
    }

    if (!SupabaseClientProvider.isInitialized) {
      // Supabase is still unavailable: show an explicit error page instead of
      // keeping the user on an indefinite loading state.
      context.go('/init-error');
      return;
    }

    final client = SupabaseClientProvider.clientOrNull;
    final session = client?.auth.currentSession;
    if (session != null) {
      context.go('/');
    } else {
      // No separate THIX Market account: only Supabase Auth.
      context.go('/auth/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.lightGrayBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: AppColors.lightGrayBackground))),
          // Blue header band like the homepage, but slightly taller to feel “splash”.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBand(),
          ),
          // Soft premium blobs (kept, but tuned for light background).
          const Positioned(top: -140, left: -120, child: _SplashBlob(color: AppColors.primaryBlue, size: 380)),
          const Positioned(bottom: -170, right: -140, child: _SplashBlob(color: AppColors.accentPurple, size: 420)),
          Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final glowAlpha = (0.10 + _glow.value * 0.28).clamp(0.0, 0.40);
                return Opacity(
                  opacity: _fade.value,
                  child: Transform.rotate(
                    angle: _rot.value,
                    child: Transform.scale(
                      scale: _pulse.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryBlueGradient,
                              boxShadow: [
                                BoxShadow(color: AppColors.primaryBlue.withValues(alpha: glowAlpha), blurRadius: 26, spreadRadius: 2),
                              ],
                              border: Border.all(color: AppColors.white.withValues(alpha: 0.65), width: 1),
                            ),
                            alignment: Alignment.center,
                            child: Text('T', style: context.textStyles.displaySmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'THIX ID',
                            style: context.textStyles.titleLarge?.copyWith(color: AppColors.darkNavy, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your Secure Digital Identity',
                            style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: 110,
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              backgroundColor: cs.primary.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation(cs.primary),
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
    );
  }
}

class _TopBand extends StatelessWidget {
  const _TopBand();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: SizedBox(
        height: top + 210,
        child: Stack(
          children: [
            const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.headerGradient))),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.14,
                  child: Align(
                    alignment: const Alignment(1.15, -0.55),
                    child: Transform.rotate(
                      angle: -0.12,
                      child: Container(
                        width: 320,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(42),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.white.withValues(alpha: 0.40), AppColors.white.withValues(alpha: 0.02)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
