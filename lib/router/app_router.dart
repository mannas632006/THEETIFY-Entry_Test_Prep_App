// ===========================================================================
// lib/router/app_router.dart
// ---------------------------------------------------------------------------
// This file decides WHICH SCREEN the user sees and how they move between them.
// Think of it as the map of the app. Each "route" below is one screen.
// ===========================================================================

import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/exam_list_screen.dart';
import '../screens/topic_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/topic_list_screen.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// The list of all screens (pages) in the app and their web addresses.
final appRouter = GoRouter(
  initialLocation: '/', // The screen shown when the app first opens.
  routes: [
    // Home / welcome screen.
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // The login / create-account screen.
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
    // The Admin Dashboard (for the owner). Open it at /admin.
    GoRoute(
  path: '/admin',
  builder: (context, state) {
    // Give Supabase a moment to restore session, then check.
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    if (email != 'mannas.632006@gmail.com') {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Denied.\nYou are not authorized to view this page.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }
    return const AdminScreen();
  },
),
    }
    return const AdminScreen();
  },
),
    // The list of exams (NUST NET, SAT, etc.).
    GoRoute(
      path: '/exams',
      builder: (context, state) => const ExamListScreen(),
    ),
    GoRoute(
      path: '/exam/:examId',
      builder: (context, state) => TopicListScreen(
        examId: state.pathParameters['examId'] ?? '',
        examName: 'Topics',
      ),
    ),
    // A single topic page. The ':topic' part is the topic name in the address.
GoRoute(
  path: '/topic/:topic',
  builder: (context, state) => TopicScreen(
    topicName: Uri.decodeComponent(state.pathParameters['topic'] ?? 'Unknown topic'),
    topicId: state.extra as String?,
  ),
),
  ],
);
