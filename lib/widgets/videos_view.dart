// ===========================================================================
// lib/widgets/videos_view.dart
// ---------------------------------------------------------------------------
// The Videos tab on a topic page. It does two things:
//   1. A "Search YouTube" button that opens a YouTube search for this topic
//      in a new browser tab (no API key needed).
//   2. Shows the AI-generated video lecture script (if one was generated),
//      rendered from Markdown to HTML.
//
// WEB ONLY: uses dart:html to open the new tab. The app is web-only.
// ===========================================================================

import 'dart:html' as web;

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../utils/markdown.dart';

class VideosView extends StatelessWidget {
  final String topicName;
  final String? videoScript;
  const VideosView({super.key, required this.topicName, this.videoScript});

  // Opens a YouTube search for this topic in a new tab.
  void _openYouTube() {
    final query = Uri.encodeQueryComponent('$topicName explained');
    web.window
        .open('https://www.youtube.com/results?search_query=$query', '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final hasScript = videoScript != null && videoScript!.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // YouTube search card.
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Video lectures',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Find video lectures for "$topicName" on YouTube.',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _openYouTube,
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Search YouTube'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // AI script section.
              const Text(
                'AI video lecture script',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              hasScript
                  ? HtmlWidget(markdownToHtml(videoScript!))
                  : const Text('A video script has not been generated yet.'),
            ],
          ),
        ),
      ),
    );
  }
}