// ===========================================================================
// lib/screens/admin_screen.dart
// ---------------------------------------------------------------------------
// THE ADMIN DASHBOARD (owner only — locked to AuthService.adminEmail).
//
// Exam and Topic are now "type new OR pick from existing": start typing and a
// dropdown of matching existing names appears, or type a brand-new name. When
// an existing exam is chosen, the Topic dropdown fills with that exam's topics.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/ai_service.dart';
import '../services/content_service.dart';
import '../services/generation_service.dart';
import '../config/app_config.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<bool> _accessFuture;

  List<Map<String, dynamic>> _exams = [];
  List<String> _examNames = [];
  List<String> _topicNames = [];
  String _examName = '';
  String _topicName = '';
  String _topicsExamId = '';

  bool _busy = false;
  String _progress = '';
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _accessFuture = AuthService.isAdmin();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final exams = await ContentService.getExams();
      if (!mounted) return;
      setState(() {
        _exams = exams;
        _examNames = exams
            .map((e) => (e['name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
      });
    } catch (_) {}
  }

  // When the exam text matches an existing exam, load its topics for the
  // topic dropdown. New exam name -> clear topic suggestions.
  void _onExamChanged(String value) {
    _examName = value;
    final v = value.trim().toLowerCase();
    final match = _exams.firstWhere(
      (e) => (e['name'] ?? '').toString().toLowerCase() == v,
      orElse: () => <String, dynamic>{},
    );
    if (match.isNotEmpty) {
      final id = match['id']?.toString() ?? '';
      if (id.isNotEmpty && id != _topicsExamId) {
        _topicsExamId = id;
        _loadTopicsFor(id);
      }
    } else if (_topicNames.isNotEmpty) {
      _topicsExamId = '';
      setState(() => _topicNames = []);
    }
  }

  Future<void> _loadTopicsFor(String examId) async {
    try {
      final topics = await ContentService.getTopics(examId);
      if (!mounted) return;
      setState(() {
        _topicNames = topics
            .map((t) => (t['name'] ?? '').toString())
            .where((s) => s.isNotEmpty)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _generate() async {
    final exam = _examName.trim();
    final topic = _topicName.trim();
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
      final exam = _examName.trim();
      final topic = _topicName.trim();
      final examId = await ContentService.addExam(exam);
      final topicId = await ContentService.addTopic(examId, topic);
      final toSave = Map<String, dynamic>.from(_result!);
      toSave['approved'] = true;
      await ContentService.saveTopicContent(topicId, toSave);
      _showMessage('Published! "$topic" is now live for students.');
      setState(() => _result = null);
      _loadExams(); // refresh dropdown suggestions
    } catch (e) {
      _showMessage('Publishing failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Fill in estimated study time for any already-published topic that has none.
  Future<void> _backfillEstimates() async {
    if (!AppConfig.hasAi) {
      _showMessage('AI is not set up. Add your AI key to the .env file.');
      return;
    }
    setState(() {
      _busy = true;
      _progress = 'Checking topics...';
    });
    try {
      final topics = await ContentService.getAllTopics();
      final meta = await ContentService.getAllTopicContentMeta();

      final hasContent = <String>{};
      final hasEstimate = <String>{};
      for (final m in meta) {
        final id = m['topic_id'].toString();
        hasContent.add(id);
        if (m['estimated_minutes'] != null) hasEstimate.add(id);
      }

      final todo = topics.where((t) {
        final id = t['id'].toString();
        return hasContent.contains(id) && !hasEstimate.contains(id);
      }).toList();

      if (todo.isEmpty) {
        _showMessage('All published topics already have a time estimate.');
        setState(() => _busy = false);
        return;
      }

      var done = 0;
      for (final t in todo) {
        final id = t['id'].toString();
        final name = t['name']?.toString() ?? '';
        final exam = (t['exams'] is Map)
            ? ((t['exams'] as Map)['name']?.toString() ?? '')
            : '';
        setState(() =>
            _progress = 'Estimating ${done + 1} of ${todo.length}: $name');
        final txt = await AiService.generateEstimatedMinutes(name, exam);
        final mins = _firstInt(txt) ?? 30;
        await ContentService.updateEstimatedMinutes(id, mins);
        done++;
      }
      _showMessage('Done! Estimated $done topic(s).');
    } catch (e) {
      _showMessage('Backfill failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int? _firstInt(String text) {
    final m = RegExp(r'\d+').firstMatch(text);
    return m == null ? null : int.tryParse(m.group(0)!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: FutureBuilder<bool>(
        future: _accessFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data != true) return _accessDenied();
          return _dashboard();
        },
      ),
    );
  }

  Widget _accessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            const Text('Access Denied',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('This area is for the site owner only.',
                textAlign: TextAlign.center),
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

  Widget _dashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create study content',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Pick an existing exam/topic or type a new name, then generate.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Exam'),
                      const SizedBox(height: 6),
                      _examField(),
                      const SizedBox(height: 18),
                      _label('Topic'),
                      const SizedBox(height: 6),
                      _topicField(),
                      const SizedBox(height: 22),
                      ElevatedButton.icon(
                        onPressed: _busy ? null : _generate,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Generate Everything'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Maintenance: fill in estimated study time for older topics.
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Maintenance',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        'Older topics published before time estimates existed '
                        'show no study time. This fills them in using the AI.',
                        style: TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _backfillEstimates,
                        icon: const Icon(Icons.schedule),
                        label:
                            const Text('Estimate time for existing topics'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                const SizedBox(height: 8),
                const Text('Review the generated content',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _preview('Interactive Lesson (HTML)', _result!['html_lesson']),
                _preview('Deep Notes', _result!['deep_notes']),
                _preview('Crash Notes (3-hour)', _result!['crash_notes']),
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
      ),
    );
  }

  Widget _label(String t) =>
      Text(t, style: const TextStyle(fontWeight: FontWeight.w600));

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  Widget _examField() {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        final input = textEditingValue.text.toLowerCase();
        if (input.isEmpty) return _examNames;
        return _examNames.where((o) => o.toLowerCase().contains(input));
      },
      onSelected: _onExamChanged,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _dec('e.g. NUST NET'),
          onChanged: _onExamChanged,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Widget _topicField() {
    return Autocomplete<String>(
      optionsBuilder: (textEditingValue) {
        final input = textEditingValue.text.toLowerCase();
        if (input.isEmpty) return _topicNames;
        return _topicNames.where((o) => o.toLowerCase().contains(input));
      },
      onSelected: (v) => _topicName = v,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: _dec('e.g. Trigonometry'),
          onChanged: (v) => _topicName = v,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  Widget _preview(String title, String? content) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
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