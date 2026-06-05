import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/schedule.dart';

class TimetableTab extends StatelessWidget {
  const TimetableTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final entries = appState.activeSchedule;
    final isTeacher = appState.currentUser?.role == 'teacher';
    final teachesThis = isTeacher && (appState.currentUser?.assignedLessons.contains(appState.activeLessonId) ?? false);

    return Scaffold(
      body: entries.isEmpty
          ? const Center(child: Text('No schedule for this lesson.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) => _ScheduleCard(entry: entries[index]),
            ),
      floatingActionButton: teachesThis
          ? FloatingActionButton(
              onPressed: () => _showShiftDialog(context, appState),
              child: const Icon(Icons.edit),
            )
          : null,
    );
  }

  void _showShiftDialog(BuildContext context, AppState appState) {
    final entry = appState.activeSchedule.isNotEmpty ? appState.activeSchedule.first : null;
    if (entry == null) return;

    final dateCtl = TextEditingController();
    final timeCtl = TextEditingController();
    final roomCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast Schedule Shift'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateCtl,
                decoration: const InputDecoration(labelText: 'New Date (e.g. June 10)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtl,
                decoration: const InputDecoration(labelText: 'New Time (e.g. 10:00 - 12:00)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomCtl,
                decoration: const InputDecoration(labelText: 'New Location', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              entry.isShifted = true;
              entry.shiftedDate = dateCtl.text.isNotEmpty ? dateCtl.text : null;
              entry.shiftedTime = timeCtl.text.isNotEmpty ? timeCtl.text : null;
              entry.shiftedRoom = roomCtl.text.isNotEmpty ? roomCtl.text : null;
              appState.updateScheduleEntry(appState.activeLessonId, entry);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Schedule shift broadcasted!')),
              );
            },
            child: const Text('Broadcast Shift'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleEntry entry;
  const _ScheduleCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: entry.isShifted ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.isShifted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LESSON SHIFTED',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${entry.day} — ${entry.time}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: entry.isShifted ? TextDecoration.lineThrough : null,
                    color: entry.isShifted ? Colors.grey : null,
                  ),
                ),
                if (entry.isShifted && entry.shiftedTime != null)
                  Text(
                    entry.shiftedTime!,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.room,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (entry.isShifted && entry.shiftedRoom != null)
              Text(
                '→ ${entry.shiftedRoom}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.deepOrange),
              ),
            if (entry.isShifted && entry.shiftedDate != null)
              Text(
                'New date: ${entry.shiftedDate}',
                style: const TextStyle(fontSize: 13, color: Colors.deepOrange),
              ),
          ],
        ),
      ),
    );
  }
}
