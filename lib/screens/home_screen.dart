// ===========================================================================
// lib/screens/home_screen.dart
// ---------------------------------------------------------------------------
// The welcome screen. First thing a student sees. It greets them and has a
// button to start studying (which takes them to the list of exams).
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('THEETIFY')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to THEETIFY',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your AI teacher for entry test preparation.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              // When tapped, go to the exam list screen.
              onPressed: () => context.go('/exams'),
              child: const Text('Start Studying'),
            ),
          ],
        ),
      ),
    );
  }
}
