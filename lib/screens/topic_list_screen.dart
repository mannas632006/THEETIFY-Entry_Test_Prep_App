// ===========================================================================
// lib/screens/topic_list_screen.dart
// ---------------------------------------------------------------------------
// Shows the list of TOPICS for one exam, loaded live from Supabase. The
// student reaches this screen after tapping an exam on the exam list. Tapping
// a topic opens its study page (the 6-tab TopicScreen), passing the topic's
// id so its saved content can be loaded from the database.
//
// This screen is the missing link in the chain:
//   Exam list  ->  Topic list (THIS)  ->  Topic page (with content)
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/content_service.dart';

class TopicListScreen extends StatefulWidget {
  // Which exam we are showing topics for, and its name (for the title bar).
  final String examId;
  final String examName;
  const TopicListScreen({
    super.key,
    required this.examId,
    required this.examName,
  });

  @override
  State<TopicListScreen> createState() => _TopicListScreenState();
}

class _TopicListScreenState extends State<TopicListScreen> {
  // Holds the topics once they finish loading from the database.
  late Future<List<Map<String, dynamic>>> _topicsFuture;

  @override
  void initState() {
    super.initState();
    // Start loading this exam's topics as soon as the screen opens.
    _topicsFuture = ContentService.getTopics(widget.examId);
  }

  // Opens a topic's study page, passing its id (to load content) and its name.
  void _openTopic(Map<String, dynamic> topic) {
    final id = topic['id']?.toString() ?? '';
    final name = topic['name']?.toString() ?? 'Topic';
    if (id.isEmpty) return;
    context.go(
      Uri(path: '/topic/$id', queryParameters: {'name': name}).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.examName)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _topicsFuture,
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
                child: Text('Could not load topics: ${snapshot.error}'),
              ),
            );
          }

          final topics = snapshot.data ?? [];

          // No topics yet: friendly empty message.
          if (topics.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No topics yet for this exam.\n'
                  'Add some from the Admin Dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // Show the topics as a tappable list.
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              // 'status' is set to 'ready' by the Admin when content is saved.
              final isReady = topic['status'] == 'ready';
              return Card(
                child: ListTile(
                  title: Text(topic['name'] ?? 'Unnamed topic'),
                  subtitle: Text(isReady ? 'Ready to study' : 'Coming soon'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _openTopic(topic),
                ),
              );
            },
          );
        },
      ),
    );
  }
}