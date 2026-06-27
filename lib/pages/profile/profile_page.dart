import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/auth/services/thix_profile_service.dart';
import 'package:thix_central/health/thix_role_controller.dart';
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
  final _roleController = ThixRoleController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roleController.syncFromEmail(SupabaseClientProvider.clientOrNull?.auth.currentUser?.email);
    });
  }

  Future<void> _logout() async {
    try {
      final client = SupabaseClientProvider.clientOrNull;
      if (client == null) {
        debugPrint('Logout ignored: Supabase not initialized');
        return;
      }
      await client.auth.signOut();
      if (!mounted) return;
      _roleController.selectRole(ThixRole.patient, manual: false);
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
    final display = user?.email ?? (user == null ? 'Invité THIX Santé' : user.id);
    final email = user?.email;

    return AnimatedBuilder(
      animation: _roleController,
      builder: (context, _) {
        final role = _roleController.role;
        return Scaffold(
          appBar: ThixTopBar(
            title: 'Profil',
            subtitle: 'Compte ${role.label.toLowerCase()}',
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
                    decoration: BoxDecoration(gradient: role.gradient, borderRadius: BorderRadius.circular(AppRadius.search)),
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
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _Capsule(
                                    icon: verified ? Icons.verified : Icons.schedule,
                                    label: user == null ? 'Non connecté' : (verified ? 'Vérifié' : 'En attente'),
                                  ),
                                  _Capsule(icon: role.icon, label: role.label),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Bascule de rôle',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Détection automatique via ${role.domainHint}, avec possibilité de basculer manuellement entre Patient, Médecin et Pharmacie.',
                          style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              for (final option in _roleController.availableRoles)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: InkWell(
                                      onTap: () => _roleController.selectRole(option),
                                      borderRadius: BorderRadius.circular(16),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: role == option ? option.gradient : null,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(option.icon, size: 18, color: role == option ? Colors.white : option.accent),
                                            const SizedBox(height: 6),
                                            Text(
                                              option.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: context.textStyles.labelSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: role == option ? Colors.white : AppColors.darkNavy,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: email == null ? null : () => _roleController.resetToDetectedRole(email),
                              icon: const Icon(Icons.sync_rounded),
                              label: const Text('Revenir au rôle détecté'),
                            ),
                            if (email != null)
                              Text(
                                'Email actif : $email',
                                style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _StatRow(role: role),
                  const SizedBox(height: 14),
                  const _SectionCard(
                    title: 'Sécurité & conformité',
                    child: _InfoCard(
                      title: 'Identité vérifiée',
                      body: 'Votre compte THIX Santé centralise identité, rôle actif, consentement et partage sécurisé des parcours de soins.',
                      icon: Icons.shield,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionTile(
                    icon: Icons.qr_code_2,
                    title: 'Afficher mon QR',
                    subtitle: 'Partager votre THIX PASS ou badge rôle actif',
                    onTap: () {
                      if (user == null) {
                        context.push('/auth/login?next=/thix-id/card');
                      } else {
                        context.push('/thix-id/card');
                      }
                    },
                  ),
                  _ActionTile(icon: Icons.notifications_active_rounded, title: 'Notifications', subtitle: 'Push, email, SMS et rappels santé'),
                  _ActionTile(icon: Icons.folder_copy_outlined, title: 'Documents', subtitle: 'Pièces, dossiers et attestations sécurisées'),
                  _ActionTile(icon: Icons.family_restroom_rounded, title: 'Espace famille', subtitle: 'Ajoutez proches, enfants et aidants'),
                  _ActionTile(
                    icon: Icons.logout,
                    title: 'Déconnexion',
                    subtitle: 'Quitter votre session THIX Santé',
                    onTap: _logout,
                    iconColor: cs.error,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(label, style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.role});

  final ThixRole role;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stats = switch (role) {
      ThixRole.patient => const [
          _StatData(label: 'Symptômes', value: '4', icon: Icons.monitor_heart_outlined),
          _StatData(label: 'Traitements', value: '3', icon: Icons.medication_outlined),
          _StatData(label: 'RDV', value: '2', icon: Icons.calendar_today_outlined),
          _StatData(label: 'Messages', value: '6', icon: Icons.chat_bubble_outline),
        ],
      ThixRole.doctor => const [
          _StatData(label: 'Patients', value: '84', icon: Icons.groups_outlined),
          _StatData(label: 'Consult.', value: '16', icon: Icons.health_and_safety_outlined),
          _StatData(label: 'Alertes', value: '5', icon: Icons.warning_amber_outlined),
          _StatData(label: 'Notes', value: '9', icon: Icons.note_alt_outlined),
        ],
      ThixRole.pharmacy => const [
          _StatData(label: 'Commandes', value: '21', icon: Icons.receipt_long_outlined),
          _StatData(label: 'Stock', value: '9', icon: Icons.inventory_2_outlined),
          _StatData(label: 'Livraisons', value: '7', icon: Icons.local_shipping_outlined),
          _StatData(label: 'Messages', value: '4', icon: Icons.chat_bubble_outline),
        ],
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(
        children: stats.map((item) => Expanded(child: _StatItem(label: item.label, value: item.value, icon: item.icon))).toList(),
      ),
    );
  }
}

class _StatData {
  const _StatData({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;
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
    return Row(
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
