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
}

class ThixRoleController extends ChangeNotifier {
  ThixRoleController._();

  static final ThixRoleController instance = ThixRoleController._();

  static const _allowedClaims = {
    'patient': ThixRole.patient,
    'doctor': ThixRole.doctor,
    'pharmacy': ThixRole.pharmacy,
  };

  ThixRole _role = ThixRole.patient;
  ThixRole? _verifiedRole;
  bool _manualSelection = false;
  List<ThixRole> _availableRoles = _defaultRoleOrder;

  ThixRole get role => _role;
  ThixRole? get verifiedRole => _verifiedRole;
  bool get hasManualSelection => _manualSelection;
  List<ThixRole> get availableRoles => _availableRoles;

  /// Syncs the UI role from trusted session metadata only.
  ///
  /// This controller is presentation-only and must not infer privileged access
  /// from spoofable values like email domains.
  void syncFromSession({Map<String, dynamic>? appMetadata, Map<String, dynamic>? userMetadata, String? email}) {
    final resolved = _parseRoleFromMetadata(appMetadata) ?? _parseRoleFromMetadata(userMetadata) ?? _roleFromEmail(email);
    final inferredRoles = _inferRoles(email: email, verified: _parseRoleFromMetadata(appMetadata) ?? _parseRoleFromMetadata(userMetadata));
    final updatedRoles = inferredRoles.isEmpty ? _defaultRoleOrder : inferredRoles;
    final availableChanged = !_listsEqual(_availableRoles, updatedRoles);

    if (resolved == _verifiedRole && (_manualSelection || resolved == _role || resolved == null) && !availableChanged) {
      return;
    }

    _verifiedRole = _parseRoleFromMetadata(appMetadata) ?? _parseRoleFromMetadata(userMetadata);
    _availableRoles = updatedRoles;
    if (!_manualSelection && resolved != null) {
      _role = resolved;
    }
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

  void resetToVerifiedRole() {
    if (_verifiedRole == null) return;
    _manualSelection = false;
    _role = _verifiedRole!;
    notifyListeners();
  }

  ThixRole? _parseRoleFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    final raw = (metadata['thix_role'] ?? metadata['role'])?.toString().trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;
    return _allowedClaims[raw];
  }

  List<ThixRole> _inferRoles({String? email, ThixRole? verified}) {
    final roles = <ThixRole>{};
    if (verified != null) roles.add(verified);
    final emailRole = _roleFromEmail(email);
    if (emailRole != null) roles.add(emailRole);
    roles.add(ThixRole.patient);
    return roles.toList()
      ..sort((a, b) => _defaultRoleOrder.indexOf(a).compareTo(_defaultRoleOrder.indexOf(b)));
  }

  ThixRole? _roleFromEmail(String? email) {
    if (email == null || !email.contains('@')) return null;
    final domain = email.split('@').last.toLowerCase();
    if (domain.endsWith('doctor.com')) return ThixRole.doctor;
    if (domain.endsWith('pharmacy.com')) return ThixRole.pharmacy;
    return ThixRole.patient;
  }

  bool _listsEqual(List<ThixRole> a, List<ThixRole> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
