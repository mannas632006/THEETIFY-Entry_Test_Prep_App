// ===========================================================================
// lib/theme/app_theme.dart
// ---------------------------------------------------------------------------
// This file controls how the app LOOKS: its colors, fonts, and button style.
// If you want to change the app's look later, this is the friendly place to do
// it. Change the color values below and the whole app updates.
// ===========================================================================

import 'package:flutter/material.dart';

class AppTheme {
  // --- Brand colors. Change these hex codes to re-skin the app. ---
  static const Color _navy = Color(0xFF0D1B2A);   // Main dark color.
  static const Color _accent = Color(0xFF1B98E0); // Bright blue highlight.

  // The app's light theme (default look).
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _accent,
          primary: _accent,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: _navy,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        // Rounded, friendly buttons.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}
