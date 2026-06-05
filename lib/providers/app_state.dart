import 'package:flutter/foundation.dart';
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

  User? get currentUser => _currentUser;
  int get activeLessonId => _activeLessonId;
  List<Lesson> get lessons => _lessons;
  List<ScheduleEntry> get schedule => _schedule;
  List<NoteTopic> get notes => _notes;
  List<NoteHighlight> get highlights => _highlights;

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
  }

  void setLesson(int lessonId) {
    _activeLessonId = lessonId;
    notifyListeners();
  }

  void logIn(User user) {
    _currentUser = user;
    notifyListeners();
  }

  void logOut() {
    _currentUser = null;
    _activeLessonId = 1;
    notifyListeners();
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
