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
    PatientSymptom(name: 'Migraine', intensity: 3, date: DateTime.now().subtract(const Duration(days: 1)), notes: 'Repos + hydratation'),
    PatientSymptom(name: 'Tension élevée', intensity: 4, date: DateTime.now().subtract(const Duration(days: 2)), notes: 'Mesure 145/92'),
  ];
  final List<PatientVital> _vitals = [
    PatientVital(type: VitalType.tension, value1: 128, value2: 82, date: DateTime.now().subtract(const Duration(hours: 6))),
    PatientVital(type: VitalType.glycemia, value1: 1.12, date: DateTime.now().subtract(const Duration(hours: 12))),
    PatientVital(type: VitalType.weight, value1: 74.5, date: DateTime.now().subtract(const Duration(days: 1))),
  ];
  final List<PatientTreatment> _treatments = [
    PatientTreatment(name: 'Amoxicilline', dosage: '500 mg', schedule: '08:00 · 20:00', start: DateTime.now().subtract(const Duration(days: 2)), end: DateTime.now().add(const Duration(days: 5)), alerts: true),
    PatientTreatment(name: 'Vitamine D', dosage: '1 gélule', schedule: 'Chaque dimanche', start: DateTime.now().subtract(const Duration(days: 10)), end: DateTime.now().add(const Duration(days: 20)), alerts: false),
  ];
  final List<PatientAppointment> _appointments = [
    PatientAppointment(kind: 'Consultation', doctor: 'Dr. Sarr', reason: 'Suivi tension', when: DateTime.now().add(const Duration(days: 1, hours: 2)), status: 'À venir', teleconsultationRoom: 'thix-sarr-1024'),
    PatientAppointment(kind: 'Téléconsultation', doctor: 'Dr. Nadia', reason: 'Résultats analyses', when: DateTime.now().add(const Duration(hours: 5)), status: 'Aujourd’hui', teleconsultationRoom: 'thix-nadia-tele-09'),
  ];
  final List<PatientDocument> _documents = [
    PatientDocument(type: 'Ordonnance', title: 'OR-2024-118', date: DateTime.now().subtract(const Duration(days: 3))),
    PatientDocument(type: 'Analyse', title: 'Bilan sanguin', date: DateTime.now().subtract(const Duration(days: 5))),
  ];
  final List<WellnessArticle> _articles = const [
    WellnessArticle(title: 'Routine bien-être', tag: 'Conseil', description: 'Respiration, étirements et hydratation.', icon: Icons.self_improvement_rounded, color: Color(0xFF10B981)),
    WellnessArticle(title: 'Alimentation cardio', tag: 'Nutrition', description: '3 repas équilibrés et peu salés.', icon: Icons.restaurant_rounded, color: Color(0xFFFF9800)),
    WellnessArticle(title: 'Sommeil réparateur', tag: 'Sommeil', description: 'Limiter les écrans avant 22h.', icon: Icons.bed_rounded, color: Color(0xFF7C3AED)),
  ];
  bool _emergencyAlertSent = false;

  double get _healthScore {
    final symptomPenalty = _symptoms.fold<double>(0, (sum, s) => sum + s.intensity * 1.8);
    final treatmentScore = 10 + _treatments.where((t) => t.alerts).length * 4;
    final base = 96 - symptomPenalty + treatmentScore;
    return base.clamp(40, 100);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PatientScoreCard(score: _healthScore, permissions: widget.permissions),
        const SizedBox(height: 16),
        _PatientServicesRow(onAddSymptom: _openSymptomForm, onAddAppointment: _openAppointmentForm),
        const SizedBox(height: 16),
        _PatientStats(symptoms: _symptoms.length, treatments: _treatments.length, vitals: _vitals.length, appointments: _appointments.length),
        const SizedBox(height: 16),
        _PatientAppointments(appointments: _appointments, onReschedule: _reschedule, onCancel: _cancelAppointment, onTeleconsultation: _startTeleconsultation, onAdd: _openAppointmentForm),
        const SizedBox(height: 16),
        _PatientSymptoms(symptoms: _symptoms, onAdd: _openSymptomForm),
        const SizedBox(height: 16),
        _PatientVitals(vitals: _vitals, onAdd: _openVitalForm),
        const SizedBox(height: 16),
        _PatientTreatments(treatments: _treatments, onToggleAlert: _toggleTreatmentAlert),
        const SizedBox(height: 16),
        _PatientDocuments(documents: _documents, onUpload: _uploadDocument, onShare: _shareDocument),
        const SizedBox(height: 16),
        _PatientWellness(articles: _articles),
        const SizedBox(height: 16),
        _PatientEmergencyCard(onCall: _callEmergency, onAlertFamily: _alertFamily, alertSent: _emergencyAlertSent),
        const SizedBox(height: 12),
        _PatientMessagingCta(),
      ],
    );
  }

  Future<void> _openSymptomForm() async {
    final result = await showModalBottomSheet<PatientSymptom>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PatientSymptomForm(initialDate: DateTime.now()),
    );
    if (result == null) return;
    setState(() => _symptoms.insert(0, result));
  }

  Future<void> _openVitalForm() async {
    final result = await showModalBottomSheet<PatientVital>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PatientVitalForm(),
    );
    if (result == null) return;
    setState(() => _vitals.insert(0, result));
  }

  Future<void> _openAppointmentForm() async {
    final result = await showModalBottomSheet<PatientAppointment>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PatientAppointmentForm(initialDate: DateTime.now().add(const Duration(hours: 4))),
    );
    if (result == null) return;
    setState(() => _appointments.insert(0, result));
  }

  void _toggleTreatmentAlert(PatientTreatment treatment, bool value) {
    setState(() {
      final idx = _treatments.indexOf(treatment);
      if (idx != -1) {
        _treatments[idx] = treatment.copyWith(alerts: value);
      }
    });
    showThixFeatureReadySnackBar(context, value ? 'Rappel activé' : 'Rappel désactivé');
  }

  void _reschedule(PatientAppointment appt) {
    final updated = appt.copyWith(when: appt.when.add(const Duration(hours: 2)), status: 'Replanifié');
    setState(() {
      final idx = _appointments.indexOf(appt);
      if (idx != -1) _appointments[idx] = updated;
    });
    showThixFeatureReadySnackBar(context, 'RDV replanifié (+2h)');
  }

  void _cancelAppointment(PatientAppointment appt) {
    setState(() => _appointments.remove(appt));
    showThixFeatureReadySnackBar(context, 'RDV annulé');
  }

  void _startTeleconsultation(PatientAppointment appt) {
    final room = appt.teleconsultationRoom ?? 'thix-room-${DateTime.now().millisecondsSinceEpoch}';
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Téléconsultation Jitsi'),
        content: Text('Salon sécurisé : $room\nCopiez ce lien dans Jitsi Meet.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fermer'))],
      ),
    );
  }

  void _uploadDocument() {
    showThixFeatureReadySnackBar(context, 'Ajoutez vos PDF ou photos via le module Documents');
    setState(() => _documents.add(PatientDocument(type: 'Document', title: 'Import ${_documents.length + 1}', date: DateTime.now())));
  }

  void _shareDocument(PatientDocument doc) {
    final token = Random().nextInt(999999).toString().padLeft(6, '0');
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lien de partage sécurisé'),
        content: Text('Lien expirable : https://thix.health/share/${doc.title}-$token'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ok'))],
      ),
    );
  }

  void _callEmergency() => showThixFeatureReadySnackBar(context, 'Appel 15 déclenché');

  void _alertFamily() {
    setState(() => _emergencyAlertSent = true);
    showThixFeatureReadySnackBar(context, 'Famille prévenue par notification');
  }
}

class _PatientScoreCard extends StatelessWidget {
  const _PatientScoreCard({required this.score, required this.permissions});

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score global IA', style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('Basé sur symptômes, traitements, constantes et RDV.', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.92))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: permissions.entries
                      .map(
                        (e) => Chip(
                          label: Text('${e.key} ${(e.value ? 'ok' : 'off')}'.toUpperCase()),
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          labelStyle: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(22)),
            alignment: Alignment.center,
            child: Text('${score.toStringAsFixed(0)}/100', style: context.textStyles.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _PatientServicesRow extends StatelessWidget {
  const _PatientServicesRow({required this.onAddSymptom, required this.onAddAppointment});

  final VoidCallback onAddSymptom;
  final VoidCallback onAddAppointment;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _ServiceTileData(label: 'Symptômes', icon: Icons.monitor_heart_rounded, onTap: onAddSymptom, color: const Color(0xFF2453FF)),
      _ServiceTileData(label: 'Rendez-vous', icon: Icons.calendar_today_rounded, onTap: onAddAppointment, color: const Color(0xFF10B981)),
      _ServiceTileData(label: 'Téléconsultation', icon: Icons.video_call_rounded, onTap: onAddAppointment, color: const Color(0xFFFF6B00)),
      _ServiceTileData(label: 'Urgences 15', icon: Icons.local_hospital_rounded, onTap: () => showThixFeatureReadySnackBar(context, 'Urgence prête'), color: const Color(0xFFE91E63)),
    ];

    return Row(children: tiles.map((e) => Expanded(child: _ServiceTile(item: e))).toList());
  }
}

class _ServiceTileData {
  const _ServiceTileData({required this.label, required this.icon, required this.onTap, required this.color});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.item});

  final _ServiceTileData item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
          child: Column(
            children: [
              CircleAvatar(radius: 20, backgroundColor: item.color.withValues(alpha: 0.12), child: Icon(item.icon, color: item.color)),
              const SizedBox(height: 10),
              Text(item.label, textAlign: TextAlign.center, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientStats extends StatelessWidget {
  const _PatientStats({required this.symptoms, required this.treatments, required this.vitals, required this.appointments});

  final int symptoms;
  final int treatments;
  final int vitals;
  final int appointments;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatCardData(label: 'Symptômes', value: symptoms.toString(), icon: Icons.sick_rounded, color: const Color(0xFF2453FF)),
      _StatCardData(label: 'Traitements', value: treatments.toString(), icon: Icons.medication_rounded, color: const Color(0xFF7C3AED)),
      _StatCardData(label: 'Constantes', value: vitals.toString(), icon: Icons.monitor_heart_outlined, color: const Color(0xFF10B981)),
      _StatCardData(label: 'RDV', value: appointments.toString(), icon: Icons.calendar_month_rounded, color: const Color(0xFFFF6B00)),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: items.map((e) => Expanded(child: _StatCard(item: e))).toList()),
    );
  }
}

class _StatCardData {
  const _StatCardData({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _StatCardData item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: item.color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Icon(item.icon, color: item.color),
          const SizedBox(height: 6),
          Text(item.value, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          Text(item.label, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _PatientAppointments extends StatelessWidget {
  const _PatientAppointments({required this.appointments, required this.onReschedule, required this.onCancel, required this.onTeleconsultation, required this.onAdd});

  final List<PatientAppointment> appointments;
  final ValueChanged<PatientAppointment> onReschedule;
  final ValueChanged<PatientAppointment> onCancel;
  final ValueChanged<PatientAppointment> onTeleconsultation;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'Rendez-vous', action: _Action(label: 'Ajouter', onTap: onAdd), child: Column(children: appointments.map((a) => _AppointmentTile(appt: a, onReschedule: onReschedule, onCancel: onCancel, onTeleconsultation: onTeleconsultation)).toList()));
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
    final date = '${appt.when.day}/${appt.when.month} · ${appt.when.hour.toString().padLeft(2, '0')}:${appt.when.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_available_rounded, color: AppColors.primaryBlue),
              const SizedBox(width: 10),
              Expanded(child: Text('${appt.kind} · $date', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
              _StatusPill(text: appt.status),
            ],
          ),
          const SizedBox(height: 6),
          Text('${appt.doctor} · ${appt.reason}', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(onPressed: () => onReschedule(appt), icon: const Icon(Icons.schedule_rounded), label: const Text('Reporter')),
              const SizedBox(width: 10),
              OutlinedButton.icon(onPressed: () => onCancel(appt), icon: const Icon(Icons.close_rounded), label: const Text('Annuler')),
              const Spacer(),
              FilledButton.icon(onPressed: () => onTeleconsultation(appt), icon: const Icon(Icons.video_call_rounded), label: const Text('Téléconsultation')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PatientSymptoms extends StatelessWidget {
  const _PatientSymptoms({required this.symptoms, required this.onAdd});

  final List<PatientSymptom> symptoms;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Symptômes',
      action: _Action(label: 'Enregistrer', onTap: onAdd),
      child: Column(children: symptoms.map((s) => _SymptomTile(symptom: s)).toList()),
    );
  }
}

class _SymptomTile extends StatelessWidget {
  const _SymptomTile({required this.symptom});

  final PatientSymptom symptom;

  @override
  Widget build(BuildContext context) {
    final date = '${symptom.date.day}/${symptom.date.month}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12), child: Text(symptom.intensity.toString(), style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryBlue))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(symptom.name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Intensité ${symptom.intensity}/5 · $date', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
              if (symptom.notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(symptom.notes, style: context.textStyles.bodyMedium?.copyWith(color: AppColors.darkNavy)),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _PatientVitals extends StatelessWidget {
  const _PatientVitals({required this.vitals, required this.onAdd});

  final List<PatientVital> vitals;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Constantes',
      action: _Action(label: 'Ajouter', onTap: onAdd),
      child: Column(
        children: [
          _VitalChart(vitals: vitals),
          const SizedBox(height: 10),
          Column(children: vitals.map((v) => _VitalTile(vital: v)).toList()),
        ],
      ),
    );
  }
}

class _VitalChart extends StatelessWidget {
  const _VitalChart({required this.vitals});

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
                decoration: BoxDecoration(color: AppColors.lightGrayBackground, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Text(e.key.label, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 86,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: e.value.map((v) {
                          final barHeight = v.normalizedHeight * 80;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Container(height: barHeight, decoration: BoxDecoration(color: v.type.color, borderRadius: BorderRadius.circular(8))),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
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
    final date = '${vital.date.day}/${vital.date.month} ${vital.date.hour.toString().padLeft(2, '0')}h';
    final subtitle = vital.type == VitalType.tension ? '${vital.value1.toStringAsFixed(0)}/${vital.value2?.toStringAsFixed(0)} mmHg' : vital.type == VitalType.glycemia ? '${vital.value1.toStringAsFixed(2)} g/L' : '${vital.value1.toStringAsFixed(1)} kg';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: vital.type.color.withValues(alpha: 0.12), child: Icon(vital.type.icon, color: vital.type.color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(vital.type.label, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text(subtitle, style: context.textStyles.bodySmall?.copyWith(color: AppColors.darkNavy)), Text(date, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))])),
        ],
      ),
    );
  }
}

class _PatientTreatments extends StatelessWidget {
  const _PatientTreatments({required this.treatments, required this.onToggleAlert});

  final List<PatientTreatment> treatments;
  final void Function(PatientTreatment, bool) onToggleAlert;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Traitements',
      child: Column(
        children: treatments
            .map(
              (t) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(t.name, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800))), Switch(value: t.alerts, onChanged: (v) => onToggleAlert(t, v))]),
                  Text('${t.dosage} · ${t.schedule}', style: context.textStyles.bodySmall?.copyWith(color: AppColors.darkNavy)),
                  Text('Du ${t.start.day}/${t.start.month} au ${t.end.day}/${t.end.month}', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ]),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PatientDocuments extends StatelessWidget {
  const _PatientDocuments({required this.documents, required this.onUpload, required this.onShare});

  final List<PatientDocument> documents;
  final VoidCallback onUpload;
  final ValueChanged<PatientDocument> onShare;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Documents',
      action: _Action(label: 'Ajouter', onTap: onUpload),
      child: Column(
        children: documents
            .map(
              (d) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
                child: Row(
                  children: [
                    Icon(Icons.description_rounded, color: AppColors.primaryBlue),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text('${d.type} · ${d.date.day}/${d.date.month}', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))])),
                    TextButton(onPressed: () => onShare(d), child: const Text('Partager')),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PatientWellness extends StatelessWidget {
  const _PatientWellness({required this.articles});

  final List<WellnessArticle> articles;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Articles bien-être',
      child: SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: articles.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _WellnessCard(article: articles[i]),
        ),
      ),
    );
  }
}

class _WellnessCard extends StatelessWidget {
  const _WellnessCard({required this.article});

  final WellnessArticle article;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Container(width: 34, height: 34, decoration: BoxDecoration(color: article.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(article.icon, color: article.color)), const SizedBox(width: 8), Text(article.tag, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary))]),
        const SizedBox(height: 8),
        Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(article.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _PatientEmergencyCard extends StatelessWidget {
  const _PatientEmergencyCard({required this.onCall, required this.onAlertFamily, required this.alertSent});

  final VoidCallback onCall;
  final VoidCallback onAlertFamily;
  final bool alertSent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF7A00)], begin: Alignment.centerLeft, end: Alignment.centerRight), borderRadius: BorderRadius.circular(22)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Carte d’urgence', style: context.textStyles.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)), Text('Appel 15 + Alerte famille', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)))])),
        const SizedBox(width: 10),
        FilledButton(onPressed: onCall, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFE91E63)), child: const Text('Appel 15')),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: alertSent ? null : onAlertFamily, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)), child: Text(alertSent ? 'Alerte envoyée' : 'Alerte famille')),
      ]),
    );
  }
}

class _PatientMessagingCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.messages),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.primaryBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryBlue)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Messagerie', style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text('Médecins, pharmacie, assistant IA', style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.textSecondary),
        ]),
      ),
    );
  }
}

class PatientSymptomForm extends StatefulWidget {
  const PatientSymptomForm({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<PatientSymptomForm> createState() => _PatientSymptomFormState();
}

class _PatientSymptomFormState extends State<PatientSymptomForm> {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enregistrer un symptôme', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nom du symptôme')),
            const SizedBox(height: 10),
            Row(children: [Text('Intensité ${_intensity.toStringAsFixed(0)}/5', style: context.textStyles.bodyMedium), Expanded(child: Slider(value: _intensity, min: 1, max: 5, divisions: 4, label: _intensity.toStringAsFixed(0), onChanged: (v) => setState(() => _intensity = v)))]),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 3),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save_rounded), label: const Text('Sauvegarder')),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final symptom = PatientSymptom(name: _name.text.trim(), intensity: _intensity.toInt(), date: widget.initialDate, notes: _notes.text.trim());
    Navigator.of(context).pop(symptom);
  }
}

class PatientVitalForm extends StatefulWidget {
  const PatientVitalForm({super.key});

  @override
  State<PatientVitalForm> createState() => _PatientVitalFormState();
}

class _PatientVitalFormState extends State<PatientVitalForm> {
  VitalType _type = VitalType.tension;
  final _first = TextEditingController();
  final _second = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ajouter une constante', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            DropdownButtonFormField<VitalType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: VitalType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
              onChanged: (v) => setState(() => _type = v ?? VitalType.tension),
            ),
            const SizedBox(height: 10),
            TextField(controller: _first, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: _type == VitalType.weight ? 'Poids (kg)' : _type == VitalType.glycemia ? 'Glycémie (g/L)' : 'Tension systolique')),\
            if (_type == VitalType.tension) ...[
              const SizedBox(height: 10),
              TextField(controller: _second, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tension diastolique')),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.save_rounded), label: const Text('Sauvegarder')),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final firstValue = double.tryParse(_first.text.replaceAll(',', '.'));
    if (firstValue == null) return;
    final vital = PatientVital(type: _type, value1: firstValue, value2: double.tryParse(_second.text.replaceAll(',', '.')), date: DateTime.now());
    Navigator.of(context).pop(vital);
  }
}

class PatientAppointmentForm extends StatefulWidget {
  const PatientAppointmentForm({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<PatientAppointmentForm> createState() => _PatientAppointmentFormState();
}

class _PatientAppointmentFormState extends State<PatientAppointmentForm> {
  final _doctor = TextEditingController(text: 'Médecin');
  final _reason = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nouveau rendez-vous', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: _doctor, decoration: const InputDecoration(labelText: 'Médecin / Service')),
            const SizedBox(height: 10),
            TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Motif')),
            const SizedBox(height: 10),
            Row(children: [Expanded(child: Text('Date: ${_date.day}/${_date.month} ${_date.hour.toString().padLeft(2, '0')}h', style: context.textStyles.bodyMedium)), IconButton(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_rounded))]),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: _submit, icon: const Icon(Icons.check_rounded), label: const Text('Planifier')),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: _date);
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
    if (time == null) return;
    setState(() => _date = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _submit() {
    final appt = PatientAppointment(kind: 'Consultation', doctor: _doctor.text.trim(), reason: _reason.text.trim().isEmpty ? 'Suivi' : _reason.text.trim(), when: _date, status: 'À venir', teleconsultationRoom: 'thix-${_doctor.text.trim().toLowerCase().replaceAll(' ', '-')}-${_date.hour}${_date.minute}');
    Navigator.of(context).pop(appt);
  }
}

class DoctorWorkspace extends StatelessWidget {
  const DoctorWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _AdminCard(title: 'Indicateurs clés', subtitle: 'Patients: 84 · Consultations du jour: 16 · Alertes: 5', icon: Icons.stacked_line_chart_rounded, color: const Color(0xFF2453FF)),
      _AdminCard(title: 'Alertes patients', subtitle: '3 patients à risque (tension, glycémie) · 2 téléexpertises en attente', icon: Icons.warning_amber_rounded, color: const Color(0xFFE91E63)),
      _AdminCard(title: 'Consultations à venir', subtitle: '08:30 Awa Ndiaye · 10:00 Mamadou Ba · 14:00 Téléconsultation', icon: Icons.event_rounded, color: const Color(0xFF10B981)),
      _AdminCard(title: 'Prescriptions', subtitle: 'Créer, prévisualiser et envoyer à la pharmacie', icon: Icons.description_rounded, color: const Color(0xFF7C3AED)),
      _AdminCard(title: 'Téléexpertise', subtitle: 'Demander ou répondre avec Jitsi intégré', icon: Icons.hub_rounded, color: const Color(0xFFFF6B00)),
      _AdminCard(title: 'Notes & dictée vocale', subtitle: 'Dictée en mobilité + mode hors-ligne', icon: Icons.mic_rounded, color: const Color(0xFF2453FF)),
      _AdminCard(title: 'Scan bracelet patient', subtitle: 'Sécurisation des médicaments et identitovigilance', icon: Icons.qr_code_scanner_rounded, color: const Color(0xFF10B981)),
    ];
    return _Section(title: 'Espace Médecin', child: Column(children: cards.map((c) => _AdminCardTile(card: c)).toList()));
  }
}

class PharmacyWorkspace extends StatelessWidget {
  const PharmacyWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _AdminCard(title: 'Commandes en attente', subtitle: '21 prescriptions à valider · Stock critique: 9', icon: Icons.receipt_long_rounded, color: const Color(0xFF2453FF)),
      _AdminCard(title: 'Dispensation', subtitle: 'Attribution par patient + livraison suivie', icon: Icons.medication_rounded, color: const Color(0xFF10B981)),
      _AdminCard(title: 'Inventaire', subtitle: 'Lots, numéros de série, alertes de réassort', icon: Icons.inventory_2_rounded, color: const Color(0xFFFF7A00)),
      _AdminCard(title: 'Messagerie', subtitle: 'Médecins & patients · notifications actives', icon: Icons.chat_bubble_rounded, color: const Color(0xFF7C3AED)),
      _AdminCard(title: 'Rapports', subtitle: 'CA, médicaments prescrits, ordonnances critiques', icon: Icons.analytics_rounded, color: const Color(0xFFE91E63)),
      _AdminCard(title: 'Profil officine', subtitle: 'Coordonnées, horaires, équipe', icon: Icons.storefront_rounded, color: const Color(0xFF2453FF)),
    ];
    return _Section(title: 'Espace Pharmacie', child: Column(children: cards.map((c) => _AdminCardTile(card: c)).toList()));
  }
}

class _AdminCardTile extends StatelessWidget {
  const _AdminCardTile({required this.card});

  final _AdminCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: card.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)), child: Icon(card.icon, color: card.color)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(card.title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)), Text(card.subtitle, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary))])),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.action, required this.child});

  final String title;
  final _Action? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.cardBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(title, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900))), if (action != null) TextButton(onPressed: action!.onTap, child: Text(action!.label))]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _Action {
  const _Action({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.lightGrayBackground, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: context.textStyles.labelSmall?.copyWith(color: AppColors.darkNavy, fontWeight: FontWeight.w800)),
    );
  }
}

class PatientSymptom {
  PatientSymptom({required this.name, required this.intensity, required this.date, required this.notes});
  final String name;
  final int intensity;
  final DateTime date;
  final String notes;
}

enum VitalType { tension, glycemia, weight }

extension VitalTypeX on VitalType {
  String get label => switch (this) { VitalType.tension => 'Tension', VitalType.glycemia => 'Glycémie', VitalType.weight => 'Poids' };
  IconData get icon => switch (this) { VitalType.tension => Icons.monitor_heart_rounded, VitalType.glycemia => Icons.bloodtype_rounded, VitalType.weight => Icons.monitor_weight_rounded };
  Color get color => switch (this) { VitalType.tension => const Color(0xFF2453FF), VitalType.glycemia => const Color(0xFF10B981), VitalType.weight => const Color(0xFFFF6B00) };
}

class PatientVital {
  PatientVital({required this.type, required this.value1, this.value2, required this.date});
  final VitalType type;
  final double value1;
  final double? value2;
  final DateTime date;

  double get normalizedHeight {
    switch (type) {
      case VitalType.tension:
        return (value1 / 180).clamp(0.2, 1.0);
      case VitalType.glycemia:
        return (value1 / 2).clamp(0.2, 1.0);
      case VitalType.weight:
        return (value1 / 120).clamp(0.2, 1.0);
    }
  }
}

class PatientTreatment {
  PatientTreatment({required this.name, required this.dosage, required this.schedule, required this.start, required this.end, required this.alerts});
  final String name;
  final String dosage;
  final String schedule;
  final DateTime start;
  final DateTime end;
  final bool alerts;

  PatientTreatment copyWith({bool? alerts}) => PatientTreatment(name: name, dosage: dosage, schedule: schedule, start: start, end: end, alerts: alerts ?? this.alerts);
}

class PatientAppointment {
  PatientAppointment({required this.kind, required this.doctor, required this.reason, required this.when, required this.status, this.teleconsultationRoom});
  final String kind;
  final String doctor;
  final String reason;
  final DateTime when;
  final String status;
  final String? teleconsultationRoom;

  PatientAppointment copyWith({DateTime? when, String? status}) => PatientAppointment(kind: kind, doctor: doctor, reason: reason, when: when ?? this.when, status: status ?? this.status, teleconsultationRoom: teleconsultationRoom);
}

class PatientDocument {
  PatientDocument({required this.type, required this.title, required this.date});
  final String type;
  final String title;
  final DateTime date;
}

class WellnessArticle {
  const WellnessArticle({required this.title, required this.tag, required this.description, required this.icon, required this.color});
  final String title;
  final String tag;
  final String description;
  final IconData icon;
  final Color color;
}

class _AdminCard {
  const _AdminCard({required this.title, required this.subtitle, required this.icon, required this.color});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}