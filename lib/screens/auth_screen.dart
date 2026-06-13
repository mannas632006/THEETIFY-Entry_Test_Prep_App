// ===========================================================================
// lib/screens/auth_screen.dart
// ---------------------------------------------------------------------------
// One screen that handles BOTH login and signup. A toggle at the bottom lets
// the user switch between 'Log in' and 'Create account'. Kept deliberately
// simple and friendly.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../config/app_config.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Controllers hold what the user types in the email/password boxes.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true; // true = log in, false = create account.
  bool _busy = false;       // true while we wait for Supabase to respond.
  String? _error;           // an error message to show, if any.

  // Runs when the user presses the main button.
  Future<void> _submit() async {
    // Safety: if Supabase keys are missing, explain instead of crashing.
    if (!AppConfig.hasSupabase) {
      setState(() => _error =
          'Login is not set up yet. Add your Supabase keys to the .env file.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Call signUp or signIn depending on the mode.
    final error = _isLoginMode
        ? await AuthService.signIn(email, password)
        : await AuthService.signUp(email, password);

    if (!mounted) return;
    setState(() => _busy = false);

    if (error == null) {
      // Success: go to the exam list.
      context.go('/exams');
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Log In' : 'Create Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email box.
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Password box (hidden text).
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Show an error message if there is one.
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                // Main action button (shows a spinner while busy).
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isLoginMode ? 'Log In' : 'Create Account'),
                  ),
                ),
                const SizedBox(height: 12),
                // Toggle between login and signup.
                TextButton(
                  onPressed: () =>
                      setState(() => _isLoginMode = !_isLoginMode),
                  child: Text(_isLoginMode
                      ? "New here? Create an account"
                      : 'Already have an account? Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
