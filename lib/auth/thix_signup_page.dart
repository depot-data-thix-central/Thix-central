import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/auth/widgets/thix_auth_scaffold.dart';
import 'package:thix_central/auth/services/thix_profile_service.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';

class ThixSignUpPage extends StatefulWidget {
  const ThixSignUpPage({super.key});

  @override
  State<ThixSignUpPage> createState() => _ThixSignUpPageState();
}

class _ThixSignUpPageState extends State<ThixSignUpPage> {
  final _profileService = const ThixProfileService();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();

  String _country = 'Côte d\'Ivoire';
  DateTime? _birthDate;

  bool _loading = false;
  bool _showPass = false;
  bool _showPass2 = false;

  String? _nameErr;
  String? _emailErr;
  String? _passErr;
  String? _pass2Err;
  String? _birthErr;

  @override
  void initState() {
    super.initState();
    _fullName.addListener(_validate);
    _email.addListener(_validate);
    _password.addListener(_validate);
    _password2.addListener(_validate);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  bool get _isValid => _nameErr == null && _emailErr == null && _passErr == null && _pass2Err == null && _birthErr == null;

  void _validate() {
    final name = _fullName.text.trim();
    final email = _email.text.trim();
    final pass = _password.text;
    final pass2 = _password2.text;

    String? emailErr;
    if (email.isEmpty) {
      emailErr = 'Email requis';
    } else {
      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
      if (!ok) emailErr = 'Email invalide';
    }

    setState(() {
      _nameErr = name.isEmpty ? 'Nom complet requis' : (name.length < 3 ? 'Nom trop court' : null);
      _emailErr = emailErr;
      _passErr = pass.length < 8 ? 'Minimum 8 caractères' : null;
      _pass2Err = pass2 != pass ? 'Les mots de passe ne correspondent pas' : null;
      _birthErr = _birthDate == null ? 'Date de naissance requise' : null;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked == null) return;
    HapticFeedback.selectionClick();
    setState(() => _birthDate = picked);
    _validate();
  }

  Future<void> _createAccount() async {
    _validate();
    if (!_isValid) return;
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supabase non initialisé. Termine Project Setup.')));
      return;
    }

    setState(() => _loading = true);
    try {
      HapticFeedback.lightImpact();
      final email = _email.text.trim();
      final pass = _password.text;
      final fullName = _fullName.text.trim();

      final res = await client.auth.signUp(
        email: email,
        password: pass,
        data: {
          'full_name': fullName,
          'country': _country,
          if (_birthDate != null) 'birth_date': _birthDate!.toIso8601String(),
        },
      );

      if (res.user == null) throw AuthException('Inscription échouée: utilisateur non créé');

      // Best-effort: populate public.users table when available.
      await _profileService.ensureMyUserRow(
        email: email,
        fullName: fullName,
        country: _country,
        birthDate: _birthDate,
      );

      // Send email OTP for verification.
      await client.auth.signInWithOtp(email: email, shouldCreateUser: false);

      if (!mounted) return;
      context.push(
        '/auth/verify?email=${Uri.encodeComponent(email)}',
        extra: {
          'display_name': fullName,
          'country': _country,
          'birth_date': _birthDate,
        },
      );
    } catch (e) {
      debugPrint('Sign up failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ThixAuthScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 20, AppSpacing.md, 28),
        children: [
          const SizedBox(height: 10),
          Text('THIX ID', style: context.textStyles.titleLarge?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          Text('Create your secure digital identity', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.72), height: 1.35)),
          const SizedBox(height: 18),
          ThixGlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create account', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                  controller: _fullName,
                  textCapitalization: TextCapitalization.words,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(labelText: 'Nom complet', errorText: _nameErr),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(labelText: 'Adresse email', errorText: _emailErr),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _password,
                  obscureText: !_showPass,
                  autofillHints: const [AutofillHints.newPassword],
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
                TextField(
                  controller: _password2,
                  obscureText: !_showPass2,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Confirmation mot de passe',
                    errorText: _pass2Err,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _showPass2 = !_showPass2),
                      icon: Icon(_showPass2 ? Icons.visibility_off : Icons.visibility, color: cs.onSurface.withValues(alpha: 0.75), size: 18),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _country,
                  items: const [
                    DropdownMenuItem(value: 'Côte d\'Ivoire', child: Text('Côte d\'Ivoire')),
                    DropdownMenuItem(value: 'Sénégal', child: Text('Sénégal')),
                    DropdownMenuItem(value: 'Cameroun', child: Text('Cameroun')),
                    DropdownMenuItem(value: 'France', child: Text('France')),
                    DropdownMenuItem(value: 'Canada', child: Text('Canada')),
                    DropdownMenuItem(value: 'États-Unis', child: Text('États-Unis')),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) {
                          if (v == null) return;
                          HapticFeedback.selectionClick();
                          setState(() => _country = v);
                        },
                  decoration: const InputDecoration(labelText: 'Pays'),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _loading ? null : _pickBirthDate,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date de naissance',
                      errorText: _birthErr,
                      suffixIcon: Icon(Icons.calendar_month, color: cs.onSurface.withValues(alpha: 0.72), size: 18),
                    ),
                    child: Text(
                      _birthDate == null
                          ? 'Choisir une date'
                          : '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}',
                      style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurface),
                    ),
                  ),
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
                      onPressed: _loading ? null : _createAccount,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                      ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_user, color: Colors.black, size: 18),
                                SizedBox(width: 10),
                                Text('Créer mon identité'),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SocialButtons(loading: _loading),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: TextButton(
              onPressed: _loading ? null : () => context.push('/auth/login'),
              style: TextButton.styleFrom(foregroundColor: cs.onSurface.withValues(alpha: 0.82)).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
              child: const Text('Déjà un compte ? Se connecter'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButtons extends StatelessWidget {
  const _SocialButtons({required this.loading});
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: loading ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Sign-In: à brancher dans Supabase Auth Providers.'))),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(color: cs.outline.withValues(alpha: 0.30)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.g_mobiledata, size: 26),
                SizedBox(width: 8),
                Text('Continuer avec Google'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: loading ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apple Sign-In: à activer dans Supabase Auth Providers.'))),
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.onSurface,
              side: BorderSide(color: cs.outline.withValues(alpha: 0.30)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
            ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, size: 18),
                SizedBox(width: 10),
                Text('Continuer avec Apple'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
