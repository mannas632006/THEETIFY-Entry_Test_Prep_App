import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/home_screen.dart';
import '../screens/exam_list_screen.dart';
import '../screens/topic_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/admin_screen.dart';
import '../screens/topic_list_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) {
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
    GoRoute(
      path: '/topic/:topic',
      builder: (context, state) => TopicScreen(
        topicName: Uri.decodeComponent(
            state.pathParameters['topic'] ?? 'Unknown topic'),
        topicId: state.extra as String?,
      ),
    ),
  ],
);