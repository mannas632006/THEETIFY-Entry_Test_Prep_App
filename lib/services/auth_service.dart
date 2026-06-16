// ===========================================================================
// lib/services/auth_service.dart
// ---------------------------------------------------------------------------
// Handles LOGIN, SIGNUP, and LOGOUT using Supabase.
// ===========================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AuthService {
  // The single email allowed into the Admin Dashboard.
  static const String adminEmail = 'f240576@cfd.nu.edu.pk';

  static SupabaseClient get _client => Supabase.instance.client;

  static bool get isLoggedIn =>
      AppConfig.hasSupabase && _client.auth.currentUser != null;

  static String? get currentEmail => _client.auth.currentUser?.email;

  // The current logged-in user's id (or null).
  static String? get currentUserId => _client.auth.currentUser?.id;

  // Is the current user the admin? Async so callers can wait for the session.
  static Future<bool> isAdmin() async {
    if (!AppConfig.hasSupabase) return false;
    final email = _client.auth.currentUser?.email;
    if (email == null) return false;
    return email.toLowerCase() == adminEmail.toLowerCase();
  }

  static Future<String?> signUp(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  static Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}