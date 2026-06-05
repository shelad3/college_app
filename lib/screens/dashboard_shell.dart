import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_state.dart';
import 'tabs/timetable_tab.dart';
import 'tabs/hub_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/documents_tab.dart';
import 'tabs/admin_tab.dart';
import 'tabs/prefect_tab.dart';
import 'tutorial_overlay.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('tutorial_seen') ?? false;
    if (!seen && mounted) {
      _showTutorial();
    }
  }

  Future<void> _showTutorial() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TutorialOverlay(
        onNavigateToTab: (index) {
          setState(() => _currentTabIndex = index);
        },
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
  }

  List<Widget> _buildTabs(AppState appState) {
    final tabs = <Widget>[
      const TimetableTab(),
      const HubTab(),
      const NotesTab(),
      const DocumentsTab(),
      const ProfileTab(),
    ];
    if (appState.isAdmin) {
      tabs.add(const AdminTab());
    } else if (appState.isPrefect) {
      tabs.add(const PrefectTab());
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final lesson = appState.activeLesson;
    final isAdmin = appState.isAdmin;
    final isPrefect = appState.isPrefect;
    final title = isAdmin
        ? 'Admin Panel'
        : (isPrefect ? 'Prefect Panel'
            : (lesson != null ? 'Lesson ${lesson.id}: ${lesson.subjectName}' : 'Dashboard'));

    final tabs = _buildTabs(appState);
    if (_currentTabIndex >= tabs.length) {
      _currentTabIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.currentUser?.fullName ?? 'User',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${appState.currentUser?.role ?? ''}${isAdmin ? ' • SUPER ADMIN' : ''}${isPrefect ? ' • PREFECT' : ''}',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('LESSONS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            ...appState.lessons.map((lesson) => ListTile(
              leading: CircleAvatar(
                backgroundColor: appState.activeLessonId == lesson.id
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[200],
                child: Text(
                  '${lesson.id}',
                  style: TextStyle(
                    color: appState.activeLessonId == lesson.id ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(lesson.subjectName, style: const TextStyle(fontSize: 14)),
              subtitle: Text(lesson.instructor, style: const TextStyle(fontSize: 12)),
              selected: appState.activeLessonId == lesson.id,
              onTap: () {
                appState.setLesson(lesson.id);
                Navigator.of(context).pop();
              },
            )),
          ],
        ),
      ),
      body: tabs[_currentTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Timetable'),
          const BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'Hub'),
          const BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Notes'),
          const BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Documents'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          if (isAdmin)
            const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
          if (isPrefect)
            const BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Prefect'),
        ],
      ),
    );
  }
}
