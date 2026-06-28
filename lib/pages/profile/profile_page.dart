import 'dart:async';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/auth/services/thix_profile_service.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/pages/profile/models/profile_models.dart';
import 'package:thix_central/pages/profile/services/profile_dashboard_service.dart';
import 'package:thix_central/pages/profile/services/profile_pdf_service.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

// ============================================================================
// Page principale
// ============================================================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileService = const ThixProfileService();
  final _dashboardService = const ProfileDashboardService();
  final _pdf = const ProfilePdfService();
  final _localAuth = LocalAuthentication();

  Future<Map<String, dynamic>?>? _profileFuture;
  Future<ProfileDetailsModel?>? _detailsFuture;
  Future<List<EmergencyContactModel>>? _contactsFuture;
  Future<List<ProfileExperienceModel>>? _expFuture;
  Future<List<ProfileEducationModel>>? _eduFuture;
  Future<List<ProfileSkillModel>>? _skillsFuture;
  Future<List<ProfileLanguageModel>>? _langsFuture;
  Future<List<ProfileDocumentModel>>? _docsFuture;
  Future<ProfileSecuritySettingsModel?>? _secFuture;
  Future<List<ProfileSecurityEventModel>>? _secEventsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAll();
    unawaited(_safeLogEvent('dashboard_open'));
  }

  Future<void> _safeLogEvent(String type, {Map<String, dynamic>? details}) async {
    try {
      await _dashboardService.logSecurityEvent(type, details: details);
    } catch (_) {}
  }

  void _refreshAll() {
    setState(() {
      _profileFuture = _profileService.getMyProfile();
      _detailsFuture = _dashboardService.getMyDetails();
      _contactsFuture = _dashboardService.listMyEmergencyContacts();
      _expFuture = _dashboardService.listMyExperiences();
      _eduFuture = _dashboardService.listMyEducation();
      _skillsFuture = _dashboardService.listMySkills();
      _langsFuture = _dashboardService.listMyLanguages();
      _docsFuture = _dashboardService.listMyDocuments();
      _secFuture = _dashboardService.getMySecuritySettings();
      _secEventsFuture = _dashboardService.listMySecurityEvents();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Déconnecté')));
      _refreshAll();
    } catch (e) {
      debugPrint('Logout failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  // --- Upload réel de document ---
  Future<void> _uploadDocument(String docType) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final Uint8List? bytes = picked.bytes;
      final fileName = picked.name;
      if (bytes == null) throw Exception('Impossible de lire le fichier');

      final supabase = SupabaseClientProvider.client;
      final userId = supabase.auth.currentUser!.id;
      final bucket = 'profile_docs';
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await supabase.storage.from(bucket).uploadBinary(path, bytes);

      final publicUrl = supabase.storage.from(bucket).getPublicUrl(path);

      await _dashboardService.createDocument(
        docType: docType,
        label: fileName,
        fileUrl: publicUrl,
      );

      await _safeLogEvent('document_uploaded', details: {'doc_type': docType, 'file': fileName});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Document "$fileName" uploadé avec succès')));
      _refreshAll();
    } catch (e) {
      debugPrint('Upload failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur upload: $e')));
    }
  }

  // --- Activation gratuite (sans paiement) ---
  Future<void> _activateAccount(ProfileDetailsModel? details) async {
    try {
      final uid = SupabaseClientProvider.client.auth.currentUser!.id;
      final patch = (details ?? ProfileDetailsModel(
            userId: uid,
            fullName: null,
            bio: null,
            phone: null,
            address: null,
            city: null,
            nationality: null,
            maritalStatus: null,
            birthPlace: null,
            fatherName: null,
            motherName: null,
            accountStatus: 'THIX-PENDING',
            publicBio: true,
            publicExperiences: true,
            publicEducation: true,
            publicSkills: true,
            publicLanguages: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ))
          .copyWith(accountStatus: 'THIX-ACTIVE');

      await _dashboardService.upsertMyDetails(patch);
      await _safeLogEvent('account_activated');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte activé')));
      _refreshAll();
    } catch (e) {
      debugPrint('activateAccount failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _updateSecurityToggles({required bool biometricsEnabled, required bool twoFaEnabled}) async {
    try {
      if (biometricsEnabled) {
        final can = await _localAuth.canCheckBiometrics;
        final supported = await _localAuth.isDeviceSupported();
        if (!can || !supported) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biométrie indisponible sur cet appareil')));
          return;
        }
        final ok = await _localAuth.authenticate(
          localizedReason: 'Activer la biométrie pour sécuriser votre dashboard',
          options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
        );
        if (!ok) return;
      }

      await _dashboardService.upsertMySecuritySettings(biometricsEnabled: biometricsEnabled, twoFaEnabled: twoFaEnabled);
      await _safeLogEvent('security_settings_updated', details: {'biometrics': biometricsEnabled, 'two_fa': twoFaEnabled});
      _refreshAll();
    } catch (e) {
      debugPrint('updateSecurityToggles failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  // --- Export CV ---
  Future<void> _printDigitalCv() async {
    try {
      final profile = await _profileFuture;
      final details = await _detailsFuture;
      final thixId = (profile?['thix_id'] as String?) ?? 'THIX-PENDING';
      final name = (details?.fullName ?? profile?['display_name'] ?? SupabaseClientProvider.client.auth.currentUser?.email ?? 'THIX').toString();
      final exps = await _expFuture!;
      final edu = await _eduFuture!;
      final skills = await _skillsFuture!;
      final langs = await _langsFuture!;
      await _safeLogEvent('export_cv_pdf');
      await _pdf.printDigitalCv(
        displayName: name,
        thixId: thixId,
        details: details,
        experiences: exps,
        education: edu,
        skills: skills,
        languages: langs,
      );
    } catch (e) {
      debugPrint('printDigitalCv failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur PDF: $e')));
    }
  }

  // --- Éditeurs (conservés) ---
  Future<void> _openEditIdentity(ProfileDetailsModel? existing) async {
    final result = await showModalBottomSheet<ProfileDetailsModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => IdentityEditorSheet(existing: existing),
    );
    if (result == null) return;
    try {
      await _dashboardService.upsertMyDetails(result);
      await _safeLogEvent('profile_identity_updated');
      _refreshAll();
    } catch (e) {
      debugPrint('Save identity failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _openVisibilityEditor(ProfileDetailsModel? existing) async {
    final result = await showModalBottomSheet<ProfileDetailsModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => VisibilityEditorSheet(existing: existing),
    );
    if (result == null) return;
    try {
      await _dashboardService.upsertMyDetails(result);
      await _safeLogEvent('profile_visibility_updated');
      _refreshAll();
    } catch (e) {
      debugPrint('Save visibility failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _openEmergencyEditor({EmergencyContactModel? existing}) async {
    final result = await showModalBottomSheet<_EmergencyContactDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => EmergencyContactEditorSheet(existing: existing),
    );
    if (result == null) return;
    try {
      await _dashboardService.upsertEmergencyContact(
        id: existing?.id,
        name: result.name,
        phone: result.phone,
        relationship: result.relationship,
        city: result.city,
      );
      await _safeLogEvent('emergency_contact_upserted');
      _refreshAll();
    } catch (e) {
      debugPrint('Save emergency contact failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _deleteExperience(ProfileExperienceModel m) async {
    try {
      await _dashboardService.deleteExperience(m.id);
      await _safeLogEvent('experience_deleted');
      _refreshAll();
    } catch (e) {
      debugPrint('Delete experience failed: $e');
    }
  }

  Future<void> _deleteEducation(ProfileEducationModel m) async {
    try {
      await _dashboardService.deleteEducation(m.id);
      await _safeLogEvent('education_deleted');
      _refreshAll();
    } catch (e) {
      debugPrint('Delete education failed: $e');
    }
  }

  Future<void> _deleteSkill(ProfileSkillModel m) async {
    try {
      await _dashboardService.deleteSkill(m.id);
      await _safeLogEvent('skill_deleted');
      _refreshAll();
    } catch (e) {
      debugPrint('Delete skill failed: $e');
    }
  }

  Future<void> _deleteLanguage(ProfileLanguageModel m) async {
    try {
      await _dashboardService.deleteLanguage(m.id);
      await _safeLogEvent('language_deleted');
      _refreshAll();
    } catch (e) {
      debugPrint('Delete language failed: $e');
    }
  }

  Future<void> _deleteDocument(ProfileDocumentModel m) async {
    try {
      await _dashboardService.deleteDocument(m.id);
      await _safeLogEvent('document_deleted');
      _refreshAll();
    } catch (e) {
      debugPrint('Delete document failed: $e');
    }
  }

  Future<void> _openExperienceEditor({ProfileExperienceModel? existing}) async {
    final result = await showModalBottomSheet<ProfileExperienceModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => ExperienceEditorSheet(existing: existing),
    );
    if (result == null) return;
    try {
      await _dashboardService.upsertExperience(result);
      await _safeLogEvent('experience_upserted');
      _refreshAll();
    } catch (e) {
      debugPrint('Save experience failed: $e');
    }
  }

  Future<void> _openEducationEditor({ProfileEducationModel? existing}) async {
    final result = await showModalBottomSheet<ProfileEducationModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => EducationEditorSheet(existing: existing),
    );
    if (result == null) return;
    try {
      await _dashboardService.upsertEducation(result);
      await _safeLogEvent('education_upserted');
      _refreshAll();
    } catch (e) {
      debugPrint('Save education failed: $e');
    }
  }

  Future<void> _openSkillEditor({ProfileSkillModel? existing}) async {
    final result = await showModalBottomSheet<ProfileSkillModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => SkillEditorSheet(existing: existing),
    );
    if (result == null) return;
    try {
      await _dashboardService.upsertSkill(result);
      await _safeLogEvent('skill_upserted');
      _refreshAll();
    } catch (e) {
      debugPrint('Save skill failed: $e');
    }
  }

  Future<void> _openLanguageEditor({ProfileLanguageModel? existing}) async {
    final result = await showModalBottomSheet<ProfileLanguageModel>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => LanguageEditorSheet(existing: existing),
    );
    if (result == null) return;
    try {
      await _dashboardService.upsertLanguage(result);
      await _safeLogEvent('language_upserted');
      _refreshAll();
    } catch (e) {
      debugPrint('Save language failed: $e');
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => const NotificationsSheet(),
    );
  }

  Future<void> _sharePublicLink(Map<String, dynamic>? profile) async {
    final thixId = (profile?['thix_id'] as String?) ?? 'THIX-PENDING';
    final url = 'https://thix.app/u/$thixId';
    await _safeLogEvent('share_public_link', details: {'thix_id': thixId});
    if (!mounted) return;
    await Share.share('Mon profil THIX: $url');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = SupabaseClientProvider.clientOrNull?.auth.currentUser;
    final displayEmail = user?.email ?? 'Invité';

    if (user == null) {
      return Scaffold(
        appBar: ThixTopBar(
          title: 'Profil',
          subtitle: 'Connectez-vous pour continuer',
          onMenuTap: () {},
          trailing: IconButton(
            onPressed: () => context.push('/auth/login?next=/profile'),
            icon: Icon(Icons.login, color: cs.onSurface),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline, size: 44, color: cs.onSurfaceVariant),
              const SizedBox(height: 10),
              Text('Connexion requise', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('Accédez à votre THIX ID et à votre dashboard.', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => context.push('/auth/login?next=/profile'),
                icon: Icon(Icons.login, color: cs.onPrimary),
                label: Text('Se connecter', style: TextStyle(color: cs.onPrimary)),
              ),
            ]),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: _ProfileTabbedTopBar(
          title: 'Profil',
          subtitle: displayEmail,
          onMenuTap: () {},
          trailing: IconButton(
            onPressed: () => _showNotifications(context),
            icon: Icon(Icons.notifications_none_rounded, color: cs.onSurface),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Parcours'),
            Tab(text: 'Docs'),
            Tab(text: 'Sécurité'),
          ],
        ),
        floatingActionButton: _QuickFabRow(
          onScan: () => context.push('/scan'),
          onChat: () => context.push('/messages'),
        ),
        body: TabBarView(
          children: [
            _DashboardTab(
              profileFuture: _profileFuture!,
              detailsFuture: _detailsFuture!,
              contactsFuture: _contactsFuture!,
              expFuture: _expFuture!,
              eduFuture: _eduFuture!,
              skillsFuture: _skillsFuture!,
              langsFuture: _langsFuture!,
              onRefresh: _refreshAll,
              onEditIdentity: _openEditIdentity,
              onEditEmergency: _openEmergencyEditor,
              onSharePublic: _sharePublicLink,
              onShowQr: () => context.push('/thix-id/card'),
              onLogout: _logout,
              onPrintCv: _printDigitalCv,
            ),
            _ParcoursTab(
              detailsFuture: _detailsFuture!,
              expFuture: _expFuture!,
              eduFuture: _eduFuture!,
              skillsFuture: _skillsFuture!,
              langsFuture: _langsFuture!,
              onRefresh: _refreshAll,
              onEditVisibility: _openVisibilityEditor,
              onAddExperience: () => _openExperienceEditor(),
              onAddEducation: () => _openEducationEditor(),
              onAddSkill: () => _openSkillEditor(),
              onAddLanguage: () => _openLanguageEditor(),
              onEditExperience: (m) => _openExperienceEditor(existing: m),
              onEditEducation: (m) => _openEducationEditor(existing: m),
              onEditSkill: (m) => _openSkillEditor(existing: m),
              onEditLanguage: (m) => _openLanguageEditor(existing: m),
              onDeleteExperience: _deleteExperience,
              onDeleteEducation: _deleteEducation,
              onDeleteSkill: _deleteSkill,
              onDeleteLanguage: _deleteLanguage,
            ),
            _DocumentsTab(
              docsFuture: _docsFuture!,
              onRefresh: _refreshAll,
              onUploadDoc: _uploadDocument,
              onDeleteDoc: _deleteDocument,
            ),
            _SecurityTab(
              secFuture: _secFuture!,
              secEventsFuture: _secEventsFuture!,
              onRefresh: _refreshAll,
              onUpdateToggles: _updateSecurityToggles,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Composants réutilisables
// ============================================================================

// --- AppBar avec onglets ---
class _ProfileTabbedTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileTabbedTopBar({required this.title, this.subtitle, this.onMenuTap, this.trailing, required this.tabs});
  final String title;
  final String? subtitle;
  final VoidCallback? onMenuTap;
  final Widget? trailing;
  final List<Widget> tabs;

  @override
  Size get preferredSize => const Size.fromHeight(62 + 44);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 62,
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onMenuTap,
                    icon: Icon(Icons.menu, color: cs.onSurface),
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                  const SizedBox(width: 8),
                ],
              ),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              tabs: tabs,
            ),
          ],
        ),
      ),
    );
  }
}

// --- FAB rapide ---
class _QuickFabRow extends StatelessWidget {
  const _QuickFabRow({required this.onScan, required this.onChat});
  final VoidCallback onScan;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_scan',
            onPressed: onScan,
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            elevation: 0,
            child: const Icon(Icons.qr_code_scanner_rounded),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            heroTag: 'fab_chat',
            onPressed: onChat,
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            elevation: 0,
            child: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
    );
  }
}

// --- Onglet Dashboard ---
class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.profileFuture,
    required this.detailsFuture,
    required this.contactsFuture,
    required this.expFuture,
    required this.eduFuture,
    required this.skillsFuture,
    required this.langsFuture,
    required this.onRefresh,
    required this.onEditIdentity,
    required this.onEditEmergency,
    required this.onSharePublic,
    required this.onShowQr,
    required this.onLogout,
    required this.onPrintCv,
  });

  final Future<Map<String, dynamic>?> profileFuture;
  final Future<ProfileDetailsModel?> detailsFuture;
  final Future<List<EmergencyContactModel>> contactsFuture;
  final Future<List<ProfileExperienceModel>> expFuture;
  final Future<List<ProfileEducationModel>> eduFuture;
  final Future<List<ProfileSkillModel>> skillsFuture;
  final Future<List<ProfileLanguageModel>> langsFuture;
  final VoidCallback onRefresh;
  final ValueChanged<ProfileDetailsModel?> onEditIdentity;
  final void Function({EmergencyContactModel? existing}) onEditEmergency;
  final Future<void> Function(Map<String, dynamic>? profile) onSharePublic;
  final VoidCallback onShowQr;
  final Future<void> Function() onLogout;
  final VoidCallback onPrintCv;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 120),
        children: [
          FutureBuilder<Map<String, dynamic>?>(
            future: profileFuture,
            builder: (context, snap) {
              final p = snap.data;
              final user = SupabaseClientProvider.clientOrNull?.auth.currentUser;
              final email = user?.email ?? '';
              final thixId = (p?['thix_id'] as String?) ?? 'THIX-PENDING';
              final verified = user != null && (user.emailConfirmedAt != null || p?['email_verified'] == true);

              return FutureBuilder<ProfileDetailsModel?>(
                future: detailsFuture,
                builder: (context, ds) {
                  final details = ds.data;
                  final name = (details?.fullName ?? p?['display_name'] ?? email).toString();
                  final score = _ThixScore.compute(details: details, exp: null, edu: null, skills: null, langs: null);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: AppColors.primaryBlueGradient, borderRadius: BorderRadius.circular(AppRadius.search)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        ThixAvatar(size: 58, initials: name.isEmpty ? 'T' : name.characters.first.toUpperCase()),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, style: context.textStyles.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text('THIX ID: $thixId', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.88))),
                            const SizedBox(height: 10),
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              _Capsule(icon: verified ? Icons.verified : Icons.schedule, label: verified ? 'Vérifié' : 'En attente'),
                              _Capsule(icon: Icons.public, label: 'Profil public'),
                            ]),
                          ]),
                        ),
                        IconButton(
                          onPressed: () => onEditIdentity(details),
                          icon: const Icon(Icons.edit_outlined, color: Colors.white),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Text('THIX Score', style: context.textStyles.labelLarge?.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.92)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('$score / 100', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => onSharePublic(p),
                            icon: const Icon(Icons.share_outlined),
                            label: const Text('Partager'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onShowQr,
                            icon: const Icon(Icons.qr_code_2_rounded),
                            label: const Text('Mon QR'),
                          ),
                        ),
                      ]),
                    ]),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Informations civiles',
            child: FutureBuilder<ProfileDetailsModel?>(
              future: detailsFuture,
              builder: (context, snap) {
                final d = snap.data;
                return Column(children: [
                  _KvRow(label: 'Nationalité', value: d?.nationality),
                  _KvRow(label: 'État civil', value: d?.maritalStatus),
                  _KvRow(label: 'Lieu de naissance', value: d?.birthPlace),
                  _KvRow(label: 'Adresse', value: d?.address),
                  _KvRow(label: 'Ville', value: d?.city),
                  _KvRow(label: 'Père', value: d?.fatherName),
                  _KvRow(label: 'Mère', value: d?.motherName),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => onEditIdentity(d),
                      icon: Icon(Icons.edit_outlined, color: cs.primary),
                      label: Text('Modifier', style: TextStyle(color: cs.primary)),
                    ),
                  ),
                ]);
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Contacts d’urgence',
            trailing: IconButton(
              onPressed: () => onEditEmergency(),
              icon: Icon(Icons.add, color: cs.primary),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: FutureBuilder<List<EmergencyContactModel>>(
              future: contactsFuture,
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return Text('Aucun contact. Ajoutez une personne à appeler en cas d’urgence.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                }
                return Column(
                  children: [
                    for (final c in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ContactTile(
                          contact: c,
                          onEdit: () => onEditEmergency(existing: c),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Actions',
            child: Column(children: [
              _ActionTile(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Exporter CV (PDF)',
                subtitle: 'Impression / sauvegarde PDF depuis votre appareil',
                onTap: onPrintCv,
              ),
              const SizedBox(height: 10),
              _ActionTile(
                icon: Icons.logout,
                title: 'Déconnexion',
                subtitle: 'Quitter votre session',
                onTap: onLogout,
                iconColor: cs.error,
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// --- Onglet Parcours ---
class _ParcoursTab extends StatelessWidget {
  const _ParcoursTab({
    required this.detailsFuture,
    required this.expFuture,
    required this.eduFuture,
    required this.skillsFuture,
    required this.langsFuture,
    required this.onRefresh,
    required this.onEditVisibility,
    required this.onAddExperience,
    required this.onAddEducation,
    required this.onAddSkill,
    required this.onAddLanguage,
    required this.onEditExperience,
    required this.onEditEducation,
    required this.onEditSkill,
    required this.onEditLanguage,
    required this.onDeleteExperience,
    required this.onDeleteEducation,
    required this.onDeleteSkill,
    required this.onDeleteLanguage,
  });

  final Future<ProfileDetailsModel?> detailsFuture;
  final Future<List<ProfileExperienceModel>> expFuture;
  final Future<List<ProfileEducationModel>> eduFuture;
  final Future<List<ProfileSkillModel>> skillsFuture;
  final Future<List<ProfileLanguageModel>> langsFuture;
  final VoidCallback onRefresh;
  final ValueChanged<ProfileDetailsModel?> onEditVisibility;
  final VoidCallback onAddExperience;
  final VoidCallback onAddEducation;
  final VoidCallback onAddSkill;
  final VoidCallback onAddLanguage;
  final ValueChanged<ProfileExperienceModel> onEditExperience;
  final ValueChanged<ProfileEducationModel> onEditEducation;
  final ValueChanged<ProfileSkillModel> onEditSkill;
  final ValueChanged<ProfileLanguageModel> onEditLanguage;
  final ValueChanged<ProfileExperienceModel> onDeleteExperience;
  final ValueChanged<ProfileEducationModel> onDeleteEducation;
  final ValueChanged<ProfileSkillModel> onDeleteSkill;
  final ValueChanged<ProfileLanguageModel> onDeleteLanguage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('MM/yyyy');

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 120),
        children: [
          _SectionCard(
            title: 'Visibilité (Public / Privé)',
            trailing: IconButton(
              onPressed: () async {
                final d = await detailsFuture;
                onEditVisibility(d);
              },
              icon: Icon(Icons.tune_rounded, color: cs.primary),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: FutureBuilder<ProfileDetailsModel?>(
              future: detailsFuture,
              builder: (context, snap) {
                final d = snap.data;
                if (d == null) return Text('Configurez la visibilité de votre profil.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                return Wrap(spacing: 8, runSpacing: 8, children: [
                  _VisibilityChip(label: 'Bio', isPublic: d.publicBio),
                  _VisibilityChip(label: 'Expériences', isPublic: d.publicExperiences),
                  _VisibilityChip(label: 'Formations', isPublic: d.publicEducation),
                  _VisibilityChip(label: 'Compétences', isPublic: d.publicSkills),
                  _VisibilityChip(label: 'Langues', isPublic: d.publicLanguages),
                ]);
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Expériences',
            trailing: IconButton(
              onPressed: onAddExperience,
              icon: Icon(Icons.add, color: cs.primary),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: FutureBuilder<List<ProfileExperienceModel>>(
              future: expFuture,
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) return Text('Ajoutez votre première expérience.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                return Column(children: [
                  for (final e in items)
                    _EntityCard(
                      title: e.title,
                      subtitle: [e.organization, e.city].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • '),
                      trailing: _PeriodText(df: df, start: e.startDate, end: e.endDate),
                      onEdit: () => onEditExperience(e),
                      onDelete: () => onDeleteExperience(e),
                    ),
                ]);
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Formations',
            trailing: IconButton(
              onPressed: onAddEducation,
              icon: Icon(Icons.add, color: cs.primary),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: FutureBuilder<List<ProfileEducationModel>>(
              future: eduFuture,
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) return Text('Ajoutez votre cursus.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                return Column(children: [
                  for (final e in items)
                    _EntityCard(
                      title: e.institution,
                      subtitle: [e.degree, e.level].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • '),
                      trailing: Text('${e.startYear ?? ''} → ${e.endYear ?? ''}', style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      onEdit: () => onEditEducation(e),
                      onDelete: () => onDeleteEducation(e),
                    ),
                ]);
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Compétences',
            trailing: IconButton(
              onPressed: onAddSkill,
              icon: Icon(Icons.add, color: cs.primary),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: FutureBuilder<List<ProfileSkillModel>>(
              future: skillsFuture,
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) return Text('Ajoutez vos compétences.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in items)
                      _TagPill(
                        label: s.name,
                        meta: s.level,
                        onTap: () => onEditSkill(s),
                        onDelete: () => onDeleteSkill(s),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Langues',
            trailing: IconButton(
              onPressed: onAddLanguage,
              icon: Icon(Icons.add, color: cs.primary),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: FutureBuilder<List<ProfileLanguageModel>>(
              future: langsFuture,
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) return Text('Ajoutez les langues que vous parlez.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final l in items)
                      _TagPill(
                        label: l.name,
                        meta: l.level ?? '-',
                        onTap: () => onEditLanguage(l),
                        onDelete: () => onDeleteLanguage(l),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodText extends StatelessWidget {
  const _PeriodText({required this.df, required this.start, required this.end});
  final DateFormat df;
  final DateTime? start;
  final DateTime? end;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String fmt(DateTime? d) => d == null ? '' : df.format(d);
    final txt = '${fmt(start)} → ${end == null ? '...' : fmt(end)}';
    return Text(txt.trim(), style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant));
  }
}

// --- Onglet Documents ---
class _DocumentsTab extends StatefulWidget {
  const _DocumentsTab({required this.docsFuture, required this.onRefresh, required this.onUploadDoc, required this.onDeleteDoc});
  final Future<List<ProfileDocumentModel>> docsFuture;
  final VoidCallback onRefresh;
  final ValueChanged<String> onUploadDoc;
  final ValueChanged<ProfileDocumentModel> onDeleteDoc;

  @override
  State<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<_DocumentsTab> {
  String? _filter;
  static const _types = ['CIN', 'Passeport', 'Permis', 'Diplôme', 'Preuve adresse', 'Autre'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 120),
        children: [
          _SectionCard(
            title: 'Filtrer',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final t in _types)
                  ChoiceChip(
                    label: Text(t),
                    selected: _filter == t,
                    onSelected: (_) => setState(() => _filter = t),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Portefeuille documentaire',
            trailing: PopupMenuButton<String>(
              onSelected: widget.onUploadDoc,
              itemBuilder: (context) => [
                for (final t in _types) PopupMenuItem(value: t, child: Text('Uploader $t')),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.upload_file, color: cs.onPrimaryContainer, size: 18),
                  const SizedBox(width: 6),
                  Text('Upload', style: context.textStyles.labelLarge?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
            child: FutureBuilder<List<ProfileDocumentModel>>(
              future: widget.docsFuture,
              builder: (context, snap) {
                final all = snap.data ?? const [];
                final items = _filter == null ? all : all.where((d) => d.docType == _filter).toList(growable: false);
                if (items.isEmpty) return Text('Aucun document pour ce filtre.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                return Column(
                  children: [
                    for (final d in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _DocumentTile(doc: d, onDelete: () => widget.onDeleteDoc(d)),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'KYC avancé (CNI + Selfie)',
            child: Text(
              'Utilisez l’upload ci‑dessus pour déposer vos pièces d’identité. Le selfie sera ajouté dans une prochaine version.',
              style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Onglet Sécurité ---
class _SecurityTab extends StatelessWidget {
  const _SecurityTab({
    required this.secFuture,
    required this.secEventsFuture,
    required this.onRefresh,
    required this.onUpdateToggles,
  });
  final Future<ProfileSecuritySettingsModel?> secFuture;
  final Future<List<ProfileSecurityEventModel>> secEventsFuture;
  final VoidCallback onRefresh;
  final Future<void> Function({required bool biometricsEnabled, required bool twoFaEnabled}) onUpdateToggles;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final df = DateFormat('dd/MM HH:mm');
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 10, AppSpacing.md, 120),
        children: [
          _SectionCard(
            title: 'Paramètres de sécurité',
            child: FutureBuilder<ProfileSecuritySettingsModel?>(
              future: secFuture,
              builder: (context, snap) {
                final s = snap.data;
                final bio = s?.biometricsEnabled ?? false;
                final two = s?.twoFaEnabled ?? false;
                return Column(children: [
                  SwitchListTile.adaptive(
                    value: bio,
                    onChanged: (v) => onUpdateToggles(biometricsEnabled: v, twoFaEnabled: two),
                    title: Text('Biométrie', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    subtitle: Text('Face ID / Empreinte (local device)', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                  SwitchListTile.adaptive(
                    value: two,
                    onChanged: (v) => onUpdateToggles(biometricsEnabled: bio, twoFaEnabled: v),
                    title: Text('Double Authentification (2FA)', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                    subtitle: Text('Stocke le paramètre, intégration OTP à venir', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                ]);
              },
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Journal d’activité',
            child: FutureBuilder<List<ProfileSecurityEventModel>>(
              future: secEventsFuture,
              builder: (context, snap) {
                final ev = snap.data ?? const [];
                if (ev.isEmpty) return Text('Aucun événement.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant));
                return Column(
                  children: [
                    for (final e in ev)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
                              child: Icon(Icons.shield_outlined, color: cs.onPrimaryContainer),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(e.eventType, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text(df.format(e.createdAt), style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Widgets assistants
// ============================================================================

class ThixAvatar extends StatelessWidget {
  final double size;
  final String initials;

  const ThixAvatar({super.key, required this.size, required this.initials});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: Text(initials.isNotEmpty ? initials.substring(0, 1).toUpperCase() : 'T', style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.w900)),
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 6),
        Text(label, style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({required this.label, required this.value});
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final v = (value ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 130, child: Text(label, style: context.textStyles.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800))),
        Expanded(child: Text(v.isEmpty ? '—' : v, style: context.textStyles.bodyMedium)),
      ]),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.onEdit});
  final EmergencyContactModel contact;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtitle = [contact.relationship, contact.city].where((v) => (v ?? '').trim().isNotEmpty).map((v) => v!.trim()).join(' • ');
    return InkWell(
      onTap: onEdit,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.serviceCard),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.emergency_outlined, color: cs.onPrimaryContainer)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(contact.name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(contact.phone, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              if (subtitle.isNotEmpty) Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ]),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.serviceCard),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: iconColor ?? cs.onPrimaryContainer)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ),
          Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({required this.label, required this.isPublic});
  final String label;
  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = isPublic ? cs.primaryContainer : cs.surfaceContainerHighest;
    final fg = isPublic ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isPublic ? Icons.public : Icons.lock_outline, size: 16, color: fg),
        const SizedBox(width: 6),
        Text(label, style: context.textStyles.labelLarge?.copyWith(color: fg, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({required this.title, required this.subtitle, required this.trailing, required this.onEdit, required this.onDelete});
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle.isEmpty ? '—' : subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              trailing,
            ]),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
            child: Icon(Icons.more_horiz, color: cs.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.meta, required this.onTap, required this.onDelete});
  final String label;
  final String meta;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Text(meta, style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 6),
          InkWell(
            onTap: onDelete,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
          ),
        ]),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc, required this.onDelete});
  final ProfileDocumentModel doc;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color badgeBg;
    Color badgeFg;
    String label;
    switch (doc.status) {
      case 'verified':
        badgeBg = Colors.green.shade50;
        badgeFg = Colors.green.shade800;
        label = 'Vérifié';
        break;
      case 'rejected':
        badgeBg = Colors.red.shade50;
        badgeFg = Colors.red.shade800;
        label = 'Rejeté';
        break;
      default:
        badgeBg = Colors.orange.shade50;
        badgeFg = Colors.orange.shade800;
        label = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.folder_copy_outlined, color: cs.onPrimaryContainer)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(doc.docType, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(doc.fileUrl ?? '—', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(999)),
          child: Text(label, style: context.textStyles.labelSmall?.copyWith(color: badgeFg, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 10),
        IconButton(
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: cs.error),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ]),
    );
  }
}

// --- Calcul du THIX Score ---
class _ThixScore {
  static int compute({
    required ProfileDetailsModel? details,
    required List<ProfileExperienceModel>? exp,
    required List<ProfileEducationModel>? edu,
    required List<ProfileSkillModel>? skills,
    required List<ProfileLanguageModel>? langs,
  }) {
    int points = 0;
    bool has(String? v) => (v ?? '').trim().isNotEmpty;
    if (has(details?.fullName)) points += 10;
    if (has(details?.bio)) points += 10;
    if (has(details?.phone)) points += 10;
    if (has(details?.address) || has(details?.city)) points += 10;
    if (has(details?.nationality)) points += 10;
    if (exp != null && exp.isNotEmpty) points += 20;
    if (edu != null && edu.isNotEmpty) points += 10;
    if (skills != null && skills.isNotEmpty) points += 10;
    if (langs != null && langs.isNotEmpty) points += 10;
    return points.clamp(0, 100);
  }
}

// ============================================================================
// Feuilles d’édition
// ============================================================================

// --- Identity Editor ---
class IdentityEditorSheet extends StatefulWidget {
  const IdentityEditorSheet({super.key, required this.existing});
  final ProfileDetailsModel? existing;

  @override
  State<IdentityEditorSheet> createState() => _IdentityEditorSheetState();
}

class _IdentityEditorSheetState extends State<IdentityEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _nationality;
  late final TextEditingController _marital;
  late final TextEditingController _birthPlace;
  late final TextEditingController _father;
  late final TextEditingController _mother;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _name = TextEditingController(text: d?.fullName ?? '');
    _bio = TextEditingController(text: d?.bio ?? '');
    _phone = TextEditingController(text: d?.phone ?? '');
    _address = TextEditingController(text: d?.address ?? '');
    _city = TextEditingController(text: d?.city ?? '');
    _nationality = TextEditingController(text: d?.nationality ?? '');
    _marital = TextEditingController(text: d?.maritalStatus ?? '');
    _birthPlace = TextEditingController(text: d?.birthPlace ?? '');
    _father = TextEditingController(text: d?.fatherName ?? '');
    _mother = TextEditingController(text: d?.motherName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _nationality.dispose();
    _marital.dispose();
    _birthPlace.dispose();
    _father.dispose();
    _mother.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final uid = SupabaseClientProvider.client.auth.currentUser!.id;
    final base = widget.existing ??
        ProfileDetailsModel(
          userId: uid,
          fullName: null,
          bio: null,
          phone: null,
          address: null,
          city: null,
          nationality: null,
          maritalStatus: null,
          birthPlace: null,
          fatherName: null,
          motherName: null,
          accountStatus: 'THIX-PENDING',
          publicBio: true,
          publicExperiences: true,
          publicEducation: true,
          publicSkills: true,
          publicLanguages: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md + bottomInset),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text('Éditer profil', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nom complet'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
            const SizedBox(height: 10),
            TextFormField(controller: _bio, decoration: const InputDecoration(labelText: 'Bio'), maxLines: 3),
            const SizedBox(height: 10),
            TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone'), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Adresse')),
            const SizedBox(height: 10),
            TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'Ville')),
            const SizedBox(height: 10),
            TextFormField(controller: _nationality, decoration: const InputDecoration(labelText: 'Nationalité')),
            const SizedBox(height: 10),
            TextFormField(controller: _marital, decoration: const InputDecoration(labelText: 'État civil')),
            const SizedBox(height: 10),
            TextFormField(controller: _birthPlace, decoration: const InputDecoration(labelText: 'Lieu de naissance')),
            const SizedBox(height: 10),
            TextFormField(controller: _father, decoration: const InputDecoration(labelText: 'Nom du père')),
            const SizedBox(height: 10),
            TextFormField(controller: _mother, decoration: const InputDecoration(labelText: 'Nom de la mère')),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop(
                  base.copyWith(
                    fullName: _name.text.trim(),
                    bio: _bio.text.trim(),
                    phone: _phone.text.trim(),
                    address: _address.text.trim(),
                    city: _city.text.trim(),
                    nationality: _nationality.text.trim(),
                    maritalStatus: _marital.text.trim(),
                    birthPlace: _birthPlace.text.trim(),
                    fatherName: _father.text.trim(),
                    motherName: _mother.text.trim(),
                  ),
                );
              },
              icon: Icon(Icons.save, color: cs.onPrimary),
              label: Text('Enregistrer', style: TextStyle(color: cs.onPrimary)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// --- Visibility Editor ---
class VisibilityEditorSheet extends StatefulWidget {
  const VisibilityEditorSheet({super.key, required this.existing});
  final ProfileDetailsModel? existing;

  @override
  State<VisibilityEditorSheet> createState() => _VisibilityEditorSheetState();
}

class _VisibilityEditorSheetState extends State<VisibilityEditorSheet> {
  late bool _bio;
  late bool _exp;
  late bool _edu;
  late bool _skills;
  late bool _langs;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _bio = d?.publicBio ?? true;
    _exp = d?.publicExperiences ?? true;
    _edu = d?.publicEducation ?? true;
    _skills = d?.publicSkills ?? true;
    _langs = d?.publicLanguages ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final uid = SupabaseClientProvider.client.auth.currentUser!.id;
    final base = widget.existing ??
        ProfileDetailsModel(
          userId: uid,
          fullName: null,
          bio: null,
          phone: null,
          address: null,
          city: null,
          nationality: null,
          maritalStatus: null,
          birthPlace: null,
          fatherName: null,
          motherName: null,
          accountStatus: 'THIX-PENDING',
          publicBio: true,
          publicExperiences: true,
          publicEducation: true,
          publicSkills: true,
          publicLanguages: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md + bottomInset),
      child: ListView(shrinkWrap: true, children: [
        Text('Visibilité du profil public', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Chaque section peut être rendue visible ou privée.', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        SwitchListTile.adaptive(value: _bio, onChanged: (v) => setState(() => _bio = v), title: const Text('Bio')),
        SwitchListTile.adaptive(value: _exp, onChanged: (v) => setState(() => _exp = v), title: const Text('Expériences')),
        SwitchListTile.adaptive(value: _edu, onChanged: (v) => setState(() => _edu = v), title: const Text('Formations')),
        SwitchListTile.adaptive(value: _skills, onChanged: (v) => setState(() => _skills = v), title: const Text('Compétences')),
        SwitchListTile.adaptive(value: _langs, onChanged: (v) => setState(() => _langs = v), title: const Text('Langues')),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(base.copyWith(publicBio: _bio, publicExperiences: _exp, publicEducation: _edu, publicSkills: _skills, publicLanguages: _langs));
          },
          icon: Icon(Icons.save, color: cs.onPrimary),
          label: Text('Enregistrer', style: TextStyle(color: cs.onPrimary)),
        ),
      ]),
    );
  }
}

// --- Emergency Contact Editor ---
class _EmergencyContactDraft {
  const _EmergencyContactDraft({required this.name, required this.phone, required this.relationship, required this.city});
  final String name;
  final String phone;
  final String? relationship;
  final String? city;
}

class EmergencyContactEditorSheet extends StatefulWidget {
  const EmergencyContactEditorSheet({super.key, required this.existing});
  final EmergencyContactModel? existing;

  @override
  State<EmergencyContactEditorSheet> createState() => _EmergencyContactEditorSheetState();
}

class _EmergencyContactEditorSheetState extends State<EmergencyContactEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _rel;
  late final TextEditingController _city;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _rel = TextEditingController(text: c?.relationship ?? '');
    _city = TextEditingController(text: c?.city ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _rel.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md + bottomInset),
      child: Form(
        key: _formKey,
        child: ListView(shrinkWrap: true, children: [
          Text(widget.existing == null ? 'Ajouter un contact' : 'Modifier le contact', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nom'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
          const SizedBox(height: 10),
          TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Téléphone'), keyboardType: TextInputType.phone, validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
          const SizedBox(height: 10),
          TextFormField(controller: _rel, decoration: const InputDecoration(labelText: 'Lien (ex: Frère, Parent)')),
          const SizedBox(height: 10),
          TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'Ville')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(_EmergencyContactDraft(name: _name.text.trim(), phone: _phone.text.trim(), relationship: _rel.text.trim(), city: _city.text.trim()));
            },
            icon: Icon(Icons.save, color: cs.onPrimary),
            label: Text('Enregistrer', style: TextStyle(color: cs.onPrimary)),
          ),
        ]),
      ),
    );
  }
}

// --- Experience Editor ---
class ExperienceEditorSheet extends StatefulWidget {
  const ExperienceEditorSheet({super.key, required this.existing});
  final ProfileExperienceModel? existing;

  @override
  State<ExperienceEditorSheet> createState() => _ExperienceEditorSheetState();
}

class _ExperienceEditorSheetState extends State<ExperienceEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _org;
  late final TextEditingController _sector;
  late final TextEditingController _city;
  late final TextEditingController _missions;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _org = TextEditingController(text: e?.organization ?? '');
    _sector = TextEditingController(text: e?.sector ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _missions = TextEditingController(text: e?.missions ?? '');
    _start = e?.startDate;
    _end = e?.endDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _org.dispose();
    _sector.dispose();
    _city.dispose();
    _missions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final uid = SupabaseClientProvider.client.auth.currentUser!.id;
    final now = DateTime.now();
    final base = widget.existing ??
        ProfileExperienceModel(
          id: '',
          userId: uid,
          title: '',
          organization: null,
          sector: null,
          city: null,
          startDate: null,
          endDate: null,
          missions: null,
          attachments: const [],
          createdAt: now,
          updatedAt: now,
        );

    String fmt(DateTime? d) => d == null ? '—' : DateFormat('dd/MM/yyyy').format(d);

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md + bottomInset),
      child: Form(
        key: _formKey,
        child: ListView(shrinkWrap: true, children: [
          Text(widget.existing == null ? 'Ajouter expérience' : 'Modifier expérience', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Titre'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
          const SizedBox(height: 10),
          TextFormField(controller: _org, decoration: const InputDecoration(labelText: 'Organisation')),
          const SizedBox(height: 10),
          TextFormField(controller: _sector, decoration: const InputDecoration(labelText: 'Secteur')),
          const SizedBox(height: 10),
          TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'Ville')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(context: context, firstDate: DateTime(1950), lastDate: DateTime(2100), initialDate: _start ?? DateTime(now.year, 1, 1));
                  if (picked == null) return;
                  setState(() => _start = picked);
                },
                child: Text('Début: ${fmt(_start)}'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await showDatePicker(context: context, firstDate: DateTime(1950), lastDate: DateTime(2100), initialDate: _end ?? DateTime(now.year, 12, 31));
                  if (picked == null) return;
                  setState(() => _end = picked);
                },
                child: Text('Fin: ${fmt(_end)}'),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextFormField(controller: _missions, decoration: const InputDecoration(labelText: 'Missions'), maxLines: 4),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(
                base.copyWith(
                  title: _title.text.trim(),
                  organization: _org.text.trim(),
                  sector: _sector.text.trim(),
                  city: _city.text.trim(),
                  startDate: _start,
                  endDate: _end,
                  missions: _missions.text.trim(),
                ),
              );
            },
            icon: Icon(Icons.save, color: cs.onPrimary),
            label: Text('Enregistrer', style: TextStyle(color: cs.onPrimary)),
          ),
        ]),
      ),
    );
  }
}

// --- Education Editor ---
class EducationEditorSheet extends StatefulWidget {
  const EducationEditorSheet({super.key, required this.existing});
  final ProfileEducationModel? existing;

  @override
  State<EducationEditorSheet> createState() => _EducationEditorSheetState();
}

class _EducationEditorSheetState extends State<EducationEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _inst;
  late final TextEditingController _degree;
  late final TextEditingController _level;
  late final TextEditingController _startYear;
  late final TextEditingController _endYear;
  late final TextEditingController _desc;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _inst = TextEditingController(text: e?.institution ?? '');
    _degree = TextEditingController(text: e?.degree ?? '');
    _level = TextEditingController(text: e?.level ?? '');
    _startYear = TextEditingController(text: e?.startYear?.toString() ?? '');
    _endYear = TextEditingController(text: e?.endYear?.toString() ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
  }

  @override
  void dispose() {
    _inst.dispose();
    _degree.dispose();
    _level.dispose();
    _startYear.dispose();
    _endYear.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final uid = SupabaseClientProvider.client.auth.currentUser!.id;
    final now = DateTime.now();
    final base = widget.existing ??
        ProfileEducationModel(
          id: '',
          userId: uid,
          institution: '',
          degree: null,
          level: null,
          startYear: null,
          endYear: null,
          description: null,
          attachments: const [],
          createdAt: now,
          updatedAt: now,
        );

    int? year(String v) {
      final t = v.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md + bottomInset),
      child: Form(
        key: _formKey,
        child: ListView(shrinkWrap: true, children: [
          Text(widget.existing == null ? 'Ajouter formation' : 'Modifier formation', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextFormField(controller: _inst, decoration: const InputDecoration(labelText: 'Établissement'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
          const SizedBox(height: 10),
          TextFormField(controller: _degree, decoration: const InputDecoration(labelText: 'Diplôme')),
          const SizedBox(height: 10),
          TextFormField(controller: _level, decoration: const InputDecoration(labelText: 'Niveau (Primaire/Supérieur)')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextFormField(controller: _startYear, decoration: const InputDecoration(labelText: 'Année début'), keyboardType: TextInputType.number)),
            const SizedBox(width: 10),
            Expanded(child: TextFormField(controller: _endYear, decoration: const InputDecoration(labelText: 'Année fin'), keyboardType: TextInputType.number)),
          ]),
          const SizedBox(height: 10),
          TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(
                base.copyWith(
                  institution: _inst.text.trim(),
                  degree: _degree.text.trim(),
                  level: _level.text.trim(),
                  startYear: year(_startYear.text),
                  endYear: year(_endYear.text),
                  description: _desc.text.trim(),
                ),
              );
            },
            icon: Icon(Icons.save, color: cs.onPrimary),
            label: Text('Enregistrer', style: TextStyle(color: cs.onPrimary)),
          ),
        ]),
      ),
    );
  }
}

// --- Skill Editor ---
class SkillEditorSheet extends StatefulWidget {
  const SkillEditorSheet({super.key, required this.existing});
  final ProfileSkillModel? existing;

  @override
  State<SkillEditorSheet> createState() => _SkillEditorSheetState();
}

class _SkillEditorSheetState extends State<SkillEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _desc;
  String _level = 'beginner';
  static const _levels = ['beginner', 'intermediate', 'advanced', 'expert'];

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _name = TextEditingController(text: s?.name ?? '');
    _desc = TextEditingController(text: s?.description ?? '');
    _level = s?.level ?? 'beginner';
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final uid = SupabaseClientProvider.client.auth.currentUser!.id;
    final now = DateTime.now();
    final base = widget.existing ??
        ProfileSkillModel(
          id: '',
          userId: uid,
          name: '',
          level: 'beginner',
          description: null,
          createdAt: now,
          updatedAt: now,
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md + bottomInset),
      child: Form(
        key: _formKey,
        child: ListView(shrinkWrap: true, children: [
          Text(widget.existing == null ? 'Ajouter compétence' : 'Modifier compétence', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Compétence'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _level,
            items: [for (final l in _levels) DropdownMenuItem(value: l, child: Text(l))],
            onChanged: (v) => setState(() => _level = v ?? _level),
            decoration: const InputDecoration(labelText: 'Niveau'),
          ),
          const SizedBox(height: 10),
          TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(base.copyWith(name: _name.text.trim(), level: _level, description: _desc.text.trim()));
            },
            icon: Icon(Icons.save, color: cs.onPrimary),
            label: Text('Enregistrer', style: TextStyle(color: cs.onPrimary)),
          ),
        ]),
      ),
    );
  }
}

// --- Language Editor ---
class LanguageEditorSheet extends StatefulWidget {
  const LanguageEditorSheet({super.key, required this.existing});
  final ProfileLanguageModel? existing;

  @override
  State<LanguageEditorSheet> createState() => _LanguageEditorSheetState();
}

class _LanguageEditorSheetState extends State<LanguageEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _level;

  @override
  void initState() {
    super.initState();
    final l = widget.existing;
    _name = TextEditingController(text: l?.name ?? '');
    _level = TextEditingController(text: l?.level ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final uid = SupabaseClientProvider.client.auth.currentUser!.id;
    final now = DateTime.now();
    final base = widget.existing ??
        ProfileLanguageModel(
          id: '',
          userId: uid,
          name: '',
          level: null,
          createdAt: now,
          updatedAt: now,
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md + bottomInset),
      child: Form(
        key: _formKey,
        child: ListView(shrinkWrap: true, children: [
          Text(widget.existing == null ? 'Ajouter langue' : 'Modifier langue', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Langue'), validator: (v) => (v ?? '').trim().isEmpty ? 'Requis' : null),
          const SizedBox(height: 10),
          TextFormField(controller: _level, decoration: const InputDecoration(labelText: 'Niveau (ex: B2, Courant)')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              if (!(_formKey.currentState?.validate() ?? false)) return;
              Navigator.of(context).pop(base.copyWith(name: _name.text.trim(), level: _level.text.trim()));
            },
            icon: Icon(Icons.save, color: cs.onPrimary),
            label: Text('Enregistrer', style: TextStyle(color: cs.onPrimary)),
          ),
        ]),
      ),
    );
  }
}

// --- Notifications Sheet ---
class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Notifications', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text('Centre de notifications (version minimale).', style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          _MiniNotifTile(icon: Icons.verified_outlined, title: 'Vérification', subtitle: 'Complétez vos documents pour accélérer le badge.'),
          _MiniNotifTile(icon: Icons.picture_as_pdf_outlined, title: 'CV', subtitle: 'Votre CV numérique est prêt à être exporté.'),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text('Fermer', style: TextStyle(color: cs.primary)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _MiniNotifTile extends StatelessWidget {
  const _MiniNotifTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: cs.outline.withValues(alpha: 0.14))),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: cs.onPrimaryContainer)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ),
        ]),
      ),
    );
  }
}
