import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/note.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  NoteTopic? _selectedTopic;
  final _noteControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _noteControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isTeacher = appState.currentUser?.role == 'teacher';

    if (_selectedTopic == null) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.notes.length,
        itemBuilder: (context, index) {
          final topic = appState.notes[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(topic.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => setState(() => _selectedTopic = topic),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTopic!.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedTopic = null),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _selectedTopic!.paragraphs.length,
        itemBuilder: (context, index) {
          final para = _selectedTopic!.paragraphs[index];
          final hasTaught = para.taughtDate != null;
          final studentNote = para.studentNotes[appState.currentUser?.username ?? ''];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: hasTaught ? Colors.green.shade50 : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasTaught)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Taught on ${para.taughtDate!.day}/${para.taughtDate!.month}/${para.taughtDate!.year}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  SelectableText(para.text, style: const TextStyle(fontSize: 15, height: 1.5)),
                  if (studentNote != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.yellow.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sticky_note_2, size: 16, color: Colors.brown),
                          const SizedBox(width: 8),
                          Expanded(child: Text(studentNote, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isTeacher)
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text('Mark Taught Date'),
                          onPressed: () => _markTaughtDate(context, appState, para),
                        ),
                      if (!isTeacher)
                        TextButton.icon(
                          icon: const Icon(Icons.note_add, size: 16),
                          label: const Text('Add Personal NB'),
                          onPressed: () => _addPersonalNote(context, appState, para),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _markTaughtDate(BuildContext context, AppState appState, NoteParagraph para) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      appState.markTaughtDate(para.id, date);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Marked as taught on ${date.day}/${date.month}/${date.year}')),
        );
      }
    }
  }

  void _addPersonalNote(BuildContext context, AppState appState, NoteParagraph para) {
    final username = appState.currentUser?.username ?? '';
    _noteControllers[para.id] ??= TextEditingController(text: para.studentNotes[username] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Personal Note'),
        content: TextField(
          controller: _noteControllers[para.id],
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Type your personal note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final note = _noteControllers[para.id]!.text.trim();
              if (note.isNotEmpty) {
                appState.addStudentNote(para.id, username, note);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
