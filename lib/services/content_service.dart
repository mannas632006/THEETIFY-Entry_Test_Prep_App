// ===========================================================================
// lib/services/content_service.dart
// ---------------------------------------------------------------------------
// This file reads exams, topics, and topic content FROM the Supabase database.
// The rest of the app calls these simple functions to get data, so no screen
// has to know how the database works.
// ===========================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class ContentService {
  static SupabaseClient get _client => Supabase.instance.client;

  // --- Get the list of all exams ---
  // Returns a list where each item is a map like {id: ..., name: ...}.
  static Future<List<Map<String, dynamic>>> getExams() async {
    if (!AppConfig.hasSupabase) return [];
    final result = await _client.from('exams').select().order('name');
    return List<Map<String, dynamic>>.from(result);
  }

  // --- Get all topics that belong to one exam ---
  static Future<List<Map<String, dynamic>>> getTopics(String examId) async {
    if (!AppConfig.hasSupabase) return [];
    final result = await _client
        .from('topics')
        .select()
        .eq('exam_id', examId)
        .order('name');
    return List<Map<String, dynamic>>.from(result);
  }

  // --- Get the generated content for one topic ---
  // Returns null if no content exists yet.
  static Future<Map<String, dynamic>?> getTopicContent(String topicId) async {
    if (!AppConfig.hasSupabase) return null;
    final result = await _client
        .from('topic_content')
        .select()
        .eq('topic_id', topicId)
        .maybeSingle();
    return result;
  }
}
