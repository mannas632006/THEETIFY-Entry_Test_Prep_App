// ===========================================================================
// lib/screens/topic_screen.dart
// ---------------------------------------------------------------------------
// The heart of the app: a single topic's study page. It LOADS the generated
// content for this topic from the database and shows it across tabs:
//   - Lesson (interactive HTML)
//   - Deep Notes
//   - Crash Notes (3-hour revision)
//   - Quiz (interactive)
//   - AI Teacher (live chat)
//   - Videos (coming next)
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../services/content_service.dart';
import '../widgets/ai_teacher_chat.dart';
import '../widgets/quiz_view.dart';

class TopicScreen extends StatefulWidget {
  // We accept BOTH a topic name (to show) and an optional topic id (to load
  // content from the database). When opened from the exam list, the id is set.
  final String topicName;
  final String? topicId;
  const TopicScreen({super.key, required this.topicName, this.topicId});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  // Holds the loaded content for this topic (null until loaded).
  Future<Map<String, dynamic>?>? _contentFuture;

  @override
  void initState() {
    super.initState();
    // If we have a topic id, load its saved content from the database.
    if (widget.topicId != null) {
      _contentFuture = ContentService.getTopicContent(widget.topicId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.topicName),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Lesson'),
              Tab(text: 'Deep Notes'),
              Tab(text: 'Crash Notes'),
              Tab(text: 'Quiz'),
              Tab(text: 'AI Teacher'),
              Tab(text: 'Videos'),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _contentFuture,
          builder: (context, snapshot) {
            // While loading content from the database, show a spinner.
            if (widget.topicId != null &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final content = snapshot.data; // may be null if nothing saved yet.

            return TabBarView(
              children: [
                // 1) Interactive HTML lesson (rendered as real HTML).
                _scrollable(
                  content?['html_lesson'] != null
                      ? HtmlWidget(content!['html_lesson'])
                      : _empty('The lesson has not been generated yet.'),
                ),
                // 2) Deep notes (plain text).
                _scrollable(Text(content?['deep_notes'] ??
                    'In-depth notes have not been generated yet.')),
                // 3) Crash notes (plain text).
                _scrollable(Text(content?['crash_notes'] ??
                    'Crash notes have not been generated yet.')),
                // 4) Interactive quiz.
                content?['quiz_json'] != null
                    ? QuizView(quizJson: content!['quiz_json'])
                    : _empty('The quiz has not been generated yet.'),
                // 5) Live AI Teacher chat, locked to study topics only.
                AiTeacherChat(examContext: widget.topicName),
                // 6) Videos (coming next).
                _empty('YouTube + AI video lectures will appear here.'),
              ],
            );
          },
        ),
      ),
    );
  }

  // Wraps content in scrolling + padding so long text reads nicely.
  Widget _scrollable(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  // A centered friendly message for empty tabs.
  Widget _empty(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
