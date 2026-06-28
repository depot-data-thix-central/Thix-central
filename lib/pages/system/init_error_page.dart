import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/nav.dart';
import 'package:thix_central/theme.dart';

class InitErrorPage extends StatefulWidget {
  const InitErrorPage({super.key});

  @override
  State<InitErrorPage> createState() => _InitErrorPageState();
}

class _InitErrorPageState extends State<InitErrorPage> {
  bool _isRetrying = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final err = SupabaseClientProvider.initError;
    if (err != null) _message = err.toString();
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _message = null;
    });
    try {
      SupabaseClientProvider.resetForRetry();
      final ok = await SupabaseClientProvider.initializeFromEnv().timeout(const Duration(seconds: 8));
      if (!mounted) return;
      if (ok) {
        final session = SupabaseClientProvider.clientOrNull?.auth.currentSession;
        context.go(session == null ? AppRoutes.login : AppRoutes.home);
      } else {
        setState(() => _message = (SupabaseClientProvider.initError ?? 'Supabase init failed').toString());
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _message = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.lightGrayBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Connexion indisponible'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.10)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_off_rounded, color: cs.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Supabase ne répond pas', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(
                            'Impossible d\'initialiser la connexion. Vous pouvez réessayer, ou continuer vers le login (mode dégradé).',
                            style: context.textStyles.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_message != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _message!,
                    style: context.textStyles.bodySmall?.copyWith(color: cs.onErrorContainer, height: 1.35),
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isRetrying ? null : () => context.go(AppRoutes.login),
                      icon: Icon(Icons.login_rounded, color: cs.primary),
                      label: Text('Aller au login', style: TextStyle(color: cs.primary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: cs.primary.withValues(alpha: 0.35)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isRetrying ? null : _retry,
                      icon: _isRetrying
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: cs.onPrimary),
                            )
                          : Icon(Icons.refresh_rounded, color: cs.onPrimary),
                      label: Text(_isRetrying ? 'Connexion…' : 'Réessayer', style: TextStyle(color: cs.onPrimary)),
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
