import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';

class ThixTopBar extends StatelessWidget implements PreferredSizeWidget {
  const ThixTopBar({super.key, required this.title, this.subtitle, this.onMenuTap, this.trailing});
  final String title;
  final String? subtitle;
  final VoidCallback? onMenuTap;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: Icon(Icons.menu, color: cs.onSurface),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ThixAvatar extends StatelessWidget {
  const ThixAvatar({super.key, this.size = 34, this.initials = 'N'});
  final double size;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryBlueGradient,
        shape: BoxShape.circle,
        border: Border.all(color: cs.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}
