import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/pages/profile/models/profile_models.dart';

class ProfileDashboardService {
  const ProfileDashboardService();

  SupabaseClient get _client => SupabaseClientProvider.client;

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Not authenticated');
    return uid;
  }

  // ----- Profil général -----
  Future<ProfileDetailsModel?> getMyDetails() async {
    final uid = _requireUid();
    try {
      final row = await _client.from('profile_details').select('*').eq('user_id', uid).maybeSingle();
      if (row == null) return null;
      return ProfileDetailsModel.fromJson(row);
    } catch (e) {
      debugPrint('getMyDetails failed: $e');
      return null;
    }
  }

  Future<ProfileDetailsModel> upsertMyDetails(ProfileDetailsModel patch) async {
    final uid = _requireUid();
    try {
      final row = await _client
          .from('profile_details')
          .upsert(patch.toJson()..['user_id'] = uid)
          .select('*')
          .single();
      return ProfileDetailsModel.fromJson(row);
    } catch (e) {
      debugPrint('upsertMyDetails failed: $e');
      rethrow;
    }
  }

  // ----- Contacts d'urgence -----
  Future<List<EmergencyContactModel>> listMyEmergencyContacts() async {
    final uid = _requireUid();
    try {
      final rows = await _client.from('emergency_contacts').select('*').eq('user_id', uid).order('created_at', ascending: false);
      return rows.map<EmergencyContactModel>((e) => EmergencyContactModel.fromJson(e)).toList(growable: false);
    } catch (e) {
      debugPrint('listMyEmergencyContacts failed: $e');
      return const [];
    }
  }

  Future<void> upsertEmergencyContact({String? id, required String name, required String phone, String? relationship, String? city}) async {
    final uid = _requireUid();
    final payload = <String, dynamic>{
      if (id != null) 'id': id,
      'user_id': uid,
      'name': name.trim(),
      'phone': phone.trim(),
      'relationship': relationship?.trim().isEmpty == true ? null : relationship?.trim(),
      'city': city?.trim().isEmpty == true ? null : city?.trim(),
    };
    try {
      await _client.from('emergency_contacts').upsert(payload);
    } catch (e) {
      debugPrint('upsertEmergencyContact failed: $e');
      rethrow;
    }
  }

  Future<void> deleteEmergencyContact(String id) async {
    try {
      await _client.from('emergency_contacts').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteEmergencyContact failed: $e');
      rethrow;
    }
  }

  // ----- Expériences -----
  Future<List<ProfileExperienceModel>> listMyExperiences() async {
    final uid = _requireUid();
    try {
      final rows = await _client.from('profile_experiences').select('*').eq('user_id', uid).order('start_date', ascending: false).order('created_at', ascending: false);
      return rows.map<ProfileExperienceModel>((e) => ProfileExperienceModel.fromJson(e)).toList(growable: false);
    } catch (e) {
      debugPrint('listMyExperiences failed: $e');
      return const [];
    }
  }

  Future<void> upsertExperience(ProfileExperienceModel model) async {
    final uid = _requireUid();
    try {
      await _client.from('profile_experiences').upsert(model.toJson()..['user_id'] = uid);
    } catch (e) {
      debugPrint('upsertExperience failed: $e');
      rethrow;
    }
  }

  Future<void> deleteExperience(String id) async {
    try {
      await _client.from('profile_experiences').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteExperience failed: $e');
      rethrow;
    }
  }

  // ----- Formations -----
  Future<List<ProfileEducationModel>> listMyEducation() async {
    final uid = _requireUid();
    try {
      final rows = await _client.from('profile_education').select('*').eq('user_id', uid).order('end_year', ascending: false).order('created_at', ascending: false);
      return rows.map<ProfileEducationModel>((e) => ProfileEducationModel.fromJson(e)).toList(growable: false);
    } catch (e) {
      debugPrint('listMyEducation failed: $e');
      return const [];
    }
  }

  Future<void> upsertEducation(ProfileEducationModel model) async {
    final uid = _requireUid();
    try {
      await _client.from('profile_education').upsert(model.toJson()..['user_id'] = uid);
    } catch (e) {
      debugPrint('upsertEducation failed: $e');
      rethrow;
    }
  }

  Future<void> deleteEducation(String id) async {
    try {
      await _client.from('profile_education').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteEducation failed: $e');
      rethrow;
    }
  }

  // ----- Compétences -----
  Future<List<ProfileSkillModel>> listMySkills() async {
    final uid = _requireUid();
    try {
      final rows = await _client.from('profile_skills').select('*').eq('user_id', uid).order('created_at', ascending: false);
      return rows.map<ProfileSkillModel>((e) => ProfileSkillModel.fromJson(e)).toList(growable: false);
    } catch (e) {
      debugPrint('listMySkills failed: $e');
      return const [];
    }
  }

  Future<void> upsertSkill(ProfileSkillModel model) async {
    final uid = _requireUid();
    try {
      await _client.from('profile_skills').upsert(model.toJson()..['user_id'] = uid);
    } catch (e) {
      debugPrint('upsertSkill failed: $e');
      rethrow;
    }
  }

  Future<void> deleteSkill(String id) async {
    try {
      await _client.from('profile_skills').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteSkill failed: $e');
      rethrow;
    }
  }

  // ----- Langues -----
  Future<List<ProfileLanguageModel>> listMyLanguages() async {
    final uid = _requireUid();
    try {
      final rows = await _client.from('profile_languages').select('*').eq('user_id', uid).order('created_at', ascending: false);
      return rows.map<ProfileLanguageModel>((e) => ProfileLanguageModel.fromJson(e)).toList(growable: false);
    } catch (e) {
      debugPrint('listMyLanguages failed: $e');
      return const [];
    }
  }

  Future<void> upsertLanguage(ProfileLanguageModel model) async {
    final uid = _requireUid();
    try {
      await _client.from('profile_languages').upsert(model.toJson()..['user_id'] = uid);
    } catch (e) {
      debugPrint('upsertLanguage failed: $e');
      rethrow;
    }
  }

  Future<void> deleteLanguage(String id) async {
    try {
      await _client.from('profile_languages').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteLanguage failed: $e');
      rethrow;
    }
  }

  // ----- Documents -----
  Future<List<ProfileDocumentModel>> listMyDocuments({String? docType}) async {
    final uid = _requireUid();
    try {
      var query = _client.from('profile_documents').select('*').eq('user_id', uid);
      if (docType != null && docType.trim().isNotEmpty) {
        query = query.eq('doc_type', docType.trim());
      }
      final rows = await query.order('created_at', ascending: false);
      return rows.map<ProfileDocumentModel>((e) => ProfileDocumentModel.fromJson(e)).toList(growable: false);
    } catch (e) {
      debugPrint('listMyDocuments failed: $e');
      return const [];
    }
  }

  Future<void> createDocument({required String docType, String? label, String? fileUrl, Map<String, dynamic>? kycPack}) async {
    final uid = _requireUid();
    final payload = <String, dynamic>{
      'user_id': uid,
      'doc_type': docType,
      'label': label,
      'file_url': fileUrl,
      if (kycPack != null) 'kyc_pack': kycPack,
    };
    try {
      await _client.from('profile_documents').insert(payload);
    } catch (e) {
      debugPrint('createDocument failed: $e');
      rethrow;
    }
  }

  Future<void> deleteDocument(String id) async {
    try {
      await _client.from('profile_documents').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteDocument failed: $e');
      rethrow;
    }
  }

  // ----- Sécurité -----
  Future<ProfileSecuritySettingsModel?> getMySecuritySettings() async {
    final uid = _requireUid();
    try {
      final row = await _client.from('profile_security_settings').select('*').eq('user_id', uid).maybeSingle();
      if (row == null) return null;
      return ProfileSecuritySettingsModel.fromJson(row);
    } catch (e) {
      debugPrint('getMySecuritySettings failed: $e');
      return null;
    }
  }

  Future<ProfileSecuritySettingsModel> upsertMySecuritySettings({required bool biometricsEnabled, required bool twoFaEnabled}) async {
    final uid = _requireUid();
    final payload = <String, dynamic>{
      'user_id': uid,
      'biometrics_enabled': biometricsEnabled,
      'two_fa_enabled': twoFaEnabled,
    };
    try {
      final row = await _client.from('profile_security_settings').upsert(payload).select('*').single();
      return ProfileSecuritySettingsModel.fromJson(row);
    } catch (e) {
      debugPrint('upsertMySecuritySettings failed: $e');
      rethrow;
    }
  }

  Future<void> logSecurityEvent(String eventType, {Map<String, dynamic>? details}) async {
    final uid = _requireUid();
    try {
      await _client.from('profile_security_events').insert({
        'user_id': uid,
        'event_type': eventType,
        if (details != null) 'details': details,
      });
    } catch (e) {
      debugPrint('logSecurityEvent failed (ignored): $e');
    }
  }

  Future<List<ProfileSecurityEventModel>> listMySecurityEvents({int limit = 60}) async {
    final uid = _requireUid();
    try {
      final rows = await _client.from('profile_security_events')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map<ProfileSecurityEventModel>((e) => ProfileSecurityEventModel.fromJson(e)).toList(growable: false);
    } catch (e) {
      debugPrint('listMySecurityEvents failed: $e');
      return const [];
    }
  }
}
