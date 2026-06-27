import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    try {
      const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
      const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Missing SUPABASE_URL / SUPABASE_ANON_KEY env vars');
      }
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
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
      throw StateError('Supabase not initialized. Complete Supabase Project Setup in Dreamflow.');
    }
    return c;
  }
}
