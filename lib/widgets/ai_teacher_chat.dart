// ===========================================================================
// lib/widgets/ai_teacher_chat.dart
// ---------------------------------------------------------------------------
// The live AI Teacher chat. Designed to feel calm and tutor-like: a friendly
// header, tappable starter prompts when empty, clean chat bubbles, and roomy
// spacing so students aren't overwhelmed. The AI is locked to study topics
// only (rules live in ai_service.dart).
// ===========================================================================

import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AiTeacherChat extends StatefulWidget {
  final String examContext;
  const AiTeacherChat({super.key, required this.examContext});

  @override
  State<AiTeacherChat> createState() => _AiTeacherChatState();
}

class _AiTeacherChatState extends State<AiTeacherChat> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _waiting = false;

  static const _accent = Color(0xFF1B98E0);

  static const List<String> _starters = [
    'Explain this topic in simple terms',
    'Give me a practice question',
    'What are common mistakes here?',
    'Summarize the key points',
  ];

  Future<void> _sendText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _waiting) return;

    // Snapshot PAST turns before adding the new message (so it isn't sent twice).
    final history = List<Map<String, String>>.from(_messages);

    setState(() {
      _messages.add({'role': 'user', 'content': trimmed});
      _inputController.clear();
      _waiting = true;
    });
    _scrollToBottom();

    final reply = await AiService.chat(
      message: trimmed,
      examContext: widget.examContext,
      history: history,
    );

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
      _waiting = false;
    });
    _scrollToBottom();
  }

  void _send() => _sendText(_inputController.text);

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        Expanded(child: _messages.isEmpty ? _emptyState() : _messageList()),
        if (_waiting)
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(22, 4, 22, 4),
              child: Text(
                'AI teacher is typing…',
                style: TextStyle(
                    color: Colors.black45, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        _inputBar(),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: _accent,
            child: Icon(Icons.school, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Teacher',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  'Here to help with ${widget.examContext}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0x1F1B98E0),
              child: Icon(Icons.auto_stories, color: _accent, size: 28),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ask me anything about this topic',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "I only help with your exam prep — pick a starter below or type your own.",
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _starters
                  .map((s) => ActionChip(
                        label: Text(s),
                        onPressed: _waiting ? null : () => _sendText(s),
                        backgroundColor: const Color(0x141B98E0),
                        side: const BorderSide(color: Color(0x331B98E0)),
                        labelStyle: const TextStyle(
                            color: _accent, fontWeight: FontWeight.w500),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0x1F1B98E0),
                  child: Icon(Icons.school, size: 15, color: _accent),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  constraints: const BoxConstraints(maxWidth: 560),
                  decoration: BoxDecoration(
                    color: isUser ? _accent : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    msg['content'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      height: 1.45,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: 'Type your question…',
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _accent,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _waiting ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}