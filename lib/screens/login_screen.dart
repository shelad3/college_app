import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }

    final isSuperAdmin = username == 'EIT/500/S25/038' && password == '0112327446';
    final isPrefectUser = username == 'PREFECT/001' && password == '0112327446';

    String role;
    if (isSuperAdmin || isPrefectUser) {
      role = 'student';
    } else if (RegExp(r'^[A-Za-z]').hasMatch(username)) {
      role = 'student';
    } else if (RegExp(r'^\d+$').hasMatch(username)) {
      role = 'teacher';
    } else {
      setState(() => _error = 'Invalid username format.');
      return;
    }

    final phone = role == 'teacher' ? username : '0712345678';
    if (!isSuperAdmin && !isPrefectUser && password != phone) {
      setState(() => _error = 'Invalid credentials.');
      return;
    }

    String fullName;
    if (isSuperAdmin) {
      fullName = 'Sheldon Ramu';
    } else if (isPrefectUser) {
      fullName = 'Class Prefect';
    } else if (role == 'student') {
      fullName = 'Student User';
    } else {
      fullName = 'Teacher User';
    }

    String userPhone;
    String userEmail;
    if (isSuperAdmin) {
      userPhone = '0112327446';
      userEmail = 'sheldonramu8@gmail.com';
    } else if (isPrefectUser) {
      userPhone = '0112000000';
      userEmail = '';
    } else if (role == 'teacher') {
      userPhone = username;
      userEmail = '';
    } else {
      userPhone = '0712345678';
      userEmail = '';
    }

    final user = User(
      username: username,
      fullName: fullName,
      role: role,
      phone: userPhone,
      email: userEmail,
      isFirstLogin: false,
      isSuperAdmin: isSuperAdmin,
      isPrefect: isPrefectUser,
      assignedLessons: role == 'teacher' ? [] : [1, 2, 3, 4],
    );

    context.read<AppState>().logIn(user);

    if (user.isFirstLogin) {
      _showFirstLoginOverlay(role);
    }
  }

  void _showFirstLoginOverlay(String role) {
    final newPasswordController = TextEditingController();
    List<int> selectedLessons = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('First Time Setup'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Please set a new password to continue.'),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (role == 'teacher') ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Select the lessons you instruct:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(4, (index) {
                        final lessonId = index + 1;
                        final lesson = context.read<AppState>().lessons[lessonId - 1];
                        final isSelected = selectedLessons.contains(lessonId);
                        return CheckboxListTile(
                          title: Text('Lesson ${lesson.id}: ${lesson.subjectName}'),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedLessons.add(lessonId);
                              } else {
                                selectedLessons.remove(lessonId);
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (newPasswordController.text.trim().isEmpty) return;
                    final appState = context.read<AppState>();
                    appState.completeFirstLogin(newPasswordController.text.trim());
                    if (role == 'teacher') {
                      appState.assignTeacherLessons(selectedLessons);
                    }
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Finish Setup'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'College Portal',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'Registration Number or Phone',
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      hintText: 'Password',
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('Login', style: TextStyle(fontSize: 16)),
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
