import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/nav.dart';
import 'package:thix_central/theme.dart';

class ThixHomePage extends StatelessWidget {
  const ThixHomePage({super.key});

  static const _screenHPadding = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrayBackground,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _HeaderBlock()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_screenHPadding, 0, _screenHPadding, 0),
              child: Column(
                children: const [
                  SizedBox(height: 16),
                  _SearchBar(),
                  SizedBox(height: 14),
                  _QuickActionsRow(),
                  SizedBox(height: 28),
                  _ServicesHeader(),
                  SizedBox(height: 16),
                  _ServicesGrid(),
                  SizedBox(height: 16),
                  _PromoCarousel(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 98)),
        ],
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  static const _screenHPadding = 20.0;
  // Slightly taller top band (blue header) for better visual balance.
  static const _bottomPadding = 42.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        children: [
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.headerGradient))),
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.18,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Align(
                    alignment: const Alignment(1.25, -0.6),
                    child: Transform.rotate(angle: -0.10, child: const _WorldMapBackdrop()),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_screenHPadding, top + 2, _screenHPadding, _bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _TopHeaderBar(),
                SizedBox(height: 10),
                _Greeting(),
                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldMapBackdrop extends StatelessWidget {
  const _WorldMapBackdrop();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 420,
      height: 280,
      child: CustomPaint(
        painter: _WorldMapPainter(color: AppColors.white.withValues(alpha: 0.55)),
      ),
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  const _WorldMapPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    Path blob(List<Offset> pts) {
      final p = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final prev = pts[i - 1];
        final cur = pts[i];
        final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
        p.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
      }
      p.close();
      return p;
    }

    final w = size.width;
    final h = size.height;

    canvas.drawPath(
      blob([
        Offset(w * 0.18, h * 0.18),
        Offset(w * 0.10, h * 0.30),
        Offset(w * 0.16, h * 0.42),
        Offset(w * 0.12, h * 0.58),
        Offset(w * 0.22, h * 0.70),
        Offset(w * 0.30, h * 0.62),
        Offset(w * 0.28, h * 0.46),
        Offset(w * 0.32, h * 0.30),
      ]),
      paint,
    );

    canvas.drawPath(
      blob([
        Offset(w * 0.46, h * 0.22),
        Offset(w * 0.40, h * 0.30),
        Offset(w * 0.46, h * 0.38),
        Offset(w * 0.44, h * 0.52),
        Offset(w * 0.52, h * 0.70),
        Offset(w * 0.60, h * 0.58),
        Offset(w * 0.56, h * 0.38),
        Offset(w * 0.58, h * 0.28),
      ]),
      paint,
    );

    canvas.drawPath(
      blob([
        Offset(w * 0.70, h * 0.24),
        Offset(w * 0.62, h * 0.34),
        Offset(w * 0.68, h * 0.44),
        Offset(w * 0.66, h * 0.56),
        Offset(w * 0.78, h * 0.70),
        Offset(w * 0.92, h * 0.56),
        Offset(w * 0.88, h * 0.40),
        Offset(w * 0.94, h * 0.30),
        Offset(w * 0.82, h * 0.22),
      ]),
      paint,
    );

    final dotPaint = Paint()..color = color.withValues(alpha: 0.35);
    for (var y = 0; y < 9; y++) {
      for (var x = 0; x < 13; x++) {
        final dx = (w * 0.10) + x * (w * 0.07);
        final dy = (h * 0.12) + y * (h * 0.09);
        canvas.drawCircle(Offset(dx, dy), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter oldDelegate) => oldDelegate.color != color;
}

class _TopHeaderBar extends StatelessWidget {
  const _TopHeaderBar();

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, letterSpacing: -0.2);
    final subtitleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.white.withValues(alpha: 0.78), fontWeight: FontWeight.w500, letterSpacing: -0.2);

    return Row(
      children: [
        const _HeaderIconButton(icon: Icons.menu),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Text('THIX ID', style: titleStyle)]),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Identité Sécurisée', style: subtitleStyle),
                const SizedBox(width: 6),
                const Icon(Icons.verified, size: 14, color: AppColors.primaryBlue),
              ],
            ),
          ],
        ),
        const Spacer(),
        const _NotificationBell(badgeCount: 3),
        const SizedBox(width: 12),
        const _AvatarWithStatus(),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Icon(icon, size: 24, color: AppColors.white),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.badgeCount});
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const SizedBox(width: 24, height: 24, child: Icon(Icons.notifications_none, size: 24, color: AppColors.white)),
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.dangerRed, shape: BoxShape.circle),
            child: Text(
              badgeCount.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarWithStatus extends StatelessWidget {
  const _AvatarWithStatus();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white.withValues(alpha: 0.12),
            border: Border.all(color: AppColors.white, width: 3),
          ),
          alignment: Alignment.center,
          child: Text('N', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.successGreen, border: Border.all(color: AppColors.white, width: 2)),
          ),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final h1 = Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontWeight: FontWeight.w800, letterSpacing: -0.2, fontSize: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('Bonjour Nathan 👋', style: h1)],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.75), letterSpacing: -0.2, fontSize: 13);
    return SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.search),
          boxShadow: const [AppShadows.secondary],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(child: Text('Rechercher un service, document, opportunité...', style: hint, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              const Icon(Icons.tune, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickAction(icon: Icons.qr_code_scanner, label: 'Scanner QR', color: AppColors.primaryBlue, onTap: () => context.go(AppRoutes.scan))),
        const SizedBox(width: 12),
        const Expanded(child: _QuickAction(icon: Icons.nfc, label: 'NFC', color: AppColors.successGreen)),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(icon: Icons.description_outlined, label: 'Documents', color: AppColors.accentPurple, onTap: () => context.go(AppRoutes.services))),
        const SizedBox(width: 12),
        Expanded(child: _QuickAction(icon: Icons.verified_user_outlined, label: 'Sécurité', color: AppColors.accentOrange, onTap: () => context.push(AppRoutes.thixIdCard))),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.serviceCard),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        height: 72,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.serviceCard),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.darkNavy, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServicesHeader extends StatelessWidget {
  const _ServicesHeader();

  @override
  Widget build(BuildContext context) {
    final title = Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.darkNavy, fontWeight: FontWeight.w700, letterSpacing: -0.2);
    final action = Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w700, letterSpacing: -0.2);
    return Row(
      children: [
        Expanded(child: Text('Tous mes services', style: title)),
        InkWell(
          onTap: () => context.go(AppRoutes.services),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Text('Voir tout', style: action),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.primaryBlue),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: AppSpacing.gridGutter,
      mainAxisSpacing: AppSpacing.gridGutter,
      // Smaller service buttons: slightly wider than tall.
      childAspectRatio: 1.15,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: const [
        _ServiceTile(icon: Icons.play_circle_filled, iconColor: AppColors.primaryBlue, title: 'THIX MEDIA', subtitle: 'Vidéos, musiques, podcasts'),
        _ServiceTile(icon: Icons.shopping_bag, iconColor: AppColors.accentOrange, title: 'THIX Market', subtitle: 'Achetez, vendez, profitez', route: AppRoutes.market),
        _ServiceTile(icon: Icons.school, iconColor: AppColors.accentGreen2, title: 'Formations', subtitle: 'Apprenez, progressez', route: AppRoutes.learning),
        _ServiceTile(icon: Icons.work, iconColor: AppColors.accentPurple, title: 'Emplois', subtitle: 'Trouvez votre prochain job', route: AppRoutes.jobs),
        _ServiceTile(icon: Icons.groups, iconColor: AppColors.accentBlue2, title: 'Réseau Pro', subtitle: 'Développez votre réseau', route: AppRoutes.social),
        _ServiceTile(icon: Icons.event, iconColor: AppColors.dangerRed, title: 'Événements', subtitle: 'Participez, réservez', route: AppRoutes.events),
        _ServiceTile(icon: Icons.lightbulb, iconColor: AppColors.goldBadge, title: 'Opportunités', subtitle: 'Découvrez, saisissez'),
        _ServiceTile(icon: Icons.account_balance_wallet, iconColor: AppColors.successGreen, title: 'THIX Money', subtitle: 'Gérez vos finances'),
        _ServiceTile(icon: Icons.favorite, iconColor: AppColors.dangerRed, title: 'THIX Santé', subtitle: 'Prenez soin de vous', route: AppRoutes.health),
        _ServiceTile(icon: Icons.feed, iconColor: AppColors.accentOrange, title: 'THIX INFO', subtitle: 'Actualités & informations', route: AppRoutes.news),
        _ServiceTile(icon: Icons.account_balance, iconColor: AppColors.accentBlue3, title: 'Services Gov', subtitle: 'Services publics en ligne', route: AppRoutes.services),
        _ServiceTile(icon: Icons.confirmation_num, iconColor: AppColors.accentPurple, title: 'Réservation', subtitle: 'Billets, hôtels, voyages', route: AppRoutes.reservation),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, this.route});
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.darkNavy, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.05);

    return InkWell(
      onTap: route == null ? null : () => context.push(route!),
      borderRadius: BorderRadius.circular(AppRadius.serviceCard),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.serviceCard),
          border: Border.all(color: AppColors.cardBorder, width: 1),
          boxShadow: const [AppShadows.secondary],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(height: 6),
              Text(title, style: t, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  static const _count = 4;
  final PageController _controller = PageController(viewportFraction: 1);
  int _index = 0;
  Timer? _startTimer;
  Timer? _autoTimer;

  static const _autoScrollDelay = Duration(seconds: 10);
  static const _autoScrollEvery = Duration(seconds: 4);
  static const _pageAnimDuration = Duration(milliseconds: 320);

  @override
  void initState() {
    super.initState();
    // Start auto-scroll only after a grace period so the first banner is readable.
    _startTimer = Timer(_autoScrollDelay, () {
      if (!mounted) return;
      _autoTimer = Timer.periodic(_autoScrollEvery, (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_index + 1) % _count;
        _controller.animateToPage(next, duration: _pageAnimDuration, curve: Curves.easeOutCubic);
      });
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 132,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.search),
            child: PageView.builder(
              controller: _controller,
              reverse: true,
              onPageChanged: (v) => setState(() => _index = v),
              itemCount: _count,
              itemBuilder: (context, i) => _PromoBannerCard(index: i),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _count,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _index ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: (i == _index ? AppColors.primaryBlue : AppColors.cardBorder),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromoBannerCard extends StatelessWidget {
  const _PromoBannerCard({required this.index});
  final int index;

  String? _routeForIndex(int index) {
    if (index % 4 == 0) return AppRoutes.market;
    if (index % 4 == 3) return AppRoutes.health;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final overline = Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.white.withValues(alpha: 0.72), fontWeight: FontWeight.w700, letterSpacing: -0.2, fontSize: 11);
    final title = Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2);
    final cta = Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w800, letterSpacing: -0.2, fontSize: 11);

    final items = const [
      ('SPONSOR', 'THIX Market', 'Offres exclusives aujourd\'hui'),
      ('PUB', 'THIX Money', 'Cashback + sécurité renforcée'),
      ('NOUVEAU', 'THIX Media', 'Vidéos & podcasts premium'),
      ('PARTENAIRE', 'THIX Santé', 'Suivi bien-être & conseils'),
    ];
    final (tag, line1, line2) = items[index % items.length];

    final route = _routeForIndex(index);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: route == null ? null : () => context.push(route),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Stack(
          children: [
            const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.promoGradient))),
            Positioned(
              left: 16,
              top: 14,
              right: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                    child: Text(tag, style: overline),
                  ),
                  const SizedBox(height: 10),
                  Text(line1, style: title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(line2, style: overline?.copyWith(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.button)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Voir', style: cta),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right, size: 18, color: AppColors.primaryBlue),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              bottom: -10,
              child: Opacity(opacity: 0.9, child: _PromoArt(index: index)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoArt extends StatelessWidget {
  const _PromoArt({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final icons = const [Icons.shopping_bag, Icons.account_balance_wallet, Icons.play_circle_filled, Icons.favorite];
    final icon = icons[index % icons.length];
    return SizedBox(
      width: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: 16,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, color: AppColors.white.withValues(alpha: 0.95), size: 46),
            ),
          ),
          Positioned(
            right: 54,
            top: 0,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white.withValues(alpha: 0.16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
