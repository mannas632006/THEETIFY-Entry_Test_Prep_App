// ===========================================================================
// lib/screens/exam_list_screen.dart
// ---------------------------------------------------------------------------
// Shows the list of exams a student can prepare for, loaded LIVE from the
// Supabase database. Tapping an exam opens that exam's TOPIC LIST.
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
  late Future<List<Map<String, dynamic>>> _examsFuture;

  @override
  void initState() {
    super.initState();
    _examsFuture = ContentService.getExams();
  }

  // Opens an exam's topic list, passing its id (to load topics) and name.
  void _openExam(Map<String, dynamic> exam) {
    final id = exam['id']?.toString() ?? '';
    final name = exam['name']?.toString() ?? 'Topics';
    if (id.isEmpty) return;
    context.go(
      Uri(path: '/exam/$id', queryParameters: {'name': name}).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose an Exam'),
        actions: [
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _examsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load exams: ${snapshot.error}'),
              ),
            );
          }

          final exams = snapshot.data ?? [];

          if (exams.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, size: 48, color: Colors.black26),
                    SizedBox(height: 12),
                    Text(
                      'No exams yet.\nAdd some from the Admin Dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          // Centered and width-limited so it looks good on wide screens.
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exams.length,
                itemBuilder: (context, index) {
                  final exam = exams[index];
                  final desc = exam['description']?.toString();
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0x1F1B98E0),
                        child: Icon(Icons.school, color: Color(0xFF1B98E0)),
                      ),
                      title: Text(
                        exam['name'] ?? 'Unnamed exam',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      subtitle: Text(
                        (desc != null && desc.isNotEmpty)
                            ? desc
                            : 'Tap to see topics',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _openExam(exam),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}