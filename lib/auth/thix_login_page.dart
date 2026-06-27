import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/auth/services/thix_profile_service.dart';
import 'package:thix_central/auth/widgets/thix_auth_scaffold.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';

class ThixLoginPage extends StatefulWidget {
  const ThixLoginPage({super.key, this.afterLoginRoute});
  final String? afterLoginRoute;

  @override
  State<ThixLoginPage> createState() => _ThixLoginPageState();
}

class _ThixLoginPageState extends State<ThixLoginPage> {
  final _profileService = const ThixProfileService();
  final _auth = LocalAuthentication();

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _remember = true;
  bool _showPass = false;
  bool _biometricAvailable = false;

  String? _emailErr;
  String? _passErr;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _checkBiometric();
    _email.addListener(_validate);
    _password.addListener(_validate);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('thix_last_email');
      final remember = prefs.getBool('thix_remember_email') ?? true;
      if (!mounted) return;
      setState(() {
        _remember = remember;
        if (saved != null && saved.isNotEmpty) _email.text = saved;
      });
    } catch (e) {
      debugPrint('loadPrefs failed: $e');
    }
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('thix_remember_email', _remember);
      if (_remember) {
        await prefs.setString('thix_last_email', _email.text.trim());
      } else {
        await prefs.remove('thix_last_email');
      }
    } catch (e) {
      debugPrint('savePrefs failed: $e');
    }
  }

  Future<void> _checkBiometric() async {
    if (kIsWeb) return;
    try {
      final can = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      if (!mounted) return;
      setState(() => _biometricAvailable = can && supported);
    } catch (e) {
      debugPrint('biometric check failed: $e');
    }
  }

  void _validate() {
    final email = _email.text.trim();
    final pass = _password.text;
    String? emailErr;
    if (email.isEmpty) {
      emailErr = 'Email requis';
    } else {
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
      if (!ok) emailErr = 'Email invalide';
    }
    setState(() {
      _emailErr = emailErr;
      _passErr = pass.isEmpty ? 'Mot de passe requis' : null;
    });
  }

  Future<void> _login() async {
    _validate();
    if (_emailErr != null || _passErr != null) return;
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supabase non initialisé. Termine Project Setup.')));
      return;
    }

    setState(() => _loading = true);
    try {
      HapticFeedback.lightImpact();
      await _savePrefs();
      final email = _email.text.trim();
      final pass = _password.text;

      await client.auth.signInWithPassword(email: email, password: pass);

      // Ensure profile exists for THIX ID features.
      await _profileService.ensureMyProfile();

      if (!mounted) return;
      final dest = widget.afterLoginRoute ?? '/';
      context.go(dest);
    } catch (e) {
      debugPrint('Login failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur connexion: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final client = SupabaseClientProvider.clientOrNull;
    final email = _email.text.trim();
    if (client == null || email.isEmpty) return;
    try {
      HapticFeedback.selectionClick();
      await client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email de réinitialisation envoyé.')));
    } catch (e) {
      debugPrint('resetPasswordForEmail failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _unlockWithBiometrics() async {
    if (!_biometricAvailable) return;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock your THIX ID',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!ok || !mounted) return;
      HapticFeedback.lightImpact();

      // If a session already exists (persisted), just continue.
      final session = SupabaseClientProvider.clientOrNull?.auth.currentSession;
      if (session != null) {
        final dest = widget.afterLoginRoute ?? '/';
        context.go(dest);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connecte-toi une première fois pour activer la connexion biométrique.')),
      );
    } catch (e) {
      debugPrint('biometric auth failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biométrie indisponible.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ThixAuthScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 20, AppSpacing.md, 28),
        children: [
          Text('Welcome Back', style: context.textStyles.titleLarge?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Access your secure digital identity', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35)),
          const SizedBox(height: 18),
          ThixGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Login', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: 'Email', errorText: _emailErr),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _password,
                  obscureText: !_showPass,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    errorText: _passErr,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showPass = !_showPass),
                      icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, color: cs.onSurface.withValues(alpha: 0.75), size: 18),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      onTap: _loading
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              setState(() => _remember = !_remember);
                              _savePrefs();
                            },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_remember ? Icons.check_circle : Icons.circle_outlined, size: 18, color: _remember ? AppColors.thixCyanGlow : cs.onSurface.withValues(alpha: 0.55)),
                            const SizedBox(width: 8),
                            Text('Remember me', style: context.textStyles.labelLarge?.copyWith(color: cs.onSurface.withValues(alpha: 0.84))),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _loading ? null : _forgotPassword,
                      style: TextButton.styleFrom(foregroundColor: cs.onSurface.withValues(alpha: 0.82)).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.thixIdCyanGradient,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      boxShadow: [BoxShadow(color: AppColors.thixCyanGlow.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
                    ),
                    child: TextButton(
                      onPressed: _loading ? null : _login,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.lock_open, color: Colors.black, size: 18), SizedBox(width: 10), Text('Connexion sécurisée')],
                            ),
                    ),
                  ),
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _loading ? null : _unlockWithBiometrics,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.onSurface,
                        side: BorderSide(color: cs.outline.withValues(alpha: 0.30)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.fingerprint, size: 20), SizedBox(width: 10), Text('Connexion biométrique')],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _loading ? null : () => context.push('/auth/signup'),
              style: TextButton.styleFrom(foregroundColor: cs.onSurface.withValues(alpha: 0.82)).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
              child: const Text('Nouveau ? Créer mon identité'),
            ),
          ),
        ],
      ),
    );
  }
}
