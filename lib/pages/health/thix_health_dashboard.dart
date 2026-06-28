// 📁 lib/pages/health/thix_health_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thix_central/auth/auth_manager.dart';
import 'package:thix_central/health/thix_role_controller.dart';
import 'package:thix_central/health/thix_ui_feedback.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/nav.dart';
import 'package:thix_central/pages/health/health_role_workspaces.dart';
import 'package:thix_central/theme.dart';
import 'package:permission_handler/permission_handler.dart';

// --- Providers (à définir ailleurs, mais importés ici) ---
import '../../data/repositories/patient_repository.dart';
import '../../data/repositories/symptom_repository.dart';
import '../../data/repositories/constant_repository.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/medication_repository.dart';
import '../../services/ai/openai_service.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';

// Pour simplifier, on définit les providers ici (normalement dans un fichier séparé)
final patientRepositoryProvider = Provider((ref) => PatientRepository());
final symptomRepositoryProvider = Provider((ref) => SymptomRepository());
final constantRepositoryProvider = Provider((ref) => ConstantRepository());
final appointmentRepositoryProvider = Provider((ref) => AppointmentRepository());
final medicationRepositoryProvider = Provider((ref) => MedicationRepository());
final openAIServiceProvider = Provider((ref) => OpenAIService());
final storageServiceProvider = Provider((ref) => StorageService());
final notificationServiceProvider = Provider((ref) => NotificationService());

class ThixHealthDashboardPage extends ConsumerStatefulWidget {
  const ThixHealthDashboardPage({super.key});

  @override
  ConsumerState<ThixHealthDashboardPage> createState() => _ThixHealthDashboardPageState();
}

class _ThixHealthDashboardPageState extends ConsumerState<ThixHealthDashboardPage> {
  final _roleController = ThixRoleController.instance;
  final _authManager = SupabaseAuthManager();
  final _permissionKeys = ['notifications', 'location', 'camera', 'storage'];
  Map<String, bool> _permissions = {};
  bool _onboardingShown = false;

  @override
  void initState() {
    super.initState();
    _loadOnboarding();
    _requestPermissions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = SupabaseClientProvider.clientOrNull?.auth.currentUser;
      _roleController.syncFromSession(appMetadata: user?.appMetadata, userMetadata: user?.userMetadata, email: user?.email);
      if (!_onboardingShown) {
        _showOnboarding();
      }
    });
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.notification,
      Permission.location,
      Permission.camera,
      Permission.storage,
    ].request();
    setState(() {
      _permissions = {
        'notifications': statuses[Permission.notification]?.isGranted ?? false,
        'location': statuses[Permission.location]?.isGranted ?? false,
        'camera': statuses[Permission.camera]?.isGranted ?? false,
        'storage': statuses[Permission.storage]?.isGranted ?? false,
      };
    });
    // Sauvegarder dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    for (final entry in _permissions.entries) {
      await prefs.setBool('health_perm_${entry.key}', entry.value);
    }
  }

  Future<void> _loadOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = <String, bool>{};
    for (final key in _permissionKeys) {
      saved[key] = prefs.getBool('health_perm_$key') ?? false;
    }
    final seen = prefs.getBool('health_onboarding_seen') ?? false;
    if (!mounted) return;
    setState(() {
      _permissions = saved;
      _onboardingShown = seen;
    });
  }

  Future<void> _showOnboarding({bool force = false}) async {
    if (!mounted || (_onboardingShown && !force)) return;
    setState(() => _onboardingShown = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_onboarding_seen', true);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _OnboardingSheet(),
    );
  }

  Future<void> _togglePermission(String key, bool value) async {
    // Appeler la vraie permission
    PermissionStatus status;
    switch (key) {
      case 'notifications':
        status = await Permission.notification.request();
        break;
      case 'location':
        status = await Permission.location.request();
        break;
      case 'camera':
        status = await Permission.camera.request();
        break;
      case 'storage':
        status = await Permission.storage.request();
        break;
      default:
        return;
    }
    final granted = status.isGranted;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_perm_$key', granted);
    if (!mounted) return;
    setState(() {
      _permissions = {..._permissions, key: granted};
    });
  }

  Future<void> _resetPassword() async {
    final user = SupabaseClientProvider.clientOrNull?.auth.currentUser;
    final initialEmail = user?.email ?? '';
    final controller = TextEditingController(text: initialEmail);
    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Email', hintText: 'prenom@exemple.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: const Text('Envoyer')),
        ],
      ),
    );
    if (confirmed == null || confirmed.isEmpty) return;
    try {
      await _authManager.resetPassword(email: confirmed, context: context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lien envoyé à $confirmed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _signOut() async {
    try {
      await _authManager.signOut();
      if (!mounted) return;
      _roleController.selectRole(ThixRole.patient, manual: false);
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur de déconnexion: $e')));
    }
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
                        _DashboardTopBar(
                          greetingName: greetingName,
                          role: role,
                          onBack: () => context.go(AppRoutes.home),
                        ),
                        const SizedBox(height: 18),
                        _RoleSwitcher(controller: _roleController),
                        const SizedBox(height: 14),
                        _AccessBanner(
                          role: role,
                          email: email,
                          permissions: _permissions,
                          onTogglePermission: _togglePermission,
                          onResetPassword: _resetPassword,
                          onSignOut: _signOut,
                          onBack: () => context.go(AppRoutes.home),
                          onShowOnboarding: () => _showOnboarding(force: true),
                          hasManualSelection: _roleController.hasManualSelection,
                          verifiedRole: _roleController.verifiedRole,
                          detectedRoles: _roleController.availableRoles,
                        ),
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
                        const SizedBox(height: 20),
                        // Workspace réel avec les données
                        HealthRoleWorkspace(
                          role: role,
                          permissions: _permissions,
                        ),
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

// Les widgets _DashboardTopBar, _RoleSwitcher, _HeroBanner, etc. sont inchangés.
// Pour gagner de la place, on les garde identiques.
// ... (les widgets de l'interface restent identiques, on ne les répète pas ici)
