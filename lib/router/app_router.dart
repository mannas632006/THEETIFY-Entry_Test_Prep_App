// ===========================================================================
// lib/router/app_router.dart
// ---------------------------------------------------------------------------
// The map of the app: which screen each web address shows.
// ===========================================================================

import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/exam_list_screen.dart';
import '../screens/topic_list_screen.dart';
import '../screens/topic_screen.dart';
import '../screens/timetable_screen.dart';
import '../screens/admin_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Public landing / welcome screen.
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // Login / create account.
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
    // The student's home dashboard (after login).
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    // The AI study timetable.
    GoRoute(
      path: '/timetable',
      builder: (context, state) => const TimetableScreen(),
    ),
    // The Admin Dashboard (owner only).
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminScreen(),
    ),
    // The list of exams.
    GoRoute(
      path: '/exams',
      builder: (context, state) => const ExamListScreen(),
    ),
    // The topics for one exam (exam id in path, name in ?name=).
    GoRoute(
      path: '/exam/:examId',
      builder: (context, state) => TopicListScreen(
        examId: state.pathParameters['examId'] ?? '',
        examName: state.uri.queryParameters['name'] ?? 'Topics',
      ),
    ),
    // A single topic's study page (topic id in path, name in ?name=).
    GoRoute(
      path: '/topic/:topicId',
      builder: (context, state) => TopicScreen(
        topicId: state.pathParameters['topicId'] ?? '',
        topicName: state.uri.queryParameters['name'] ?? 'Topic',
      ),
    ),
  ],
);