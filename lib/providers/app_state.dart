import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/lesson.dart';
import '../models/schedule.dart';
import '../models/note.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  int _activeLessonId = 1;
  List<Lesson> _lessons = [];
  List<ScheduleEntry> _schedule = [];
  List<NoteTopic> _notes = [];
  final List<NoteHighlight> _highlights = [];
  List<String> announcements = [];
  List<ChatMessage> discussions = [];
  List<User> _allUsers = [];
  int _nextLessonId = 5;

  User? get currentUser => _currentUser;
  int get activeLessonId => _activeLessonId;
  List<Lesson> get lessons => _lessons;
  List<ScheduleEntry> get schedule => _schedule;
  List<NoteTopic> get notes => _notes;
  List<NoteHighlight> get highlights => _highlights;
  List<User> get allUsers => _allUsers;
  bool get isAdmin => _currentUser?.isSuperAdmin == true;
  bool get isPrefect => _currentUser?.isPrefect == true;
  bool get canManage => isAdmin || isPrefect;

  Lesson? get activeLesson {
    try {
      return _lessons.firstWhere((l) => l.id == _activeLessonId);
    } catch (_) {
      return null;
    }
  }

  List<ScheduleEntry> get activeSchedule =>
      _schedule.where((s) => s.lessonId == _activeLessonId).toList();

  void initMockData() {
    _lessons = [
      const Lesson(id: 1, subjectName: 'Electrical Principles & Circuits', instructor: 'Instructor A'),
      const Lesson(id: 2, subjectName: 'Electronics & Telecommunications', instructor: 'Instructor B'),
      const Lesson(id: 3, subjectName: 'Computer Logic & Microprocessors', instructor: 'Instructor C'),
      const Lesson(id: 4, subjectName: 'Practical Systems & Labs', instructor: 'Instructor D'),
    ];

    _schedule = [
      ScheduleEntry(lessonId: 1, day: 'Monday', time: '08:00 - 10:00', room: 'Lab 101'),
      ScheduleEntry(lessonId: 1, day: 'Wednesday', time: '10:00 - 12:00', room: 'Room 203'),
      ScheduleEntry(lessonId: 2, day: 'Tuesday', time: '09:00 - 11:00', room: 'Lab 102'),
      ScheduleEntry(lessonId: 2, day: 'Thursday', time: '14:00 - 16:00', room: 'Room 205'),
      ScheduleEntry(lessonId: 3, day: 'Monday', time: '13:00 - 15:00', room: 'Lab 103'),
      ScheduleEntry(lessonId: 3, day: 'Wednesday', time: '08:00 - 10:00', room: 'Room 207'),
      ScheduleEntry(lessonId: 4, day: 'Friday', time: '08:00 - 12:00', room: 'Main Lab'),
      ScheduleEntry(lessonId: 4, day: 'Tuesday', time: '13:00 - 15:00', room: 'Room 209'),
    ];

    _notes = [
      NoteTopic(
        id: 't1',
        title: 'Topic 1: Practical Verification',
        paragraphs: [
          NoteParagraph(id: 'p1', text: 'Verification is the process of confirming that a system meets its specified requirements. In practical engineering, this involves systematic testing and measurement of circuit behavior against theoretical predictions.', topicId: 't1'),
          NoteParagraph(id: 'p2', text: 'The verification methodology includes both simulation-based approaches and physical measurements using oscilloscopes, multimeters, and signal analyzers.', topicId: 't1'),
          NoteParagraph(id: 'p3', text: 'Key verification metrics include signal integrity, power consumption, timing analysis, and thermal characteristics under normal and stress conditions.', topicId: 't1'),
        ],
      ),
      NoteTopic(
        id: 't2',
        title: 'Topic 2: System Architecture Code',
        paragraphs: [
          NoteParagraph(id: 'p4', text: 'System architecture defines the fundamental organization of a system, embodied in its components, their relationships to each other and to the environment, and the principles guiding its design and evolution.', topicId: 't2'),
          NoteParagraph(id: 'p5', text: 'Modern embedded systems architecture follows a layered approach: hardware abstraction layer, operating system layer, application framework, and user interface.', topicId: 't2'),
          NoteParagraph(id: 'p6', text: 'Code architecture patterns such as MVC, MVVM, and clean architecture help maintain separation of concerns and testability in complex systems.', topicId: 't2'),
        ],
      ),
    ];

    announcements = [
      'Welcome to the new semester!',
      'Lab safety briefing this Friday at 9:00 AM.',
    ];

    discussions = [
      ChatMessage(user: 'Student A', text: 'Has anyone completed the assignment?', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
      ChatMessage(user: 'Student B', text: 'Almost done, just the last section remaining.', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    ];

    _allUsers = [
      User(username: 'EIT/500/S25/038', fullName: 'Sheldon Ramu', role: 'student', phone: '0112327446', email: 'sheldonramu8@gmail.com', isSuperAdmin: true),
      User(username: '0712345678', fullName: 'Teacher User', role: 'teacher', phone: '0712345678', assignedLessons: [1, 2]),
    ];
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
    _lessons.add(Lesson(id: _nextLessonId++, subjectName: subjectName, instructor: instructor));
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
