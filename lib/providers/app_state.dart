import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user.dart';
import '../models/lesson.dart';
import '../models/schedule.dart';
import '../models/note.dart';
import '../models/document.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  int _activeLessonId = 1;
  List<Lesson> _lessons = [];
  List<ScheduleEntry> _schedule = [];
  List<NoteTopic> _notes = [];
  final List<NoteHighlight> _highlights = [];
  List<String> announcements = [];
  List<ChatMessage> discussions = [];
  final List<User> _allUsers = [];
  List<AppDocument> _documents = [];

  User? get currentUser => _currentUser;
  int get activeLessonId => _activeLessonId;
  List<Lesson> get lessons => _lessons;
  List<ScheduleEntry> get schedule => _schedule;
  List<NoteTopic> get notes => _notes;
  List<NoteHighlight> get highlights => _highlights;
  List<User> get allUsers => _allUsers;
  List<AppDocument> get documents => _documents;
  bool get isAdmin => _currentUser?.isSuperAdmin == true;
  bool get isPrefect => _currentUser?.isPrefect == true;
  bool get canManage => isAdmin || isPrefect;
  bool _dataLoaded = false;
  bool get dataLoaded => _dataLoaded;

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
    if (match.isNotEmpty) {
      return match.first.value;
    }
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

      announcements = (results[4] as List).map((j) => j['content'] as String).toList();

      discussions = (results[5] as List).map((j) => ChatMessage(
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
    } catch (e) {
      _lessons = [];
      _schedule = [];
      _notes = [];
      announcements = [];
      discussions = [];
      _documents = [];
    }
    _dataLoaded = true;
    notifyListeners();
  }

  void setLesson(int lessonId) {
    _activeLessonId = lessonId;
    notifyListeners();
  }

  void logIn(User user) {
    _currentUser = user;
    _persistSession(user.username);
    notifyListeners();
  }

  Future<void> logOut() async {
    _currentUser = null;
    _activeLessonId = 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_username');
    await prefs.remove('tutorial_seen');
    notifyListeners();
  }

  Future<String?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('saved_username');
  }

  void autoLogin(String username) {
    final isSuperAdmin = username == 'EIT/500/S25/038';
    final isPrefectUser = username == 'PREFECT/001';
    _currentUser = User(
      username: username,
      fullName: isSuperAdmin ? 'Sheldon Ramu' : (isPrefectUser ? 'Class Prefect' : (RegExp(r'^\d+$').hasMatch(username) ? 'Teacher User' : 'Student User')),
      role: isSuperAdmin || isPrefectUser ? 'student' : (RegExp(r'^\d+$').hasMatch(username) ? 'teacher' : 'student'),
      phone: isSuperAdmin ? '0112327446' : (isPrefectUser ? '0112000000' : (RegExp(r'^\d+$').hasMatch(username) ? username : '0712345678')),
      email: isSuperAdmin ? 'sheldonramu8@gmail.com' : '',
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
  void addUser(User user) {
    _allUsers.add(user);
    notifyListeners();
  }

  void updateUser(int index, User user) {
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
  }

  void updateLesson(int index, String subjectName, String instructor) {
    if (index >= 0 && index < _lessons.length) {
      _lessons[index] = Lesson(id: _lessons[index].id, subjectName: subjectName, instructor: instructor);
      notifyListeners();
    }
  }

  void deleteLesson(int index) {
    if (index >= 0 && index < _lessons.length) {
      _lessons.removeAt(index);
      notifyListeners();
    }
  }

  // ---- Schedule CRUD (admin) ----
  void addScheduleEntry(ScheduleEntry entry) {
    _schedule.add(entry);
    notifyListeners();
  }

  void deleteScheduleEntry(int index) {
    if (index >= 0 && index < _schedule.length) {
      _schedule.removeAt(index);
      notifyListeners();
    }
  }

  // ---- Notes CRUD (admin) ----
  void addNoteTopic(NoteTopic topic) {
    _notes.add(topic);
    notifyListeners();
  }

  void deleteNoteTopic(int index) {
    if (index >= 0 && index < _notes.length) {
      _notes.removeAt(index);
      notifyListeners();
    }
  }

  void addParagraph(int topicIndex, NoteParagraph para) {
    if (topicIndex >= 0 && topicIndex < _notes.length) {
      _notes[topicIndex].paragraphs.add(para);
      notifyListeners();
    }
  }

  void deleteParagraph(int topicIndex, int paraIndex) {
    if (topicIndex >= 0 && topicIndex < _notes.length) {
      if (paraIndex >= 0 && paraIndex < _notes[topicIndex].paragraphs.length) {
        _notes[topicIndex].paragraphs.removeAt(paraIndex);
        notifyListeners();
      }
    }
  }

  // ---- Hub moderation ----
  void deleteAnnouncement(int index) {
    if (index >= 0 && index < announcements.length) {
      announcements.removeAt(index);
      notifyListeners();
    }
  }

  void deleteDiscussion(int index) {
    if (index >= 0 && index < discussions.length) {
      discussions.removeAt(index);
      notifyListeners();
    }
  }

  void updateScheduleEntry(int lessonId, ScheduleEntry updated) {
    final idx = _schedule.indexWhere((s) => s.lessonId == lessonId);
    if (idx != -1) {
      _schedule[idx] = updated;
      notifyListeners();
    }
  }

  void addAnnouncement(String text) {
    announcements.insert(0, text);
    notifyListeners();
  }

  void addDiscussion(ChatMessage msg) {
    discussions.add(msg);
    notifyListeners();
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
  }

  void deleteDocument(String id) {
    _documents.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}

class ChatMessage {
  final String user;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.user,
    required this.text,
    required this.timestamp,
  });
}
