import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';

class AuthRequiredPanel extends StatelessWidget {
  const AuthRequiredPanel({super.key, required this.message, required this.afterLoginRoute});
  final String message;
  final String afterLoginRoute;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!SupabaseClientProvider.isInitialized) {
      return _BackendNotConfiguredPanel(error: SupabaseClientProvider.initError);
    }

    final user = SupabaseClientProvider.clientOrNull?.auth.currentUser;
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
            onPressed: () => context.push('/auth/login?next=$afterLoginRoute'),
            style: TextButton.styleFrom(foregroundColor: cs.primary),
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}

class _BackendNotConfiguredPanel extends StatelessWidget {
  const _BackendNotConfiguredPanel({required this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: cs.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Supabase n\'est pas initialisé (mode preview). Ouvre le panneau Supabase et termine “Project Setup”, puis relance.',
              style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
            ),
          ),
          if (error != null)
            Tooltip(
              message: error.toString(),
              child: Icon(Icons.info_outline, color: cs.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
