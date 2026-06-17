// ===========================================================================
// lib/screens/topic_screen.dart
// ---------------------------------------------------------------------------
// A single topic's study page (6 tabs). Now also:
//   - records this as the student's "last viewed" topic (for the dashboard),
//   - lets the student BOOKMARK the topic (app bar),
//   - lets the student MARK it COMPLETE (app bar),
//   - passes the topic id to the quiz so scores are saved to history.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../services/auth_service.dart';
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

  bool _bookmarked = false;
  bool _completed = false;

  bool get _loggedIn => AuthService.isLoggedIn;

  @override
  void initState() {
    super.initState();
    final id = widget.topicId;
    if (id != null && id.isNotEmpty) {
      _contentFuture = ContentService.getTopicContent(id);
      if (_loggedIn) {
        ContentService.setLastViewed(id, widget.topicName);
        _loadStatus(id);
      }
    }
  }

  Future<void> _loadStatus(String id) async {
    final b = await ContentService.isBookmarked(id);
    final c = await ContentService.isTopicCompleted(id);
    if (!mounted) return;
    setState(() {
      _bookmarked = b;
      _completed = c;
    });
  }

  Future<void> _toggleBookmark() async {
    final id = widget.topicId;
    if (id == null || id.isEmpty) return;
    final next = !_bookmarked;
    setState(() => _bookmarked = next);
    await ContentService.setBookmark(id, widget.topicName, next);
  }

  Future<void> _toggleComplete() async {
    final id = widget.topicId;
    if (id == null || id.isEmpty) return;
    final next = !_completed;
    setState(() => _completed = next);
    if (next) {
      await ContentService.markTopicComplete(id);
    } else {
      await ContentService.unmarkTopicComplete(id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next ? 'Marked complete' : 'Marked not complete')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasId = widget.topicId != null && widget.topicId!.isNotEmpty;

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.topicName),
          actions: [
            if (hasId && _loggedIn) ...[
              IconButton(
                tooltip: _bookmarked ? 'Remove bookmark' : 'Bookmark',
                icon: Icon(
                    _bookmarked ? Icons.bookmark : Icons.bookmark_border),
                onPressed: _toggleBookmark,
              ),
              IconButton(
                tooltip: _completed ? 'Mark not complete' : 'Mark complete',
                icon: Icon(_completed
                    ? Icons.check_circle
                    : Icons.check_circle_outline),
                onPressed: _toggleComplete,
              ),
            ],
          ],
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
                _hasText(htmlLesson)
                    ? HtmlIframe(html: htmlLesson!)
                    : _empty('The lesson has not been generated yet.'),
                _scrollable(
                  _hasText(deepNotes)
                      ? HtmlWidget(markdownToHtml(deepNotes!))
                      : const Text(
                          'In-depth notes have not been generated yet.'),
                ),
                _scrollable(
                  _hasText(crashNotes)
                      ? HtmlWidget(markdownToHtml(crashNotes!))
                      : const Text('Crash notes have not been generated yet.'),
                ),
                _hasText(quizJson)
                    ? QuizView(
                        quizJson: quizJson!,
                        topicId: widget.topicId,
                        topicName: widget.topicName,
                      )
                    : _empty('The quiz has not been generated yet.'),
                AiTeacherChat(examContext: widget.topicName),
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