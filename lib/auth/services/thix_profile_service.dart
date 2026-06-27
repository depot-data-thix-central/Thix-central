import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';

class ThixProfileService {
  const ThixProfileService();

  static String? _profileKey;
  static bool _fallbackTried = false;

  SupabaseClient get _client => SupabaseClientProvider.client;

  Future<String> _resolveProfileKey() async {
    if (_profileKey != null) return _profileKey!;
    try {
      await _client.from('profiles').select('user_id').limit(0);
      _profileKey = 'user_id';
    } on PostgrestException catch (e) {
      // Fallback to the common "id" column when user_id isn't present.
      if (e.code == 'PGRST204' || e.message.contains('user_id')) {
        _profileKey = 'id';
        _fallbackTried = true;
      } else {
        debugPrint('profiles key detection failed: $e');
        _profileKey = 'user_id';
      }
    } catch (e) {
      debugPrint('profiles key detection failed: $e');
      _profileKey = 'user_id';
    }
    return _profileKey!;
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final key = await _resolveProfileKey();
    try {
      final res = await _client.from('profiles').select('*').eq(key, user.id).maybeSingle();
      return res;
    } on PostgrestException catch (e) {
      if (key == 'user_id' && !_fallbackTried && (e.code == 'PGRST204' || e.message.contains('user_id'))) {
        _profileKey = 'id';
        _fallbackTried = true;
        return getMyProfile();
      }
      debugPrint('getMyProfile skipped: $e');
      return null;
    } catch (e) {
      debugPrint('getMyProfile skipped: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> ensureMyProfile({String? displayName, String? country, DateTime? birthDate}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final key = await _resolveProfileKey();
    final patch = <String, dynamic>{key: user.id};
    if (displayName != null && displayName.trim().isNotEmpty) patch['display_name'] = displayName.trim();
    if (country != null && country.trim().isNotEmpty) patch['country'] = country.trim();
    if (birthDate != null) {
      final y = birthDate.year.toString().padLeft(4, '0');
      final m = birthDate.month.toString().padLeft(2, '0');
      final d = birthDate.day.toString().padLeft(2, '0');
      patch['birth_date'] = '$y-$m-$d';
    }

    try {
      final row = await _client.from('profiles').upsert(patch).select('*').single();
      return row;
    } on PostgrestException catch (e) {
      if (key == 'user_id' && !_fallbackTried && (e.code == 'PGRST204' || e.message.contains('user_id'))) {
        _profileKey = 'id';
        _fallbackTried = true;
        return ensureMyProfile(displayName: displayName, country: country, birthDate: birthDate);
      }
      debugPrint('ensureMyProfile failed: $e');
      return patch;
    } catch (e) {
      debugPrint('ensureMyProfile failed: $e');
      return patch;
    }
  }

  /// Best-effort upsert into `public.users` table (if it exists in your DB).
  ///
  /// This aligns with the app signup form (nom/email/pays/date naissance).
  ///
  /// If the table is not deployed yet, we swallow the error to avoid blocking
  /// authentication flows.
  Future<void> ensureMyUserRow({String? email, String? fullName, String? country, DateTime? birthDate}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final payload = <String, dynamic>{
      'id': user.id,
      'email': (email ?? user.email ?? '').trim(),
      if (fullName != null && fullName.trim().isNotEmpty) 'full_name': fullName.trim(),
      if (country != null && country.trim().isNotEmpty) 'country': country.trim(),
      if (birthDate != null) 'birth_date': birthDate.toIso8601String(),
    };

    try {
      await _client.from('users').upsert(payload);
    } catch (e) {
      // Don't break auth UX if migration isn't applied yet.
      debugPrint('ensureMyUserRow skipped/failed: $e');
    }
  }
}
