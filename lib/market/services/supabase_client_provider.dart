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
  static DateTime? _initStartedAt;

  static bool get isInitialized => _initialized;
  static Object? get initError => _initError;
  static DateTime? get initStartedAt => _initStartedAt;

  static bool get isInitInFlight => _initStartedAt != null && !_initialized && _initError == null;

  static String _mask(String value) {
    if (value.isEmpty) return '';
    if (value.length <= 10) return '***';
    return '${value.substring(0, 6)}…${value.substring(value.length - 4)}';
  }

  static void resetForRetry() {
    _initialized = false;
    _initError = null;
    _initStartedAt = null;
  }

  static bool _looksLikeJwt(String token) => token.split('.').length == 3;

  /// Initializes Supabase using env vars.
  /// Returns `true` when ready; `false` when missing configuration.
  static Future<bool> initializeFromEnv() async {
    if (_initialized) return true;
    try {
      _initStartedAt ??= DateTime.now();
      // Dreamflow can provide the URL/key via the generated SupabaseConfig file.
      // In some environments (Preview/Publish), `--dart-define` values may be
      // absent, so we fall back to SupabaseConfig.
      const envUrl = String.fromEnvironment('SUPABASE_URL');
      const envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

      final url = envUrl.isNotEmpty ? envUrl : SupabaseConfig.supabaseUrl;
      final anonKey = envAnonKey.isNotEmpty ? envAnonKey : SupabaseConfig.anonKey;
      if (url.isEmpty || anonKey.isEmpty) throw Exception('Missing Supabase configuration (URL / anon key)');
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme || !(uri.scheme == 'https' || uri.scheme == 'http')) {
        throw Exception('Invalid Supabase URL: "$url"');
      }
      if (!_looksLikeJwt(anonKey)) {
        throw Exception('Invalid Supabase anon key format (expected JWT)');
      }

      debugPrint('Supabase init: url=${uri.host}, anonKey=${_mask(anonKey)}');

      // On published web builds, we must avoid waiting forever.
      await Supabase.initialize(url: url, anonKey: anonKey, debug: kDebugMode).timeout(const Duration(seconds: 8));
      _initialized = true;
      _initError = null;
      _initStartedAt = null;
      return true;
    } catch (e) {
      _initialized = false;
      _initError = e;
      _initStartedAt = null;
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
