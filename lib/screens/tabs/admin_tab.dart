import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class AdminTab extends StatelessWidget {
  const AdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(context, user?.fullName ?? 'Admin'),
        const SizedBox(height: 16),
        _buildStatCard('Total Lessons', '${appState.lessons.length}', Icons.book, Colors.indigo),
        const SizedBox(height: 12),
        _buildStatCard('Schedule Entries', '${appState.schedule.length}', Icons.calendar_month, Colors.teal),
        const SizedBox(height: 12),
        _buildStatCard('Note Topics', '${appState.notes.length}', Icons.menu_book, Colors.orange),
        const SizedBox(height: 12),
        _buildStatCard('Announcements', '${appState.announcements.length}', Icons.campaign, Colors.red),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        const Text('User Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildInfoTile(Icons.person, 'Username', user?.username ?? ''),
        _buildInfoTile(Icons.badge, 'Full Name', user?.fullName ?? ''),
        _buildInfoTile(Icons.email, 'Email', user?.email ?? ''),
        _buildInfoTile(Icons.phone, 'Phone', user?.phone ?? ''),
        _buildInfoTile(Icons.admin_panel_settings, 'Role', 'Super Admin'),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildActionButton(context, Icons.sync, 'Sync All Data', () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data sync initiated (mock)')),
          );
        }),
        const SizedBox(height: 8),
        _buildActionButton(context, Icons.refresh, 'Refresh Lessons', () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lessons refreshed (mock)')),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.indigo.shade700, Colors.indigo.shade400],
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white24,
              child: Icon(Icons.admin_panel_settings, size: 32, color: Colors.white),
            ),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
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

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
