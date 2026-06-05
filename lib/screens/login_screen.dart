import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/auth_helper.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  String? _error;
  bool _loading = false;

  Future<void> _handleLogin() async {
    setState(() { _error = null; _loading = true; });

    try {
      final supabase = Supabase.instance.client;
      final usernameOrEmail = _emailCtl.text.trim();
      final password = _passwordCtl.text.trim();

      if (usernameOrEmail.isEmpty || password.isEmpty) {
        setState(() { _error = 'Please fill in all fields.'; _loading = false; });
        return;
      }

      final isEmail = usernameOrEmail.contains('@');
      String email = usernameOrEmail;

      if (!isEmail) {
        final response = await supabase.auth.signInWithPassword(
          email: '$usernameOrEmail@college.app',
          password: password,
        );
        if (response.user != null) {
          _onLoginSuccess(response.user!);
          return;
        }
        setState(() => _loading = false);
        return;
      }

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        if (!mounted) return;
        _onLoginSuccess(response.user!);
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Connection error. Check your network.');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onLoginSuccess(User authUser) {
    final user = AuthHelper.userFromAuth(authUser);
    if (user == null) {
      setState(() => _error = 'Could not load profile.');
      return;
    }
    context.read<AppState>().logIn(user);
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.school_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text('College Portal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Sign in to continue', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailCtl,
                    decoration: const InputDecoration(
                      hintText: 'Email or Registration No',
                      labelText: 'Email / Reg No',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password (Phone Number)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleLogin,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
