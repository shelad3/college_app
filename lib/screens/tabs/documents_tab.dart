import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_state.dart';
import '../../models/document.dart';

class DocumentsTab extends StatelessWidget {
  const DocumentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeLessonId = appState.activeLessonId;
    final activeLesson = appState.activeLesson;
    final filtered = appState.documents.where((d) => d.lessonId == activeLessonId).toList();

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.filter_alt, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  'Showing documents for: ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Expanded(
                  child: Text(
                    activeLesson?.subjectName ?? 'Lesson $activeLessonId',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No documents for this lesson', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Tap + to upload', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return _DocumentCard(doc: doc);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _uploadDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _uploadDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final nameCtl = TextEditingController();
    String selectedType = 'pdf';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Upload Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Document Title',
                  hintText: 'e.g. Chapter 5 Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'File Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'pdf', child: Text('PDF Document')),
                  DropdownMenuItem(value: 'doc', child: Text('Word Document')),
                  DropdownMenuItem(value: 'xls', child: Text('Excel Spreadsheet')),
                  DropdownMenuItem(value: 'ppt', child: Text('PowerPoint')),
                ],
                onChanged: (v) => setState(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text('Tap to select file', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtl.text.isEmpty) return;
                appState.addDocument(AppDocument(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  lessonId: appState.activeLessonId,
                  title: nameCtl.text,
                  fileType: selectedType,
                ));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document added')),
                );
              },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final AppDocument doc;
  const _DocumentCard({required this.doc});

  IconData _fileIcon() {
    switch (doc.fileType.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'xls': case 'xlsx': return Icons.table_chart;
      case 'ppt': case 'pptx': return Icons.slideshow;
      default: return Icons.insert_drive_file;
    }
  }

  Color _fileColor() {
    switch (doc.fileType.toLowerCase()) {
      case 'pdf': return Colors.red;
      case 'doc': case 'docx': return Colors.blue;
      case 'xls': case 'xlsx': return Colors.green;
      case 'ppt': case 'pptx': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _fileColor().withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_fileIcon(), color: _fileColor(), size: 28),
        ),
        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _fileColor().withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(doc.fileTypeLabel, style: TextStyle(fontSize: 10, color: _fileColor(), fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text(
              'Lesson ${doc.lessonId}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const Spacer(),
            Text(
              '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
        onTap: () => _openViewer(context, doc),
        trailing: PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'view', child: Text('View')),
            if (doc.fileUrl != null)
              const PopupMenuItem(value: 'download', child: Text('Download')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (action) {
            switch (action) {
              case 'view':
                _openViewer(context, doc);
              case 'download':
                if (doc.fileUrl != null) _downloadFile(context, doc.fileUrl!);
              case 'delete':
                context.read<AppState>().deleteDocument(doc.id);
            }
          },
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, AppDocument doc) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DocumentViewerScreen(doc: doc),
    ));
  }

  Future<void> _downloadFile(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file')),
        );
      }
    }
  }
}

class DocumentViewerScreen extends StatelessWidget {
  final AppDocument doc;
  const DocumentViewerScreen({super.key, required this.doc});

  IconData _fileIcon() {
    switch (doc.fileType.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'xls': case 'xlsx': return Icons.table_chart;
      case 'ppt': case 'pptx': return Icons.slideshow;
      default: return Icons.insert_drive_file;
    }
  }

  Color _fileColor() {
    switch (doc.fileType.toLowerCase()) {
      case 'pdf': return Colors.red;
      case 'doc': case 'docx': return Colors.blue;
      case 'xls': case 'xlsx': return Colors.green;
      case 'ppt': case 'pptx': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _fileColor().withAlpha(15),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Icon(_fileIcon(), size: 64, color: _fileColor()),
                const SizedBox(height: 12),
                Text(doc.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _fileColor().withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(doc.fileTypeLabel, style: TextStyle(color: _fileColor(), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _infoRow(Icons.bookmark, 'File Type', doc.fileTypeLabel),
                const SizedBox(height: 8),
                _infoRow(Icons.calendar_today, 'Uploaded', '${doc.createdAt.day}/${doc.createdAt.month}/${doc.createdAt.year}'),
                const SizedBox(height: 8),
                _infoRow(Icons.person_outline, 'Uploaded by', doc.uploadedBy ?? 'Unknown'),
                const SizedBox(height: 24),
                if (doc.fileUrl != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.tryParse(doc.fileUrl!);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open file')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open File'),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'File not available for preview',
                          style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Document has been recorded but no file was uploaded.\nUse the upload dialog to attach a real file.',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
      ],
    );
  }
}
