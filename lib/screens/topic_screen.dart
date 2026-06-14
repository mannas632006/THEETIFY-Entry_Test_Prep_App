import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;

import '../services/content_service.dart';
import '../widgets/ai_teacher_chat.dart';
import '../widgets/quiz_view.dart';

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
    _contentFuture = ContentService.getTopicContentByName(widget.topicName);
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final content = snapshot.data;

            return TabBarView(
              children: [
                // 1) Interactive HTML lesson
                content?['html_lesson'] != null
                    ? _HtmlLessonView(htmlContent: content!['html_lesson'])
                    : _empty('The lesson has not been generated yet.'),
                // 2) Deep notes
                _scrollable(Text(content?['deep_notes'] ??
                    'In-depth notes have not been generated yet.')),
                // 3) Crash notes
                _scrollable(Text(content?['crash_notes'] ??
                    'Crash notes have not been generated yet.')),
                // 4) Quiz
                content?['quiz_json'] != null
                    ? QuizView(quizJson: content!['quiz_json'])
                    : _empty('The quiz has not been generated yet.'),
                // 5) AI Teacher
                AiTeacherChat(examContext: widget.topicName),
                // 6) Videos
                _empty('YouTube + AI video lectures will appear here.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _scrollable(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: child,
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

class _HtmlLessonView extends StatefulWidget {
  final String htmlContent;
  const _HtmlLessonView({required this.htmlContent});

  @override
  State<_HtmlLessonView> createState() => _HtmlLessonViewState();
}

class _HtmlLessonViewState extends State<_HtmlLessonView> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'html-lesson-${DateTime.now().millisecondsSinceEpoch}';

    final String fullHtml = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: 'Segoe UI', sans-serif;
    background: linear-gradient(135deg, #0D1B2A 0%, #1a2a3a 100%);
    color: #e0e0e0;
    padding: 24px;
    line-height: 1.7;
  }
  h1, h2, h3 {
    color: #1B98E0;
    margin: 24px 0 12px 0;
    animation: fadeInDown 0.5s ease;
  }
  h1 { font-size: 2em; border-bottom: 2px solid #1B98E0; padding-bottom: 8px; }
  h2 { font-size: 1.5em; }
  h3 { font-size: 1.2em; color: #4db8ff; }
  p { margin: 12px 0; animation: fadeIn 0.5s ease; }
  ul, ol { margin: 12px 0 12px 24px; }
  li { margin: 8px 0; animation: fadeInLeft 0.5s ease; }
  strong { color: #1B98E0; }
  em { color: #4db8ff; }
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 16px 0;
    animation: fadeIn 0.5s ease;
  }
  th {
    background: #1B98E0;
    color: white;
    padding: 12px;
    text-align: left;
  }
  td {
    padding: 10px 12px;
    border-bottom: 1px solid #2a3a4a;
  }
  tr:hover { background: rgba(27, 152, 224, 0.1); }
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
  }
  @keyframes fadeInDown {
    from { opacity: 0; transform: translateY(-20px); }
    to { opacity: 1; transform: translateY(0); }
  }
  @keyframes fadeInLeft {
    from { opacity: 0; transform: translateX(-20px); }
    to { opacity: 1; transform: translateX(0); }
  }
</style>
</head>
<body>
${widget.htmlContent}
</body>
</html>
''';

    final blob = html.Blob([fullHtml], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => iframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: HtmlElementView(viewType: _viewId),
    );
  }
}