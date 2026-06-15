// ===========================================================================
// lib/screens/topic_list_screen.dart
// ---------------------------------------------------------------------------
// Shows the list of TOPICS for one exam, loaded live from Supabase. Tapping a
// topic opens its study page (the 6-tab TopicScreen), passing the topic's id
// so its saved content can be loaded.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/content_service.dart';

class TopicListScreen extends StatefulWidget {
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
  late Future<List<Map<String, dynamic>>> _topicsFuture;

  @override
  void initState() {
    super.initState();
    _topicsFuture = ContentService.getTopics(widget.examId);
  }

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load topics: ${snapshot.error}'),
              ),
            );
          }

          final topics = snapshot.data ?? [];

          if (topics.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_outlined,
                        size: 48, color: Colors.black26),
                    SizedBox(height: 12),
                    Text(
                      'No topics yet for this exam.\n'
                      'Add some from the Admin Dashboard.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final topic = topics[index];
                  final isReady = topic['status'] == 'ready';
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
                        child: Icon(Icons.menu_book, color: Color(0xFF1B98E0)),
                      ),
                      title: Text(
                        topic['name'] ?? 'Unnamed topic',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: isReady
                                  ? const Color(0x1F2E9E5B)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isReady ? 'Ready' : 'Coming soon',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isReady
                                    ? const Color(0xFF2E9E5B)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _openTopic(topic),
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