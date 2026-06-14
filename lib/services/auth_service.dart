// ===========================================================================
// lib/services/auth_service.dart
// ---------------------------------------------------------------------------
// This file handles LOGIN, SIGNUP, and LOGOUT using Supabase.
// The rest of the app calls these simple functions instead of dealing with
// Supabase directly. That keeps things tidy and easy to change later.
// ===========================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AuthService {
  // The single email allowed into the Admin Dashboard. Change this if the
  // owner's email ever changes. (Later this can move to the profiles table.)
  static const String adminEmail = 'f240576@cfd.nu.edu.pk';

  // A shortcut to the Supabase client (only used when keys are present).
  static SupabaseClient get _client => Supabase.instance.client;

  // True if a user is currently logged in.
  static bool get isLoggedIn =>
      AppConfig.hasSupabase && _client.auth.currentUser != null;

  // The current user's email (or null if not logged in).
  static String? get currentEmail => _client.auth.currentUser?.email;

  // --- Is the current user the admin? ---
  // Async so the screen can wait while the session is confirmed, and so we
  // can later swap this for a real database role check without changing
  // callers. Returns false if Supabase is off or no one is logged in.
  static Future<bool> isAdmin() async {
    if (!AppConfig.hasSupabase) return false;
    final email = _client.auth.currentUser?.email;
    if (email == null) return false;
    return email.toLowerCase() == adminEmail.toLowerCase();
  }

  // --- Create a new account ---
  // Returns null on success, or an error message to show the user.
  static Future<String?> signUp(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message; // A friendly error like 'Password too short'.
    } catch (e) {
      return 'Something went wrong. Please try again.';
    }
  }

  // --- Log into an existing account ---
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

  // --- Log out ---
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}