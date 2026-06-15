// ===========================================================================
// lib/screens/topic_screen.dart
// ---------------------------------------------------------------------------
// A single topic's study page. Loads the generated content for this topic and
// shows it across tabs:
//   - Lesson (interactive HTML inside a real iframe)
//   - Deep Notes (Markdown rendered as HTML)
//   - Crash Notes (Markdown rendered as HTML)
//   - Quiz (interactive)
//   - AI Teacher (live chat)
//   - Videos (YouTube search)
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../services/content_service.dart';
import '../utils/markdown.dart';
import '../widgets/ai_teacher_chat.dart';
import '../widgets/html_iframe.dart';
import '../widgets/quiz_view.dart';
import '../widgets/videos_view.dart';

class TopicScreen extends StatefulWidget {
  final String topicName;
  final String? topicId;
  const TopicScreen({super.key, required this.topicName, this.topicId});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  Future<Map<String, dynamic>?>? _contentFuture;

  @override
  void initState() {
    super.initState();
    final id = widget.topicId;
    if (id != null && id.isNotEmpty) {
      _contentFuture = ContentService.getTopicContent(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasId = widget.topicId != null && widget.topicId!.isNotEmpty;

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
            if (hasId &&
                snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final content = snapshot.data;
            final htmlLesson = content?['html_lesson'] as String?;
            final deepNotes = content?['deep_notes'] as String?;
            final crashNotes = content?['crash_notes'] as String?;
            final quizJson = content?['quiz_json'] as String?;

            return TabBarView(
              children: [
                // 1) Interactive HTML lesson inside a real iframe.
                _hasText(htmlLesson)
                    ? HtmlIframe(html: htmlLesson!)
                    : _empty('The lesson has not been generated yet.'),
                // 2) Deep notes (Markdown -> HTML).
                _scrollable(
                  _hasText(deepNotes)
                      ? HtmlWidget(markdownToHtml(deepNotes!))
                      : const Text(
                          'In-depth notes have not been generated yet.'),
                ),
                // 3) Crash notes (Markdown -> HTML).
                _scrollable(
                  _hasText(crashNotes)
                      ? HtmlWidget(markdownToHtml(crashNotes!))
                      : const Text('Crash notes have not been generated yet.'),
                ),
                // 4) Interactive quiz.
                _hasText(quizJson)
                    ? QuizView(quizJson: quizJson!)
                    : _empty('The quiz has not been generated yet.'),
                // 5) Live AI Teacher chat, locked to study topics only.
                AiTeacherChat(examContext: widget.topicName),
                // 6) Videos: YouTube search.
                VideosView(topicName: widget.topicName),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Widget _scrollable(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: child,
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}