import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  void _onTap(int index) => widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: KeyedSubtree(key: ValueKey(widget.navigationShell.currentIndex), child: widget.navigationShell),
        ),
      ),
      bottomNavigationBar: _ThixBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}

class _ThixBottomNav extends StatelessWidget {
  const _ThixBottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    const barHeight = 88.0;

    return SizedBox(
      height: barHeight + bottom,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.bottomNav)),
              child: Container(
                height: barHeight + bottom,
                padding: EdgeInsets.only(bottom: bottom),
                decoration: BoxDecoration(color: AppColors.white, boxShadow: const [AppShadows.secondary], border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      label: 'Accueil',
                      icon: Icons.home_rounded,
                      selected: currentIndex == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavItem(
                      label: 'Santé',
                      icon: Icons.favorite_outline_rounded,
                      selected: currentIndex == 1,
                      onTap: () => onTap(1),
                    ),
                    const SizedBox(width: 76),
                    _NavItem(
                      label: 'Messages',
                      icon: Icons.chat_bubble_outline_rounded,
                      selected: currentIndex == 3,
                      onTap: () => onTap(3),
                      badgeCount: 3,
                    ),
                    _NavItem(
                      label: 'Profil',
                      icon: Icons.person_outline_rounded,
                      selected: currentIndex == 4,
                      onTap: () => onTap(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: bottom + 6,
            child: _CenterButton(selected: currentIndex == 2, onTap: () => onTap(2)),
          ),
        ],
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.selected, required this.onTap});
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
      letterSpacing: -0.2,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        scale: selected ? 1.0 : 0.98,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: AppColors.primaryBlueGradient,
                shape: BoxShape.circle,
                boxShadow: const [AppShadows.main],
              ),
              child: const Icon(Icons.note_add_rounded, size: 30, color: AppColors.white),
            ),
            const SizedBox(height: 6),
            Text('Nouveau', style: labelStyle),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.label, required this.icon, required this.selected, required this.onTap, this.badgeCount});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryBlue : AppColors.textSecondary;
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.2);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 82,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 22, color: color),
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      right: -10,
                      top: -8,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: AppColors.dangerRed, shape: BoxShape.circle),
                        child: Text(
                          badgeCount!.toString(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.0, letterSpacing: -0.2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
