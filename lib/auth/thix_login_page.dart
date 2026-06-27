import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class ThixLoginPage extends StatefulWidget {
  const ThixLoginPage({super.key, this.afterLoginRoute});
  final String? afterLoginRoute;

  @override
  State<ThixLoginPage> createState() => _ThixLoginPageState();
}

class _ThixLoginPageState extends State<ThixLoginPage> {
  final TextEditingController _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _email.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien de connexion envoyé. Ouvre ton email pour te connecter.')),
      );
    } catch (e) {
      debugPrint('Login OTP failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur connexion: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'Connexion',
        subtitle: 'THIX ID (Supabase Auth)',
        onMenuTap: () => context.pop(),
        trailing: IconButton(
          onPressed: _loading ? null : () => context.pop(),
          icon: Icon(Icons.close, color: cs.onSurface),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 14, AppSpacing.md, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppRadius.mainCard),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connecte-toi pour utiliser THIX Market', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('On envoie un lien de connexion (magic link) par email. Pas de compte THIX Market séparé.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
                const SizedBox(height: 14),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'ex: nom@domaine.com',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.primaryBlueGradient, borderRadius: BorderRadius.circular(AppRadius.button)),
                    child: TextButton(
                      onPressed: _loading ? null : _sendMagicLink,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.email_outlined, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text('Recevoir le lien de connexion'),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<AuthState>(
            stream: Supabase.instance.client.auth.onAuthStateChange,
            builder: (context, snap) {
              final session = snap.data?.session;
              if (session == null) return const SizedBox.shrink();
              final dest = widget.afterLoginRoute ?? '/market';
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: AppColors.successGreen),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Connecté: ${session.user.email ?? session.user.id}', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                    TextButton(
                      onPressed: () => context.go(dest),
                      style: TextButton.styleFrom(foregroundColor: cs.primary),
                      child: const Text('Continuer'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
