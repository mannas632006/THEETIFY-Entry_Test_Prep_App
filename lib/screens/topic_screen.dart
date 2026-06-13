// ===========================================================================
// lib/screens/topic_screen.dart
// ---------------------------------------------------------------------------
// The heart of the app: a single topic's study page. It has TABS for each
// type of content the student gets for that topic:
//   - Lesson (interactive HTML)
//   - Deep Notes
//   - Crash Notes (3-hour revision)
//   - Quiz
//   - AI Teacher (chat)
//   - Videos
//
// Right now these tabs show placeholder text. As we build each feature, we
// fill them in. This keeps the app working and visible at every step.
// ===========================================================================

import 'package:flutter/material.dart';
import '../widgets/ai_teacher_chat.dart';

class TopicScreen extends StatelessWidget {
  final String topicName; // The topic this page is about, e.g. "Trigonometry".
  const TopicScreen({super.key, required this.topicName});

  @override
  Widget build(BuildContext context) {
    // DefaultTabController gives us the row of tabs at the top.
    return DefaultTabController(
      length: 6, // We have 6 content tabs.
      child: Scaffold(
        appBar: AppBar(
          title: Text(topicName),
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
        body: TabBarView(
          children: [
            _placeholder('Interactive HTML lesson will appear here.'),
            _placeholder('In-depth notes will appear here.'),
            _placeholder('3-hour crash revision notes will appear here.'),
            _placeholder('A quiz to test yourself will appear here.'),
            // The live AI Teacher chat, locked to study topics only.
            AiTeacherChat(examContext: topicName),
            _placeholder('YouTube + AI video lectures will appear here.'),
          ],
        ),
      ),
    );
  }

  // A small reusable box that shows centered placeholder text for now.
  Widget _placeholder(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
