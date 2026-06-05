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
  bool _isSignUp = false;

  Future<void> _handleAuth() async {
    setState(() { _error = null; _loading = true; });

    try {
      final supabase = Supabase.instance.client;

      if (_isSignUp) {
        final email = _emailCtl.text.trim();
        final password = _passwordCtl.text.trim();
        if (!email.contains('@') && password.length < 6) {
          setState(() { _error = 'Enter valid email and password (min 6 chars)'; _loading = false; });
          return;
        }
        await supabase.auth.signUp(
          email: email,
          password: password,
          data: AuthHelper.signUpMetadata(
            username: email.split('@').first,
            fullName: email.split('@').first,
            role: 'student',
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created! You can now sign in.')),
          );
          setState(() { _isSignUp = false; _loading = false; });
        }
        return;
      }

      final usernameOrEmail = _emailCtl.text.trim();
      final password = _passwordCtl.text.trim();

      if (usernameOrEmail.isEmpty || password.isEmpty) {
        setState(() { _error = 'Please fill in all fields.'; _loading = false; });
        return;
      }

      // Determine if this is email or username login
      final isEmail = usernameOrEmail.contains('@');
      String email = usernameOrEmail;

      if (!isEmail) {
        // Look up email by username via auth admin API or use username as email format
        // For simplicity, try common patterns
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
                  Text('College Portal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_isSignUp ? 'Create an account' : 'Sign in to continue', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailCtl,
                    decoration: InputDecoration(
                      hintText: _isSignUp ? 'Email address' : 'Email or Registration No',
                      labelText: _isSignUp ? 'Email' : 'Username / Email',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordCtl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
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
                      onPressed: _loading ? null : _handleAuth,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_isSignUp ? 'Sign Up' : 'Login', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => setState(() { _isSignUp = !_isSignUp; _error = null; }),
                    child: Text(_isSignUp ? 'Already have an account? Sign in' : 'New student? Create account'),
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
