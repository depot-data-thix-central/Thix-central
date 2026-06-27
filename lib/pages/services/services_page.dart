import 'package:flutter/material.dart';
import 'package:thix_central/health/thix_role_controller.dart';
import 'package:thix_central/health/thix_ui_feedback.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final _roleController = ThixRoleController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _roleController.syncFromEmail(SupabaseClientProvider.clientOrNull?.auth.currentUser?.email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _roleController,
      builder: (context, _) {
        final role = _roleController.role;
        final modules = _serviceModules(role);
        final capabilities = _serviceCapabilities(role);
        return Scaffold(
          appBar: ThixTopBar(
            title: 'THIX Santé',
            subtitle: 'Modules métier par rôle',
            onMenuTap: () {},
            trailing: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search_rounded, color: AppColors.darkNavy),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: role.gradient,
                  borderRadius: BorderRadius.circular(AppRadius.mainCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expérience ${role.label.toLowerCase()}', style: context.textStyles.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(role.headline, style: context.textStyles.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(role.subtitle, style: context.textStyles.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.90), height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _RoleSelector(controller: _roleController),
              const SizedBox(height: 18),
              _BlockTitle(title: 'Modules principaux', subtitle: 'Accès rapide au parcours ${role.label.toLowerCase()}'),
              const SizedBox(height: 10),
              ...modules.map((item) => _ServiceTile(item: item)),
              const SizedBox(height: 18),
              _BlockTitle(title: 'Capacités incluses', subtitle: 'Fonctionnalités prêtes pour le rôle ${role.label.toLowerCase()}'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: capabilities
                    .map(
                      (capability) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: capability.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(capability.icon, size: 18, color: capability.color),
                            const SizedBox(width: 8),
                            Text(capability.title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.controller});

  final ThixRoleController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          for (final role in controller.availableRoles)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => controller.selectRole(role),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: controller.role == role ? role.gradient : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(role.icon, size: 18, color: controller.role == role ? Colors.white : role.accent),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            role.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: controller.role == role ? Colors.white : AppColors.darkNavy,
                            ),
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
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.item});

  final _ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => showThixFeatureReadySnackBar(context, item.title),
        borderRadius: BorderRadius.circular(AppRadius.serviceCard),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.serviceCard),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(item.subtitle, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: item.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem({required this.title, required this.subtitle, required this.icon, required this.color});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

List<_ServiceItem> _serviceModules(ThixRole role) {
  switch (role) {
    case ThixRole.patient:
      return const [
        _ServiceItem(title: 'Suivi santé', subtitle: 'Symptômes, constantes, traitements et alertes locales', icon: Icons.monitor_heart_rounded, color: Color(0xFF2453FF)),
        _ServiceItem(title: 'Rendez-vous', subtitle: 'Prise, annulation, report et téléconsultation Jitsi', icon: Icons.calendar_month_rounded, color: Color(0xFF10B981)),
        _ServiceItem(title: 'Dossier médical', subtitle: 'Documents, examens, ordonnances et partage sécurisé', icon: Icons.folder_shared_rounded, color: Color(0xFF7C3AED)),
        _ServiceItem(title: 'Messages', subtitle: 'Médecins, pharmacie, assistant IA et notifications', icon: Icons.chat_bubble_rounded, color: Color(0xFFFF6B00)),
      ];
    case ThixRole.doctor:
      return const [
        _ServiceItem(title: 'Dashboard clinique', subtitle: 'KPIs, alertes patients à risque et consultations à venir', icon: Icons.dashboard_rounded, color: Color(0xFF2453FF)),
        _ServiceItem(title: 'Patients', subtitle: 'Recherche, résumé clinique, constantes et notes médicales', icon: Icons.groups_rounded, color: Color(0xFF10B981)),
        _ServiceItem(title: 'Prescriptions', subtitle: 'Création, aperçu et envoi sécurisé patient/pharmacie', icon: Icons.description_rounded, color: Color(0xFF7C3AED)),
        _ServiceItem(title: 'Téléexpertise', subtitle: 'Demande d’avis, téléconsultation et agenda mensuel', icon: Icons.video_call_rounded, color: Color(0xFFFF6B00)),
      ];
    case ThixRole.pharmacy:
      return const [
        _ServiceItem(title: 'Ordonnances', subtitle: 'Validation, acceptation et rejet avec détail patient', icon: Icons.fact_check_rounded, color: Color(0xFF2453FF)),
        _ServiceItem(title: 'Inventaire', subtitle: 'Quantités, seuils, lots et alertes de stock bas', icon: Icons.inventory_2_rounded, color: Color(0xFF10B981)),
        _ServiceItem(title: 'Dispensation', subtitle: 'Attribution des médicaments et suivi des commandes', icon: Icons.medication_rounded, color: Color(0xFF7C3AED)),
        _ServiceItem(title: 'Rapports', subtitle: 'Commandes, médicaments prescrits et chiffre d’affaires', icon: Icons.analytics_rounded, color: Color(0xFFFF6B00)),
      ];
  }
}

List<_ServiceItem> _serviceCapabilities(ThixRole role) {
  switch (role) {
    case ThixRole.patient:
      return const [
        _ServiceItem(title: 'Notifications', subtitle: '', icon: Icons.notifications_active_rounded, color: Color(0xFF2453FF)),
        _ServiceItem(title: 'Partage dossier', subtitle: '', icon: Icons.share_rounded, color: Color(0xFF10B981)),
        _ServiceItem(title: 'Consentement', subtitle: '', icon: Icons.verified_user_rounded, color: Color(0xFF7C3AED)),
        _ServiceItem(title: 'Espace famille', subtitle: '', icon: Icons.family_restroom_rounded, color: Color(0xFFFF6B00)),
      ];
    case ThixRole.doctor:
      return const [
        _ServiceItem(title: 'Téléconsultation', subtitle: '', icon: Icons.video_camera_front_rounded, color: Color(0xFF2453FF)),
        _ServiceItem(title: 'Dictée vocale', subtitle: '', icon: Icons.mic_rounded, color: Color(0xFF10B981)),
        _ServiceItem(title: 'Mode hors-ligne', subtitle: '', icon: Icons.cloud_off_rounded, color: Color(0xFF7C3AED)),
        _ServiceItem(title: 'Analytics', subtitle: '', icon: Icons.bar_chart_rounded, color: Color(0xFFFF6B00)),
      ];
    case ThixRole.pharmacy:
      return const [
        _ServiceItem(title: 'Livraisons', subtitle: '', icon: Icons.local_shipping_rounded, color: Color(0xFF2453FF)),
        _ServiceItem(title: 'Messagerie', subtitle: '', icon: Icons.chat_bubble_rounded, color: Color(0xFF10B981)),
        _ServiceItem(title: 'Réassort', subtitle: '', icon: Icons.add_business_rounded, color: Color(0xFF7C3AED)),
        _ServiceItem(title: 'Traçabilité', subtitle: '', icon: Icons.qr_code_rounded, color: Color(0xFFFF6B00)),
      ];
  }
}
