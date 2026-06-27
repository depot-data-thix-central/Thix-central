import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/auth/services/thix_profile_service.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileService = const ThixProfileService();

  Future<void> _logout() async {
    try {
      final client = SupabaseClientProvider.clientOrNull;
      if (client == null) {
        debugPrint('Logout ignored: Supabase not initialized');
        return;
      }
      await client.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Déconnecté')));
      setState(() {});
    } catch (e) {
      debugPrint('Logout failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = SupabaseClientProvider.clientOrNull?.auth.currentUser;
    final display = user?.email ?? (user == null ? 'Invité' : user.id);
    return Scaffold(
      appBar: ThixTopBar(
        title: 'Profil',
        subtitle: 'Identité vérifiée',
        onMenuTap: () {},
        trailing: IconButton(
          onPressed: () {},
          icon: Icon(Icons.settings_outlined, color: cs.onSurface),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileService.getMyProfile(),
        builder: (context, snap) {
          final p = snap.data;
          final thixId = user == null ? 'Non connecté' : ((p?['thix_id'] as String?) ?? 'THIX-PENDING');
          final verified = user != null && (user.emailConfirmedAt != null || p?['email_verified'] == true);

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.circular(AppRadius.search)),
                child: Row(
                  children: [
                    ThixAvatar(size: 58, initials: display.isEmpty ? 'T' : display.characters.first.toUpperCase()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(display, style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('THIX ID: $thixId', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.88))),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(verified ? Icons.verified : Icons.schedule, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(user == null ? 'Non connecté' : (verified ? 'Verified' : 'Pending'), style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 14),
          _StatRow(),
          const SizedBox(height: 14),
          _InfoCard(
            title: 'Identité Vérifiée',
            body:
                'Ce profil a été vérifié par THIX ID. Les informations publiques ci-dessous ont été vérifiées et sont authentiques.',
            icon: Icons.shield,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.qr_code_2,
            title: 'Afficher mon QR',
            subtitle: 'Partager votre THIX PASS',
            onTap: () {
              if (user == null) {
                context.push('/auth/login?next=/thix-id/card');
              } else {
                context.push('/thix-id/card');
              }
            },
          ),
          _ActionTile(icon: Icons.badge_outlined, title: 'Mon statut', subtitle: 'Niveau, score, notifications'),
          _ActionTile(icon: Icons.folder_copy_outlined, title: 'Documents', subtitle: 'Pièces & attestations'),
          _ActionTile(
            icon: Icons.logout,
            title: 'Déconnexion',
            subtitle: 'Quitter votre session THIX ID',
            onTap: _logout,
            iconColor: cs.error,
          ),
            ],
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(
        children: const [
          Expanded(child: _StatItem(label: 'Diplômes', value: '0', icon: Icons.school_outlined)),
          Expanded(child: _StatItem(label: 'Certifications', value: '0', icon: Icons.workspace_premium_outlined)),
          Expanded(child: _StatItem(label: 'Expériences', value: '0', icon: Icons.work_outline)),
          Expanded(child: _StatItem(label: 'Consultations', value: '0', icon: Icons.chat_bubble_outline)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: cs.primary, size: 20),
        const SizedBox(height: 6),
        Text(value, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body, required this.icon});
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(body, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, this.onTap, this.iconColor});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.serviceCard),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: iconColor ?? cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
