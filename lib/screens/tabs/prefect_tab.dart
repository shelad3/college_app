import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class PrefectTab extends StatefulWidget {
  const PrefectTab({super.key});

  @override
  State<PrefectTab> createState() => _PrefectTabState();
}

class _PrefectTabState extends State<PrefectTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Column(
      children: [
        _buildHeader(context, appState),
        TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Announcements'),
            Tab(text: 'Discussions'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(),
              _PrefectAnnouncementsTab(),
              _PrefectDiscussionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, AppState appState) {
    final user = appState.currentUser;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade700, Colors.teal.shade400]),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Icon(Icons.shield, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Class Prefect Panel', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text(user?.fullName ?? 'Prefect', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Limited management access', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PrefectStatCard('Total Students', '${appState.allUsers.where((u) => u.role == 'student').length + 1}', Icons.people, Colors.blue),
        const SizedBox(height: 8),
        _PrefectStatCard('Total Lessons', '${appState.lessons.length}', Icons.book, Colors.indigo),
        const SizedBox(height: 8),
        _PrefectStatCard('Schedule Entries', '${appState.schedule.length}', Icons.calendar_month, Colors.teal),
        const SizedBox(height: 8),
        _PrefectStatCard('Announcements', '${appState.announcements.length}', Icons.campaign, Colors.orange),
        const SizedBox(height: 8),
        _PrefectStatCard('Discussions', '${appState.discussions.length}', Icons.chat, Colors.purple),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        const Text('Your Permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _PermissionTile(Icons.visibility, 'View all users and stats'),
        _PermissionTile(Icons.campaign, 'Post and manage announcements'),
        _PermissionTile(Icons.delete_sweep, 'Moderate discussions (delete messages)'),
        _PermissionTile(Icons.visibility, 'View lessons and schedules (read-only)'),
        _PermissionTile(Icons.visibility, 'View notes (read-only)'),
      ],
    );
  }
}

class _PrefectAnnouncementsTab extends StatefulWidget {
  @override
  State<_PrefectAnnouncementsTab> createState() => _PrefectAnnouncementsTabState();
}

class _PrefectAnnouncementsTabState extends State<_PrefectAnnouncementsTab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: appState.announcements.length,
            itemBuilder: (context, index) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: const Icon(Icons.campaign, color: Colors.blue),
                title: Text(appState.announcements[index], style: const TextStyle(fontSize: 13)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => appState.deleteAnnouncement(index),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Post an announcement...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (_controller.text.trim().isNotEmpty) {
                    appState.addAnnouncement(_controller.text.trim());
                    _controller.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrefectDiscussionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: appState.discussions.length,
      itemBuilder: (context, index) {
        final msg = appState.discussions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            leading: CircleAvatar(child: Text(msg.user[0], style: const TextStyle(fontSize: 12))),
            title: Text('${msg.user}: ${msg.text}', style: const TextStyle(fontSize: 13)),
            subtitle: Text('${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
              onPressed: () => appState.deleteDiscussion(index),
            ),
          ),
        );
      },
    );
  }
}

class _PrefectStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _PrefectStatCard(this.label, this.value, this.icon, this.color);

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

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PermissionTile(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
