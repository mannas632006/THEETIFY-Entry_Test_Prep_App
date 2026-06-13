// ===========================================================================
// lib/main.dart
// ---------------------------------------------------------------------------
// This is the STARTING POINT of the whole app. When the app launches, this
// file runs first. In plain English, it does three things:
//   1. Loads your secret keys from the .env file.
//   2. Connects to Supabase (the login + database service).
//   3. Shows the first screen to the user.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

// The 'main' function is where every Flutter app begins.
Future<void> main() async {
  // Makes sure Flutter is fully ready before we do setup work.
  WidgetsFlutterBinding.ensureInitialized();

  // --- Step 1: Load secret keys from the .env file ---
  // If the file is missing, we still let the app start (helpful during early
  // testing), but features needing keys will be disabled until keys are added.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // No .env yet. That is OK for now; AppConfig handles missing values safely.
  }

  // --- Step 2: Connect to Supabase (only if keys are present) ---
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // --- Step 3: Start the app ---
  runApp(const TheetifyApp());
}

// This widget describes the overall app (its name, theme, and navigation).
class TheetifyApp extends StatelessWidget {
  const TheetifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'THEETIFY',
      debugShowCheckedModeBanner: false, // Hides the 'debug' ribbon.
      theme: AppTheme.light, // Our colors and fonts (see theme/app_theme.dart).
      routerConfig: appRouter, // Which screen to show (see router/app_router.dart).
    );
  }
}
