// ===========================================================================
// lib/services/generation_service.dart
// ---------------------------------------------------------------------------
// Generates every content type for a topic for the Admin "Generate" feature,
// including an estimated study time (in minutes) for the topic.
// ===========================================================================

import 'ai_service.dart';

class GenerationService {
  static Future<Map<String, dynamic>> generateEverything({
    required String topic,
    required String exam,
    void Function(String step)? onProgress,
  }) async {
    onProgress?.call('Writing the interactive lesson...');
    final htmlLesson = await AiService.generateHtmlLesson(topic, exam);

    onProgress?.call('Writing in-depth notes...');
    final deepNotes = await AiService.generateDeepNotes(topic, exam);

    onProgress?.call('Writing 3-hour crash notes...');
    final crashNotes = await AiService.generateCrashNotes(topic, exam);

    onProgress?.call('Creating the quiz...');
    final quiz = await AiService.generateQuiz(topic, exam);

    onProgress?.call('Estimating study time...');
    final minsText = await AiService.generateEstimatedMinutes(topic, exam);
    final estimatedMinutes = _firstInt(minsText) ?? 30;

    onProgress?.call('Done!');

    // These keys match columns in the 'topic_content' table.
    return {
      'html_lesson': htmlLesson,
      'deep_notes': deepNotes,
      'crash_notes': crashNotes,
      'quiz_json': quiz,
      'estimated_minutes': estimatedMinutes,
      'ai_teacher_context': '$exam - $topic',
      'approved': false,
    };
  }

  // Pulls the first whole number out of a string (e.g. "About 45 min" -> 45).
  static int? _firstInt(String text) {
    final match = RegExp(r'\d+').firstMatch(text);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }
}