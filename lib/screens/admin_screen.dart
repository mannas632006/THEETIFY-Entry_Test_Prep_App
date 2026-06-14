import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/content_service.dart';
import '../services/generation_service.dart';
import '../config/app_config.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _examController = TextEditingController();
  final _topicController = TextEditingController();

  bool _busy = false;
  bool _checkingAuth = true;
  bool _isAdmin = false;
  String _progress = '';
  Map<String, dynamic>? _result;

  static const String _adminEmail = 'f240576@cfd.nu.edu.pk';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait a moment for Supabase to restore session
    await Future.delayed(const Duration(milliseconds: 500));
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      _isAdmin = user?.email == _adminEmail;
      _checkingAuth = false;
    });
  }

  Future<void> _generate() async {
    final exam = _examController.text.trim();
    final topic = _topicController.text.trim();

    if (exam.isEmpty || topic.isEmpty) {
      _showMessage('Please enter both an exam name and a topic name.');
      return;
    }
    if (!AppConfig.hasAi) {
      _showMessage('AI is not set up. Add your AI key to the .env file.');
      return;
    }

    setState(() {
      _busy = true;
      _result = null;
      _progress = 'Starting...';
    });

    try {
      final result = await GenerationService.generateEverything(
        topic: topic,
        exam: exam,
        onProgress: (step) => setState(() => _progress = step),
      );
      setState(() => _result = result);
    } catch (e) {
      _showMessage('Generation failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    if (_result == null) return;
    if (!AppConfig.hasSupabase) {
      _showMessage('Database not set up. Add your Supabase keys to .env.');
      return;
    }

    setState(() => _busy = true);
    try {
      final exam = _examController.text.trim();
      final topic = _topicController.text.trim();

      final examId = await ContentService.addExam(exam);
      final topicId = await ContentService.addTopic(examId, topic);

      final toSave = Map<String, dynamic>.from(_result!);
      toSave['approved'] = true;
      await ContentService.saveTopicContent(topicId, toSave);

      _showMessage('Published! "$topic" is now live for students.');
      setState(() => _result = null);
    } catch (e) {
      _showMessage('Publishing failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Denied.\nYou are not authorized to view this page.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create study content automatically',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _examController,
              decoration: const InputDecoration(
                labelText: 'Exam name (e.g. NUST NET)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic name (e.g. Trigonometry)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _busy ? null : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate Everything'),
            ),
            const SizedBox(height: 16),
            if (_busy)
              Row(
                children: [
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_progress)),
                ],
              ),
            if (_result != null && !_busy) ...[
              const Divider(height: 32),
              const Text('Review the generated content:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _preview('Interactive Lesson (HTML)', _result!['html_lesson']),
              _preview('Deep Notes', _result!['deep_notes']),
              _preview('Crash Notes (3-hour)', _result!['crash_notes']),
              _preview('Video Script', _result!['video_script']),
              _preview('Quiz (JSON)', _result!['quiz_json']),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _publish,
                    icon: const Icon(Icons.publish),
                    label: const Text('Publish (make live)'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _preview(String title, String? content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(title),
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                content ?? 'Not generated yet.',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}