// ===========================================================================
// lib/screens/auth_screen.dart
// ---------------------------------------------------------------------------
// One screen for BOTH login and signup. Pass startInSignup: true (via
// /login?mode=signup) to open directly in create-account mode. After success,
// the student lands on their Home dashboard.
// ===========================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../config/app_config.dart';

class AuthScreen extends StatefulWidget {
  final bool startInSignup;
  const AuthScreen({super.key, this.startInSignup = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isLoginMode;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _isLoginMode = !widget.startInSignup;
  }

  Future<void> _submit() async {
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

    final error = _isLoginMode
        ? await AuthService.signIn(email, password)
        : await AuthService.signUp(email, password);

    if (!mounted) return;
    setState(() => _busy = false);

    if (error == null) {
      context.go('/dashboard');
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
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
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