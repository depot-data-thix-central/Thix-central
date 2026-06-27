import 'package:flutter/material.dart';

const _defaultRoleOrder = [
  ThixRole.patient,
  ThixRole.doctor,
  ThixRole.pharmacy,
];

enum ThixRole { patient, doctor, pharmacy }

extension ThixRoleX on ThixRole {
  String get label {
    switch (this) {
      case ThixRole.patient:
        return 'Patient';
      case ThixRole.doctor:
        return 'Médecin';
      case ThixRole.pharmacy:
        return 'Pharmacie';
    }
  }

  String get shortLabel {
    switch (this) {
      case ThixRole.patient:
        return 'Santé';
      case ThixRole.doctor:
        return 'Cabinet';
      case ThixRole.pharmacy:
        return 'Officine';
    }
  }

  String get headline {
    switch (this) {
      case ThixRole.patient:
        return 'Votre santé entre de bonnes mains';
      case ThixRole.doctor:
        return 'Pilotez vos consultations et vos alertes';
      case ThixRole.pharmacy:
        return 'Sécurisez chaque ordonnance et chaque dispensation';
    }
  }

  String get subtitle {
    switch (this) {
      case ThixRole.patient:
        return 'Consultez, suivez et prenez soin de votre santé au quotidien.';
      case ThixRole.doctor:
        return 'Suivez vos patients, prescriptions et téléconsultations depuis une seule interface.';
      case ThixRole.pharmacy:
        return 'Gérez les ordonnances, le stock et les livraisons dans le même flux métier.';
    }
  }

  String get ctaLabel {
    switch (this) {
      case ThixRole.patient:
        return 'Dossier de santé';
      case ThixRole.doctor:
        return 'Agenda du jour';
      case ThixRole.pharmacy:
        return 'Valider les ordonnances';
    }
  }

  IconData get icon {
    switch (this) {
      case ThixRole.patient:
        return Icons.favorite_rounded;
      case ThixRole.doctor:
        return Icons.medical_services_rounded;
      case ThixRole.pharmacy:
        return Icons.local_pharmacy_rounded;
    }
  }

  Color get accent {
    switch (this) {
      case ThixRole.patient:
        return const Color(0xFF00C3A5);
      case ThixRole.doctor:
        return const Color(0xFF3F51FF);
      case ThixRole.pharmacy:
        return const Color(0xFFFF7A00);
    }
  }

  LinearGradient get gradient {
    switch (this) {
      case ThixRole.patient:
        return const LinearGradient(
          colors: [Color(0xFF1E56E6), Color(0xFF14C7B7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ThixRole.doctor:
        return const LinearGradient(
          colors: [Color(0xFF102A86), Color(0xFF5C7CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ThixRole.pharmacy:
        return const LinearGradient(
          colors: [Color(0xFFFF7A00), Color(0xFFFFB347)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String get domainHint {
    switch (this) {
      case ThixRole.patient:
        return '@patient.com';
      case ThixRole.doctor:
        return '@doctor.com';
      case ThixRole.pharmacy:
        return '@pharmacy.com';
    }
  }
}

class ThixRoleController extends ChangeNotifier {
  ThixRoleController._();

  static final ThixRoleController instance = ThixRoleController._();

  ThixRole _role = ThixRole.patient;
  bool _manualSelection = false;

  ThixRole get role => _role;
  bool get hasManualSelection => _manualSelection;
  List<ThixRole> get availableRoles => _defaultRoleOrder;

  static ThixRole detectFromEmail(String? email) {
    final normalized = email?.trim().toLowerCase() ?? '';
    if (normalized.endsWith('@doctor.com')) {
      return ThixRole.doctor;
    }
    if (normalized.endsWith('@pharmacy.com')) {
      return ThixRole.pharmacy;
    }
    return ThixRole.patient;
  }

  /// Applies automatic role detection only until the user chooses a role manually.
  void syncFromEmail(String? email) {
    if (_manualSelection) return;
    final detected = detectFromEmail(email);
    if (detected == _role) return;
    _role = detected;
    notifyListeners();
  }

  void selectRole(ThixRole nextRole, {bool manual = true}) {
    final selectionChanged = _role != nextRole;
    final modeChanged = _manualSelection != manual;
    if (!selectionChanged && !modeChanged) return;
    _role = nextRole;
    _manualSelection = manual;
    notifyListeners();
  }

  void resetToDetectedRole(String? email) {
    _manualSelection = false;
    syncFromEmail(email);
  }
}
