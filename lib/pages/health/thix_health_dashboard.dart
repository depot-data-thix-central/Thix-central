import 'package:flutter/material.dart';
import 'package:thix_central/health/thix_role_controller.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/theme.dart';

class ThixHealthDashboardPage extends StatefulWidget {
  const ThixHealthDashboardPage({super.key});

  @override
  State<ThixHealthDashboardPage> createState() => _ThixHealthDashboardPageState();
}

class _ThixHealthDashboardPageState extends State<ThixHealthDashboardPage> {
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
        final email = SupabaseClientProvider.clientOrNull?.auth.currentUser?.email;
        final greetingName = _displayNameFromEmail(email, role);
        return Scaffold(
          backgroundColor: AppColors.lightGrayBackground,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardTopBar(greetingName: greetingName, role: role),
                        const SizedBox(height: 18),
                        _RoleSwitcher(controller: _roleController),
                        const SizedBox(height: 16),
                        _HeroBanner(role: role, greetingName: greetingName),
                        const SizedBox(height: 18),
                        _QuickAccessRow(role: role),
                        const SizedBox(height: 20),
                        _RoleSummary(role: role),
                        const SizedBox(height: 20),
                        _RoleModules(role: role),
                        const SizedBox(height: 20),
                        _RoleHighlights(role: role),
                        const SizedBox(height: 20),
                        _ArticlesOrAlerts(role: role),
                        const SizedBox(height: 20),
                        _BottomAction(role: role),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _displayNameFromEmail(String? email, ThixRole role) {
  final localPart = email?.split('@').first.trim();
  if (localPart != null && localPart.isNotEmpty) {
    final pieces = localPart.split(RegExp(r'[._-]+')).where((part) => part.isNotEmpty).toList();
    if (pieces.isNotEmpty) {
      return pieces.first[0].toUpperCase() + pieces.first.substring(1);
    }
  }
  switch (role) {
    case ThixRole.patient:
      return 'Michel';
    case ThixRole.doctor:
      return 'Dr. Nadia';
    case ThixRole.pharmacy:
      return 'Pharmacie Centrale';
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({required this.greetingName, required this.role});

  final String greetingName;
  final ThixRole role;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [AppShadows.secondary],
          ),
          child: const Icon(Icons.menu_rounded, color: AppColors.darkNavy),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: role.gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THIX SANTÉ',
                      style: context.textStyles.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: AppColors.darkNavy,
                      ),
                    ),
                    Text(
                      'Votre santé, notre priorité.',
                      style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _RoundIconBadge(icon: Icons.notifications_none_rounded, badge: '3'),
        const SizedBox(width: 10),
        _AvatarBadge(name: greetingName),
      ],
    );
  }
}

class _RoleSwitcher extends StatelessWidget {
  const _RoleSwitcher({required this.controller});

  final ThixRoleController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          for (final role in controller.availableRoles)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _RoleChip(
                  role: role,
                  selected: controller.role == role,
                  onTap: () => controller.selectRole(role),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role, required this.selected, required this.onTap});

  final ThixRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected ? role.gradient : null,
          color: selected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(role.icon, size: 18, color: selected ? Colors.white : role.accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                role.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.labelLarge?.copyWith(
                  color: selected ? Colors.white : AppColors.darkNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.role, required this.greetingName});

  final ThixRole role;
  final String greetingName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: role.gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [AppShadows.main],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $greetingName 👋',
                  style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  role.headline,
                  style: context.textStyles.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  role.subtitle,
                  style: context.textStyles.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92), height: 1.35),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: () => _showInfo(context, role.ctaLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: role.accent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(role.ctaLabel, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HeroIllustration(role: role),
        ],
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.role});

  final ThixRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 16,
            child: Icon(role.icon, size: 42, color: Colors.white.withValues(alpha: 0.95)),
          ),
          Positioned(
            bottom: 14,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Icon(
                    role == ThixRole.patient
                        ? Icons.health_and_safety_rounded
                        : role == ThixRole.doctor
                            ? Icons.monitor_heart_rounded
                            : Icons.inventory_2_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    role.shortLabel,
                    style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  const _QuickAccessRow({required this.role});

  final ThixRole role;

  @override
  Widget build(BuildContext context) {
    final items = _quickItemsFor(role);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: _QuickItem(
                item: items[index],
                showDivider: index < items.length - 1,
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickItem extends StatelessWidget {
  const _QuickItem({required this.item, required this.showDivider});

  final _ActionItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showInfo(context, item.label),
      child: Container(
        decoration: BoxDecoration(
          border: showDivider ? const Border(right: BorderSide(color: AppColors.cardBorder)) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        child: Column(
          children: [
            Icon(item.icon, color: item.color, size: 28),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: AppColors.darkNavy),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSummary extends StatelessWidget {
  const _RoleSummary({required this.role});

  final ThixRole role;

  @override
  Widget build(BuildContext context) {
    final items = _summaryItemsFor(role);
    return _SectionCard(
      title: role == ThixRole.patient ? 'Résumé de santé' : role == ThixRole.doctor ? 'Vue d\'ensemble clinique' : 'Pilotage pharmacie',
      actionLabel: 'Voir tout',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemBuilder: (context, index) => _MetricCard(item: items[index]),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.item});

  final _MetricItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: context.textStyles.labelLarge?.copyWith(color: item.color, fontWeight: FontWeight.w700),
                ),
              ),
              Icon(item.icon, color: item.color, size: 22),
            ],
          ),
          Text(
            item.value,
            style: context.textStyles.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.darkNavy),
          ),
          Text(
            item.caption,
            style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RoleModules extends StatelessWidget {
  const _RoleModules({required this.role});

  final ThixRole role;

  @override
  Widget build(BuildContext context) {
    final sections = _moduleSectionsFor(role);
    return Column(
      children: sections
          .map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _SectionCard(
                title: section.title,
                actionLabel: section.actionLabel,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: section.items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.12,
                  ),
                  itemBuilder: (context, index) => _FeatureCard(item: section.items[index]),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item});

  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showInfo(context, item.title),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: item.color.withValues(alpha: 0.10),
              child: Icon(item.icon, color: item.color),
            ),
            Text(
              item.title,
              style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.darkNavy),
            ),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.35),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.arrow_forward_rounded, color: item.color, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleHighlights extends StatelessWidget {
  const _RoleHighlights({required this.role});

  final ThixRole role;

  @override
  Widget build(BuildContext context) {
    final items = _highlightItemsFor(role);
    return _SectionCard(
      title: role == ThixRole.patient ? 'Parcours prioritaire' : role == ThixRole.doctor ? 'Flux clinique du jour' : 'Opérations critiques',
      actionLabel: 'Voir tout',
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TimelineTile(item: item),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item});

  final _TimelineItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showInfo(context, item.title),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(item.subtitle, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(item.trailing, style: context.textStyles.labelLarge?.copyWith(color: item.color, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ArticlesOrAlerts extends StatelessWidget {
  const _ArticlesOrAlerts({required this.role});

  final ThixRole role;

  @override
  Widget build(BuildContext context) {
    final cards = _articleItemsFor(role);
    return _SectionCard(
      title: role == ThixRole.patient ? 'Pour vous' : role == ThixRole.doctor ? 'Alertes & analyses' : 'Rapports & messagerie',
      actionLabel: 'Voir tout',
      child: SizedBox(
        height: 188,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => _ArticleCard(item: cards[index]),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.item});

  final _ArticleItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: () => _showInfo(context, item.title),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 78,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [item.color.withValues(alpha: 0.95), item.color.withValues(alpha: 0.55)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.tag,
                            style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 10,
                        child: Icon(item.icon, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                Text(item.footer, style: context.textStyles.labelSmall?.copyWith(color: item.color, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.role});

  final ThixRole role;

  @override
  Widget build(BuildContext context) {
    final title = role == ThixRole.patient
        ? 'Besoin d\'aide immédiate ?'
        : role == ThixRole.doctor
            ? 'Actions terrain disponibles'
            : 'Réassort et livraison en un clic';
    final subtitle = role == ThixRole.patient
        ? 'Contactez les urgences en un clic ou prévenez vos proches.'
        : role == ThixRole.doctor
            ? 'Scan bracelet, dictée vocale et mode hors-ligne pour vos tournées.'
            : 'Lancez le réapprovisionnement ou prévenez le patient de la livraison.';
    final buttonLabel = role == ThixRole.patient
        ? 'Appeler 15'
        : role == ThixRole.doctor
            ? 'Outils mobiles'
            : 'Réapprovisionner';
    final buttonColor = role == ThixRole.patient ? const Color(0xFFE91E63) : role.accent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [buttonColor.withValues(alpha: 0.12), Colors.white],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: buttonColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              role == ThixRole.patient
                  ? Icons.phone_in_talk_rounded
                  : role == ThixRole.doctor
                      ? Icons.mobile_friendly_rounded
                      : Icons.local_shipping_rounded,
              color: buttonColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => _showInfo(context, buttonLabel),
            style: FilledButton.styleFrom(
              backgroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, this.actionLabel, required this.child});

  final String title;
  final String? actionLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.darkNavy),
                ),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: () => _showInfo(context, actionLabel!),
                  child: Text(actionLabel!, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RoundIconBadge extends StatelessWidget {
  const _RoundIconBadge({required this.icon, this.badge});

  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [AppShadows.secondary],
          ),
          child: Icon(icon, color: AppColors.darkNavy),
        ),
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
              child: Text(
                badge!,
                style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryBlueGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        name.trim().isEmpty ? 'T' : name.trim()[0].toUpperCase(),
        style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;
}

class _MetricItem {
  const _MetricItem({required this.label, required this.value, required this.caption, required this.icon, required this.color});

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;
}

class _FeatureItem {
  const _FeatureItem({required this.title, required this.subtitle, required this.icon, required this.color});

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _TimelineItem {
  const _TimelineItem({required this.title, required this.subtitle, required this.trailing, required this.icon, required this.color});

  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final Color color;
}

class _ArticleItem {
  const _ArticleItem({required this.tag, required this.title, required this.subtitle, required this.footer, required this.icon, required this.color});

  final String tag;
  final String title;
  final String subtitle;
  final String footer;
  final IconData icon;
  final Color color;
}

class _ModuleSection {
  const _ModuleSection({required this.title, required this.actionLabel, required this.items});

  final String title;
  final String actionLabel;
  final List<_FeatureItem> items;
}

void _showInfo(BuildContext context, String label) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label prêt à être utilisé.')));
}

List<_ActionItem> _quickItemsFor(ThixRole role) {
  switch (role) {
    case ThixRole.patient:
      return const [
        _ActionItem(label: 'Rendez-vous', icon: Icons.calendar_month_rounded, color: Color(0xFF2453FF)),
        _ActionItem(label: 'Consultation', icon: Icons.health_and_safety_rounded, color: Color(0xFF10B981)),
        _ActionItem(label: 'Examens', icon: Icons.science_rounded, color: Color(0xFF7C3AED)),
        _ActionItem(label: 'Ordonnances', icon: Icons.medication_rounded, color: Color(0xFFFF6B00)),
        _ActionItem(label: 'Urgences', icon: Icons.favorite_rounded, color: Color(0xFFE91E63)),
        _ActionItem(label: 'Plus', icon: Icons.more_horiz_rounded, color: AppColors.textSecondary),
      ];
    case ThixRole.doctor:
      return const [
        _ActionItem(label: 'Patients', icon: Icons.groups_rounded, color: Color(0xFF2453FF)),
        _ActionItem(label: 'Agenda', icon: Icons.calendar_today_rounded, color: Color(0xFF10B981)),
        _ActionItem(label: 'Notes', icon: Icons.edit_note_rounded, color: Color(0xFF7C3AED)),
        _ActionItem(label: 'Jitsi', icon: Icons.video_call_rounded, color: Color(0xFFFF6B00)),
        _ActionItem(label: 'Alertes', icon: Icons.warning_amber_rounded, color: Color(0xFFE91E63)),
        _ActionItem(label: 'Plus', icon: Icons.more_horiz_rounded, color: AppColors.textSecondary),
      ];
    case ThixRole.pharmacy:
      return const [
        _ActionItem(label: 'Commandes', icon: Icons.receipt_long_rounded, color: Color(0xFF2453FF)),
        _ActionItem(label: 'Stock', icon: Icons.inventory_2_rounded, color: Color(0xFF10B981)),
        _ActionItem(label: 'Lots', icon: Icons.qr_code_scanner_rounded, color: Color(0xFF7C3AED)),
        _ActionItem(label: 'Livraison', icon: Icons.local_shipping_rounded, color: Color(0xFFFF6B00)),
        _ActionItem(label: 'Alertes', icon: Icons.notifications_active_rounded, color: Color(0xFFE91E63)),
        _ActionItem(label: 'Plus', icon: Icons.more_horiz_rounded, color: AppColors.textSecondary),
      ];
  }
}

List<_MetricItem> _summaryItemsFor(ThixRole role) {
  switch (role) {
    case ThixRole.patient:
      return const [
        _MetricItem(label: 'Consultations', value: '12', caption: 'Cette année', icon: Icons.calendar_month_rounded, color: Color(0xFF2453FF)),
        _MetricItem(label: 'Examens', value: '7', caption: 'Complétés', icon: Icons.science_rounded, color: Color(0xFF10B981)),
        _MetricItem(label: 'Médicaments', value: '3', caption: 'En cours', icon: Icons.medication_rounded, color: Color(0xFF7C3AED)),
        _MetricItem(label: 'Rendez-vous', value: '2', caption: 'À venir', icon: Icons.event_available_rounded, color: Color(0xFFFF6B00)),
      ];
    case ThixRole.doctor:
      return const [
        _MetricItem(label: 'Patients', value: '84', caption: 'Actifs', icon: Icons.groups_rounded, color: Color(0xFF2453FF)),
        _MetricItem(label: 'Consultations', value: '16', caption: 'Aujourd\'hui', icon: Icons.health_and_safety_rounded, color: Color(0xFF10B981)),
        _MetricItem(label: 'Alertes', value: '5', caption: 'À traiter', icon: Icons.warning_amber_rounded, color: Color(0xFFE91E63)),
        _MetricItem(label: 'Téléexpertises', value: '3', caption: 'En attente', icon: Icons.hub_rounded, color: Color(0xFF7C3AED)),
      ];
    case ThixRole.pharmacy:
      return const [
        _MetricItem(label: 'Commandes', value: '21', caption: 'En attente', icon: Icons.receipt_long_rounded, color: Color(0xFF2453FF)),
        _MetricItem(label: 'Stock critique', value: '9', caption: 'Réappro. requis', icon: Icons.inventory_rounded, color: Color(0xFFE91E63)),
        _MetricItem(label: 'Dispensations', value: '43', caption: 'Aujourd\'hui', icon: Icons.medication_rounded, color: Color(0xFF10B981)),
        _MetricItem(label: 'Livraisons', value: '7', caption: 'En transit', icon: Icons.local_shipping_rounded, color: Color(0xFFFF6B00)),
      ];
  }
}

List<_ModuleSection> _moduleSectionsFor(ThixRole role) {
  switch (role) {
    case ThixRole.patient:
      return const [
        _ModuleSection(
          title: 'Services santé',
          actionLabel: 'Voir tout',
          items: [
            _FeatureItem(title: 'Santé des enfants', subtitle: 'Suivez la santé de vos enfants', icon: Icons.child_care_rounded, color: Color(0xFF2453FF)),
            _FeatureItem(title: 'Carnet vaccinal', subtitle: 'Vaccins, rappels et attestations', icon: Icons.vaccines_rounded, color: Color(0xFF10B981)),
            _FeatureItem(title: 'Suivi grossesse', subtitle: 'Parcours maternité pas à pas', icon: Icons.pregnant_woman_rounded, color: Color(0xFF7C3AED)),
            _FeatureItem(title: 'Assurance santé', subtitle: 'Protégez votre foyer', icon: Icons.shield_rounded, color: Color(0xFFFF6B00)),
          ],
        ),
        _ModuleSection(
          title: 'Services rapides',
          actionLabel: 'Voir tout',
          items: [
            _FeatureItem(title: 'Consulter un médecin', subtitle: 'Parlez à un professionnel', icon: Icons.support_agent_rounded, color: Color(0xFF2453FF)),
            _FeatureItem(title: 'Dossier médical', subtitle: 'Accédez à vos documents', icon: Icons.folder_shared_rounded, color: Color(0xFF10B981)),
            _FeatureItem(title: 'Résultats d\'examens', subtitle: 'Consultez vos analyses', icon: Icons.biotech_rounded, color: Color(0xFF7C3AED)),
            _FeatureItem(title: 'Pharmacies proches', subtitle: 'Trouvez la plus proche', icon: Icons.local_pharmacy_rounded, color: Color(0xFFFF6B00)),
          ],
        ),
      ];
    case ThixRole.doctor:
      return const [
        _ModuleSection(
          title: 'Pilotage clinique',
          actionLabel: 'Voir tout',
          items: [
            _FeatureItem(title: 'Patients', subtitle: 'Résumé, allergies et traitements', icon: Icons.groups_rounded, color: Color(0xFF2453FF)),
            _FeatureItem(title: 'Constantes', subtitle: 'Graphiques tension, poids, glycémie', icon: Icons.monitor_heart_rounded, color: Color(0xFF10B981)),
            _FeatureItem(title: 'Prescriptions', subtitle: 'Créer, prévisualiser et envoyer', icon: Icons.description_rounded, color: Color(0xFF7C3AED)),
            _FeatureItem(title: 'Téléconsultation', subtitle: 'Appels vidéo Jitsi et suivi', icon: Icons.video_call_rounded, color: Color(0xFFFF6B00)),
          ],
        ),
        _ModuleSection(
          title: 'Terrain & mobilité',
          actionLabel: 'Voir tout',
          items: [
            _FeatureItem(title: 'Scan bracelet', subtitle: 'Sécurisation des médicaments', icon: Icons.qr_code_scanner_rounded, color: Color(0xFF2453FF)),
            _FeatureItem(title: 'Dictée vocale', subtitle: 'Compte rendu assisté', icon: Icons.mic_rounded, color: Color(0xFF10B981)),
            _FeatureItem(title: 'Documents', subtitle: 'Numérisez ordonnances et radios', icon: Icons.document_scanner_rounded, color: Color(0xFF7C3AED)),
            _FeatureItem(title: 'Mode hors-ligne', subtitle: 'Synchronisation différée', icon: Icons.cloud_off_rounded, color: Color(0xFFFF6B00)),
          ],
        ),
      ];
    case ThixRole.pharmacy:
      return const [
        _ModuleSection(
          title: 'Exécution officine',
          actionLabel: 'Voir tout',
          items: [
            _FeatureItem(title: 'Ordonnances', subtitle: 'Validation, acceptation ou rejet', icon: Icons.fact_check_rounded, color: Color(0xFF2453FF)),
            _FeatureItem(title: 'Inventaire', subtitle: 'Quantités, seuils et lots', icon: Icons.inventory_2_rounded, color: Color(0xFF10B981)),
            _FeatureItem(title: 'Dispensation', subtitle: 'Attribution à chaque patient', icon: Icons.medication_rounded, color: Color(0xFF7C3AED)),
            _FeatureItem(title: 'Livraisons', subtitle: 'Préparation, transit et remise', icon: Icons.local_shipping_rounded, color: Color(0xFFFF6B00)),
          ],
        ),
        _ModuleSection(
          title: 'Coordination',
          actionLabel: 'Voir tout',
          items: [
            _FeatureItem(title: 'Messagerie', subtitle: 'Échange avec médecins et patients', icon: Icons.chat_bubble_rounded, color: Color(0xFF2453FF)),
            _FeatureItem(title: 'Rapports', subtitle: 'CA, commandes et prescriptions', icon: Icons.analytics_rounded, color: Color(0xFF10B981)),
            _FeatureItem(title: 'Réassort', subtitle: 'Alerte stock bas et commande', icon: Icons.add_business_rounded, color: Color(0xFF7C3AED)),
            _FeatureItem(title: 'Profil officine', subtitle: 'Coordonnées et horaires', icon: Icons.storefront_rounded, color: Color(0xFFFF6B00)),
          ],
        ),
      ];
  }
}

List<_TimelineItem> _highlightItemsFor(ThixRole role) {
  switch (role) {
    case ThixRole.patient:
      return const [
        _TimelineItem(title: 'Prochain rendez-vous', subtitle: 'Dr. Sarr · Cardiologie · 10:30', trailing: 'Demain', icon: Icons.event_rounded, color: Color(0xFF2453FF)),
        _TimelineItem(title: 'Traitement en cours', subtitle: 'Amoxicilline 500 mg · 2 prises restantes', trailing: 'Ce soir', icon: Icons.medication_rounded, color: Color(0xFF7C3AED)),
        _TimelineItem(title: 'Score de santé IA', subtitle: 'Score global 86/100 · tendance stable', trailing: '+4', icon: Icons.insights_rounded, color: Color(0xFF10B981)),
      ];
    case ThixRole.doctor:
      return const [
        _TimelineItem(title: 'Consultation 08:30', subtitle: 'Awa Ndiaye · suivi diabète · salle 2', trailing: 'En cours', icon: Icons.local_hospital_rounded, color: Color(0xFF2453FF)),
        _TimelineItem(title: 'Téléexpertise', subtitle: 'Demande en attente pour imagerie thoracique', trailing: '2 avis', icon: Icons.hub_rounded, color: Color(0xFF7C3AED)),
        _TimelineItem(title: 'Patient à risque', subtitle: 'TA élevée détectée sur 24h · alerte rouge', trailing: '95%', icon: Icons.warning_rounded, color: Color(0xFFE91E63)),
      ];
    case ThixRole.pharmacy:
      return const [
        _TimelineItem(title: 'Prescription à valider', subtitle: 'Ordonnance OR-20814 · 4 médicaments', trailing: 'Maintenant', icon: Icons.description_rounded, color: Color(0xFF2453FF)),
        _TimelineItem(title: 'Stock bas', subtitle: 'Paracétamol 1g · seuil critique atteint', trailing: '12 boîtes', icon: Icons.inventory_rounded, color: Color(0xFFE91E63)),
        _TimelineItem(title: 'Livraison prioritaire', subtitle: 'Patient Diallo · préparation terminée', trailing: 'ETA 20 min', icon: Icons.delivery_dining_rounded, color: Color(0xFFFF6B00)),
      ];
  }
}

List<_ArticleItem> _articleItemsFor(ThixRole role) {
  switch (role) {
    case ThixRole.patient:
      return const [
        _ArticleItem(tag: 'Conseil santé', title: '5 conseils pour rester en bonne santé', subtitle: 'Prévention, activité physique et sommeil.', footer: '3 min de lecture', icon: Icons.directions_run_rounded, color: Color(0xFF10B981)),
        _ArticleItem(tag: 'Nutrition', title: 'Alimentation équilibrée : les bases', subtitle: 'Repères simples pour vos repas du quotidien.', footer: '4 min de lecture', icon: Icons.restaurant_rounded, color: Color(0xFFFF9800)),
        _ArticleItem(tag: 'Prévention', title: 'Prévention : un geste qui sauve', subtitle: 'Réagir vite face à une urgence à domicile.', footer: '2 min de lecture', icon: Icons.volunteer_activism_rounded, color: Color(0xFFE91E63)),
      ];
    case ThixRole.doctor:
      return const [
        _ArticleItem(tag: 'Alertes', title: '5 patients à risque nécessitent un suivi', subtitle: 'Anomalies de constantes et rappels thérapeutiques.', footer: 'Priorité clinique', icon: Icons.warning_rounded, color: Color(0xFFE91E63)),
        _ArticleItem(tag: 'Analytics', title: 'Évolution des consultations cette semaine', subtitle: 'Hausse de 12% des téléconsultations et pics de charge.', footer: 'Mise à jour live', icon: Icons.bar_chart_rounded, color: Color(0xFF2453FF)),
        _ArticleItem(tag: 'Notes', title: 'Dictée vocale disponible hors ligne', subtitle: 'Capturez vos comptes rendus sur le terrain.', footer: 'Outil mobile', icon: Icons.mic_rounded, color: Color(0xFF10B981)),
      ];
    case ThixRole.pharmacy:
      return const [
        _ArticleItem(tag: 'Rapports', title: 'Top médicaments prescrits cette semaine', subtitle: 'Vue consolidée pour vos commandes fournisseurs.', footer: 'Rapport auto', icon: Icons.analytics_rounded, color: Color(0xFF2453FF)),
        _ArticleItem(tag: 'Messagerie', title: '3 confirmations patients en attente', subtitle: 'Relancer la livraison et confirmer la dispensation.', footer: 'Temps réel', icon: Icons.chat_rounded, color: Color(0xFF10B981)),
        _ArticleItem(tag: 'Contrôle', title: 'Traçabilité des lots et dates critiques', subtitle: 'Sécurisez vos stocks sensibles et stupéfiants.', footer: 'Audit qualité', icon: Icons.verified_user_rounded, color: Color(0xFF7C3AED)),
      ];
  }
}
