import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/supabase/supabase_config.dart';

/// Central place to initialize and access Supabase safely.
///
/// Dreamflow preview can run without `--dart-define` values. In that case,
/// `Supabase.initialize()` fails and calling `Supabase.instance` will crash.
class SupabaseClientProvider {
  static bool _initialized = false;
  static Object? _initError;

  static bool get isInitialized => _initialized;
  static Object? get initError => _initError;

  /// Initializes Supabase using env vars.
  /// Returns `true` when ready; `false` when missing configuration.
  static Future<bool> initializeFromEnv() async {
    if (_initialized) return true;
    try {
      // Dreamflow can provide the URL/key via the generated SupabaseConfig file.
      // In some environments (Preview/Publish), `--dart-define` values may be
      // absent, so we fall back to SupabaseConfig.
      const envUrl = String.fromEnvironment('SUPABASE_URL');
      const envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

      final url = envUrl.isNotEmpty ? envUrl : SupabaseConfig.supabaseUrl;
      final anonKey = envAnonKey.isNotEmpty ? envAnonKey : SupabaseConfig.anonKey;
      if (url.isEmpty || anonKey.isEmpty) {
        throw Exception('Missing Supabase configuration (URL / anon key)');
      }

      await Supabase.initialize(url: url, anonKey: anonKey, debug: kDebugMode);
      _initialized = true;
      _initError = null;
      return true;
    } catch (e) {
      _initialized = false;
      _initError = e;
      debugPrint('Supabase init failed: $e');
      return false;
    }
  }

  /// Safe getter. Returns null when Supabase wasn't initialized.
  static SupabaseClient? get clientOrNull {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  /// Strict getter used by services.
  /// Throws a readable error instead of the supabase_flutter assertion.
  static SupabaseClient get client {
    final c = clientOrNull;
    if (c == null) {
      throw StateError('Supabase not initialized. Please check Supabase connection / keys.');
    }
    return c;
  }
}
