// ===========================================================================
// lib/widgets/videos_view.dart
// ---------------------------------------------------------------------------
// The Videos tab on a topic page. Simple by design: one clear button that
// opens a YouTube search for this topic in a new browser tab. No API key
// needed, and nothing to overwhelm the student.
//
// WEB ONLY: uses dart:html to open the new tab. The app is web-only.
// ===========================================================================

import 'dart:html' as web;

import 'package:flutter/material.dart';

class VideosView extends StatelessWidget {
  final String topicName;
  const VideosView({super.key, required this.topicName});

  void _openYouTube() {
    final query = Uri.encodeQueryComponent('$topicName explained');
    web.window
        .open('https://www.youtube.com/results?search_query=$query', '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0x1FFF0000),
                child: Icon(Icons.smart_display,
                    color: Color(0xFFFF0000), size: 36),
              ),
              const SizedBox(height: 18),
              const Text(
                'Watch video lectures',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Find the best YouTube lectures for "$topicName".',
                style: const TextStyle(color: Colors.black54, fontSize: 15),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _openYouTube,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Search on YouTube'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}