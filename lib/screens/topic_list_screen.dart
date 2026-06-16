// ===========================================================================
// lib/screens/topic_list_screen.dart
// ---------------------------------------------------------------------------
// Lists the TOPICS for one exam. Now also shows, per topic:
//   - a green check if the student has completed it,
//   - the estimated study time (if the AI provided one).
// Tapping a topic opens its study page.
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
  List<Map<String, dynamic>> _topics = [];
  Set<String> _completed = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final topics = await ContentService.getTopics(widget.examId);
      final completed = await ContentService.getCompletedTopicIds();
      if (!mounted) return;
      setState(() {
        _topics = topics;
        _completed = completed;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openTopic(Map<String, dynamic> topic) {
    final id = topic['id']?.toString() ?? '';
    final name = topic['name']?.toString() ?? 'Topic';
    if (id.isEmpty) return;
    context.go(
      Uri(path: '/topic/$id', queryParameters: {'name': name}).toString(),
    );
  }

  // Reads the estimated study time out of the embedded topic_content (if any).
  int? _minutesFor(Map<String, dynamic> topic) {
    final tc = topic['topic_content'];
    if (tc is List && tc.isNotEmpty && tc.first is Map) {
      final v = (tc.first as Map)['estimated_minutes'];
      if (v is num) return v.toInt();
    } else if (tc is Map) {
      final v = tc['estimated_minutes'];
      if (v is num) return v.toInt();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.examName)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load topics: $_error'),
        ),
      );
    }
    if (_topics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, size: 48, color: Colors.black26),
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
          itemCount: _topics.length,
          itemBuilder: (context, index) {
            final topic = _topics[index];
            final id = topic['id']?.toString() ?? '';
            final isReady = topic['status'] == 'ready';
            final isDone = _completed.contains(id);
            final minutes = _minutesFor(topic);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isDone
                      ? const Color(0x1F2E9E5B)
                      : const Color(0x1F1B98E0),
                  child: Icon(
                    isDone ? Icons.check : Icons.menu_book,
                    color: isDone
                        ? const Color(0xFF2E9E5B)
                        : const Color(0xFF1B98E0),
                  ),
                ),
                title: Text(
                  topic['name'] ?? 'Unnamed topic',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      _chip(
                        isDone
                            ? 'Completed'
                            : (isReady ? 'Ready' : 'Coming soon'),
                        isDone
                            ? const Color(0xFF2E9E5B)
                            : (isReady
                                ? const Color(0xFF1B98E0)
                                : Colors.grey.shade600),
                      ),
                      if (minutes != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 13, color: Colors.black45),
                            const SizedBox(width: 3),
                            Text('~$minutes min',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ],
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
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}