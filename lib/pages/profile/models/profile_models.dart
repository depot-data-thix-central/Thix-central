import 'package:flutter/foundation.dart';

@immutable
class EmergencyContactModel {
  const EmergencyContactModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    required this.city,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String phone;
  final String? relationship;
  final String? city;
  final DateTime createdAt;
  final DateTime updatedAt;

  EmergencyContactModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? relationship,
    String? city,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      city: city ?? this.city,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static EmergencyContactModel fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      relationship: json['relationship']?.toString(),
      city: json['city']?.toString(),
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'city': city,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class ProfileDetailsModel {
  const ProfileDetailsModel({
    required this.userId,
    required this.fullName,
    required this.bio,
    required this.phone,
    required this.address,
    required this.city,
    required this.nationality,
    required this.maritalStatus,
    required this.birthPlace,
    required this.fatherName,
    required this.motherName,
    required this.accountStatus,
    required this.publicBio,
    required this.publicExperiences,
    required this.publicEducation,
    required this.publicSkills,
    required this.publicLanguages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final String? fullName;
  final String? bio;
  final String? phone;
  final String? address;
  final String? city;
  final String? nationality;
  final String? maritalStatus;
  final String? birthPlace;
  final String? fatherName;
  final String? motherName;
  final String accountStatus;
  final bool publicBio;
  final bool publicExperiences;
  final bool publicEducation;
  final bool publicSkills;
  final bool publicLanguages;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileDetailsModel copyWith({
    String? userId,
    String? fullName,
    String? bio,
    String? phone,
    String? address,
    String? city,
    String? nationality,
    String? maritalStatus,
    String? birthPlace,
    String? fatherName,
    String? motherName,
    String? accountStatus,
    bool? publicBio,
    bool? publicExperiences,
    bool? publicEducation,
    bool? publicSkills,
    bool? publicLanguages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileDetailsModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      nationality: nationality ?? this.nationality,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      birthPlace: birthPlace ?? this.birthPlace,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      accountStatus: accountStatus ?? this.accountStatus,
      publicBio: publicBio ?? this.publicBio,
      publicExperiences: publicExperiences ?? this.publicExperiences,
      publicEducation: publicEducation ?? this.publicEducation,
      publicSkills: publicSkills ?? this.publicSkills,
      publicLanguages: publicLanguages ?? this.publicLanguages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ProfileDetailsModel fromJson(Map<String, dynamic> json) {
    return ProfileDetailsModel(
      userId: (json['user_id'] ?? '').toString(),
      fullName: json['full_name']?.toString(),
      bio: json['bio']?.toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      nationality: json['nationality']?.toString(),
      maritalStatus: json['marital_status']?.toString(),
      birthPlace: json['birth_place']?.toString(),
      fatherName: json['father_name']?.toString(),
      motherName: json['mother_name']?.toString(),
      accountStatus: (json['thix_account_status'] ?? 'THIX-PENDING').toString(),
      publicBio: (json['public_bio'] as bool?) ?? true,
      publicExperiences: (json['public_experiences'] as bool?) ?? true,
      publicEducation: (json['public_education'] as bool?) ?? true,
      publicSkills: (json['public_skills'] as bool?) ?? true,
      publicLanguages: (json['public_languages'] as bool?) ?? true,
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'bio': bio,
      'phone': phone,
      'address': address,
      'city': city,
      'nationality': nationality,
      'marital_status': maritalStatus,
      'birth_place': birthPlace,
      'father_name': fatherName,
      'mother_name': motherName,
      'thix_account_status': accountStatus,
      'public_bio': publicBio,
      'public_experiences': publicExperiences,
      'public_education': publicEducation,
      'public_skills': publicSkills,
      'public_languages': publicLanguages,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class ProfileExperienceModel {
  const ProfileExperienceModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.organization,
    required this.sector,
    required this.city,
    required this.startDate,
    required this.endDate,
    required this.missions,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? organization;
  final String? sector;
  final String? city;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? missions;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileExperienceModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? organization,
    String? sector,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    String? missions,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileExperienceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      sector: sector ?? this.sector,
      city: city ?? this.city,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      missions: missions ?? this.missions,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  static ProfileExperienceModel fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final attachments = <String>[];
    if (rawAttachments is List) {
      for (final v in rawAttachments) {
        final s = v?.toString();
        if (s != null && s.trim().isNotEmpty) attachments.add(s);
      }
    }

    return ProfileExperienceModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      organization: json['organization']?.toString(),
      sector: json['sector']?.toString(),
      city: json['city']?.toString(),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      missions: json['missions']?.toString(),
      attachments: attachments,
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    String? toPgDate(DateTime? d) {
      if (d == null) return null;
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return '$y-$m-$dd';
    }

    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'organization': organization,
      'sector': sector,
      'city': city,
      'start_date': toPgDate(startDate),
      'end_date': toPgDate(endDate),
      'missions': missions,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class ProfileEducationModel {
  const ProfileEducationModel({
    required this.id,
    required this.userId,
    required this.institution,
    required this.degree,
    required this.level,
    required this.startYear,
    required this.endYear,
    required this.description,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String institution;
  final String? degree;
  final String? level;
  final int? startYear;
  final int? endYear;
  final String? description;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileEducationModel copyWith({
    String? id,
    String? userId,
    String? institution,
    String? degree,
    String? level,
    int? startYear,
    int? endYear,
    String? description,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileEducationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      institution: institution ?? this.institution,
      degree: degree ?? this.degree,
      level: level ?? this.level,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ProfileEducationModel fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final attachments = <String>[];
    if (rawAttachments is List) {
      for (final v in rawAttachments) {
        final s = v?.toString();
        if (s != null && s.trim().isNotEmpty) attachments.add(s);
      }
    }
    int? asInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '');

    return ProfileEducationModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      institution: (json['institution'] ?? '').toString(),
      degree: json['degree']?.toString(),
      level: json['level']?.toString(),
      startYear: asInt(json['start_year']),
      endYear: asInt(json['end_year']),
      description: json['description']?.toString(),
      attachments: attachments,
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'institution': institution,
      'degree': degree,
      'level': level,
      'start_year': startYear,
      'end_year': endYear,
      'description': description,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class ProfileSkillModel {
  const ProfileSkillModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.level,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String level;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileSkillModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? level,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileSkillModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      level: level ?? this.level,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ProfileSkillModel fromJson(Map<String, dynamic> json) {
    return ProfileSkillModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      level: (json['level'] ?? 'beginner').toString(),
      description: json['description']?.toString(),
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'level': level,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class ProfileLanguageModel {
  const ProfileLanguageModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? level;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileLanguageModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? level,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileLanguageModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ProfileLanguageModel fromJson(Map<String, dynamic> json) {
    return ProfileLanguageModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      level: json['level']?.toString(),
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'level': level,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class ProfileDocumentModel {
  const ProfileDocumentModel({
    required this.id,
    required this.userId,
    required this.docType,
    required this.label,
    required this.fileUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String docType;
  final String? label;
  final String? fileUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ProfileDocumentModel fromJson(Map<String, dynamic> json) {
    return ProfileDocumentModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      docType: (json['doc_type'] ?? '').toString(),
      label: json['label']?.toString(),
      fileUrl: json['file_url']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
    );
  }
}

@immutable
class ProfileTransactionModel {
  const ProfileTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amountUsd,
    required this.method,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String type;
  final double amountUsd;
  final String method;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ProfileTransactionModel fromJson(Map<String, dynamic> json) {
    double asDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    return ProfileTransactionModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      type: (json['txn_type'] ?? '').toString(),
      amountUsd: asDouble(json['amount_usd']),
      method: (json['method'] ?? 'SIMULATED').toString(),
      status: (json['status'] ?? 'success').toString(),
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
    );
  }
}

@immutable
class ProfileSecuritySettingsModel {
  const ProfileSecuritySettingsModel({
    required this.userId,
    required this.biometricsEnabled,
    required this.twoFaEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  final String userId;
  final bool biometricsEnabled;
  final bool twoFaEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ProfileSecuritySettingsModel fromJson(Map<String, dynamic> json) {
    return ProfileSecuritySettingsModel(
      userId: (json['user_id'] ?? '').toString(),
      biometricsEnabled: (json['biometrics_enabled'] as bool?) ?? false,
      twoFaEnabled: (json['two_fa_enabled'] as bool?) ?? false,
      createdAt: _parseTs(json['created_at']),
      updatedAt: _parseTs(json['updated_at']),
    );
  }
}

@immutable
class ProfileSecurityEventModel {
  const ProfileSecurityEventModel({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String eventType;
  final DateTime createdAt;

  static DateTime _parseTs(dynamic v) {
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static ProfileSecurityEventModel fromJson(Map<String, dynamic> json) {
    return ProfileSecurityEventModel(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      eventType: (json['event_type'] ?? '').toString(),
      createdAt: _parseTs(json['created_at']),
    );
  }
}
