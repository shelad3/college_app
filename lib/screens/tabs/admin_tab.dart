import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/app_state.dart';
import '../../models/user.dart';
import '../../models/lesson.dart';
import '../../models/schedule.dart';
import '../../models/note.dart';
import '../../models/document.dart';
import '../../utils/uuid.dart';
import 'quiz_tab.dart' show AdminQuizPage;

class AdminTab extends StatefulWidget {
  const AdminTab({super.key});

  @override
  State<AdminTab> createState() => _AdminTabState();
}

class _AdminTabState extends State<AdminTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Users'),
            Tab(text: 'Lessons'),
            Tab(text: 'Schedule'),
            Tab(text: 'Notes'),
            Tab(text: 'Documents'),
            Tab(text: 'Quizzes'),
            Tab(text: 'Hub'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DashboardPage(),
              _UsersPage(),
              _LessonsPage(),
              _SchedulePage(),
              _NotesPage(),
              _AdminDocumentsPage(),
              AdminQuizPage(),
              _HubPage(),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================
class _DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(name: user?.fullName ?? 'Admin'),
        const SizedBox(height: 16),
        _StatCard(label: 'Total Users', value: '${appState.allUsers.length + (appState.currentUser != null ? 1 : 0)}', icon: Icons.people, color: Colors.blue),
        const SizedBox(height: 8),
        _StatCard(label: 'Total Lessons', value: '${appState.lessons.length}', icon: Icons.book, color: Colors.indigo),
        const SizedBox(height: 8),
        _StatCard(label: 'Schedule Entries', value: '${appState.schedule.length}', icon: Icons.calendar_month, color: Colors.teal),
        const SizedBox(height: 8),
        _StatCard(label: 'Note Topics', value: '${appState.notes.length}', icon: Icons.menu_book, color: Colors.orange),
        const SizedBox(height: 8),
        _StatCard(label: 'Announcements', value: '${appState.announcements.length}', icon: Icons.campaign, color: Colors.red),
        const SizedBox(height: 8),
        _StatCard(label: 'Discussions', value: '${appState.discussions.length}', icon: Icons.chat, color: Colors.purple),
        const SizedBox(height: 8),
        _StatCard(label: 'Documents', value: '${appState.documents.length}', icon: Icons.folder, color: Colors.deepOrange),
        const SizedBox(height: 8),
        _StatCard(label: 'Quizzes', value: '${appState.quizzes.length}', icon: Icons.quiz, color: Colors.purple),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ============================================================
// USERS PAGE
// ============================================================
class _UsersPage extends StatelessWidget {
  void _addUserDialog(BuildContext context) {
    final nameCtl = TextEditingController();
    final usernameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final emailCtl = TextEditingController();
    String role = 'student';
    bool isPrefect = false;
    bool creating = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add User'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: usernameCtl, decoration: const InputDecoration(labelText: 'Reg Number', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Phone (used as password)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: emailCtl, decoration: const InputDecoration(labelText: 'Email (optional, auto-generated if empty)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: const [DropdownMenuItem(value: 'student', child: Text('Student')), DropdownMenuItem(value: 'teacher', child: Text('Teacher'))],
              onChanged: (v) => setState(() => role = v!),
            ),
            if (role == 'student')
              CheckboxListTile(
                title: const Text('Class Prefect'),
                value: isPrefect,
                onChanged: (v) => setState(() => isPrefect = v!),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: creating ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: creating
                ? null
                : () async {
                    if (nameCtl.text.isEmpty || usernameCtl.text.isEmpty || phoneCtl.text.isEmpty) return;
                    setState(() => creating = true);
                    final email = emailCtl.text.trim().isEmpty
                        ? '${usernameCtl.text.trim()}@college.app'
                        : emailCtl.text.trim();
                    final result = await context.read<AppState>().createUserViaRpc(
                      email: email,
                      password: phoneCtl.text.trim(),
                      username: usernameCtl.text.trim(),
                      fullName: nameCtl.text.trim(),
                      role: role,
                      phone: phoneCtl.text.trim(),
                      isPrefect: isPrefect,
                    );
                    if (ctx.mounted) {
                      if (result == null) {
                        context.read<AppState>().addUser(AppUser(
                          username: usernameCtl.text,
                          fullName: nameCtl.text,
                          role: role,
                          phone: phoneCtl.text,
                          isPrefect: isPrefect,
                        ));
                        Navigator.pop(ctx);
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(result)),
                        );
                        setState(() => creating = false);
                      }
                    }
                  },
            child: creating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
          ),
        ],
      ),
    ));
  }

  void _editUserDialog(BuildContext context, int index, AppUser user) {
    final nameCtl = TextEditingController(text: user.fullName);
    final usernameCtl = TextEditingController(text: user.username);
    final phoneCtl = TextEditingController(text: user.phone);
    String role = user.role;
    bool isPrefect = user.isPrefect;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: usernameCtl, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: phoneCtl, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: const [DropdownMenuItem(value: 'student', child: Text('Student')), DropdownMenuItem(value: 'teacher', child: Text('Teacher'))],
              onChanged: (v) => setState(() => role = v!),
            ),
            if (role == 'student')
              CheckboxListTile(
                title: const Text('Class Prefect'),
                value: isPrefect,
                onChanged: (v) => setState(() => isPrefect = v!),
              ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (nameCtl.text.isEmpty) return;
            context.read<AppState>().updateUser(index, AppUser(
              username: usernameCtl.text, fullName: nameCtl.text, role: role, phone: phoneCtl.text, isPrefect: isPrefect,
            ));
            Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allUsers = [
      appState.currentUser!,
      ...appState.allUsers,
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addUserDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: allUsers.length,
        itemBuilder: (context, index) {
          final u = allUsers[index];
          final canDelete = index > 0 && u.username != appState.currentUser?.username;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: u.isSuperAdmin ? Colors.amber : (u.isPrefect ? Colors.teal : (u.role == 'teacher' ? Colors.blue : Colors.grey)),
                child: Icon(
                  u.isSuperAdmin ? Icons.admin_panel_settings : (u.isPrefect ? Icons.shield : (u.role == 'teacher' ? Icons.school : Icons.person)),
                  color: Colors.white, size: 20,
                ),
              ),
              title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${u.username}  •  ${u.role}${u.isSuperAdmin ? ' • SUPER ADMIN' : ''}${u.isPrefect ? ' • PREFECT' : ''}', style: const TextStyle(fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (index > 0)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => _editUserDialog(context, index - 1, u),
                    ),
                  if (canDelete)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () {
                        showDialog(context: context, builder: (ctx) => AlertDialog(
                          title: const Text('Delete User'),
                          content: Text('Remove ${u.fullName}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            TextButton(onPressed: () {
                              context.read<AppState>().deleteUser(index - 1);
                              Navigator.pop(ctx);
                            }, style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
                          ],
                        ));
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// LESSONS PAGE
// ============================================================
class _LessonsPage extends StatelessWidget {
  void _addLessonDialog(BuildContext context) {
    final nameCtl = TextEditingController();
    final instrCtl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Lesson'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Subject Name', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: instrCtl, decoration: const InputDecoration(labelText: 'Instructor', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          if (nameCtl.text.isEmpty) return;
          context.read<AppState>().addLesson(nameCtl.text, instrCtl.text);
          Navigator.pop(ctx);
        }, child: const Text('Add')),
      ],
    ));
  }

  void _editLessonDialog(BuildContext context, int index, Lesson lesson) {
    final nameCtl = TextEditingController(text: lesson.subjectName);
    final instrCtl = TextEditingController(text: lesson.instructor);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Edit Lesson'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Subject Name', border: OutlineInputBorder())),
        const SizedBox(height: 8),
        TextField(controller: instrCtl, decoration: const InputDecoration(labelText: 'Instructor', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          context.read<AppState>().updateLesson(lesson.id - 1, nameCtl.text, instrCtl.text);
          Navigator.pop(ctx);
        }, child: const Text('Save')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addLessonDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: appState.lessons.length,
        itemBuilder: (context, index) {
          final l = appState.lessons[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('${l.id}')),
              title: Text(l.subjectName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(l.instructor, style: const TextStyle(fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editLessonDialog(context, index, l)),
                  IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () {
                    context.read<AppState>().deleteLesson(index).catchError((_) {});
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// SCHEDULE PAGE
// ============================================================
class _SchedulePage extends StatelessWidget {
  void _addScheduleDialog(BuildContext context) {
    final lessonCtl = TextEditingController();
    final dayCtl = TextEditingController();
    final timeCtl = TextEditingController();
    final roomCtl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Schedule Entry'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: lessonCtl, decoration: const InputDecoration(labelText: 'Lesson ID (1-4)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: dayCtl, decoration: const InputDecoration(labelText: 'Day (e.g. Monday)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: timeCtl, decoration: const InputDecoration(labelText: 'Time (e.g. 08:00-10:00)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: roomCtl, decoration: const InputDecoration(labelText: 'Room', border: OutlineInputBorder())),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          final lessonId = int.tryParse(lessonCtl.text) ?? 1;
          context.read<AppState>().addScheduleEntry(ScheduleEntry(
            lessonId: lessonId, day: dayCtl.text, time: timeCtl.text, room: roomCtl.text,
          ));
          Navigator.pop(ctx);
        }, child: const Text('Add')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addScheduleDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: appState.schedule.length,
        itemBuilder: (context, index) {
          final s = appState.schedule[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('L${s.lessonId}')),
              title: Text('${s.day}  •  ${s.time}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${s.room}${s.isShifted ? '  •  SHIFTED' : ''}', style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => context.read<AppState>().deleteScheduleEntry(index),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// NOTES PAGE
// ============================================================
class _NotesPage extends StatelessWidget {
  void _addTopicDialog(BuildContext context) {
    final titleCtl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Note Topic'),
      content: TextField(controller: titleCtl, decoration: const InputDecoration(labelText: 'Topic Title', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          if (titleCtl.text.isEmpty) return;
          final id = 't${DateTime.now().millisecondsSinceEpoch}';
          context.read<AppState>().addNoteTopic(NoteTopic(id: id, title: titleCtl.text, paragraphs: []));
          Navigator.pop(ctx);
        }, child: const Text('Add')),
      ],
    ));
  }

  void _addParagraphDialog(BuildContext context, int topicIndex) {
    final textCtl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Paragraph'),
      content: TextField(controller: textCtl, maxLines: 3, decoration: const InputDecoration(labelText: 'Paragraph text', border: OutlineInputBorder())),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () {
          if (textCtl.text.isEmpty) return;
          final id = 'p${DateTime.now().millisecondsSinceEpoch}';
          final topicId = context.read<AppState>().notes[topicIndex].id;
          context.read<AppState>().addParagraph(topicIndex, NoteParagraph(id: id, text: textCtl.text, topicId: topicId));
          Navigator.pop(ctx);
        }, child: const Text('Add')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTopicDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: appState.notes.length,
        itemBuilder: (context, index) {
          final topic = appState.notes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${topic.paragraphs.length} paragraphs'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => _addParagraphDialog(context, index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: () => context.read<AppState>().deleteNoteTopic(index),
                  ),
                ],
              ),
              children: [
                ...topic.paragraphs.asMap().entries.map((e) => ListTile(
                  dense: true,
                  title: Text(e.value.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, size: 16, color: Colors.red),
                    onPressed: () => context.read<AppState>().deleteParagraph(index, e.key),
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// DOCUMENTS PAGE (admin)
// ============================================================
class _AdminDocumentsPage extends StatelessWidget {
  void _addDocDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final nameCtl = TextEditingController();
    int lessonId = appState.activeLessonId;
    String selectedType = 'pdf';
    String? selectedFileName;
    Uint8List? selectedFileBytes;
    bool uploading = false;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Upload Document'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Document Title', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: lessonId,
              decoration: const InputDecoration(labelText: 'Lesson', border: OutlineInputBorder()),
              items: appState.lessons.map((l) => DropdownMenuItem(value: l.id, child: Text('Lesson ${l.id}: ${l.subjectName}'))).toList(),
              onChanged: (v) => setState(() => lessonId = v!),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: uploading ? null : () async {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
                );
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  setState(() {
                    selectedFileName = file.name;
                    selectedFileBytes = file.bytes;
                    final ext = file.extension?.toLowerCase() ?? '';
                    if (ext == 'pdf') { selectedType = 'pdf'; }
                    else if (['doc', 'docx'].contains(ext)) { selectedType = 'doc'; }
                    else if (['xls', 'xlsx'].contains(ext)) { selectedType = 'xls'; }
                    else if (['ppt', 'pptx'].contains(ext)) { selectedType = 'ppt'; }
                  });
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: selectedFileName != null ? Colors.green.shade300 : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: selectedFileName != null ? Colors.green.shade50 : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(selectedFileName != null ? Icons.check_circle : Icons.cloud_upload,
                         color: selectedFileName != null ? Colors.green : Colors.grey[400]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedFileName ?? 'Tap to select file',
                        style: TextStyle(color: selectedFileName != null ? Colors.green[700] : Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: uploading ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: uploading || nameCtl.text.isEmpty || selectedFileBytes == null
                ? null
                : () async {
                    setState(() => uploading = true);
                    final url = await appState.uploadDocumentFile(
                      selectedFileName!, selectedFileBytes!, lessonId,
                    );
                    if (ctx.mounted) {
                      if (url != null) {
                        appState.addDocument(AppDocument(
                          id: uuid(), lessonId: lessonId,
                          title: nameCtl.text, fileType: selectedType,
                          fileUrl: url,
                          uploadedBy: appState.currentUser?.fullName,
                        ));
                        Navigator.pop(ctx);
                      } else {
                        setState(() => uploading = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Upload failed. Check storage setup.')),
                        );
                      }
                    }
                  },
            child: uploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Upload'),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addDocDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: appState.documents.length,
        itemBuilder: (context, index) {
          final d = appState.documents[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('L${d.lessonId}')),
              title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text('${d.fileTypeLabel}  •  ${d.createdAt.day}/${d.createdAt.month}/${d.createdAt.year}', style: const TextStyle(fontSize: 12)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: () => appState.deleteDocument(d.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// HUB MODERATION PAGE
// ============================================================
class _HubPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...appState.announcements.asMap().entries.map((e) => Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: const Icon(Icons.campaign, color: Colors.blue),
            title: Text(e.value.content, style: const TextStyle(fontSize: 13)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => context.read<AppState>().deleteAnnouncement(e.key),
            ),
          ),
        )),
        const Divider(height: 32),
        const Text('Discussions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...appState.discussions.asMap().entries.map((e) => Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text(e.value.user[0], style: const TextStyle(fontSize: 12))),
            title: Text('${e.value.user}: ${e.value.text}', style: const TextStyle(fontSize: 13)),
            subtitle: Text('${e.value.timestamp.hour}:${e.value.timestamp.minute.toString().padLeft(2, '0')}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => context.read<AppState>().deleteDiscussion(e.key),
            ),
          ),
        )),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================
class _HeaderCard extends StatelessWidget {
  final String name;
  const _HeaderCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [Colors.indigo.shade700, Colors.indigo.shade400]),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 30, backgroundColor: Colors.white24, child: Icon(Icons.admin_panel_settings, size: 32, color: Colors.white)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Super Admin', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('Full system access', style: TextStyle(color: Colors.white60, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withAlpha(30), child: Icon(icon, color: color)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }
}
