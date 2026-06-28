import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';

/// Health module dependencies (models + repositories + providers).
///
/// This file exists to keep the Santé module self-contained and avoid relying on
/// legacy imports (old data/models and repository providers).

// -----------------------------------------------------------------------------
// Models
// -----------------------------------------------------------------------------

@immutable
class SymptomModel {
  const SymptomModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.intensity,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final String name;
  final int intensity;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  SymptomModel copyWith({
    String? id,
    String? patientId,
    String? name,
    int? intensity,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SymptomModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      intensity: intensity ?? this.intensity,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'name': name,
        'intensity': intensity,
        'date': date.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static SymptomModel? tryFromJson(Map<String, dynamic> json) {
    try {
      final patientId = (json['patient_id'] ?? '').toString();
      final name = (json['name'] ?? '').toString();
      if (patientId.isEmpty || name.isEmpty) return null;
      return SymptomModel(
        id: (json['id'] ?? '').toString(),
        patientId: patientId,
        name: name,
        intensity: (json['intensity'] as num?)?.toInt() ?? 0,
        date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
        notes: (json['notes'] as String?),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('SymptomModel.tryFromJson failed: $e');
      return null;
    }
  }
}

@immutable
class ConstantModel {
  const ConstantModel({
    required this.id,
    required this.patientId,
    required this.date,
    this.tensionSystolic,
    this.tensionDiastolic,
    this.glycemie,
    this.poids,
    this.taille,
    this.heartRate,
    this.temperature,
    this.spo2,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final DateTime date;
  final double? tensionSystolic;
  final double? tensionDiastolic;
  final double? glycemie;
  final double? poids;
  final double? taille;
  final double? heartRate;
  final double? temperature;
  final double? spo2;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConstantModel copyWith({
    String? id,
    String? patientId,
    DateTime? date,
    double? tensionSystolic,
    double? tensionDiastolic,
    double? glycemie,
    double? poids,
    double? taille,
    double? heartRate,
    double? temperature,
    double? spo2,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConstantModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      date: date ?? this.date,
      tensionSystolic: tensionSystolic ?? this.tensionSystolic,
      tensionDiastolic: tensionDiastolic ?? this.tensionDiastolic,
      glycemie: glycemie ?? this.glycemie,
      poids: poids ?? this.poids,
      taille: taille ?? this.taille,
      heartRate: heartRate ?? this.heartRate,
      temperature: temperature ?? this.temperature,
      spo2: spo2 ?? this.spo2,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'date': date.toIso8601String(),
        'tension_systolic': tensionSystolic,
        'tension_diastolic': tensionDiastolic,
        'glycemie': glycemie,
        'poids': poids,
        'taille': taille,
        'heart_rate': heartRate,
        'temperature': temperature,
        'spo2': spo2,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static ConstantModel? tryFromJson(Map<String, dynamic> json) {
    try {
      final patientId = (json['patient_id'] ?? '').toString();
      if (patientId.isEmpty) return null;
      return ConstantModel(
        id: (json['id'] ?? '').toString(),
        patientId: patientId,
        date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
        tensionSystolic: (json['tension_systolic'] as num?)?.toDouble(),
        tensionDiastolic: (json['tension_diastolic'] as num?)?.toDouble(),
        glycemie: (json['glycemie'] as num?)?.toDouble(),
        poids: (json['poids'] as num?)?.toDouble(),
        taille: (json['taille'] as num?)?.toDouble(),
        heartRate: (json['heart_rate'] as num?)?.toDouble(),
        temperature: (json['temperature'] as num?)?.toDouble(),
        spo2: (json['spo2'] as num?)?.toDouble(),
        notes: (json['notes'] as String?),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('ConstantModel.tryFromJson failed: $e');
      return null;
    }
  }
}

@immutable
class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.alert,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final String name;
  final String dosage;
  final String frequency;
  final bool? alert;
  final DateTime createdAt;
  final DateTime updatedAt;

  MedicationModel copyWith({
    String? id,
    String? patientId,
    String? name,
    String? dosage,
    String? frequency,
    bool? alert,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      alert: alert ?? this.alert,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'alert': alert,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static MedicationModel? tryFromJson(Map<String, dynamic> json) {
    try {
      final patientId = (json['patient_id'] ?? '').toString();
      final name = (json['name'] ?? '').toString();
      if (patientId.isEmpty || name.isEmpty) return null;
      return MedicationModel(
        id: (json['id'] ?? '').toString(),
        patientId: patientId,
        name: name,
        dosage: (json['dosage'] ?? '').toString(),
        frequency: (json['frequency'] ?? '').toString(),
        alert: json['alert'] as bool?,
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('MedicationModel.tryFromJson failed: $e');
      return null;
    }
  }
}

@immutable
class AppointmentModel {
  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    this.notes,
    this.teleRoom,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final DateTime date;
  final String time;
  final String status;
  final String? notes;
  final String? teleRoom;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppointmentModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? doctorId,
    String? doctorName,
    String? specialty,
    DateTime? date,
    String? time,
    String? status,
    String? notes,
    String? teleRoom,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      specialty: specialty ?? this.specialty,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      teleRoom: teleRoom ?? this.teleRoom,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'patient_name': patientName,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'specialty': specialty,
        'date': date.toIso8601String(),
        'time': time,
        'status': status,
        'notes': notes,
        'tele_room': teleRoom,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static AppointmentModel? tryFromJson(Map<String, dynamic> json) {
    try {
      final patientId = (json['patient_id'] ?? '').toString();
      if (patientId.isEmpty) return null;
      return AppointmentModel(
        id: (json['id'] ?? '').toString(),
        patientId: patientId,
        patientName: (json['patient_name'] ?? '').toString(),
        doctorId: (json['doctor_id'] ?? '').toString(),
        doctorName: (json['doctor_name'] ?? 'Médecin').toString(),
        specialty: (json['specialty'] ?? 'Généraliste').toString(),
        date: DateTime.tryParse((json['date'] ?? '').toString()) ?? DateTime.now(),
        time: (json['time'] ?? '').toString(),
        status: (json['status'] ?? 'pending').toString(),
        notes: json['notes'] as String?,
        teleRoom: json['tele_room'] as String?,
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.now(),
        updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('AppointmentModel.tryFromJson failed: $e');
      return null;
    }
  }
}

// -----------------------------------------------------------------------------
// Repositories (local-first persistence via SharedPreferences)
// -----------------------------------------------------------------------------

abstract class _JsonListStore<T> {
  String get storageKey;
  T? tryDecode(Map<String, dynamic> json);
  Map<String, dynamic> encode(T item);

  Future<List<T>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return <T>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <T>[];
      final items = <T>[];
      for (final e in decoded) {
        if (e is Map<String, dynamic>) {
          final item = tryDecode(e);
          if (item != null) items.add(item);
        }
      }
      // auto-sanitize
      await prefs.setString(storageKey, jsonEncode(items.map(encode).toList()));
      return items;
    } catch (e) {
      debugPrint('loadAll failed ($storageKey): $e');
      return <T>[];
    }
  }

  Future<void> saveAll(List<T> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, jsonEncode(items.map(encode).toList()));
    } catch (e) {
      debugPrint('saveAll failed ($storageKey): $e');
    }
  }
}

class SymptomRepository extends _JsonListStore<SymptomModel> {
  @override
  String get storageKey => 'health_symptoms_v1';

  @override
  SymptomModel? tryDecode(Map<String, dynamic> json) => SymptomModel.tryFromJson(json);

  @override
  Map<String, dynamic> encode(SymptomModel item) => item.toJson();

  Future<List<SymptomModel>> getSymptomsByPatient(String patientId) async {
    final all = await loadAll();
    final filtered = all.where((s) => s.patientId == patientId).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> addSymptom(SymptomModel symptom) async {
    final all = await loadAll();
    final id = symptom.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : symptom.id;
    all.add(symptom.copyWith(id: id));
    await saveAll(all);
  }
}

class ConstantRepository extends _JsonListStore<ConstantModel> {
  @override
  String get storageKey => 'health_constants_v1';

  @override
  ConstantModel? tryDecode(Map<String, dynamic> json) => ConstantModel.tryFromJson(json);

  @override
  Map<String, dynamic> encode(ConstantModel item) => item.toJson();

  Future<List<ConstantModel>> getConstantsByPatient(String patientId) async {
    final all = await loadAll();
    final filtered = all.where((c) => c.patientId == patientId).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> addConstant(ConstantModel constant) async {
    final all = await loadAll();
    final id = constant.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : constant.id;
    all.add(constant.copyWith(id: id));
    await saveAll(all);
  }
}

class MedicationRepository extends _JsonListStore<MedicationModel> {
  @override
  String get storageKey => 'health_medications_v1';

  @override
  MedicationModel? tryDecode(Map<String, dynamic> json) => MedicationModel.tryFromJson(json);

  @override
  Map<String, dynamic> encode(MedicationModel item) => item.toJson();

  Future<List<MedicationModel>> getActiveMedications(String patientId) async {
    final all = await loadAll();
    final filtered = all.where((m) => m.patientId == patientId).toList();
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  Future<void> updateMedication(MedicationModel medication) async {
    final all = await loadAll();
    final idx = all.indexWhere((m) => m.id == medication.id);
    if (idx == -1) {
      all.add(medication.copyWith(id: medication.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : medication.id));
    } else {
      all[idx] = medication;
    }
    await saveAll(all);
  }
}

class AppointmentRepository extends _JsonListStore<AppointmentModel> {
  @override
  String get storageKey => 'health_appointments_v1';

  @override
  AppointmentModel? tryDecode(Map<String, dynamic> json) => AppointmentModel.tryFromJson(json);

  @override
  Map<String, dynamic> encode(AppointmentModel item) => item.toJson();

  Future<List<AppointmentModel>> getAppointmentsByPatient(String patientId) async {
    final all = await loadAll();
    final filtered = all.where((a) => a.patientId == patientId).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  Future<void> createAppointment(AppointmentModel appt) async {
    final all = await loadAll();
    final id = appt.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : appt.id;
    all.add(appt.copyWith(id: id));
    await saveAll(all);
  }

  Future<void> updateAppointment(AppointmentModel appt) async {
    final all = await loadAll();
    final idx = all.indexWhere((a) => a.id == appt.id);
    if (idx == -1) {
      all.add(appt.copyWith(id: appt.id.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : appt.id));
    } else {
      all[idx] = appt;
    }
    await saveAll(all);
  }

  Future<void> cancelAppointment(String id) async {
    final all = await loadAll();
    all.removeWhere((a) => a.id == id);
    await saveAll(all);
  }
}

/// Kept for compatibility with older code in the dashboard.
class PatientRepository {
  const PatientRepository();
}

class StorageService {
  const StorageService();

  Future<List<Map<String, dynamic>>> listFiles({required String bucketName, required String folder}) async {
    // TODO: connect to Supabase Storage if/when a bucket is configured.
    return <Map<String, dynamic>>[];
  }
}

class NotificationService {
  const NotificationService();
}

class OpenAIService {
  OpenAIService({required SymptomRepository symptomRepository, required ConstantRepository constantRepository, required AppointmentRepository appointmentRepository, required MedicationRepository medicationRepository})
      : _symptoms = symptomRepository,
        _constants = constantRepository,
        _appointments = appointmentRepository,
        _medications = medicationRepository;

  final SymptomRepository _symptoms;
  final ConstantRepository _constants;
  final AppointmentRepository _appointments;
  final MedicationRepository _medications;

  /// Local-only fallback: returns a simple score derived from counts.
  ///
  /// When you connect a real Edge Function / OpenAI integration, this can be
  /// swapped without touching the UI.
  Future<Map<String, dynamic>?> getPredictiveAnalysis(String patientId) async {
    final symptoms = await _symptoms.getSymptomsByPatient(patientId);
    final constants = await _constants.getConstantsByPatient(patientId);
    final appointments = await _appointments.getAppointmentsByPatient(patientId);
    final medications = await _medications.getActiveMedications(patientId);

    final raw = 100 - (symptoms.length * 4) - (appointments.length * 2) + (constants.length * 1) + (medications.length * 1);
    final score = raw.clamp(0, 100);
    return {'healthScore': score};
  }
}

// -----------------------------------------------------------------------------
// Providers
// -----------------------------------------------------------------------------

final patientRepositoryProvider = Provider<PatientRepository>((ref) => const PatientRepository());
final symptomRepositoryProvider = Provider<SymptomRepository>((ref) => SymptomRepository());
final constantRepositoryProvider = Provider<ConstantRepository>((ref) => ConstantRepository());
final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) => AppointmentRepository());
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) => MedicationRepository());
final storageServiceProvider = Provider<StorageService>((ref) => const StorageService());
final notificationServiceProvider = Provider<NotificationService>((ref) => const NotificationService());

final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService(
    symptomRepository: ref.read(symptomRepositoryProvider),
    constantRepository: ref.read(constantRepositoryProvider),
    appointmentRepository: ref.read(appointmentRepositoryProvider),
    medicationRepository: ref.read(medicationRepositoryProvider),
  );
});

final currentPatientIdProvider = Provider<String>((ref) {
  return SupabaseClientProvider.clientOrNull?.auth.currentUser?.id ?? '';
});
