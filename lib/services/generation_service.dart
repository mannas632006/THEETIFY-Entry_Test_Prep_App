// ===========================================================================
// lib/services/generation_service.dart
// ---------------------------------------------------------------------------
// This ties everything together for the "type a topic -> Generate" feature.
// It calls the AI to make EVERY content type for a topic, then hands the
// results back so the Admin can review them before saving.
// ===========================================================================

import 'ai_service.dart';

class GenerationService {
  // Generate ALL content for one topic at once.
  // Returns a map ready to be saved to the database (after you approve it).
  //
  // 'onProgress' lets the screen show messages like "Generating quiz...".
  static Future<Map<String, dynamic>> generateEverything({
    required String topic,
    required String exam,
    void Function(String step)? onProgress,
  }) async {
    // We generate each piece one by one and report progress as we go.
    onProgress?.call('Writing the interactive lesson...');
    final htmlLesson = await AiService.generateHtmlLesson(topic, exam);

    onProgress?.call('Writing in-depth notes...');
    final deepNotes = await AiService.generateDeepNotes(topic, exam);

    onProgress?.call('Writing 3-hour crash notes...');
    final crashNotes = await AiService.generateCrashNotes(topic, exam);

    onProgress?.call('Writing the video lecture script...');
    final videoScript = await AiService.generateVideoScript(topic, exam);

    onProgress?.call('Creating the quiz...');
    final quiz = await AiService.generateQuiz(topic, exam);

    onProgress?.call('Done!');

    // These keys match the columns in the 'topic_content' database table.
    return {
      'html_lesson': htmlLesson,
      'deep_notes': deepNotes,
      'crash_notes': crashNotes,
      'video_script': videoScript,
      'quiz_json': quiz,
      'ai_teacher_context': '$exam - $topic',
      'approved': false, // You approve it from the dashboard before students see it.
    };
  }
}
