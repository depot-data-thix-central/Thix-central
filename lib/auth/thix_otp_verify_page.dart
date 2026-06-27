import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/auth/services/thix_profile_service.dart';
import 'package:thix_central/auth/widgets/thix_auth_scaffold.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';

class ThixOtpVerifyPage extends StatefulWidget {
  const ThixOtpVerifyPage({super.key, required this.email, this.pendingProfile});
  final String? email;
  final Map<String, dynamic>? pendingProfile;

  @override
  State<ThixOtpVerifyPage> createState() => _ThixOtpVerifyPageState();
}

class _ThixOtpVerifyPageState extends State<ThixOtpVerifyPage> {
  final _profileService = const ThixProfileService();
  final _code = TextEditingController();
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    final client = SupabaseClientProvider.clientOrNull;
    final email = widget.email?.trim();
    if (client == null || email == null || email.isEmpty) return;
    try {
      HapticFeedback.selectionClick();
      await client.auth.signInWithOtp(email: email, shouldCreateUser: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code renvoyé.')));
    } catch (e) {
      debugPrint('Resend OTP failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _verify() async {
    final client = SupabaseClientProvider.clientOrNull;
    final email = widget.email?.trim();
    if (client == null) {
      setState(() => _err = 'Supabase non initialisé');
      return;
    }
    if (email == null || email.isEmpty) {
      setState(() => _err = 'Email manquant');
      return;
    }

    final token = _code.text.trim();
    if (token.length < 6) {
      setState(() => _err = 'Code invalide');
      return;
    }

    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      HapticFeedback.lightImpact();
      await client.auth.verifyOTP(type: OtpType.email, email: email, token: token);

      // Now authenticated: upsert profile (and generate THIX ID) if needed.
      final pending = widget.pendingProfile;
      final dynamic birthRaw = pending == null ? null : pending['birth_date'];
      final DateTime? birthDate = birthRaw is DateTime ? birthRaw : null;
      await _profileService.ensureMyProfile(
        displayName: pending?['display_name'] as String?,
        country: pending?['country'] as String?,
        birthDate: birthDate,
      );
      await SupabaseClientProvider.client.from('profiles').upsert({'user_id': SupabaseClientProvider.client.auth.currentUser!.id, 'email_verified': true});

      if (!mounted) return;
      context.go('/thix-id/card');
    } catch (e) {
      debugPrint('Verify OTP failed: $e');
      if (!mounted) return;
      setState(() => _err = 'Code incorrect ou expiré');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final email = widget.email ?? '';
    return ThixAuthScaffold(
      showBack: true,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 18, AppSpacing.md, 28),
        children: [
          Text('Verify email', style: context.textStyles.titleLarge?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('We sent a secure code to $email', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35)),
          const SizedBox(height: 16),
          ThixGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter OTP', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  decoration: InputDecoration(
                    labelText: 'Code (6 chiffres)',
                    errorText: _err,
                    hintText: '123456',
                  ),
                  onChanged: (_) {
                    if (_err != null) setState(() => _err = null);
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.thixIdCyanGradient,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: [BoxShadow(color: AppColors.thixCyanGlow.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: TextButton(
                      onPressed: _loading ? null : _verify,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shield, size: 18, color: Colors.black),
                                SizedBox(width: 10),
                                Text('Vérifier'),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: _loading ? null : _resend,
                    style: TextButton.styleFrom(foregroundColor: cs.onSurface.withValues(alpha: 0.82)).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                    child: const Text('Renvoyer le code'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
