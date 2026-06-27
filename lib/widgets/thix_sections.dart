import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';

class ThixSectionHeader extends StatelessWidget {
  const ThixSectionHeader({super.key, required this.title, this.actionLabel, this.onActionTap, this.leadingIcon});
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      child: Row(
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, color: cs.primary, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
              child: Text(actionLabel!, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class ThixPillChip extends StatelessWidget {
  const ThixPillChip({super.key, required this.label, required this.icon, this.onTap, this.badgeCount});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = cs.outline.withValues(alpha: 0.16);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 18, color: cs.primary),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: cs.error, borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.surface, width: 1.5)),
                      child: Text(
                        badgeCount! > 9 ? '9+' : badgeCount!.toString(),
                        style: context.textStyles.labelSmall?.copyWith(color: cs.onError, fontWeight: FontWeight.w700, height: 1.1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Text(label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}
