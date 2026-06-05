import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/lesson.dart';
import '../models/schedule.dart';
import '../models/note.dart';
import '../models/document.dart';
import '../models/quiz.dart';
import '../utils/uuid.dart';

class Announcement {
  final String id;
  final String content;
  const Announcement({required this.id, required this.content});
}

class AppState extends ChangeNotifier {
  AppUser? _currentUser;
  int _activeLessonId = 1;
  List<Lesson> _lessons = [];
  List<ScheduleEntry> _schedule = [];
  List<NoteTopic> _notes = [];
  final List<NoteHighlight> _highlights = [];
  List<Announcement> _announcements = [];
  List<ChatMessage> _discussions = [];
  final List<AppUser> _allUsers = [];
  List<AppDocument> _documents = [];
  final List<Quiz> _quizzes = [];
  final List<QuizAttempt> _quizAttempts = [];

  AppUser? get currentUser => _currentUser;
  int get activeLessonId => _activeLessonId;
  List<Lesson> get lessons => _lessons;
  List<ScheduleEntry> get schedule => _schedule;
  List<NoteTopic> get notes => _notes;
  List<NoteHighlight> get highlights => _highlights;
  List<AppUser> get allUsers => _allUsers;
  List<AppDocument> get documents => _documents;
  List<Quiz> get quizzes => _quizzes;
  List<QuizAttempt> get quizAttempts => _quizAttempts;
  List<Quiz> get activeQuizzes => _quizzes.where((q) => q.lessonId == _activeLessonId).toList();
  List<Announcement> get announcements => _announcements;
  List<ChatMessage> get discussions => _discussions;
  bool get isAdmin => _currentUser?.isSuperAdmin == true;
  bool get isPrefect => _currentUser?.isPrefect == true;
  bool get canManage => isAdmin || isPrefect;
  bool _dataLoaded = false;
  bool get dataLoaded => _dataLoaded;
  String? _error;
  String? get error => _error;

  Lesson? get activeLesson {
    try {
      return _lessons.firstWhere((l) => l.id == _activeLessonId);
    } catch (_) {
      return null;
    }
  }

  List<ScheduleEntry> get activeSchedule =>
      _schedule.where((s) => s.lessonId == _activeLessonId).toList();

  List<AppDocument> get activeDocuments =>
      _documents.where((d) => d.lessonId == _activeLessonId).toList();

  List<NoteTopic> get activeNotes {
    final match = _allLessonsNotes.entries.where((t) => t.key == _activeLessonId).toList();
    if (match.isNotEmpty) return match.first.value;
    return _notes;
  }

  final Map<int, List<NoteTopic>> _allLessonsNotes = {};

  Future<void> initSupabaseData() async {
    try {
      final supabase = Supabase.instance.client;
      final results = await Future.wait([
        supabase.from('lessons').select(),
        supabase.from('schedules').select(),
        supabase.from('note_topics').select(),
        supabase.from('note_paragraphs').select(),
        supabase.from('announcements').select().order('created_at', ascending: false),
        supabase.from('discussions').select().order('created_at', ascending: false),
        supabase.from('documents').select().order('created_at', ascending: false),
      ]);

      _lessons = (results[0] as List).map((json) => Lesson(
        id: json['id'] as int,
        subjectName: json['subject_name'] as String,
        instructor: json['instructor'] as String,
      )).toList();

      _schedule = (results[1] as List).map((json) => ScheduleEntry(
        id: json['id'] as String,
        lessonId: json['lesson_id'] as int,
        day: json['day'] as String,
        time: json['time'] as String,
        room: json['room'] as String,
        isShifted: json['is_shifted'] as bool? ?? false,
        shiftedTime: json['shifted_time'] as String?,
        shiftedRoom: json['shifted_room'] as String?,
        shiftedDate: json['shifted_date'] as String?,
      )).toList();

      final topicsJson = results[2] as List;
      final paragraphsJson = results[3] as List;

      final paragraphsByTopic = <String, List<NoteParagraph>>{};
      for (final p in paragraphsJson) {
        final topicId = p['topic_id'] as String;
        paragraphsByTopic.putIfAbsent(topicId, () => []);
        paragraphsByTopic[topicId]!.add(NoteParagraph(
          id: p['id'] as String,
          text: p['text'] as String,
          topicId: topicId,
          taughtDate: p['taught_date'] != null ? DateTime.tryParse(p['taught_date'] as String) : null,
        ));
      }

      final Map<int, List<NoteTopic>> byLesson = {};
      for (final t in topicsJson) {
        final topicId = t['id'] as String;
        final topic = NoteTopic(
          id: topicId,
          title: t['title'] as String,
          paragraphs: paragraphsByTopic[topicId] ?? [],
        );
        _notes.add(topic);
        final lessonId = t['lesson_id'] as int? ?? 1;
        byLesson.putIfAbsent(lessonId, () => []);
        byLesson[lessonId]!.add(topic);
      }
      _allLessonsNotes.addAll(byLesson);

      _announcements = (results[4] as List).map((j) => Announcement(
        id: j['id'] as String,
        content: j['content'] as String,
      )).toList();

      _discussions = (results[5] as List).map((j) => ChatMessage(
        id: j['id'] as String,
        user: j['user_name'] as String,
        text: j['text'] as String,
        timestamp: DateTime.parse(j['created_at'] as String),
      )).toList();

      _documents = (results[6] as List).map((j) => AppDocument(
        id: j['id'] as String,
        lessonId: j['lesson_id'] as int,
        title: j['title'] as String,
        fileType: j['file_type'] as String,
        fileUrl: j['file_url'] as String?,
        uploadedBy: j['uploaded_by'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      )).toList();

      _error = null;
    } catch (e) {
      _lessons = [];
      _schedule = [];
      _notes = [];
      _announcements = [];
      _discussions = [];
      _documents = [];
      _error = 'Failed to load data: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}';
    }
    _dataLoaded = true;
    notifyListeners();
  }

  void setLesson(int lessonId) {
    _activeLessonId = lessonId;
    notifyListeners();
  }

  void logIn(AppUser user) {
    _currentUser = user;
    _persistSession(user.username);
    notifyListeners();
  }

  Future<void> logOut() async {
    await Supabase.instance.client.auth.signOut();
    _currentUser = null;
    _activeLessonId = 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_username');
    await prefs.remove('tutorial_seen');
    notifyListeners();
  }

  Future<String?> restoreSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return session.user.email;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_username');
  }

  void autoLogin(String username) {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser != null) {
      final meta = authUser.userMetadata;
      if (meta != null) {
        _currentUser = AppUser(
          username: meta['username'] as String? ?? username,
          fullName: meta['full_name'] as String? ?? username,
          role: meta['role'] as String? ?? 'student',
          phone: meta['phone'] as String? ?? '',
          email: authUser.email ?? '',
          isFirstLogin: false,
          isSuperAdmin: meta['is_super_admin'] as bool? ?? false,
          isPrefect: meta['is_prefect'] as bool? ?? false,
          assignedLessons: (meta['assigned_lessons'] as List<dynamic>?)?.cast<int>() ?? [],
          profileImagePath: meta['profile_image_url'] as String?,
        );
        notifyListeners();
        return;
      }
    }
    final isSuperAdmin = username == 'EIT/500/S25/038';
    final isPrefectUser = username == 'PREFECT/001';
    _currentUser = AppUser(
      username: username,
      fullName: isSuperAdmin ? 'Sheldon Ramu' : (isPrefectUser ? 'Class Prefect' : (RegExp(r'^\d+$').hasMatch(username) ? 'Teacher User' : 'Student User')),
      role: isSuperAdmin || isPrefectUser ? 'student' : (RegExp(r'^\d+$').hasMatch(username) ? 'teacher' : 'student'),
      phone: isSuperAdmin ? '0112327446' : (isPrefectUser ? '0112000000' : ''),
      email: '',
      isFirstLogin: false,
      isSuperAdmin: isSuperAdmin,
      isPrefect: isPrefectUser,
      assignedLessons: RegExp(r'^\d+$').hasMatch(username) ? [] : [1, 2, 3, 4],
    );
    notifyListeners();
  }

  Future<void> _persistSession(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_username', username);
  }

  void completeFirstLogin(String newPassword) {
    if (_currentUser != null) {
      _currentUser!.isFirstLogin = false;
      notifyListeners();
    }
  }

  void assignTeacherLessons(List<int> lessonIds) {
    if (_currentUser != null && _currentUser!.role == 'teacher') {
      _currentUser!.assignedLessons = lessonIds;
      notifyListeners();
    }
  }

  // ---- User CRUD (admin) ----
  Future<String?> createUserViaRpc({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required String role,
    String phone = '',
    bool isPrefect = false,
  }) async {
    try {
      await Supabase.instance.client.rpc('create_auth_user', params: {
        'p_email': email,
        'p_password': password,
        'p_username': username,
        'p_full_name': fullName,
        'p_role': role,
        'p_phone': phone,
        'p_is_prefect': isPrefect,
        'p_is_super_admin': false,
      });
      return null;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Only super admin')) return 'Only super admin can create users.';
      if (msg.contains('duplicate key') && msg.contains('profiles_username_key')) return 'Username already exists.';
      if (msg.contains('duplicate key') && msg.contains('users_email_key')) return 'Email already exists.';
      return 'Failed to create user: ${msg.length > 60 ? msg.substring(0, 60) : msg}';
    }
  }

  void addUser(AppUser user) {
    _allUsers.add(user);
    notifyListeners();
  }

  void updateUser(int index, AppUser user) {
    if (index >= 0 && index < _allUsers.length) {
      _allUsers[index] = user;
      notifyListeners();
    }
  }

  void deleteUser(int index) {
    if (index >= 0 && index < _allUsers.length) {
      _allUsers.removeAt(index);
      notifyListeners();
    }
  }

  // ---- Lesson CRUD (admin) ----
  void addLesson(String subjectName, String instructor) {
    final nextId = _lessons.isEmpty ? 1 : _lessons.map((l) => l.id).reduce((a, b) => a > b ? a : b) + 1;
    _lessons.add(Lesson(id: nextId, subjectName: subjectName, instructor: instructor));
    notifyListeners();
    Supabase.instance.client.from('lessons').insert({
      'id': nextId, 'subject_name': subjectName, 'instructor': instructor,
    }).catchError((e) => debugPrint('sync lesson fail: $e'));
  }

  void updateLesson(int index, String subjectName, String instructor) {
    if (index >= 0 && index < _lessons.length) {
      final id = _lessons[index].id;
      _lessons[index] = Lesson(id: id, subjectName: subjectName, instructor: instructor);
      notifyListeners();
      Supabase.instance.client.from('lessons').update({
        'subject_name': subjectName, 'instructor': instructor,
      }).eq('id', id).catchError((e) => debugPrint('sync lesson update fail: $e'));
    }
  }

  Future<void> deleteLesson(int index) async {
    if (index >= 0 && index < _lessons.length) {
      final id = _lessons[index].id;
      _lessons.removeAt(index);
      notifyListeners();
      try {
        await Supabase.instance.client.from('lessons').delete().eq('id', id);
      } catch (e) {
        debugPrint('sync lesson delete fail: $e');
        initSupabaseData();
      }
    }
  }

  // ---- Schedule CRUD (admin) ----
  void addScheduleEntry(ScheduleEntry entry) {
    final id = uuid();
    final entryWithId = ScheduleEntry(
      id: id, lessonId: entry.lessonId, day: entry.day,
      time: entry.time, room: entry.room,
    );
    _schedule.add(entryWithId);
    notifyListeners();
    Supabase.instance.client.from('schedules').insert(entryWithId.toJson())
        .catchError((e) => debugPrint('sync schedule fail: $e'));
  }

  void deleteScheduleEntry(int index) {
    if (index >= 0 && index < _schedule.length) {
      final sid = _schedule[index].id;
      _schedule.removeAt(index);
      notifyListeners();
      if (sid != null) {
        Supabase.instance.client.from('schedules').delete().eq('id', sid)
            .catchError((e) => debugPrint('sync schedule delete fail: $e'));
      }
    }
  }

  void updateScheduleEntry(int lessonId, ScheduleEntry updated) {
    final idx = _schedule.indexWhere((s) => s.lessonId == lessonId);
    if (idx != -1) {
      _schedule[idx] = updated;
      notifyListeners();
      if (updated.id != null) {
        Supabase.instance.client.from('schedules').update(updated.toJson())
            .eq('id', updated.id!).catchError((e) => debugPrint('sync schedule update fail: $e'));
      }
    }
  }

  // ---- Notes CRUD (admin) ----
  void addNoteTopic(NoteTopic topic) {
    _notes.add(topic);
    notifyListeners();
    Supabase.instance.client.from('note_topics').insert({
      'id': topic.id, 'title': topic.title, 'lesson_id': _activeLessonId,
    }).catchError((e) => debugPrint('sync topic fail: $e'));
  }

  void deleteNoteTopic(int index) {
    if (index >= 0 && index < _notes.length) {
      final tid = _notes[index].id;
      _notes.removeAt(index);
      notifyListeners();
      Supabase.instance.client.from('note_topics').delete().eq('id', tid)
          .catchError((e) => debugPrint('sync topic delete fail: $e'));
    }
  }

  void addParagraph(int topicIndex, NoteParagraph para) {
    if (topicIndex >= 0 && topicIndex < _notes.length) {
      _notes[topicIndex].paragraphs.add(para);
      notifyListeners();
      Supabase.instance.client.from('note_paragraphs').insert({
        'id': para.id, 'topic_id': para.topicId, 'text': para.text,
      }).catchError((e) => debugPrint('sync para fail: $e'));
    }
  }

  void deleteParagraph(int topicIndex, int paraIndex) {
    if (topicIndex >= 0 && topicIndex < _notes.length) {
      if (paraIndex >= 0 && paraIndex < _notes[topicIndex].paragraphs.length) {
        final pid = _notes[topicIndex].paragraphs[paraIndex].id;
        _notes[topicIndex].paragraphs.removeAt(paraIndex);
        notifyListeners();
        Supabase.instance.client.from('note_paragraphs').delete().eq('id', pid)
            .catchError((e) => debugPrint('sync para delete fail: $e'));
      }
    }
  }

  // ---- Hub moderation ----
  void deleteAnnouncement(int index) {
    if (index >= 0 && index < _announcements.length) {
      final aid = _announcements[index].id;
      _announcements.removeAt(index);
      notifyListeners();
      Supabase.instance.client.from('announcements').delete().eq('id', aid)
          .catchError((e) => debugPrint('sync announcement delete fail: $e'));
    }
  }

  void deleteDiscussion(int index) {
    if (index >= 0 && index < _discussions.length) {
      final did = _discussions[index].id;
      _discussions.removeAt(index);
      notifyListeners();
      Supabase.instance.client.from('discussions').delete().eq('id', did!)
          .catchError((e) => debugPrint('sync discussion delete fail: $e'));
    }
  }

  void addAnnouncement(String text) {
    final id = uuid();
    _announcements.insert(0, Announcement(id: id, content: text));
    notifyListeners();
    Supabase.instance.client.from('announcements').insert({
      'id': id, 'content': text, 'created_by': _currentUser?.username,
    }).catchError((e) => debugPrint('sync announcement fail: $e'));
  }

  void addDiscussion(ChatMessage msg) {
    final id = uuid();
    final msgWithId = ChatMessage(
      id: id, user: msg.user, text: msg.text, timestamp: msg.timestamp,
    );
    _discussions.add(msgWithId);
    notifyListeners();
    Supabase.instance.client.from('discussions').insert({
      'id': id, 'user_name': msg.user, 'text': msg.text,
    }).catchError((e) => debugPrint('sync discussion fail: $e'));
  }

  void addHighlight(NoteHighlight highlight) {
    _highlights.add(highlight);
    notifyListeners();
  }

  void addStudentNote(String paragraphId, String studentId, String note) {
    for (final topic in _notes) {
      for (final para in topic.paragraphs) {
        if (para.id == paragraphId) {
          final notes = Map<String, String>.from(para.studentNotes);
          notes[studentId] = note;
          para.studentNotes = notes;
          notifyListeners();
          return;
        }
      }
    }
  }

  void markTaughtDate(String paragraphId, DateTime date) {
    for (final topic in _notes) {
      for (final para in topic.paragraphs) {
        if (para.id == paragraphId) {
          para.taughtDate = date;
          notifyListeners();
          return;
        }
      }
    }
  }

  void updateProfileImage(String path) {
    if (_currentUser != null) {
      _currentUser!.profileImagePath = path;
      notifyListeners();
    }
  }

  // ---- Document CRUD ----
  void addDocument(AppDocument doc) {
    _documents.add(doc);
    notifyListeners();
    Supabase.instance.client.from('documents').insert({
      'id': doc.id, 'lesson_id': doc.lessonId, 'title': doc.title,
      'file_type': doc.fileType, 'file_url': doc.fileUrl, 'uploaded_by': doc.uploadedBy,
    }).catchError((e) => debugPrint('sync document fail: $e'));
  }

  Future<String?> uploadDocumentFile(String fileName, Uint8List bytes, int lessonId) async {
    try {
      final storagePath = '$lessonId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await Supabase.instance.client.storage.from('documents').uploadBinary(
        storagePath, bytes,
        fileOptions: FileOptions(upsert: true),
      );
      return Supabase.instance.client.storage.from('documents').getPublicUrl(storagePath);
    } catch (e) {
      debugPrint('Upload fail: $e');
      return null;
    }
  }

  Future<void> _deleteStorageFile(String fileUrl) async {
    try {
      final uri = Uri.parse(fileUrl);
      final segs = uri.pathSegments;
      final bucketIdx = segs.indexOf('documents');
      if (bucketIdx != -1 && bucketIdx + 1 < segs.length) {
        final path = segs.sublist(bucketIdx + 1).join('/');
        await Supabase.instance.client.storage.from('documents').remove([path]);
      }
    } catch (e) {
      debugPrint('Storage delete fail: $e');
    }
  }

  void deleteDocument(String id) {
    String? fileUrl;
    final idx = _documents.indexWhere((d) => d.id == id);
    if (idx != -1) {
      fileUrl = _documents[idx].fileUrl;
      _documents.removeAt(idx);
    }
    notifyListeners();
    Supabase.instance.client.from('documents').delete().eq('id', id)
        .catchError((e) => debugPrint('sync document delete fail: $e'));
    if (fileUrl != null && fileUrl.isNotEmpty) {
      _deleteStorageFile(fileUrl);
    }
  }

  // ---- Quiz CRUD ----
  List<Quiz> quizzesForLesson(int lessonId) =>
      _quizzes.where((q) => q.lessonId == lessonId).toList();

  void addQuiz(Quiz quiz) {
    _quizzes.add(quiz);
    notifyListeners();
    Supabase.instance.client.from('quizzes').insert({
      'id': quiz.id, 'lesson_id': quiz.lessonId, 'title': quiz.title,
      'description': quiz.description, 'duration_minutes': quiz.durationMinutes,
      'due_date': quiz.dueDate?.toIso8601String(),
    }).catchError((e) => debugPrint('sync quiz fail: $e'));
  }

  void deleteQuiz(String id) {
    _quizzes.removeWhere((q) => q.id == id);
    notifyListeners();
    Supabase.instance.client.from('quizzes').delete().eq('id', id)
        .catchError((e) => debugPrint('sync quiz delete fail: $e'));
  }

  void addQuestionToQuiz(String quizId, QuizQuestion question) {
    final idx = _quizzes.indexWhere((q) => q.id == quizId);
    if (idx != -1) {
      _quizzes[idx].questions.add(question);
      notifyListeners();
      Supabase.instance.client.from('quiz_questions').insert({
        'id': question.id, 'quiz_id': question.quizId,
        'question_text': question.questionText,
        'option_a': question.optionA, 'option_b': question.optionB,
        'option_c': question.optionC, 'option_d': question.optionD,
        'correct_answer': question.correctAnswer, 'sort_order': question.sortOrder,
      }).catchError((e) => debugPrint('sync question fail: $e'));
    }
  }

  void removeQuestionFromQuiz(String quizId, int questionIndex) {
    final idx = _quizzes.indexWhere((q) => q.id == quizId);
    if (idx != -1 && questionIndex < _quizzes[idx].questions.length) {
      final qid = _quizzes[idx].questions[questionIndex].id;
      _quizzes[idx].questions.removeAt(questionIndex);
      notifyListeners();
      Supabase.instance.client.from('quiz_questions').delete().eq('id', qid)
          .catchError((e) => debugPrint('sync question delete fail: $e'));
    }
  }

  QuizAttempt? getAttemptForQuiz(String quizId) {
    try {
      return _quizAttempts.firstWhere((a) => a.quizId == quizId);
    } catch (_) {
      return null;
    }
  }

  void submitQuizAttempt(QuizAttempt attempt) {
    final idx = _quizAttempts.indexWhere((a) => a.quizId == attempt.quizId);
    if (idx != -1) {
      _quizAttempts[idx] = attempt;
    } else {
      _quizAttempts.add(attempt);
    }
    notifyListeners();
    Supabase.instance.client.from('quiz_attempts').upsert({
      'id': attempt.id, 'quiz_id': attempt.quizId,
      'student_id': attempt.studentId, 'score': attempt.score,
      'total_questions': attempt.totalQuestions, 'answers': attempt.answers,
      'started_at': attempt.startedAt.toIso8601String(),
      'submitted_at': attempt.submittedAt?.toIso8601String(),
    }).catchError((e) => debugPrint('sync attempt fail: $e'));
  }
}

class ChatMessage {
  final String? id;
  final String user;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    this.id,
    required this.user,
    required this.text,
    required this.timestamp,
  });
}
