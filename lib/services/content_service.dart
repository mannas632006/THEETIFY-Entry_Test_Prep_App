// ===========================================================================
// lib/services/content_service.dart
// ---------------------------------------------------------------------------
// This file reads exams, topics, and topic content FROM the Supabase database,
// and (for the admin) writes them back. The rest of the app calls these simple
// functions so no screen has to know how the database works.
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

  // ==========================================================================
  // ADMIN WRITE FUNCTIONS (used by the Admin Dashboard)
  // ==========================================================================

  // --- Add an exam, OR reuse the existing one with the same name. ---
  // Returns its id. This prevents a new "NUST NET" row every time you publish.
  static Future<String> addExam(String name, {String? description}) async {
    // Look for an exam that already has this exact name.
    final existing = await _client
        .from('exams')
        .select('id')
        .eq('name', name)
        .limit(1)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    // None found: create it.
    final result = await _client
        .from('exams')
        .insert({'name': name, 'description': description})
        .select()
        .single();
    return result['id'] as String;
  }

  // --- Add a topic under an exam, OR reuse the existing one with the same ---
  // --- name in that exam. Returns its id. ---
  static Future<String> addTopic(String examId, String name) async {
    // Look for a topic with this name already under this exam.
    final existing = await _client
        .from('topics')
        .select('id')
        .eq('exam_id', examId)
        .eq('name', name)
        .limit(1)
        .maybeSingle();
    if (existing != null) return existing['id'] as String;

    // None found: create it.
    final result = await _client
        .from('topics')
        .insert({'exam_id': examId, 'name': name})
        .select()
        .single();
    return result['id'] as String;
  }

  // --- Save (or replace) all generated content for a topic. ---
  // 'content' is a map of the generated fields. We also mark the topic 'ready'.
  static Future<void> saveTopicContent(
    String topicId,
    Map<String, dynamic> content,
  ) async {
    // upsert = update if a row exists for this topic, otherwise insert.
    await _client.from('topic_content').upsert({
      'topic_id': topicId,
      ...content,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'topic_id');

    await _client.from('topics').update({'status': 'ready'}).eq('id', topicId);
  }
}