class Quiz {
  final String id;
  final int lessonId;
  final String title;
  final String? description;
  final int durationMinutes;
  final DateTime? dueDate;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.lessonId,
    required this.title,
    this.description,
    required this.durationMinutes,
    this.dueDate,
    this.questions = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class QuizQuestion {
  final String id;
  final String quizId;
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final int sortOrder;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    this.sortOrder = 0,
  });

  String optionAt(int index) {
    switch (index) {
      case 0: return optionA;
      case 1: return optionB;
      case 2: return optionC;
      case 3: return optionD;
      default: return '';
    }
  }

  String labelAt(int index) => String.fromCharCode(65 + index); // A, B, C, D
}

class QuizAttempt {
  final String id;
  final String quizId;
  final String studentId;
  final int score;
  final int totalQuestions;
  final Map<String, String> answers;
  final DateTime startedAt;
  final DateTime? submittedAt;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.score,
    required this.totalQuestions,
    required this.answers,
    required this.startedAt,
    this.submittedAt,
  });

  double get percentage => totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
}
