// ===========================================================================
// lib/widgets/ai_teacher_chat.dart
// ---------------------------------------------------------------------------
// The live AI Teacher chat box shown on a topic page. The student types a
// question, the AI replies. The AI is locked to study topics only (the rules
// live in ai_service.dart).
// ===========================================================================

import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AiTeacherChat extends StatefulWidget {
  // Tells the AI what the student is studying, e.g. "NUST NET - Trigonometry".
  final String examContext;
  const AiTeacherChat({super.key, required this.examContext});

  @override
  State<AiTeacherChat> createState() => _AiTeacherChatState();
}

class _AiTeacherChatState extends State<AiTeacherChat> {
  final _inputController = TextEditingController();
  // Each message is {role: 'user'/'assistant', content: '...'}.
  final List<Map<String, String>> _messages = [];
  bool _waiting = false; // true while the AI is thinking.

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _waiting) return;

    // Snapshot the conversation so far (PAST turns only) to send as history.
    // We take this BEFORE adding the new message, otherwise the new message
    // would be sent twice: once in history and once as the message itself.
    final history = List<Map<String, String>>.from(_messages);

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _inputController.clear();
      _waiting = true;
    });

    // Ask the AI, passing the recent conversation as history.
    final reply = await AiService.chat(
      message: text,
      examContext: widget.examContext,
      history: history,
    );

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
      _waiting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The scrolling list of chat bubbles.
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Ask your AI teacher anything about this topic!',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isUser = msg['role'] == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Text(msg['content'] ?? ''),
                      ),
                    );
                  },
                ),
        ),
        // Shows a small 'thinking' indicator while waiting.
        if (_waiting)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('AI teacher is thinking...'),
          ),
        // The input row: text box + send button.
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    hintText: 'Type your question...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _waiting ? null : _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}