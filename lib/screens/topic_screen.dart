// ===========================================================================
// lib/screens/topic_screen.dart
// ---------------------------------------------------------------------------
// A single topic's study page. Content is now GATED: only subscribed students
// (or the admin) can open the material. Non-subscribers see a paywall. The
// topic name is still visible (they reach this from the public topic list);
// only the lessons/notes/quiz/AI-teacher are locked.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';

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
  bool _checkingAccess = true;
  bool _hasAccess = false;
  Future<Map<String, dynamic>?>? _contentFuture;

  bool _bookmarked = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final id = widget.topicId;

    // Record this as the last-viewed topic (so it shows on the dashboard).
    if (id != null && id.isNotEmpty && AuthService.isLoggedIn) {
      ContentService.setLastViewed(id, widget.topicName);
    }

    bool access = false;
    try {
      final subscribed = await ContentService.isSubscribed();
      final admin = await AuthService.isAdmin();
      access = subscribed || admin;
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _hasAccess = access;
      _checkingAccess = false;
      if (access && id != null && id.isNotEmpty) {
        _contentFuture = ContentService.getTopicContent(id);
      }
    });

    if (access && id != null && id.isNotEmpty) _loadStatus(id);
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
    // Checking access.
    if (_checkingAccess) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topicName)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Locked.
    if (!_hasAccess) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.topicName)),
        body: _paywall(),
      );
    }

    // Unlocked: the full study page.
    final hasId = widget.topicId != null && widget.topicId!.isNotEmpty;
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.topicName),
          actions: [
            if (hasId) ...[
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

  Widget _paywall() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0x1F1B98E0),
                child: Icon(Icons.lock_outline,
                    color: Color(0xFF1B98E0), size: 34),
              ),
              const SizedBox(height: 18),
              const Text('This material is locked',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Subscribe to unlock the full lesson, deep notes, crash notes, '
                'quiz, and AI teacher for every topic.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => context.go('/subscribe'),
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock — view the plan'),
              ),
            ],
          ),
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