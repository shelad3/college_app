import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _currentPwCtl = TextEditingController();
  final _newPwCtl = TextEditingController();
  String? _pwMessage;

  @override
  void dispose() {
    _currentPwCtl.dispose();
    _newPwCtl.dispose();
    super.dispose();
  }

  void _savePassword() {
    if (_currentPwCtl.text.isEmpty || _newPwCtl.text.isEmpty) {
      setState(() => _pwMessage = 'Please fill in both fields.');
      return;
    }
    setState(() => _pwMessage = 'Password updated successfully.');
    _currentPwCtl.clear();
    _newPwCtl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    if (user == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey[200],
                backgroundImage: user.profileImagePath != null
                    ? NetworkImage(user.profileImagePath!)
                    : null,
                child: user.profileImagePath == null
                    ? const Icon(Icons.person, size: 48, color: Colors.grey)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Image picker not implemented in mock')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    initialValue: user.fullName,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user.role == 'student' ? user.username : user.phone,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: user.role == 'student' ? 'Registration Number' : 'Phone Number',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(user.role == 'student' ? Icons.badge_outlined : Icons.phone),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPwCtl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPwCtl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_pwMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(_pwMessage!, style: TextStyle(color: _pwMessage!.contains('success') ? Colors.green : Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savePassword,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (user.role == 'teacher') ...[
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Lessons', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...appState.lessons.map((lesson) {
                      final assigned = user.assignedLessons.contains(lesson.id);
                      return Card(
                        color: assigned ? Colors.green.shade50 : Colors.grey.shade100,
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: assigned ? Colors.green : Colors.grey,
                            child: Text('${lesson.id}', style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(lesson.subjectName, style: const TextStyle(fontSize: 14)),
                          trailing: Icon(
                            assigned ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: assigned ? Colors.green : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                context.read<AppState>().logOut();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
