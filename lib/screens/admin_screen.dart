// ===========================================================================
// lib/screens/admin_screen.dart
// ---------------------------------------------------------------------------
// THE ADMIN DASHBOARD (for YOU, the owner).
//
// ACCESS: This screen is now locked. When it opens, it checks whether the
// logged-in user is the admin (see AuthService.adminEmail). Anyone else sees
// an "Access Denied" message and cannot generate or publish content.
//
// What you do here, in plain steps:
//   1. Pick which exam the topic belongs to (or type a new exam name).
//   2. Type the topic name (e.g. "Trigonometry").
//   3. Press "Generate Everything".
//   4. The app uses AI to create the lesson, notes, crash notes, quiz, and
//      video script automatically. You see progress messages as it works.
//   5. Review the result, then press "Publish" to make it live for students.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../services/generation_service.dart';
import '../config/app_config.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _examController = TextEditingController();
  final _topicController = TextEditingController();

  // Whether the current user is allowed in. Checked once when the screen opens.
  late Future<bool> _accessFuture;

  bool _busy = false;            // true while generating.
  String _progress = '';         // current progress message.
  Map<String, dynamic>? _result; // the generated content, before publishing.

  @override
  void initState() {
    super.initState();
    _accessFuture = AuthService.isAdmin();
  }

  // Step 1+2+3: generate all content for the typed topic.
  Future<void> _generate() async {
    final exam = _examController.text.trim();
    final topic = _topicController.text.trim();

    // Basic checks so nothing breaks.
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

  // Step 5: save everything to the database so students can see it.
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

      // Create the exam and topic rows, then save the generated content.
      final examId = await ContentService.addExam(exam);
      final topicId = await ContentService.addTopic(examId, topic);

      final toSave = Map<String, dynamic>.from(_result!);
      toSave['approved'] = true; // Publishing means approved.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: FutureBuilder<bool>(
        future: _accessFuture,
        builder: (context, snapshot) {
          // Still checking who you are.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Not the admin: block access.
          if (snapshot.data != true) {
            return _accessDenied();
          }
          // Admin confirmed: show the real dashboard.
          return _dashboard();
        },
      ),
    );
  }

  // Shown to anyone who is not the admin.
  Widget _accessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This area is for the site owner only.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }

  // The real admin dashboard (only built for the admin).
  Widget _dashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create study content automatically',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Exam name input.
          TextField(
            controller: _examController,
            decoration: const InputDecoration(
              labelText: 'Exam name (e.g. NUST NET)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          // Topic name input.
          TextField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: 'Topic name (e.g. Trigonometry)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // Generate button.
          ElevatedButton.icon(
            onPressed: _busy ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Generate Everything'),
          ),
          const SizedBox(height: 16),

          // Progress / spinner while working.
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

          // Review area: show previews of what was generated.
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
    );
  }

  // A collapsible preview box for one piece of generated content.
  Widget _preview(String title, String? content) {
    return Card(
      child: ExpansionTile(
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              (content ?? '').length > 1000
                  ? '${content!.substring(0, 1000)}...'
                  : (content ?? ''),
            ),
          ),
        ],
      ),
    );
  }
}