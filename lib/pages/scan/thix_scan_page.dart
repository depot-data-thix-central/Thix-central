import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class ThixScanPage extends StatelessWidget {
  const ThixScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX ID',
        subtitle: 'Scanner • NFC • Vérification',
        onMenuTap: () {},
        trailing: IconButton(
          onPressed: () {},
          icon: Icon(Icons.help_outline, color: cs.onSurface),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.headerGradient,
                borderRadius: BorderRadius.circular(AppRadius.search),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vérifier une identité', style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Scannez un QR code ou utilisez la NFC pour confirmer une THIX ID.', style: context.textStyles.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.88), height: 1.3)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            debugPrint('QR Scan tapped (placeholder)');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: cs.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scanner QR'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            debugPrint('NFC tapped (placeholder)');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.16),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ).copyWith(overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
                          icon: const Icon(Icons.nfc),
                          label: const Text('NFC'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
                          child: Icon(Icons.shield, color: cs.onPrimaryContainer),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Résultat de vérification', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Aucun scan pour le moment.', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 10),
                    Text(
                      'Quand tu connecteras un backend (Firebase/Supabase), on pourra enregistrer les scans, gérer les profils, et afficher le statut “Identité Vérifiée”.',
                      style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: cs.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Backend non connecté. Ouvre le panneau Firebase ou Supabase dans Dreamflow pour activer l’auth et la base de données.',
                              style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
