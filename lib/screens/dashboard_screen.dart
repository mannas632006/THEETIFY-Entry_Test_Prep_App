// ===========================================================================
// lib/screens/dashboard_screen.dart
// ---------------------------------------------------------------------------
// The student's HOME after login. A calm study dashboard showing:
//   - greeting + daily streak + "studied today" goal
//   - a gentle nudge if they haven't studied today (when reminder is on)
//   - overall progress (topics completed of total) with a bar
//   - "continue where you left off"
//   - quick actions: Browse Exams, Study Timetable
//   - search across all topics
//   - weak areas flagged from quiz history
//   - bookmarked topics
//   - Settings (study-reminder toggle) in the app bar
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/content_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _accent = Color(0xFF1B98E0);

  bool _loading = true;
  String? _error;

  int _total = 0;
  int _completed = 0;
  Map<String, dynamic>? _lastViewed;
  int _streak = 0;
  bool _studiedToday = false;
  bool _reminderOn = true;
  List<Map<String, dynamic>> _attempts = [];
  List<Map<String, dynamic>> _bookmarks = [];
  List<Map<String, dynamic>> _allTopics = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (AuthService.isLoggedIn) _load();
  }

  String _todayStr() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    try {
      final total = await ContentService.getTotalTopicCount();
      final completed = await ContentService.getCompletedTopicIds();
      final lastViewed = await ContentService.getLastViewed();
      final streak = await ContentService.getStreak();
      final attempts = await ContentService.getQuizAttempts();
      final bookmarks = await ContentService.getBookmarks();
      final allTopics = await ContentService.getAllTopics();
      final settings = await ContentService.getSettings();
      if (!mounted) return;
      setState(() {
        _total = total;
        _completed = completed.length;
        _lastViewed = lastViewed;
        _streak = streak;
        _attempts = attempts;
        _bookmarks = bookmarks;
        _allTopics = allTopics;
        _reminderOn = (settings?['study_reminder'] as bool?) ?? true;
        _studiedToday = settings != null &&
            settings['last_active_date']?.toString() == _todayStr();
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

  void _openTopic(String id, String name) {
    if (id.isEmpty) return;
    context.go(
      Uri(path: '/topic/$id', queryParameters: {'name': name}).toString(),
    );
  }

  String _greetingName() {
    final email = AuthService.currentEmail ?? '';
    if (email.isEmpty) return 'there';
    final prefix = email.split('@').first;
    return prefix.isEmpty ? 'there' : prefix;
  }

  List<Map<String, dynamic>> _weakAreas() {
    final seen = <String>{};
    final weak = <Map<String, dynamic>>[];
    for (final a in _attempts) {
      final tid = a['topic_id']?.toString() ?? '';
      if (tid.isEmpty || seen.contains(tid)) continue;
      seen.add(tid);
      final score = (a['score'] as num?)?.toDouble() ?? 0;
      final total = (a['total'] as num?)?.toDouble() ?? 0;
      if (total > 0 && (score / total) < 0.6) weak.add(a);
    }
    return weak;
  }

  List<Map<String, dynamic>> _searchResults() {
    if (_query.trim().isEmpty) return [];
    final q = _query.toLowerCase();
    return _allTopics
        .where((t) => (t['name']?.toString().toLowerCase() ?? '').contains(q))
        .take(15)
        .toList();
  }

  String? _examNameOf(Map<String, dynamic> topic) {
    final e = topic['exams'];
    if (e is Map) return e['name']?.toString();
    return null;
  }

  Future<void> _openSettings() async {
    bool reminder = _reminderOn;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Daily study reminder'),
                    subtitle: const Text(
                        'Show a nudge on this page if you haven\'t studied today.'),
                    value: reminder,
                    onChanged: (v) => setLocal(() => reminder = v),
                  ),
                  const Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _confirmReset();
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      label: const Text('Reset my progress',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await ContentService.saveSettings(studyReminder: reminder);
                    if (!mounted) return;
                    setState(() => _reminderOn = reminder);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
            'This clears your completed topics, quiz history, streak, and '
            '"continue where you left off". Bookmarks are kept. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ContentService.resetProgress();
      if (!mounted) return;
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Progress reset.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please log in to see your dashboard.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Log in'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.signOut();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load your data: $_error'),
                  ),
                )
              : _content(),
    );
  }

  Widget _content() {
    final pct = _total == 0 ? 0.0 : _completed / _total;
    final results = _searchResults();
    final weak = _weakAreas();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome back, ${_greetingName()} 👋',
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Let\'s keep your preparation on track.',
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),

            // Getting-started hint for brand-new students.
            if (_completed == 0 &&
                _attempts.isEmpty &&
                _bookmarks.isEmpty &&
                _lastViewed == null) ...[
              _banner(
                Icons.rocket_launch_outlined,
                'New here? Tap "Browse Exams" below to open your first topic. '
                'Your progress, streak, and weak areas appear here as you study.',
                _accent,
                const Color(0x141B98E0),
              ),
              const SizedBox(height: 12),
            ],

            // Nudge.
            if (_reminderOn && !_studiedToday) ...[
              _banner(
                Icons.notifications_active_outlined,
                'You haven\'t studied today — open a topic to keep your streak alive!',
                const Color(0xFFE08F1A),
                const Color(0x1FF4A623),
              ),
              const SizedBox(height: 12),
            ],

            // Habit card (streak + today).
            _card(
              child: Row(
                children: [
                  _statBlock('🔥 $_streak', 'day streak'),
                  const SizedBox(width: 24),
                  _statBlock(_studiedToday ? '✓' : '–',
                      _studiedToday ? 'studied today' : 'not yet today'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Progress.
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your progress',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('$_completed of $_total topics',
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Continue where you left off.
            if (_lastViewed != null &&
                (_lastViewed!['topic_id'] != null)) ...[
              _card(
                child: Row(
                  children: [
                    const Icon(Icons.play_circle_fill,
                        color: _accent, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Continue where you left off',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 12)),
                          Text(
                            _lastViewed!['topic_name']?.toString() ?? 'Topic',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openTopic(
                        _lastViewed!['topic_id'].toString(),
                        _lastViewed!['topic_name']?.toString() ?? 'Topic',
                      ),
                      child: const Text('Resume'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Quick actions.
            Row(
              children: [
                Expanded(
                  child: _actionCard(Icons.menu_book, 'Browse Exams',
                      () => context.go('/exams')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(Icons.calendar_month, 'Study Timetable',
                      () => context.go('/timetable')),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search.
            const Text('Search topics',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search across all topics…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            if (_query.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              if (results.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No topics match.',
                      style: TextStyle(color: Colors.black54)),
                )
              else
                ...results.map((t) => _topicTile(
                      t['name']?.toString() ?? 'Topic',
                      _examNameOf(t),
                      () => _openTopic(t['id']?.toString() ?? '',
                          t['name']?.toString() ?? 'Topic'),
                    )),
            ],
            const SizedBox(height: 20),

            // Weak areas.
            if (weak.isNotEmpty) ...[
              const Text('Needs review',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Topics where your last quiz was below 60%.',
                  style: TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 8),
              ...weak.map((a) {
                final score = (a['score'] as num?)?.toInt() ?? 0;
                final total = (a['total'] as num?)?.toInt() ?? 0;
                return _topicTile(
                  a['topic_name']?.toString() ?? 'Topic',
                  'Last quiz: $score / $total',
                  () => _openTopic(a['topic_id']?.toString() ?? '',
                      a['topic_name']?.toString() ?? 'Topic'),
                  leadingColor: const Color(0xFFE08F1A),
                  leadingIcon: Icons.priority_high,
                );
              }),
              const SizedBox(height: 20),
            ],

            // Bookmarks.
            if (_bookmarks.isNotEmpty) ...[
              const Text('Bookmarks',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._bookmarks.map((b) => _topicTile(
                    b['topic_name']?.toString() ?? 'Topic',
                    null,
                    () => _openTopic(b['topic_id']?.toString() ?? '',
                        b['topic_name']?.toString() ?? 'Topic'),
                    leadingIcon: Icons.bookmark,
                  )),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _statBlock(String big, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(big,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _banner(IconData icon, String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _actionCard(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x141B98E0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x331B98E0)),
        ),
        child: Column(
          children: [
            Icon(icon, color: _accent, size: 30),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: _accent)),
          ],
        ),
      ),
    );
  }

  Widget _topicTile(String title, String? subtitle, VoidCallback onTap,
      {IconData leadingIcon = Icons.menu_book, Color leadingColor = _accent}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: leadingColor.withOpacity(0.12),
          child: Icon(leadingIcon, color: leadingColor, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: onTap,
      ),
    );
  }
}