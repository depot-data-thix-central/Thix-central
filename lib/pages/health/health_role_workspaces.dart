import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/health/thix_role_controller.dart';
import 'package:thix_central/health/thix_ui_feedback.dart';
import 'package:thix_central/nav.dart';
import 'package:thix_central/theme.dart';

class HealthRoleWorkspace extends StatelessWidget {
  const HealthRoleWorkspace({super.key, required this.role, required this.permissions});

  final ThixRole role;
  final Map<String, bool> permissions;

  @override
  Widget build(BuildContext context) {
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

class PatientWorkspace extends StatefulWidget {
  const PatientWorkspace({super.key, required this.permissions});

  final Map<String, bool> permissions;

  @override
  State<PatientWorkspace> createState() => _PatientWorkspaceState();
}

class _PatientWorkspaceState extends State<PatientWorkspace> {
  final List<PatientSymptom> _symptoms = [
    PatientSymptom(name: 'Migraine', intensity: 3, notes: 'Repos + hydratation'),
    PatientSymptom(name: 'Tension élevée', intensity: 4, notes: '145/92 mmHg'),
  ];
  final List<PatientVital> _vitals = [
    PatientVital(type: VitalType.tension, primary: 128, secondary: 82),
    PatientVital(type: VitalType.glycemia, primary: 1.12),
    PatientVital(type: VitalType.weight, primary: 74.5),
  ];
  final List<PatientTreatment> _treatments = [
    PatientTreatment(name: 'Amoxicilline', dosage: '500 mg', schedule: '08:00 · 20:00', alerts: true),
    PatientTreatment(name: 'Vitamine D', dosage: '1 gélule', schedule: 'Chaque dimanche', alerts: false),
  ];
  final List<PatientAppointment> _appointments = [
    PatientAppointment(kind: 'Consultation', doctor: 'Dr. Sarr', reason: 'Suivi tension', status: 'À venir'),
    PatientAppointment(kind: 'Téléconsultation', doctor: 'Dr. Nadia', reason: 'Résultats analyses', status: 'Aujourd’hui'),
  ];
  final List<PatientDocument> _documents = [
    PatientDocument(title: 'OR-2024-118', type: 'Ordonnance'),
    PatientDocument(title: 'Bilan sanguin', type: 'Analyse'),
  ];
  bool _alertSent = false;

  double get _healthScore {
    final penalty = _symptoms.fold<double>(0, (sum, s) => sum + s.intensity * 1.5);
    final gain = _treatments.where((t) => t.alerts).length * 4;
    return (96 - penalty + gain).clamp(40, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScoreCard(score: _healthScore, permissions: widget.permissions),
        const SizedBox(height: 14),
        _QuickServices(onAddSymptom: _openSymptomForm, onAddAppointment: _openAppointmentForm),
        const SizedBox(height: 14),
        _StatsRow(symptoms: _symptoms.length, treatments: _treatments.length, vitals: _vitals.length, appointments: _appointments.length),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Rendez-vous',
          actionLabel: 'Ajouter',
          onAction: _openAppointmentForm,
          child: Column(children: _appointments.map((a) => _AppointmentTile(appt: a, onReschedule: _reschedule, onCancel: _cancel, onTeleconsultation: _teleconsult)).toList()),
        ),
        const SizedBox(height: 14),
        SectionCard(title: 'Symptômes', actionLabel: 'Enregistrer', onAction: _openSymptomForm, child: Column(children: _symptoms.map((s) => _SymptomTile(symptom: s)).toList())),
        const SizedBox(height: 14),
        SectionCard(title: 'Constantes', actionLabel: 'Ajouter', onAction: _openVitalForm, child: Column(children: [_VitalBars(vitals: _vitals), const SizedBox(height: 10), ..._vitals.map((v) => _VitalTile(vital: v))])),
        const SizedBox(height: 14),
        SectionCard(title: 'Traitements', child: Column(children: _treatments.map((t) => _TreatmentTile(treatment: t, onToggle: (v) => _toggleTreatment(t, v))).toList())),
        const SizedBox(height: 14),
        SectionCard(title: 'Documents', actionLabel: 'Ajouter', onAction: _addDocument, child: Column(children: _documents.map((d) => _DocumentTile(doc: d, onShare: _shareDocument)).toList())),
        const SizedBox(height: 14),
        SectionCard(title: 'Articles bien-être', child: _WellnessRow()),
        const SizedBox(height: 14),
        _EmergencyCard(onCall: _call15, onAlert: _alertFamily, sent: _alertSent),
        const SizedBox(height: 12),
        _MessagingCard(),
      ],
    );
  }

  Future<void> _openSymptomForm() async {
    final result = await showModalBottomSheet<PatientSymptom>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SymptomForm(),
    );
    if (result == null) return;
    setState(() => _symptoms.insert(0, result));
  }

  Future<void> _openVitalForm() async {
    final result = await showModalBottomSheet<PatientVital>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _VitalForm(),
    );
    if (result == null) return;
    setState(() => _vitals.insert(0, result));
  }

  Future<void> _openAppointmentForm() async {
    final result = await showModalBottomSheet<PatientAppointment>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AppointmentForm(),
    );
    if (result == null) return;
    setState(() => _appointments.insert(0, result));
  }

  void _toggleTreatment(PatientTreatment treatment, bool value) {
    final idx = _treatments.indexOf(treatment);
    if (idx == -1) return;
    setState(() => _treatments[idx] = treatment.copyWith(alerts: value));
    showThixFeatureReadySnackBar(context, value ? 'Rappel activé' : 'Rappel désactivé');
  }

  void _reschedule(PatientAppointment appt) {
    final idx = _appointments.indexOf(appt);
    if (idx == -1) return;
    setState(() => _appointments[idx] = appt.copyWith(status: 'Replanifié +2h'));
    showThixFeatureReadySnackBar(context, 'RDV replanifié');
  }

  void _cancel(PatientAppointment appt) {
    setState(() => _appointments.remove(appt));
    showThixFeatureReadySnackBar(context, 'RDV annulé');
  }

  void _teleconsult(PatientAppointment appt) {
    final room = appt.teleRoom ?? 'thix-${Random().nextInt(9000) + 1000}';
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Téléconsultation Jitsi'),
        content: Text('Salon : $room\nOuvrez ce nom de salle dans Jitsi Meet.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
      ),
    );
  }

  void _addDocument() {
    setState(() => _documents.add(PatientDocument(title: 'Document ${_documents.length + 1}', type: 'Upload')));
    showThixFeatureReadySnackBar(context, 'Ajoutez vos PDF ou photos depuis Documents');
  }

  void _shareDocument(PatientDocument doc) {
    final token = Random().nextInt(999999).toString().padLeft(6, '0');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lien expirable'),
        content: Text('https://thix.health/share/${doc.title}-$token'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  void _call15() => showThixFeatureReadySnackBar(context, 'Appel 15 déclenché');

  void _alertFamily() {
    setState(() => _alertSent = true);
    showThixFeatureReadySnackBar(context, 'Famille alertée');
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.permissions});

  final double score;
  final Map<String, bool> permissions;

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
              Text('Basé sur symptômes, constantes, traitements et RDV.', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.92))),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: permissions.entries.map((e) => Chip(label: Text('${e.key}:${e.value ? 'on' : 'off'}'), backgroundColor: Colors.white.withValues(alpha: 0.16), labelStyle: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))).toList()),
            ]),
          ),
          Container(width: 88, height: 88, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(22)), alignment: Alignment.center, child: Text('${score.toStringAsFixed(0)}/100', style: context.textStyles.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}

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
  const _StatsRow({required this.symptoms, required this.treatments, required this.vitals, required this.appointments});

  final int symptoms;
  final int treatments;
  final int vitals;
  final int appointments;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(label: 'Symptômes', value: symptoms.toString(), icon: Icons.sick_rounded, color: const Color(0xFF2453FF)),
      _StatItem(label: 'Traitements', value: treatments.toString(), icon: Icons.medication_rounded, color: const Color(0xFF7C3AED)),
      _StatItem(label: 'Constantes', value: vitals.toString(), icon: Icons.monitor_heart_outlined, color: const Color(0xFF10B981)),
      _StatItem(label: 'RDV', value: appointments.toString(), icon: Icons.calendar_month_rounded, color: const Color(0xFFFF6B00)),
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

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appt, required this.onReschedule, required this.onCancel, required this.onTeleconsultation});

  final PatientAppointment appt;
  final ValueChanged<PatientAppointment> onReschedule;
  final ValueChanged<PatientAppointment> onCancel;
  final ValueChanged<PatientAppointment> onTeleconsultation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.event_available_rounded, color: AppColors.primaryBlue), const SizedBox(width: 8), Expanded(child: Text('${appt.kind} · ${appt.doctor}', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800))), _Pill(text: appt.status)]),
        const SizedBox(height: 6),
        Text(appt.reason, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Row(children: [OutlinedButton(onPressed: () => onReschedule(appt), child: const Text('Reporter')), const SizedBox(width: 8), OutlinedButton(onPressed: () => onCancel(appt), child: const Text('Annuler')), const Spacer(), FilledButton.icon(onPressed: () => onTeleconsultation(appt), icon: const Icon(Icons.video_call_rounded), label: const Text('Téléconsultation'))]),
      ]),
    );
  }
}

class _SymptomTile extends StatelessWidget {
  const _SymptomTile({required this.symptom});

  final PatientSymptom symptom;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [CircleAvatar(radius: 18, backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12), child: Text(symptom.intensity.toString(), style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryBlue))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(symptom.name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), if (symptom.notes.isNotEmpty) Text(symptom.notes, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))]))]),
    );
  }
}

class _VitalBars extends StatelessWidget {
  const _VitalBars({required this.vitals});

  final List<PatientVital> vitals;

  @override
  Widget build(BuildContext context) {
    final grouped = <VitalType, List<PatientVital>>{};
    for (final v in vitals) {
      grouped.putIfAbsent(v.type, () => []).add(v);
    }
    return Row(
      children: grouped.entries
          .map(
            (e) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.lightGrayBackground, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [Text(e.key.label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 6), SizedBox(height: 78, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: e.value.map((v) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Container(height: v.normalizedHeight * 70, decoration: BoxDecoration(color: e.key.color, borderRadius: BorderRadius.circular(8)))))).toList()))]),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _VitalTile extends StatelessWidget {
  const _VitalTile({required this.vital});

  final PatientVital vital;

  @override
  Widget build(BuildContext context) {
    final subtitle = vital.type == VitalType.tension ? '${vital.primary.toStringAsFixed(0)}/${vital.secondary?.toStringAsFixed(0) ?? '-'} mmHg' : vital.type == VitalType.glycemia ? '${vital.primary.toStringAsFixed(2)} g/L' : '${vital.primary.toStringAsFixed(1)} kg';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [CircleAvatar(radius: 18, backgroundColor: vital.type.color.withValues(alpha: 0.12), child: Icon(vital.type.icon, color: vital.type.color)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(vital.type.label, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))]))]),
    );
  }
}

class _TreatmentTile extends StatelessWidget {
  const _TreatmentTile({required this.treatment, required this.onToggle});

  final PatientTreatment treatment;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(treatment.name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800))), Switch(value: treatment.alerts, onChanged: onToggle)]), Text('${treatment.dosage} · ${treatment.schedule}', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))]),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc, required this.onShare});

  final PatientDocument doc;
  final ValueChanged<PatientDocument> onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [Icon(Icons.description_rounded, color: AppColors.primaryBlue), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(doc.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text(doc.type, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))])), TextButton(onPressed: () => onShare(doc), child: const Text('Partager'))]),
    );
  }
}

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
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Enregistrer un symptôme', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 12), TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom du symptôme')), const SizedBox(height: 10), Row(children: [Text('Intensité ${_intensity.toStringAsFixed(0)}/5'), Expanded(child: Slider(value: _intensity, min: 1, max: 5, divisions: 4, onChanged: (v) => setState(() => _intensity = v)))]), TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3), const SizedBox(height: 14), FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save_rounded), label: const Text('Sauvegarder'))]),
      ),
    );
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(PatientSymptom(name: _name.text.trim(), intensity: _intensity.toInt(), notes: _notes.text.trim()));
  }
}

class _VitalForm extends StatefulWidget {
  const _VitalForm();

  @override
  State<_VitalForm> createState() => _VitalFormState();
}

class _VitalFormState extends State<_VitalForm> {
  VitalType _type = VitalType.tension;
  final _primary = TextEditingController();
  final _secondary = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Ajouter une constante', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 12), DropdownButtonFormField<VitalType>(value: _type, decoration: const InputDecoration(labelText: 'Type'), items: VitalType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(), onChanged: (v) => setState(() => _type = v ?? VitalType.tension)), const SizedBox(height: 10), TextField(controller: _primary, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _type == VitalType.weight ? 'Poids (kg)' : _type == VitalType.glycemia ? 'Glycémie (g/L)' : 'Tension systolique')), if (_type == VitalType.tension) ...[const SizedBox(height: 10), TextField(controller: _secondary, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tension diastolique'))], const SizedBox(height: 14), FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save_rounded), label: const Text('Sauvegarder'))]),
      ),
    );
  }

  void _submit() {
    final primary = double.tryParse(_primary.text.replaceAll(',', '.'));
    if (primary == null) return;
    Navigator.of(context).pop(PatientVital(type: _type, primary: primary, secondary: double.tryParse(_secondary.text.replaceAll(',', '.'))));
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [Text('Planifier un RDV', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 12), TextField(controller: _doctor, decoration: const InputDecoration(labelText: 'Médecin / Service')), const SizedBox(height: 10), TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Motif')), const SizedBox(height: 14), FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.check_rounded), label: const Text('Planifier'))]),
      ),
    );
  }

  void _submit() {
    Navigator.of(context).pop(PatientAppointment(kind: 'Consultation', doctor: _doctor.text.trim(), reason: _reason.text.trim(), status: 'À venir'));
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

class PatientSymptom {
  PatientSymptom({required this.name, required this.intensity, required this.notes});
  final String name;
  final int intensity;
  final String notes;
}

enum VitalType { tension, glycemia, weight }

extension VitalTypeX on VitalType {
  String get label => switch (this) { VitalType.tension => 'Tension', VitalType.glycemia => 'Glycémie', VitalType.weight => 'Poids' };
  IconData get icon => switch (this) { VitalType.tension => Icons.monitor_heart_rounded, VitalType.glycemia => Icons.bloodtype_rounded, VitalType.weight => Icons.monitor_weight_rounded };
  Color get color => switch (this) { VitalType.tension => const Color(0xFF2453FF), VitalType.glycemia => const Color(0xFF10B981), VitalType.weight => const Color(0xFFFF6B00) };
}

class PatientVital {
  PatientVital({required this.type, required this.primary, this.secondary});
  final VitalType type;
  final double primary;
  final double? secondary;

  double get normalizedHeight => switch (type) { VitalType.tension => (primary / 180).clamp(0.2, 1.0), VitalType.glycemia => (primary / 2).clamp(0.2, 1.0), VitalType.weight => (primary / 120).clamp(0.2, 1.0) };
}

class PatientTreatment {
  PatientTreatment({required this.name, required this.dosage, required this.schedule, required this.alerts});
  final String name;
  final String dosage;
  final String schedule;
  final bool alerts;

  PatientTreatment copyWith({bool? alerts}) => PatientTreatment(name: name, dosage: dosage, schedule: schedule, alerts: alerts ?? this.alerts);
}

class PatientAppointment {
  PatientAppointment({required this.kind, required this.doctor, required this.reason, required this.status, this.teleRoom});
  final String kind;
  final String doctor;
  final String reason;
  final String status;
  final String? teleRoom;

  PatientAppointment copyWith({String? status}) => PatientAppointment(kind: kind, doctor: doctor, reason: reason, status: status ?? this.status, teleRoom: teleRoom);
}

class PatientDocument {
  PatientDocument({required this.title, required this.type});
  final String title;
  final String type;
}

class _WellnessItem {
  const _WellnessItem({required this.title, required this.tag, required this.icon, required this.color});
  final String title;
  final String tag;
  final IconData icon;
  final Color color;
}

class _AdminItem {
  const _AdminItem({required this.title, required this.subtitle, required this.icon, required this.color});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}