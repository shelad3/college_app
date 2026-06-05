import 'package:flutter/material.dart';

class TutorialOverlay extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const TutorialOverlay({super.key, this.onNavigateToTab});

  static const _tabs = [
    _TutorialItem(icon: Icons.calendar_month, label: 'Timetable', index: 0,
      desc: 'View your weekly class schedule. Each lesson has its own timetable cards showing day, time, and room location.\n\nIf a teacher shifts a class, you will see a bold "LESSON SHIFTED" banner with the new time highlighted.\n\nTeachers can tap the edit button to broadcast schedule changes.'),
    _TutorialItem(icon: Icons.forum, label: 'Hub', index: 1,
      desc: 'Two feeds in one tab:\n\n• Announcements — Official notices from teachers. Students can only read; teachers can post and attach files.\n\n• Discussions — Open chat room for everyone. Ask questions, share answers, and coordinate with classmates.'),
    _TutorialItem(icon: Icons.menu_book, label: 'Notes', index: 2,
      desc: 'Browse lesson notes organized by topic. Tap a topic to open the reading canvas.\n\nTeachers can highlight text and mark it with a "Taught on" date — visible to all students.\n\nStudents can highlight any paragraph and add personal sticky notes that only they can see.'),
    _TutorialItem(icon: Icons.quiz_outlined, label: 'Quizzes', index: 3,
      desc: 'Take lesson quizzes and track your scores. Each quiz has multiple-choice questions with a time limit.\n\nTeachers can create quizzes and add questions. After submission, you get instant results and can review your score.'),
    _TutorialItem(icon: Icons.folder, label: 'Documents', index: 4,
      desc: 'Upload and view lesson documents. Organize PDFs, Word docs, spreadsheets, and presentations by lesson.\n\nUse the filter to show documents for the active lesson. Tap a document to view details, download, or delete it.'),
    _TutorialItem(icon: Icons.person, label: 'Profile', index: 5,
      desc: 'View and edit your profile. Upload a profile picture, update your password, and see your account details.\n\nTeachers see a summary of which lessons they are assigned to instruct.'),
    _TutorialItem(icon: Icons.admin_panel_settings, label: 'Admin Panel', index: 6,
      desc: 'Super admin dashboard with 7 sub-tabs: Dashboard overview, User management, Lesson management, Schedule management, Notes management, Documents management, and Hub moderation.\n\nFull CRUD access to all app data.'),
    _TutorialItem(icon: Icons.shield, label: 'Prefect Panel', index: 7,
      desc: 'Class prefect panel with limited management tools. Overview stats, announcement posting, and discussion moderation.\n\nPrefects can view all data but only manage announcements and discussions.'),
  ];


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.explore, size: 32, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 12),
                  const Text('Welcome!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Here is a quick tour of the app',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _tabs[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).pop();
                          onNavigateToTab?.call(item.index);
                        },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(item.icon, color: Theme.of(context).colorScheme.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(item.desc, style: TextStyle(color: Colors.grey[600], fontSize: 12, height: 1.4)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it, let\'s go!'),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _TutorialItem {
  final IconData icon;
  final String label;
  final int index;
  final String desc;

  const _TutorialItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.desc,
  });
}
