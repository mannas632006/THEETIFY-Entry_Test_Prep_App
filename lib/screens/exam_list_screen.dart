// ===========================================================================
// lib/screens/exam_list_screen.dart
// ---------------------------------------------------------------------------
// Shows the list of exams a student can prepare for, loaded LIVE from the
// Supabase database. If the database has no exams yet, it shows a friendly
// message telling you to add some from the Admin Dashboard (coming soon).
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/content_service.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  // This 'future' holds the exams once they finish loading from the database.
  late Future<List<Map<String, dynamic>>> _examsFuture;

  @override
  void initState() {
    super.initState();
    // Start loading the exams as soon as the screen opens.
    _examsFuture = ContentService.getExams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose an Exam'),
        actions: [
          // A logout button in the top-right corner.
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      // FutureBuilder shows a spinner while loading, then the result.
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _examsFuture,
        builder: (context, snapshot) {
          // Still loading: show a spinner.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Something went wrong: show the error.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load exams: ${snapshot.error}'),
              ),
            );
          }

          final exams = snapshot.data ?? [];

          // No exams yet: friendly empty message.
          if (exams.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No exams yet.\nAdd some from the Admin Dashboard (coming soon).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // Show the exams as a tappable list.
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              return Card(
                child: ListTile(
                  title: Text(exam['name'] ?? 'Unnamed exam'),
                  subtitle: exam['description'] != null
                      ? Text(exam['description'])
                      : null,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  // Opens a sample topic for now. Real topic list comes next.
                  onTap: () => context.go('/exam/${exam['id']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
