import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_central/auth/services/thix_profile_service.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';

/// Authentication Manager - base interface for auth implementations.
///
/// In this project, the concrete implementation is [SupabaseAuthManager].
abstract class AuthManager {
  Future<void> signOut();
  Future<void> deleteUser(BuildContext context);
  Future<void> updateEmail({required String email, required BuildContext context});
  Future<void> resetPassword({required String email, required BuildContext context});

  /// Optional: Supabase email verification is typically handled by settings.
  /// We keep this method for API parity.
  Future<void> sendEmailVerification({required User user});

  /// Optional: refresh auth state/user.
  Future<User?> refreshUser({required User user});
}

/// Email/password authentication mixin.
mixin EmailSignInManager on AuthManager {
  Future<User?> signInWithEmail(BuildContext context, String email, String password);
  Future<User?> createAccountWithEmail(BuildContext context, String email, String password);
}

/// Concrete Supabase implementation.
///
/// Notes (Dreamflow guidelines):
/// - Single source of truth is Supabase session.
/// - We do *not* immediately load user profile data here.
/// - We *do* ensure a minimal row exists in your profile tables.
class SupabaseAuthManager extends AuthManager with EmailSignInManager {
  SupabaseAuthManager({ThixProfileService? profileService}) : _profileService = profileService ?? const ThixProfileService();

  final ThixProfileService _profileService;

  SupabaseClient get _client => SupabaseClientProvider.client;

  @override
  Future<User?> signInWithEmail(BuildContext context, String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(email: email.trim(), password: password);
      final user = res.user;
      if (user != null) {
        // Best-effort: ensure minimal profile rows exist.
        unawaited(_profileService.ensureMyProfile());
        unawaited(_profileService.ensureMyUserRow(email: user.email));
      }
      return user;
    } catch (e) {
      debugPrint('Supabase signInWithEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<User?> createAccountWithEmail(BuildContext context, String email, String password) async {
    try {
      final res = await _client.auth.signUp(email: email.trim(), password: password);
      final user = res.user;
      if (user != null) {
        // Best-effort: create a companion row in `public.users` (and/or profiles).
        unawaited(_profileService.ensureMyUserRow(email: user.email));
      }
      return user;
    } catch (e) {
      debugPrint('Supabase createAccountWithEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Supabase signOut failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(BuildContext context) async {
    // Deleting a Supabase user requires a server-side call (service role key).
    // Keep as an explicit unsupported operation in the client.
    throw UnsupportedError('User deletion must be performed server-side (service role).');
  }

  @override
  Future<void> updateEmail({required String email, required BuildContext context}) async {
    try {
      await _client.auth.updateUser(UserAttributes(email: email.trim()));
    } catch (e) {
      debugPrint('Supabase updateEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({required String email, required BuildContext context}) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } catch (e) {
      debugPrint('Supabase resetPassword failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendEmailVerification({required User user}) async {
    // Supabase handles email verification via confirmation emails.
    // No direct equivalent call is needed here.
    return;
  }

  @override
  Future<User?> refreshUser({required User user}) async {
    try {
      // There is no direct refresh() on User. We can refresh the session.
      await _client.auth.refreshSession();
      return _client.auth.currentUser;
    } catch (e) {
      debugPrint('Supabase refreshUser failed: $e');
      return _client.auth.currentUser;
    }
  }
}
