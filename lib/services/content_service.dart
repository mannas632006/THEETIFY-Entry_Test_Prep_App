// ===========================================================================
// lib/services/content_service.dart
// ---------------------------------------------------------------------------
// All database reads/writes for the app. Includes:
//   - Public content (exams, topics, topic content) for everyone.
//   - Admin writes (add exam/topic, save content).
//   - Per-student tracking (progress, bookmarks, quiz history, last viewed,
//     streak, settings, saved timetable). These require the student to be
//     logged in; each row is locked to its owner by Supabase RLS.
// ===========================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class ContentService {
  static SupabaseClient get _client => Supabase.instance.client;

  // Current logged-in user's id, or null.
  static String? get _uid => _client.auth.currentUser?.id;

  static String _dateStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // Whole-day difference between two dates (b - a).
  static int _dayDiff(DateTime a, DateTime b) =>
      DateTime(b.year, b.month, b.day)
          .difference(DateTime(a.year, a.month, a.day))
          .inDays;

  // ==========================================================================
  // PUBLIC CONTENT
  // ==========================================================================

  static Future<List<Map<String, dynamic>>> getExams() async {
    if (!AppConfig.hasSupabase) return [];
    final result = await _client.from('exams').select().order('name');
    return List<Map<String, dynamic>>.from(result);
  }

  // Topics for one exam. We try to also pull each topic's estimated study
  // time (lives on topic_content); if that join isn't available we fall back
  // to a plain topic list so the screen always loads.
  static Future<List<Map<String, dynamic>>> getTopics(String examId) async {
    if (!AppConfig.hasSupabase) return [];
    try {
      final result = await _client
          .from('topics')
          .select('id,name,status,exam_id, topic_content(estimated_minutes)')
          .eq('exam_id', examId)
          .order('name');
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      final result = await _client
          .from('topics')
          .select()
          .eq('exam_id', examId)
          .order('name');
      return List<Map<String, dynamic>>.from(result);
    }
  }

  // Every topic across all exams (with its exam name, for search / counts).
  static Future<List<Map<String, dynamic>>> getAllTopics() async {
    if (!AppConfig.hasSupabase) return [];
    try {
      final result = await _client
          .from('topics')
          .select('id,name,exam_id, exams(name)')
          .order('name');
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      final result = await _client.from('topics').select().order('name');
      return List<Map<String, dynamic>>.from(result);
    }
  }

  static Future<int> getTotalTopicCount() async {
    if (!AppConfig.hasSupabase) return 0;
    final result = await _client.from('topics').select('id');
    return List.from(result).length;
  }

  static Future<Map<String, dynamic>?> getTopicContent(String topicId) async {
    if (!AppConfig.hasSupabase) return null;
    final result = await _client
        .from('topic_content')
        .select()
        .eq('topic_id', topicId)
        .maybeSingle();
    return result;
  }

  // ==========================================================================
  // ADMIN WRITES
  // ==========================================================================

  // Add an exam OR reuse the existing one with the same name. Returns its id.
  static Future<String> addExam(String name, {String? description}) async {
    final existing = await _client
        .from('exams')
        .select('id')
        .eq('name', name)
        .limit(1)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final result = await _client
        .from('exams')
        .insert({'name': name, 'description': description})
        .select()
        .single();
    return result['id'] as String;
  }

  // Add a topic under an exam OR reuse the existing one. Returns its id.
  static Future<String> addTopic(String examId, String name) async {
    final existing = await _client
        .from('topics')
        .select('id')
        .eq('exam_id', examId)
        .eq('name', name)
        .limit(1)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    final result = await _client
        .from('topics')
        .insert({'exam_id': examId, 'name': name})
        .select()
        .single();
    return result['id'] as String;
  }

  static Future<void> saveTopicContent(
    String topicId,
    Map<String, dynamic> content,
  ) async {
    await _client.from('topic_content').upsert({
      'topic_id': topicId,
      ...content,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'topic_id');

    await _client.from('topics').update({'status': 'ready'}).eq('id', topicId);
  }

  // ==========================================================================
  // PROGRESS (mark topic complete)
  // ==========================================================================

  static Future<void> markTopicComplete(String topicId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('progress').upsert({
      'user_id': uid,
      'topic_id': topicId,
      'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,topic_id');
    await recordActivity();
  }

  static Future<void> unmarkTopicComplete(String topicId) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('progress')
        .delete()
        .eq('user_id', uid)
        .eq('topic_id', topicId);
  }

  static Future<bool> isTopicCompleted(String topicId) async {
    final uid = _uid;
    if (uid == null) return false;
    final r = await _client
        .from('progress')
        .select('topic_id')
        .eq('user_id', uid)
        .eq('topic_id', topicId)
        .maybeSingle();
    return r != null;
  }

  static Future<Set<String>> getCompletedTopicIds() async {
    final uid = _uid;
    if (uid == null) return <String>{};
    final r = await _client.from('progress').select('topic_id').eq('user_id', uid);
    return List<Map<String, dynamic>>.from(r)
        .map((e) => e['topic_id'].toString())
        .toSet();
  }

  // ==========================================================================
  // BOOKMARKS
  // ==========================================================================

  static Future<void> setBookmark(
      String topicId, String topicName, bool on) async {
    final uid = _uid;
    if (uid == null) return;
    if (on) {
      await _client.from('bookmarks').upsert({
        'user_id': uid,
        'topic_id': topicId,
        'topic_name': topicName,
        'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,topic_id');
    } else {
      await _client
          .from('bookmarks')
          .delete()
          .eq('user_id', uid)
          .eq('topic_id', topicId);
    }
  }

  static Future<bool> isBookmarked(String topicId) async {
    final uid = _uid;
    if (uid == null) return false;
    final r = await _client
        .from('bookmarks')
        .select('topic_id')
        .eq('user_id', uid)
        .eq('topic_id', topicId)
        .maybeSingle();
    return r != null;
  }

  static Future<List<Map<String, dynamic>>> getBookmarks() async {
    final uid = _uid;
    if (uid == null) return [];
    final r = await _client
        .from('bookmarks')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(r);
  }

  // ==========================================================================
  // QUIZ HISTORY
  // ==========================================================================

  static Future<void> saveQuizAttempt(
      String topicId, String topicName, int score, int total) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('quiz_attempts').insert({
      'user_id': uid,
      'topic_id': topicId,
      'topic_name': topicName,
      'score': score,
      'total': total,
      'created_at': DateTime.now().toIso8601String(),
    });
    await recordActivity();
  }

  static Future<List<Map<String, dynamic>>> getQuizAttempts() async {
    final uid = _uid;
    if (uid == null) return [];
    final r = await _client
        .from('quiz_attempts')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(r);
  }

  // ==========================================================================
  // CONTINUE WHERE YOU LEFT OFF
  // ==========================================================================

  static Future<void> setLastViewed(String topicId, String topicName) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('last_viewed').upsert({
      'user_id': uid,
      'topic_id': topicId,
      'topic_name': topicName,
      'viewed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
    await recordActivity();
  }

  static Future<Map<String, dynamic>?> getLastViewed() async {
    final uid = _uid;
    if (uid == null) return null;
    return await _client
        .from('last_viewed')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
  }

  // ==========================================================================
  // SETTINGS + STREAK
  // ==========================================================================

  static Future<Map<String, dynamic>?> getSettings() async {
    final uid = _uid;
    if (uid == null) return null;
    return await _client
        .from('student_settings')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
  }

  static Future<void> saveSettings(
      {bool? studyReminder, int? dailyGoalMinutes}) async {
    final uid = _uid;
    if (uid == null) return;
    final data = <String, dynamic>{
      'user_id': uid,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (studyReminder != null) data['study_reminder'] = studyReminder;
    if (dailyGoalMinutes != null) data['daily_goal_minutes'] = dailyGoalMinutes;
    await _client
        .from('student_settings')
        .upsert(data, onConflict: 'user_id');
  }

  // Updates the daily streak whenever the student does something today.
  static Future<void> recordActivity() async {
    final uid = _uid;
    if (uid == null) return;
    final today = DateTime.now();
    try {
      final s = await _client
          .from('student_settings')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      int streak = 1;
      if (s != null && s['last_active_date'] != null) {
        final last = DateTime.tryParse(s['last_active_date'].toString());
        final prev = (s['streak_count'] as int?) ?? 0;
        if (last != null) {
          final diff = _dayDiff(last, today);
          if (diff == 0) {
            streak = prev == 0 ? 1 : prev; // already counted today
          } else if (diff == 1) {
            streak = prev + 1; // consecutive day
          } else {
            streak = 1; // streak broken, restart
          }
        }
      }

      await _client.from('student_settings').upsert({
        'user_id': uid,
        'last_active_date': _dateStr(today),
        'streak_count': streak,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (_) {}
  }

  // The current streak, treating it as broken (0) if the last active day was
  // more than one day ago.
  static Future<int> getStreak() async {
    final s = await getSettings();
    if (s == null || s['last_active_date'] == null) return 0;
    final count = (s['streak_count'] as int?) ?? 0;
    final last = DateTime.tryParse(s['last_active_date'].toString());
    if (last == null) return 0;
    return _dayDiff(last, DateTime.now()) > 1 ? 0 : count;
  }

  // ==========================================================================
  // TIMETABLE
  // ==========================================================================

  static Future<Map<String, dynamic>?> getTimetable() async {
    final uid = _uid;
    if (uid == null) return null;
    return await _client
        .from('timetables')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
  }

  static Future<void> saveTimetable({
    String? examName,
    String? deadline,
    int? dailyHours,
    required String planJson,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('timetables').upsert({
      'user_id': uid,
      'exam_name': examName,
      'deadline': deadline,
      'daily_hours': dailyHours,
      'plan_json': planJson,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }
}