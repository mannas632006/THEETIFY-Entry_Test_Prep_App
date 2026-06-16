// ===========================================================================
// lib/widgets/quiz_view.dart
// ---------------------------------------------------------------------------
// Shows a topic's quiz as interactive questions. Reads the AI-generated JSON,
// shows each question with tappable options, reveals the correct answer, and
// once every question is answered, shows the score and saves the attempt to
// the student's quiz history (if a topic id is provided and they're logged in).
// ===========================================================================

import 'dart:convert';
import 'package:flutter/material.dart';

import '../services/content_service.dart';

class QuizView extends StatefulWidget {
  final String quizJson;
  final String? topicId;
  final String? topicName;
  const QuizView({
    super.key,
    required this.quizJson,
    this.topicId,
    this.topicName,
  });

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  List<dynamic> _questions = [];
  final Map<int, String> _selected = {};
  String? _error;
  bool _saved = false; // so we only save the attempt once

  @override
  void initState() {
    super.initState();
    try {
      final text = widget.quizJson.trim();
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start != -1 && end != -1) {
        _questions = jsonDecode(text.substring(start, end + 1));
      } else {
        _error = 'Quiz could not be read.';
      }
    } catch (e) {
      _error = 'Quiz could not be read.';
    }
  }

  int _score() {
    var correct = 0;
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i] as Map<String, dynamic>;
      if (_selected[i] != null && _selected[i] == (q['answer'] ?? '')) {
        correct++;
      }
    }
    return correct;
  }

  void _onPick(int qIndex, String option) {
    setState(() => _selected[qIndex] = option);
    // When everything is answered, save the attempt once.
    if (_selected.length == _questions.length && !_saved) {
      _saved = true;
      if (widget.topicId != null) {
        ContentService.saveQuizAttempt(
          widget.topicId!,
          widget.topicName ?? 'Quiz',
          _score(),
          _questions.length,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_questions.isEmpty) {
      return const Center(child: Text('No quiz available yet.'));
    }

    final answeredAll = _selected.length == _questions.length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          children: [
            if (answeredAll) _scoreBanner(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _questions.length,
                itemBuilder: (context, qIndex) {
                  final q = _questions[qIndex] as Map<String, dynamic>;
                  final question = q['question'] ?? '';
                  final options = List<String>.from(q['options'] ?? []);
                  final correct = q['answer'] ?? '';
                  final picked = _selected[qIndex];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${qIndex + 1}. $question',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...options.map((option) {
                            Color? color;
                            if (picked != null) {
                              if (option == correct) {
                                color = Colors.green.shade100;
                              } else if (option == picked) {
                                color = Colors.red.shade100;
                              }
                            }
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                title: Text(option),
                                onTap: picked != null
                                    ? null
                                    : () => _onPick(qIndex, option),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBanner() {
    final score = _score();
    final total = _questions.length;
    final pct = total == 0 ? 0 : (score * 100 / total).round();
    final good = pct >= 60;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: good ? const Color(0x1F2E9E5B) : const Color(0x1FF4A623),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: good ? const Color(0xFF2E9E5B) : const Color(0xFFE08F1A)),
      ),
      child: Row(
        children: [
          Icon(good ? Icons.emoji_events : Icons.menu_book,
              color: good ? const Color(0xFF2E9E5B) : const Color(0xFFE08F1A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              good
                  ? 'Great work! You scored $score / $total ($pct%).'
                  : 'You scored $score / $total ($pct%). Review this topic and try again.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}