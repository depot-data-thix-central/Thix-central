import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';

class ThixProfileService {
  const ThixProfileService();

  SupabaseClient get _client => SupabaseClientProvider.client;

  Future<Map<String, dynamic>?> getMyProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final res = await _client.from('profiles').select('*').eq('user_id', user.id).maybeSingle();
    return res;
  }

  Future<Map<String, dynamic>> ensureMyProfile({String? displayName, String? country, DateTime? birthDate}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');

    final patch = <String, dynamic>{'user_id': user.id};
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
    } catch (e) {
      debugPrint('ensureMyProfile failed: $e');
      rethrow;
    }
  }
}
