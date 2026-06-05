class NoteParagraph {
  final String id;
  final String text;
  final String topicId;
  DateTime? taughtDate;
  Map<String, String> studentNotes;

  NoteParagraph({
    required this.id,
    required this.text,
    required this.topicId,
    this.taughtDate,
    this.studentNotes = const {},
  });
}

class NoteTopic {
  final String id;
  final String title;
  final List<NoteParagraph> paragraphs;

  NoteTopic({
    required this.id,
    required this.title,
    required this.paragraphs,
  });
}

enum HighlightType { taught, personal }

class NoteHighlight {
  final String paragraphId;
  final HighlightType type;
  final String userId;
  final String? content;
  final DateTime? date;

  const NoteHighlight({
    required this.paragraphId,
    required this.type,
    required this.userId,
    this.content,
    this.date,
  });
}
