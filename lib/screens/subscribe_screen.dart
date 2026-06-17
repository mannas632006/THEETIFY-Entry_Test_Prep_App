// ===========================================================================
// lib/screens/subscribe_screen.dart
// ---------------------------------------------------------------------------
// The paywall + subscription flow (Phase A: manual approval).
//   - If already subscribed: a confirmation.
//   - If a request is pending: a "being reviewed" status.
//   - Otherwise: payment instructions + a short form where the student
//     confirms they paid (amount, their number, transaction id). That goes
//     into the admin's review queue; the admin verifies and unlocks access.
//
// >>> EDIT THE THREE CONSTANTS BELOW with your real payment details. <<<
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/content_service.dart';

// ---- EDIT THESE ----
const String _payNumber = '03XX-XXXXXXX';        // your EasyPaisa / account number
const String _payName = 'Account holder name';   // the name on that account
const String _price = 'Rs. 1000';                // your subscription price
// --------------------

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  static const _accent = Color(0xFF1B98E0);

  bool _loading = true;
  bool _subscribed = false;
  Map<String, dynamic>? _latest;

  final _amount = TextEditingController();
  final _sender = TextEditingController();
  final _tid = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _sender.dispose();
    _tid.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final sub = await ContentService.isSubscribed();
    final latest = await ContentService.getMyLatestPaymentRequest();
    if (!mounted) return;
    setState(() {
      _subscribed = sub;
      _latest = latest;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (_amount.text.trim().isEmpty ||
        _sender.text.trim().isEmpty ||
        _tid.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in all three fields.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ContentService.submitPaymentRequest(
        amount: _amount.text.trim(),
        senderNumber: _sender.text.trim(),
        transactionId: _tid.text.trim(),
      );
      await _load();
    } catch (e) {
      setState(() => _error = 'Could not submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subscribe')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please log in first.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Log in'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [_body()],
                ),
              ),
            ),
    );
  }

  Widget _body() {
    if (_subscribed) {
      return _card(
        child: Column(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0x1F2E9E5B),
              child: Icon(Icons.verified, color: Color(0xFF2E9E5B), size: 32),
            ),
            const SizedBox(height: 14),
            const Text("You're subscribed",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('All study material is unlocked. Happy studying!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/exams'),
              child: const Text('Browse exams'),
            ),
          ],
        ),
      );
    }

    final pending = _latest?['status']?.toString() == 'pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unlock everything',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text(
                'One subscription unlocks the full lessons, deep & crash notes, '
                'quizzes, the AI teacher, and the study timetable for every exam.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.sell, color: _accent),
                  const SizedBox(width: 8),
                  Text(_price,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (pending)
          _card(
            child: Row(
              children: const [
                Icon(Icons.hourglass_top, color: Color(0xFFE0921A)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Your payment is being reviewed. You'll get access once "
                    "it's verified (usually within a few hours).",
                  ),
                ),
              ],
            ),
          )
        else ...[
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How to pay',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _payRow('1.', 'Send $_price to this EasyPaisa number:'),
                Container(
                  margin: const EdgeInsets.only(left: 28, top: 6, bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x141B98E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_payNumber,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(_payName,
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
                _payRow('2.', 'Then enter your payment details below.'),
                _payRow('3.', 'We verify it and unlock your account.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Confirm your payment',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount sent',
                      border: OutlineInputBorder(),
                      isDense: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sender,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Your EasyPaisa / phone number',
                      border: OutlineInputBorder(),
                      isDense: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tid,
                  decoration: const InputDecoration(
                      labelText: 'Transaction ID (TID)',
                      border: OutlineInputBorder(),
                      isDense: true),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit payment for review'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _payRow(String n, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 24,
                child: Text(n,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: Text(t)),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      );
}