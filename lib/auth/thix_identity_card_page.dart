import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:thix_central/auth/services/thix_profile_service.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';

class ThixIdentityCardPage extends StatefulWidget {
  const ThixIdentityCardPage({super.key});

  @override
  State<ThixIdentityCardPage> createState() => _ThixIdentityCardPageState();
}

class _ThixIdentityCardPageState extends State<ThixIdentityCardPage> {
  final _profileService = const ThixProfileService();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final client = SupabaseClientProvider.clientOrNull;
    final user = client?.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('THIX ID', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            icon: Icon(Icons.close, color: cs.onSurface),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 12, AppSpacing.md, 24),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _profileService.getMyProfile(),
          builder: (context, snap) {
            if (user == null) {
              return _EmptyIdentity(
                title: 'Non connecté',
                subtitle: 'Connecte-toi pour générer ton THIX ID.',
                actionLabel: 'Connexion',
                onAction: () => context.push('/auth/login?next=/thix-id/card'),
              );
            }
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final p = snap.data;
            final displayName = (p?['display_name'] as String?) ?? (user.email ?? 'User');
            final thixId = (p?['thix_id'] as String?) ?? 'THIX-PENDING';
            final email = user.email ?? '—';
            final verified = (user.emailConfirmedAt != null) || (p?['email_verified'] == true);
            final qrPayload = 'THIX_ID:$thixId|EMAIL:$email|UID:${user.id}';

            return Column(
              children: [
                _IdentityCard(
                  displayName: displayName,
                  thixId: thixId,
                  email: email,
                  verified: verified,
                  qrData: qrPayload,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Clipboard.setData(ClipboardData(text: thixId));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('THIX ID copié')));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          side: BorderSide(color: cs.outline.withValues(alpha: 0.25)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                          minimumSize: const Size(0, 48),
                        ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Icon(Icons.copy, size: 18), SizedBox(width: 10), Text('Copier')],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryBlueGradient,
                            borderRadius: BorderRadius.circular(AppRadius.button),
                          ),
                          child: TextButton(
                            onPressed: () => context.go('/'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                            ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [Icon(Icons.home, color: Colors.white, size: 18), SizedBox(width: 10), Text('Continuer')],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.displayName, required this.thixId, required this.email, required this.verified, required this.qrData});
  final String displayName;
  final String thixId;
  final String email;
  final bool verified;
  final String qrData;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.promoGradient,
        borderRadius: BorderRadius.circular(AppRadius.mainCard),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 26, offset: const Offset(0, 14))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.thixIdCyanGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.fingerprint, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(thixId, style: context.textStyles.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(verified ? Icons.verified : Icons.schedule, color: verified ? AppColors.successGreen : Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(verified ? 'Verified' : 'Pending', style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: Colors.white.withValues(alpha: 0.12))),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(email, style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.88)))),
                Icon(verified ? Icons.lock : Icons.lock_open, color: Colors.white.withValues(alpha: 0.9), size: 18),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.qrContainer)),
            child: QrImageView(
              data: qrData,
              size: 168,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),
          const SizedBox(height: 10),
          Text('Scan this QR to verify identity', style: context.textStyles.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.78))),
        ],
      ),
    );
  }
}

class _EmptyIdentity extends StatelessWidget {
  const _EmptyIdentity({required this.title, required this.subtitle, required this.actionLabel, required this.onAction});
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.16))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint, size: 42, color: cs.primary),
            const SizedBox(height: 10),
            Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.primaryBlueGradient, borderRadius: BorderRadius.circular(AppRadius.button)),
                child: TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button))).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                  child: Text(actionLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
