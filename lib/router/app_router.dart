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

// The list of all screens (pages) in the app and their web addresses.
final appRouter = GoRouter(
  initialLocation: '/', // The screen shown when the app first opens.
  routes: [
    // Home / welcome screen.
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // The list of exams (NUST NET, SAT, etc.).
    GoRoute(
      path: '/exams',
      builder: (context, state) => const ExamListScreen(),
    ),
    // A single topic page. The ':topic' part is the topic name in the address.
    GoRoute(
      path: '/topic/:topic',
      builder: (context, state) => TopicScreen(
        topicName: state.pathParameters['topic'] ?? 'Unknown topic',
      ),
    ),
  ],
);
