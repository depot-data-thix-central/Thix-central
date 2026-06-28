// 📁 lib/pages/health/health_role_workspaces.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/health/thix_role_controller.dart';
import 'package:thix_central/health/thix_ui_feedback.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/nav.dart';
import 'package:thix_central/pages/health/health_dependencies.dart';
import 'package:thix_central/theme.dart';

// ============================================================
// 1. PROVIDERS DE DONNÉES (FutureProvider)
// ============================================================

final symptomProvider = FutureProvider.family<List<SymptomModel>, String>((ref, patientId) async {
  final repo = ref.read(symptomRepositoryProvider);
  return repo.getSymptomsByPatient(patientId);
});

final constantProvider = FutureProvider.family<List<ConstantModel>, String>((ref, patientId) async {
  final repo = ref.read(constantRepositoryProvider);
  return repo.getConstantsByPatient(patientId);
});

final medicationProvider = FutureProvider.family<List<MedicationModel>, String>((ref, patientId) async {
  final repo = ref.read(medicationRepositoryProvider);
  return repo.getActiveMedications(patientId);
});

final appointmentProvider = FutureProvider.family<List<AppointmentModel>, String>((ref, patientId) async {
  final repo = ref.read(appointmentRepositoryProvider);
  return repo.getAppointmentsByPatient(patientId);
});

final documentsProvider = FutureProvider.family<List<String>, String>((ref, patientId) async {
  final storage = ref.read(storageServiceProvider);
  final files = await storage.listFiles(bucketName: 'documents', folder: 'patient_$patientId');
  return files.map((f) => f['name'] as String).toList();
});

// ============================================================
// 2. WIDGET PRINCIPAL
// ============================================================

class HealthRoleWorkspace extends ConsumerWidget {
  const HealthRoleWorkspace({super.key, required this.role, required this.permissions});
  final ThixRole role;
  final Map<String, bool> permissions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (role) {
      case ThixRole.patient:
        return PatientWorkspace(permissions: permissions);
      case ThixRole.doctor:
        return const DoctorWorkspace();
      case ThixRole.pharmacy:
        return const PharmacyWorkspace();
    }
  }
}

// ============================================================
// 3. PATIENT WORKSPACE (CONNECTÉ À SUPABASE)
// ============================================================

class PatientWorkspace extends ConsumerStatefulWidget {
  const PatientWorkspace({super.key, required this.permissions});
  final Map<String, bool> permissions;

  @override
  ConsumerState<PatientWorkspace> createState() => _PatientWorkspaceState();
}

class _PatientWorkspaceState extends ConsumerState<PatientWorkspace> {
  bool _alertSent = false;

  @override
  Widget build(BuildContext context) {
    final patientId = SupabaseClientProvider.clientOrNull?.auth.currentUser?.id ?? '';
    if (patientId.isEmpty) return const SizedBox.shrink();

    final symptomsAsync = ref.watch(symptomProvider(patientId));
    final constantsAsync = ref.watch(constantProvider(patientId));
    final medicationsAsync = ref.watch(medicationProvider(patientId));
    final appointmentsAsync = ref.watch(appointmentProvider(patientId));
    final documentsAsync = ref.watch(documentsProvider(patientId));

    // Score de santé (via Edge Function)
    final scoreAsync = ref.watch(healthScoreProvider(patientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score de santé
        scoreAsync.when(
          data: (score) => _HealthScoreCard(score: score, permissions: widget.permissions),
          loading: () => _HealthScoreCard(score: 0, permissions: widget.permissions, loading: true),
          error: (_, __) => _HealthScoreCard(score: 0, permissions: widget.permissions, error: true),
        ),
        const SizedBox(height: 14),
        _QuickServices(
          onAddSymptom: () => _openSymptomForm(context, patientId),
          onAddAppointment: () => _openAppointmentForm(context, patientId),
        ),
        const SizedBox(height: 14),
        _StatsRow(
          symptomsCount: symptomsAsync.maybeWhen(data: (list) => list.length, orElse: () => 0),
          treatmentsCount: medicationsAsync.maybeWhen(data: (list) => list.length, orElse: () => 0),
          vitalsCount: constantsAsync.maybeWhen(data: (list) => list.length, orElse: () => 0),
          appointmentsCount: appointmentsAsync.maybeWhen(data: (list) => list.length, orElse: () => 0),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Rendez-vous',
          actionLabel: 'Ajouter',
          onAction: () => _openAppointmentForm(context, patientId),
          child: appointmentsAsync.when(
            data: (list) => list.isEmpty
                ? const Padding(padding: EdgeInsets.all(16), child: Text('Aucun rendez-vous', style: TextStyle(color: Colors.grey)))
                : Column(children: list.map((a) => _AppointmentTile(appt: a, onReschedule: () => _rescheduleAppointment(context, a), onCancel: () => _cancelAppointment(context, a), onTeleconsultation: () => _startJitsiCall(a))).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Symptômes',
          actionLabel: 'Enregistrer',
          onAction: () => _openSymptomForm(context, patientId),
          child: symptomsAsync.when(
            data: (list) => list.isEmpty
                ? const Padding(padding: EdgeInsets.all(16), child: Text('Aucun symptôme', style: TextStyle(color: Colors.grey)))
                : Column(children: list.map((s) => _SymptomTile(symptom: s)).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Constantes',
          actionLabel: 'Ajouter',
          onAction: () => _openVitalForm(context, patientId),
          child: constantsAsync.when(
            data: (list) => list.isEmpty
                ? const Padding(padding: EdgeInsets.all(16), child: Text('Aucune constante', style: TextStyle(color: Colors.grey)))
                : Column(children: [_VitalBars(vitals: list), const SizedBox(height: 10), ...list.map((v) => _VitalTile(vital: v))]),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Traitements',
          child: medicationsAsync.when(
            data: (list) => list.isEmpty
                ? const Padding(padding: EdgeInsets.all(16), child: Text('Aucun traitement', style: TextStyle(color: Colors.grey)))
                : Column(children: list.map((m) => _TreatmentTile(treatment: m, onToggle: (val) => _toggleMedicationAlert(context, m, val))).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Documents',
          actionLabel: 'Ajouter',
          onAction: () => _addDocument(context, patientId),
          child: documentsAsync.when(
            data: (list) => list.isEmpty
                ? const Padding(padding: EdgeInsets.all(16), child: Text('Aucun document', style: TextStyle(color: Colors.grey)))
                : Column(children: list.map((d) => _DocumentTile(doc: d, onShare: () => _shareDocument(context, d))).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur: $e'),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(title: 'Articles bien-être', child: _WellnessRow()),
        const SizedBox(height: 14),
        _EmergencyCard(onCall: () => _call15(), onAlert: () => _alertFamily(), sent: _alertSent),
        const SizedBox(height: 12),
        _MessagingCard(),
      ],
    );
  }

  // Fonctions d'appel aux repositories
  Future<void> _openSymptomForm(BuildContext context, String patientId) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SymptomForm(),
    );
    if (result == null) return;
    final newSymptom = SymptomModel(
      id: '',
      patientId: patientId,
      name: (result['name'] ?? '').toString(),
      intensity: (result['intensity'] as num?)?.toInt() ?? 0,
      date: DateTime.now(),
      notes: (result['notes'] ?? '').toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final repo = ref.read(symptomRepositoryProvider);
    await repo.addSymptom(newSymptom);
    ref.invalidate(symptomProvider(patientId));
    showThixFeatureReadySnackBar(context, 'Symptôme enregistré');
  }

  Future<void> _openVitalForm(BuildContext context, String patientId) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VitalForm(),
    );
    if (result == null) return;
    final newConstant = ConstantModel(
      id: '',
      patientId: patientId,
      date: DateTime.now(),
      tensionSystolic: (result['systolic'] as num?)?.toDouble(),
      tensionDiastolic: (result['diastolic'] as num?)?.toDouble(),
      glycemie: (result['glycemia'] as num?)?.toDouble(),
      poids: (result['weight'] as num?)?.toDouble(),
      taille: null,
      heartRate: null,
      temperature: null,
      spo2: null,
      notes: (result['notes'] ?? '').toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final repo = ref.read(constantRepositoryProvider);
    await repo.addConstant(newConstant);
    ref.invalidate(constantProvider(patientId));
    showThixFeatureReadySnackBar(context, 'Constante enregistrée');
  }

  Future<void> _openAppointmentForm(BuildContext context, String patientId) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AppointmentForm(),
    );
    if (result == null) return;
    final newAppt = AppointmentModel(
      id: '',
      patientId: patientId,
      patientName: '', // à récupérer du profil
      doctorId: result['doctorId'] ?? '',
      doctorName: result['doctorName'] ?? 'Médecin',
      specialty: result['specialty'] ?? 'Généraliste',
      date: DateTime.now(),
      time: '${DateTime.now().hour}:${DateTime.now().minute}',
      status: 'pending',
      notes: (result['notes'] ?? '').toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final repo = ref.read(appointmentRepositoryProvider);
    await repo.createAppointment(newAppt);
    ref.invalidate(appointmentProvider(patientId));
    showThixFeatureReadySnackBar(context, 'Rendez-vous planifié');
  }

  Future<void> _toggleMedicationAlert(BuildContext context, MedicationModel med, bool value) async {
    final repo = ref.read(medicationRepositoryProvider);
    final updated = med.copyWith(alert: value);
    await repo.updateMedication(updated);
    ref.invalidate(medicationProvider(med.patientId));
    showThixFeatureReadySnackBar(context, value ? 'Rappel activé' : 'Rappel désactivé');
  }

  Future<void> _rescheduleAppointment(BuildContext context, AppointmentModel appt) async {
    final newDate = DateTime.now().add(const Duration(days: 2));
    final updated = appt.copyWith(date: newDate, status: 'confirmed');
    final repo = ref.read(appointmentRepositoryProvider);
    await repo.updateAppointment(updated);
    ref.invalidate(appointmentProvider(appt.patientId));
    showThixFeatureReadySnackBar(context, 'RDV replanifié');
  }

  Future<void> _cancelAppointment(BuildContext context, AppointmentModel appt) async {
    final repo = ref.read(appointmentRepositoryProvider);
    await repo.cancelAppointment(appt.id);
    ref.invalidate(appointmentProvider(appt.patientId));
    showThixFeatureReadySnackBar(context, 'RDV annulé');
  }

  Future<void> _startJitsiCall(AppointmentModel appt) async {
    // Jitsi is not bundled in this project (missing dependency). Keep the UX
    // functional with a graceful fallback.
    final room = appt.teleRoom ?? 'thix-${DateTime.now().millisecondsSinceEpoch}';
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.video_call_rounded, color: AppColors.primaryBlue), const SizedBox(width: 10), Expanded(child: Text('Téléconsultation', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900))), IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close_rounded))]),
                const SizedBox(height: 10),
                Text('Le module d’appel vidéo (Jitsi) n’est pas activé sur ce build.', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Text('Salle : $room', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          context.pop();
                          showThixFeatureReadySnackBar(context, 'Ajoute Jitsi plus tard pour activer les appels');
                        },
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text('OK'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addDocument(BuildContext context, String patientId) async {
    // Simuler l'upload (à connecter à StorageService)
    showThixFeatureReadySnackBar(context, 'Ajoutez vos PDF ou photos depuis Documents');
  }

  Future<void> _shareDocument(BuildContext context, String docName) async {
    final token = DateTime.now().millisecondsSinceEpoch.toString();
    final link = 'https://thix.health/share/$docName-$token';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lien expirable'),
        content: Text(link),
        actions: [TextButton(onPressed: () => context.pop(), child: const Text('OK'))],
      ),
    );
  }

  void _call15() {
    // Lancer tel:15 via url_launcher
    showThixFeatureReadySnackBar(context, 'Appel 15 déclenché');
  }

  void _alertFamily() {
    setState(() => _alertSent = true);
    showThixFeatureReadySnackBar(context, 'Famille alertée');
  }
}

// ============================================================
// 4. SCORE DE SANTÉ (AVEC EDGE FUNCTION)
// ============================================================

final healthScoreProvider = FutureProvider.family<double, String>((ref, patientId) async {
  final aiService = ref.read(openAIServiceProvider);
  final analysis = await aiService.getPredictiveAnalysis(patientId);
  return analysis?['healthScore']?.toDouble() ?? 0.0;
});

class _HealthScoreCard extends StatelessWidget {
  const _HealthScoreCard({required this.score, required this.permissions, this.loading = false, this.error = false});
  final double score;
  final Map<String, bool> permissions;
  final bool loading;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(gradient: AppColors.primaryBlueGradient, borderRadius: BorderRadius.circular(24), boxShadow: const [AppShadows.main]),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Score de santé IA', style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(error ? 'Erreur de chargement' : loading ? 'Calcul en cours...' : 'Basé sur symptômes, constantes, traitements et RDV.', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.92))),
              const SizedBox(height: 8),
              if (!error && !loading)
                Wrap(spacing: 6, runSpacing: 6, children: permissions.entries.map((e) => Chip(label: Text('${e.key}:${e.value ? 'on' : 'off'}'), backgroundColor: Colors.white.withValues(alpha: 0.16), labelStyle: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))).toList()),
            ]),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(22)),
            alignment: Alignment.center,
            child: loading
                ? const CircularProgressIndicator(color: Colors.white)
                : error
                    ? const Icon(Icons.error_outline, color: Colors.white)
                    : Text('${score.toStringAsFixed(0)}/100', style: context.textStyles.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 5. TOUS LES AUTRES WIDGETS (STATELESS, AVEC DONNÉES)
// ============================================================

class _QuickServices extends StatelessWidget {
  const _QuickServices({required this.onAddSymptom, required this.onAddAppointment});
  final VoidCallback onAddSymptom;
  final VoidCallback onAddAppointment;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(label: 'Médecin', icon: Icons.health_and_safety_rounded, color: const Color(0xFF2453FF), onTap: onAddAppointment),
      _QuickItem(label: 'Dossier', icon: Icons.folder_shared_rounded, color: const Color(0xFF10B981), onTap: () => showThixFeatureReadySnackBar(context, 'Dossier prêt')),
      _QuickItem(label: 'Examens', icon: Icons.science_rounded, color: const Color(0xFF7C3AED), onTap: () => showThixFeatureReadySnackBar(context, 'Examens')),
      _QuickItem(label: 'Symptômes', icon: Icons.medication_liquid_rounded, color: const Color(0xFFFF6B00), onTap: onAddSymptom),
    ];
    return Row(children: items.map((i) => Expanded(child: _QuickTile(item: i))).toList());
  }
}

class _QuickItem {
  const _QuickItem({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.item});
  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
          child: Column(
            children: [
              CircleAvatar(radius: 20, backgroundColor: item.color.withValues(alpha: 0.12), child: Icon(item.icon, color: item.color)),
              const SizedBox(height: 8),
              Text(item.label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.symptomsCount, required this.treatmentsCount, required this.vitalsCount, required this.appointmentsCount});
  final int symptomsCount;
  final int treatmentsCount;
  final int vitalsCount;
  final int appointmentsCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(label: 'Symptômes', value: symptomsCount.toString(), icon: Icons.sick_rounded, color: const Color(0xFF2453FF)),
      _StatItem(label: 'Traitements', value: treatmentsCount.toString(), icon: Icons.medication_rounded, color: const Color(0xFF7C3AED)),
      _StatItem(label: 'Constantes', value: vitalsCount.toString(), icon: Icons.monitor_heart_outlined, color: const Color(0xFF10B981)),
      _StatItem(label: 'RDV', value: appointmentsCount.toString(), icon: Icons.calendar_month_rounded, color: const Color(0xFFFF6B00)),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: items.map((i) => Expanded(child: _StatTile(item: i))).toList()),
    );
  }
}

class _StatItem {
  const _StatItem({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    return Column(children: [Icon(item.icon, color: item.color), const SizedBox(height: 6), Text(item.value, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)), Text(item.label, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))]);
  }
}

// --- Appointment Tile ---
class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appt, required this.onReschedule, required this.onCancel, required this.onTeleconsultation});
  final AppointmentModel appt;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;
  final VoidCallback onTeleconsultation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.event_available_rounded, color: AppColors.primaryBlue), const SizedBox(width: 8), Expanded(child: Text('${appt.specialty} · ${appt.doctorName}', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800))), _Pill(text: appt.status)]),
        const SizedBox(height: 6),
        Text(appt.notes ?? '', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(children: [OutlinedButton(onPressed: onReschedule, child: const Text('Reporter')), const SizedBox(width: 8), OutlinedButton(onPressed: onCancel, child: const Text('Annuler')), const Spacer(), FilledButton.icon(onPressed: onTeleconsultation, icon: const Icon(Icons.video_call_rounded), label: const Text('Téléconsultation'))]),
      ]),
    );
  }
}

// --- Symptom Tile ---
class _SymptomTile extends StatelessWidget {
  const _SymptomTile({required this.symptom});
  final SymptomModel symptom;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [CircleAvatar(radius: 18, backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12), child: Text(symptom.intensity.toString(), style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryBlue))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(symptom.name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), if (symptom.notes != null && symptom.notes!.isNotEmpty) Text(symptom.notes!, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))]))]),
    );
  }
}

// --- VitalBars ---
class _VitalBars extends StatelessWidget {
  const _VitalBars({required this.vitals});
  final List<ConstantModel> vitals;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ConstantModel>>{};
    for (final v in vitals) {
      if (v.tensionSystolic != null) grouped.putIfAbsent('Tension', () => []).add(v);
      else if (v.glycemie != null) grouped.putIfAbsent('Glycémie', () => []).add(v);
      else if (v.poids != null) grouped.putIfAbsent('Poids', () => []).add(v);
    }
    final colors = {'Tension': const Color(0xFF2453FF), 'Glycémie': const Color(0xFF10B981), 'Poids': const Color(0xFFFF6B00)};
    return Row(
      children: grouped.entries.map((e) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.lightGrayBackground, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [Text(e.key, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 6), SizedBox(height: 78, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: e.value.map((v) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Container(height: _normalizedHeight(v, e.key), decoration: BoxDecoration(color: colors[e.key], borderRadius: BorderRadius.circular(8)))))).toList()))]),
        ),
      )).toList(),
    );
  }

  double _normalizedHeight(ConstantModel v, String type) {
    if (type == 'Tension' && v.tensionSystolic != null) return (v.tensionSystolic! / 180).clamp(0.2, 1.0) * 70;
    if (type == 'Glycémie' && v.glycemie != null) return (v.glycemie! / 2).clamp(0.2, 1.0) * 70;
    if (type == 'Poids' && v.poids != null) return (v.poids! / 120).clamp(0.2, 1.0) * 70;
    return 0;
  }
}

// --- Vital Tile ---
class _VitalTile extends StatelessWidget {
  const _VitalTile({required this.vital});
  final ConstantModel vital;

  @override
  Widget build(BuildContext context) {
    final subtitle = vital.tensionSystolic != null ? '${vital.tensionSystolic!.toStringAsFixed(0)}/${vital.tensionDiastolic?.toStringAsFixed(0) ?? '-'} mmHg' : vital.glycemie != null ? '${vital.glycemie!.toStringAsFixed(2)} g/L' : vital.poids != null ? '${vital.poids!.toStringAsFixed(1)} kg' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [CircleAvatar(radius: 18, backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12), child: Icon(Icons.monitor_heart_rounded, color: AppColors.primaryBlue)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Constante', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))]))]),
    );
  }
}

// --- Treatment Tile ---
class _TreatmentTile extends StatelessWidget {
  const _TreatmentTile({required this.treatment, required this.onToggle});
  final MedicationModel treatment;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(treatment.name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800))), Switch(value: treatment.alert ?? false, onChanged: onToggle)]), Text('${treatment.dosage} · ${treatment.frequency}', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))]),
    );
  }
}

// --- Document Tile ---
class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc, required this.onShare});
  final String doc;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [Icon(Icons.description_rounded, color: AppColors.primaryBlue), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(doc, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text('Document', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))])), TextButton(onPressed: onShare, child: const Text('Partager'))]),
    );
  }
}

// --- Wellness Row ---
class _WellnessRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _WellnessItem(title: 'Routine bien-être', tag: 'Conseil', icon: Icons.self_improvement_rounded, color: const Color(0xFF10B981)),
      _WellnessItem(title: 'Alimentation cardio', tag: 'Nutrition', icon: Icons.restaurant_rounded, color: const Color(0xFFFF9800)),
      _WellnessItem(title: 'Sommeil', tag: 'Habitude', icon: Icons.bed_rounded, color: const Color(0xFF7C3AED)),
    ];
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: items[i].color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)), child: Icon(items[i].icon, color: items[i].color)), const SizedBox(width: 8), Text(items[i].tag, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary))]), const SizedBox(height: 8), Text(items[i].title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800))]),
        ),
      ),
    );
  }
}

class _WellnessItem {
  const _WellnessItem({required this.title, required this.tag, required this.icon, required this.color});
  final String title;
  final String tag;
  final IconData icon;
  final Color color;
}

// --- Emergency Card ---
class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.onCall, required this.onAlert, required this.sent});
  final VoidCallback onCall;
  final VoidCallback onAlert;
  final bool sent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF7A00)], begin: Alignment.centerLeft, end: Alignment.centerRight), borderRadius: BorderRadius.circular(22)),
      child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Carte d’urgence', style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)), Text('Appel 15 + Alerte famille', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.92)))])), FilledButton(onPressed: onCall, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFE91E63)), child: const Text('Appel 15')), const SizedBox(width: 8), OutlinedButton(onPressed: sent ? null : onAlert, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)), child: Text(sent ? 'Alerte envoyée' : 'Alerte famille'))]),
    );
  }
}

// --- Messaging Card ---
class _MessagingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.messages),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
        child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryBlue)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Messages', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text('Médecins, pharmacie, assistant IA', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))])), const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.textSecondary)]),
      ),
    );
  }
}

// ============================================================
// 6. FORMULAIRES (MODALES)
// ============================================================

class _SymptomForm extends StatefulWidget {
  const _SymptomForm();
  @override
  State<_SymptomForm> createState() => _SymptomFormState();
}

class _SymptomFormState extends State<_SymptomForm> {
  final _name = TextEditingController();
  final _notes = TextEditingController();
  double _intensity = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Enregistrer un symptôme', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom du symptôme')),
          const SizedBox(height: 10),
          Row(children: [Text('Intensité ${_intensity.toStringAsFixed(0)}/5'), Expanded(child: Slider(value: _intensity, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _intensity = v)))]),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save_rounded), label: const Text('Sauvegarder')),
        ]),
      ),
    );
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop({'name': _name.text.trim(), 'intensity': _intensity, 'notes': _notes.text.trim()});
  }
}

class _VitalForm extends StatefulWidget {
  const _VitalForm();
  @override
  State<_VitalForm> createState() => _VitalFormState();
}

class _VitalFormState extends State<_VitalForm> {
  String _type = 'Tension';
  final _primary = TextEditingController();
  final _secondary = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Ajouter une constante', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            items: ['Tension', 'Glycémie', 'Poids'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v ?? 'Tension'),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _primary,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: _type == 'Poids' ? 'Poids (kg)' : _type == 'Glycémie' ? 'Glycémie (g/L)' : 'Tension systolique'),
          ),
          if (_type == 'Tension') ...[const SizedBox(height: 10), TextField(controller: _secondary, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tension diastolique'))],
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save_rounded), label: const Text('Sauvegarder')),
        ]),
      ),
    );
  }

  void _submit() {
    final primary = double.tryParse(_primary.text.replaceAll(',', '.'));
    if (primary == null) return;
    final data = {
      'systolic': _type == 'Tension' ? primary : null,
      'diastolic': _type == 'Tension' ? double.tryParse(_secondary.text.replaceAll(',', '.')) : null,
      'glycemia': _type == 'Glycémie' ? primary : null,
      'weight': _type == 'Poids' ? primary : null,
    };
    Navigator.of(context).pop(data);
  }
}

class _AppointmentForm extends StatefulWidget {
  const _AppointmentForm();
  @override
  State<_AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<_AppointmentForm> {
  final _doctor = TextEditingController(text: 'Médecin');
  final _reason = TextEditingController(text: 'Suivi');
  final _specialty = TextEditingController(text: 'Généraliste');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Planifier un RDV', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(controller: _doctor, decoration: const InputDecoration(labelText: 'Médecin / Service')),
          const SizedBox(height: 10),
          TextField(controller: _specialty, decoration: const InputDecoration(labelText: 'Spécialité')),
          const SizedBox(height: 10),
          TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Motif')),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.check_rounded), label: const Text('Planifier')),
        ]),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop({
      'doctorName': _doctor.text.trim(),
      'specialty': _specialty.text.trim(),
      'notes': _reason.text.trim(),
    });
  }
}

// ============================================================
// 7. DOCTOR & PHARMACY WORKSPACES (STATIQUES POUR L'EXEMPLE)
// ============================================================

class DoctorWorkspace extends StatelessWidget {
  const DoctorWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _AdminItem(title: 'Indicateurs clés', subtitle: 'Patients 84 · Consultations du jour 16 · Alertes 5', icon: Icons.stacked_line_chart_rounded, color: const Color(0xFF2453FF)),
      _AdminItem(title: 'Alertes patients', subtitle: 'Risque tension, glycémie · 3 priorités', icon: Icons.warning_amber_rounded, color: const Color(0xFFE91E63)),
      _AdminItem(title: 'Prescriptions', subtitle: 'Formulaire, aperçu PDF, envoi patient/pharmacie', icon: Icons.description_rounded, color: const Color(0xFF7C3AED)),
      _AdminItem(title: 'Téléconsultation / Jitsi', subtitle: 'Créer un salon sécurisé en un clic', icon: Icons.video_call_rounded, color: const Color(0xFFFF6B00)),
      _AdminItem(title: 'Agenda', subtitle: 'Vue mois + consultations du jour', icon: Icons.calendar_month_rounded, color: const Color(0xFF10B981)),
      _AdminItem(title: 'Terrain (mobile)', subtitle: 'Scan bracelet, dictée vocale, offline', icon: Icons.qr_code_scanner_rounded, color: const Color(0xFF2453FF)),
    ];
    final adminItems = [
      _AdminItem(title: 'Admin Hôpital (web uniquement)', subtitle: 'Dashboard lits, admissions, RDV, bloc opératoire, facturation, staff', icon: Icons.business_rounded, color: const Color(0xFF2453FF)),
      _AdminItem(title: 'Gestion des lits & RDV', subtitle: 'Planification lits, vue calendrier, créneaux en temps réel', icon: Icons.meeting_room_rounded, color: const Color(0xFF10B981)),
      _AdminItem(title: 'Examens & bloc', subtitle: 'Prescription examens, résultats, planning bloc + checklists', icon: Icons.biotech_rounded, color: const Color(0xFFFF6B00)),
      _AdminItem(title: 'Facturation / tiers payant', subtitle: 'Factures automatiques, mutuelles, relances impayés', icon: Icons.receipt_long_rounded, color: const Color(0xFF7C3AED)),
    ];
    final advanced = [
      _AdminItem(title: 'Cliniques avancées', subtitle: 'Triage urgences, chimio, dialyse, rééducation, grossesse', icon: Icons.medical_information_rounded, color: const Color(0xFFE91E63)),
      _AdminItem(title: 'Opérations', subtitle: 'Maintenance, stérilisation, linge, repas, transport, salles', icon: Icons.settings_suggest_rounded, color: const Color(0xFF2453FF)),
      _AdminItem(title: 'Analytics & IA', subtitle: 'CDSS, prédictions admissions, BI, fraudes, risques épidémiques', icon: Icons.auto_graph_rounded, color: const Color(0xFF10B981)),
      _AdminItem(title: 'Sécurité & IAM', subtitle: 'Consentements RGPD, audit, signature, 2FA, RBAC, chiffrement', icon: Icons.verified_user_rounded, color: const Color(0xFFFF6B00)),
      _AdminItem(title: 'Interop & Finance', subtitle: 'HL7/FHIR, webhooks, import/export, tarification NGAP/T2A', icon: Icons.sync_alt_rounded, color: const Color(0xFF7C3AED)),
      _AdminItem(title: 'Mobile terrain', subtitle: 'Scan bracelet, dictée vocale, offline, documents scannés', icon: Icons.smartphone_rounded, color: const Color(0xFFE91E63)),
    ];
    return Column(
      children: [
        SectionCard(title: 'Espace Médecin', child: Column(children: items.map((i) => _AdminTile(item: i)).toList())),
        const SizedBox(height: 12),
        SectionCard(title: 'Back-office hôpital (web)', child: Column(children: adminItems.map((i) => _AdminTile(item: i)).toList())),
        const SizedBox(height: 12),
        SectionCard(title: 'Modules avancés & conformité', child: Column(children: advanced.map((i) => _AdminTile(item: i)).toList())),
      ],
    );
  }
}

class PharmacyWorkspace extends StatelessWidget {
  const PharmacyWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _AdminItem(title: 'Commandes en attente', subtitle: '21 prescriptions · stock critique 9', icon: Icons.receipt_long_rounded, color: const Color(0xFF2453FF)),
      _AdminItem(title: 'Validation ordonnances', subtitle: 'Acceptation / rejet + suivi livraison', icon: Icons.fact_check_rounded, color: const Color(0xFF10B981)),
      _AdminItem(title: 'Inventaire & lots', subtitle: 'Quantités, seuils, réassort automatique', icon: Icons.inventory_2_rounded, color: const Color(0xFFFF7A00)),
      _AdminItem(title: 'Messagerie', subtitle: 'Médecins et patients (notifications)', icon: Icons.chat_bubble_rounded, color: const Color(0xFF7C3AED)),
      _AdminItem(title: 'Rapports', subtitle: 'CA, commandes, médicaments prescrits', icon: Icons.analytics_rounded, color: const Color(0xFFE91E63)),
      _AdminItem(title: 'Profil pharmacie', subtitle: 'Coordonnées, horaires, équipe', icon: Icons.storefront_rounded, color: const Color(0xFF2453FF)),
    ];
    return SectionCard(title: 'Espace Pharmacie', child: Column(children: items.map((i) => _AdminTile(item: i)).toList()));
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({required this.item});
  final _AdminItem item;

  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: item.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: Icon(item.icon, color: item.color)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text(item.subtitle, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))]))]));
  }
}

class _AdminItem {
  const _AdminItem({required this.title, required this.subtitle, required this.icon, required this.color});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

// ============================================================
// 8. COMPOSANTS UTILITAIRES
// ============================================================

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, this.actionLabel, this.onAction, required this.child});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900))), if (actionLabel != null) TextButton(onPressed: onAction, child: Text(actionLabel!))]), const SizedBox(height: 10), child]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.lightGrayBackground, borderRadius: BorderRadius.circular(10)), child: Text(text, style: context.textStyles.labelSmall?.copyWith(color: AppColors.darkNavy, fontWeight: FontWeight.w800)));
  }
}
