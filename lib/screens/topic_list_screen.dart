import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/content_service.dart';

class TopicListScreen extends StatefulWidget {
  final String examId;
  final String examName;
  const TopicListScreen({super.key, required this.examId, required this.examName});

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
          final topics = snapshot.data ?? [];
          if (topics.isEmpty) {
            return const Center(child: Text('No topics yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return Card(
                child: ListTile(
                  title: Text(topic['name'] ?? 'Unnamed topic'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.go(
                    '/topic/${Uri.encodeComponent(topic['name'])}',
                    extra: topic['id'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}