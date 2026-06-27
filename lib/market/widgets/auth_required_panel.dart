import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/theme.dart';

class AuthRequiredPanel extends StatelessWidget {
  const AuthRequiredPanel({super.key, required this.message, required this.afterLoginRoute});
  final String message;
  final String afterLoginRoute;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3))),
          TextButton(
            onPressed: () => context.push('/login?next=$afterLoginRoute'),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
