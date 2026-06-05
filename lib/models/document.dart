class AppDocument {
  final String id;
  final int lessonId;
  final String title;
  final String fileType;
  final String? fileUrl;
  final String? uploadedBy;
  final DateTime createdAt;

  AppDocument({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.fileType,
    this.fileUrl,
    this.uploadedBy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fileTypeLabel {
    switch (fileType.toLowerCase()) {
      case 'pdf': return 'PDF';
      case 'doc': case 'docx': return 'Word';
      case 'xls': case 'xlsx': return 'Excel';
      case 'ppt': case 'pptx': return 'PowerPoint';
      default: return fileType.toUpperCase();
    }
  }
}
