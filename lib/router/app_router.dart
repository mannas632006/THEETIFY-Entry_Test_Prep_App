// ===========================================================================
// lib/router/app_router.dart
// ---------------------------------------------------------------------------
// This file decides WHICH SCREEN the user sees and how they move between them.
// Think of it as the map of the app. Each "route" below is one screen.
// ===========================================================================

import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/exam_list_screen.dart';
import '../screens/topic_list_screen.dart';
import '../screens/topic_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/admin_screen.dart';

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
      builder: (context, state) => const AdminScreen(),
    ),
    // The list of exams (NUST NET, SAT, etc.).
    GoRoute(
      path: '/exams',
      builder: (context, state) => const ExamListScreen(),
    ),
    // The list of topics for ONE exam. The exam id is in the address; the
    // exam name rides along as a ?name= query so we can show it in the title.
    GoRoute(
      path: '/exam/:examId',
      builder: (context, state) => TopicListScreen(
        examId: state.pathParameters['examId'] ?? '',
        examName: state.uri.queryParameters['name'] ?? 'Topics',
      ),
    ),
    // A single topic's study page. The topic id is in the address (this is
    // what lets us load its saved content); the topic name comes from ?name=.
    GoRoute(
      path: '/topic/:topicId',
      builder: (context, state) => TopicScreen(
        topicId: state.pathParameters['topicId'] ?? '',
        topicName: state.uri.queryParameters['name'] ?? 'Topic',
      ),
    ),
  ],
);