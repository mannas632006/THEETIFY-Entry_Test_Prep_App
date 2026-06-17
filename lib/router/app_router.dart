// ===========================================================================
// lib/router/app_router.dart
// ---------------------------------------------------------------------------
// The map of the app: which screen each web address shows. Also redirects
// already-logged-in visitors away from the welcome page to their dashboard.
// ===========================================================================

import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/exam_list_screen.dart';
import '../screens/topic_list_screen.dart';
import '../screens/topic_screen.dart';
import '../screens/timetable_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/subscribe_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  // If a logged-in user lands on the welcome page, send them to their home.
  redirect: (context, state) {
    if (state.uri.path == '/' && AuthService.isLoggedIn) return '/dashboard';
    return null;
  },
  routes: [
    // Public landing / welcome screen.
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    // Login / create account. Open /login?mode=signup to start in sign-up mode.
    GoRoute(
      path: '/login',
      builder: (context, state) => AuthScreen(
        startInSignup: state.uri.queryParameters['mode'] == 'signup',
      ),
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
    GoRoute(
      path: '/subscribe',
      builder: (context, state) => const SubscribeScreen(),
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