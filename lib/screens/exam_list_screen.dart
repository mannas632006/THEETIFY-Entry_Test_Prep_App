// ===========================================================================
// lib/screens/exam_list_screen.dart
// ---------------------------------------------------------------------------
// Shows the list of exams a student can prepare for. Tapping one will later
// open its topics. For now the list is a simple built-in sample so you can
// SEE the app working. Later this list comes from the database.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExamListScreen extends StatelessWidget {
  const ExamListScreen({super.key});

  // Temporary sample exams. Later these load automatically from Supabase.
  static const List<String> _sampleExams = [
    'NUST NET',
    'SAT',
    'LSAT',
    'NTS',
    'GIKI Entry Test',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose an Exam')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sampleExams.length,
        itemBuilder: (context, index) {
          final exam = _sampleExams[index];
          return Card(
            child: ListTile(
              title: Text(exam),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              // For now, tapping opens a sample topic. Later it opens the
              // exam's real list of topics.
              onTap: () => context.go('/topic/Trigonometry'),
            ),
          );
        },
      ),
    );
  }
}
