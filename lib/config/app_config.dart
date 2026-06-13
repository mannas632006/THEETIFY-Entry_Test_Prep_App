// ===========================================================================
// lib/config/app_config.dart
// ---------------------------------------------------------------------------
// This file reads your secret keys (from the .env file) and makes them
// available to the rest of the app in a safe, central place.
//
// WHY THIS EXISTS: instead of scattering keys all over the code, every part
// of the app asks AppConfig for them. If you ever change a key, you only do
// it in your .env file. Nothing in the code needs to change.
// ===========================================================================

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // A small helper that safely reads a value from .env.
  // If the value is missing, it returns an empty string instead of crashing.
  static String _get(String name) => dotenv.maybeGet(name) ?? '';

  // --- AI provider settings ---
  // 'groq' for free testing now; change to 'claude' later in your .env file.
  static String get aiProvider =>
      _get('AI_PROVIDER').isEmpty ? 'groq' : _get('AI_PROVIDER');
  static String get groqApiKey => _get('GROQ_API_KEY');
  static String get claudeApiKey => _get('CLAUDE_API_KEY');

  // --- Supabase (login + database) ---
  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');

  // True only when BOTH Supabase values are present. The app checks this
  // before trying to connect, so it never crashes when keys are missing.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // True when the chosen AI provider has a key filled in.
  static bool get hasAi => aiProvider == 'claude'
      ? claudeApiKey.isNotEmpty
      : groqApiKey.isNotEmpty;

  // --- Other keys (used later) ---
  static String get youtubeApiKey => _get('YOUTUBE_API_KEY');
}
