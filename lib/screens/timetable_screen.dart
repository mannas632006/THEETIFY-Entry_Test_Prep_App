// ===========================================================================
// lib/screens/timetable_screen.dart
// ---------------------------------------------------------------------------
// The AI Study Timetable. The student picks an exam + exam date (+ optional
// daily hours); the AI builds a day-by-day plan from the days remaining and
// the topics they HAVEN'T completed yet. Each day is a clickable cell: tap it
// to see the topics for that day. The plan can be saved and printed.
//
// WEB ONLY: uses dart:html for printing.
// ===========================================================================

import 'dart:convert';
import 'dart:html' as web;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/ai_service.dart';
import '../services/content_service.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const _accent = Color(0xFF1B98E0);

  List<Map<String, dynamic>> _exams = [];
  String? _examName;
  String? _examId;
  DateTime? _deadline;
  final _hoursController = TextEditingController();

  bool _loading = true; // initial load
  bool _busy = false; // generating
  String? _message;
  List<dynamic> _plan = [];
  String _planJson = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      final exams = await ContentService.getExams();
      final saved = await ContentService.getTimetable();
      if (!mounted) return;
      setState(() {
        _exams = exams;
        if (saved != null) {
          _examName = saved['exam_name']?.toString();
          final exam = _exams.firstWhere(
            (e) => (e['name'] ?? '').toString() == _examName,
            orElse: () => <String, dynamic>{},
          );
          _examId = exam.isNotEmpty ? exam['id']?.toString() : null;
          final dl = saved['deadline']?.toString();
          if (dl != null) _deadline = DateTime.tryParse(dl);
          final dh = saved['daily_hours'];
          if (dh != null) _hoursController.text = dh.toString();
          final planText = saved['plan_json']?.toString() ?? '';
          _plan = _parsePlan(planText);
          _planJson = planText;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not load: $e';
        _loading = false;
      });
    }
  }

  List<dynamic> _parsePlan(String text) {
    try {
      final start = text.indexOf('[');
      final end = text.lastIndexOf(']');
      if (start != -1 && end != -1) {
        final list = jsonDecode(text.substring(start, end + 1));
        if (list is List) return list;
      }
    } catch (_) {}
    return [];
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  String _pretty(String ymd) {
    final d = DateTime.tryParse(ymd);
    if (d == null) return ymd;
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _generate() async {
    if (_examId == null || _examName == null) {
      _show('Please choose an exam.');
      return;
    }
    if (_deadline == null) {
      _show('Please choose your exam date.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final topics = await ContentService.getTopics(_examId!);
      final completed = await ContentService.getCompletedTopicIds();
      final remaining = topics
          .where((t) => !completed.contains(t['id'].toString()))
          .map((t) => (t['name'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();

      if (remaining.isEmpty) {
        setState(() {
          _busy = false;
          _message =
              'You\'ve already completed every topic in this exam. Nothing left to schedule!';
        });
        return;
      }

      final hours = int.tryParse(_hoursController.text.trim());
      final raw = await AiService.generateTimetable(
        exam: _examName!,
        deadline: _fmt(_deadline!),
        remainingTopics: remaining,
        dailyHours: hours,
      );
      final plan = _parsePlan(raw);
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _planJson = raw;
        _busy = false;
        if (plan.isEmpty) {
          _message = 'The AI response could not be read. Try generating again.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Could not build the timetable: $e';
      });
    }
  }

  Future<void> _save() async {
    if (_planJson.isEmpty) return;
    final hours = int.tryParse(_hoursController.text.trim());
    await ContentService.saveTimetable(
      examName: _examName,
      deadline: _deadline != null ? _fmt(_deadline!) : null,
      dailyHours: hours,
      planJson: _planJson,
    );
    _show('Timetable saved.');
  }

  String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  void _print() {
    if (_plan.isEmpty) return;
    final buf = StringBuffer();
    buf.write('<html><head><meta charset="utf-8"><title>Study Timetable</title>');
    buf.write('<style>'
        'body{font-family:Arial,Helvetica,sans-serif;padding:28px;color:#0D1B2A;}'
        'h1{margin:0 0 4px;font-size:22px;}'
        'p.sub{color:#555;margin:0 0 18px;}'
        '.day{border:1px solid #ccc;border-radius:8px;padding:12px 14px;margin-bottom:12px;}'
        '.date{font-weight:bold;color:#1B98E0;margin-bottom:6px;}'
        'ul{margin:0;padding-left:20px;}'
        'li{margin:3px 0;}'
        'em{color:#555;}'
        '</style>');
    buf.write('<script>window.onload=function(){window.print();}</script>');
    buf.write('</head><body>');
    buf.write('<h1>Study Timetable${_examName != null ? " — ${_escape(_examName!)}" : ""}</h1>');
    if (_deadline != null) {
      buf.write('<p class="sub">Exam date: ${_fmt(_deadline!)}</p>');
    }
    for (final day in _plan) {
      if (day is! Map) continue;
      buf.write('<div class="day"><div class="date">'
          '${_escape(_pretty(day['date']?.toString() ?? ''))}</div>');
      final topics = day['topics'];
      if (topics is List && topics.isNotEmpty) {
        buf.write('<ul>');
        for (final t in topics) {
          buf.write('<li>${_escape(t.toString())}</li>');
        }
        buf.write('</ul>');
      }
      final note = day['note']?.toString() ?? '';
      if (note.isNotEmpty) buf.write('<p><em>${_escape(note)}</em></p>');
      buf.write('</div>');
    }
    buf.write('</body></html>');

    final blob = web.Blob([buf.toString()], 'text/html');
    final url = web.Url.createObjectUrlFromBlob(blob);
    web.window.open(url, '_blank');
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Timetable'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _inputsCard(),
                    const SizedBox(height: 16),
                    if (_busy)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Building your timetable…'),
                            ],
                          ),
                        ),
                      ),
                    if (_message != null && !_busy)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(_message!,
                            style: const TextStyle(color: Colors.black54)),
                      ),
                    if (_plan.isNotEmpty && !_busy) ...[
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Your plan',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ),
                          TextButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: const Text('Save'),
                          ),
                          TextButton.icon(
                            onPressed: _print,
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text('Print'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Tap a day to see its topics.',
                          style: TextStyle(
                              color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 8),
                      ..._plan.map(_dayCard),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _inputsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plan your study schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _examName,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Exam',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: _exams
                .map((e) => (e['name'] ?? '').toString())
                .where((s) => s.isNotEmpty)
                .map((name) =>
                    DropdownMenuItem(value: name, child: Text(name)))
                .toList(),
            onChanged: (name) {
              setState(() {
                _examName = name;
                final exam = _exams.firstWhere(
                  (e) => (e['name'] ?? '').toString() == name,
                  orElse: () => <String, dynamic>{},
                );
                _examId = exam.isNotEmpty ? exam['id']?.toString() : null;
              });
            },
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(6),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Exam date',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              child: Text(
                _deadline != null ? _fmt(_deadline!) : 'Tap to choose a date',
                style: TextStyle(
                    color: _deadline != null ? Colors.black : Colors.black54),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _hoursController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Hours you can study per day (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _busy ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_plan.isEmpty ? 'Generate Timetable' : 'Regenerate'),
          ),
        ],
      ),
    );
  }

  Widget _dayCard(dynamic day) {
    if (day is! Map) return const SizedBox.shrink();
    final date = day['date']?.toString() ?? '';
    final topics = (day['topics'] is List)
        ? List<dynamic>.from(day['topics'])
        : <dynamic>[];
    final note = day['note']?.toString() ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1F1B98E0),
          child: Icon(Icons.event, color: _accent, size: 20),
        ),
        title: Text(_pretty(date),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${topics.length} topic(s)'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          ...topics.map((t) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_box_outline_blank, size: 18),
                title: Text(t.toString()),
              )),
          if (note.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(note,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.black54)),
            ),
        ],
      ),
    );
  }
}