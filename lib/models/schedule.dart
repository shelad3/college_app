class ScheduleEntry {
  final String? id;
  final int lessonId;
  final String day;
  final String time;
  final String room;
  bool isShifted;
  String? shiftedTime;
  String? shiftedRoom;
  String? shiftedDate;

  ScheduleEntry({
    this.id,
    required this.lessonId,
    required this.day,
    required this.time,
    required this.room,
    this.isShifted = false,
    this.shiftedTime,
    this.shiftedRoom,
    this.shiftedDate,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'lesson_id': lessonId,
    'day': day,
    'time': time,
    'room': room,
    'is_shifted': isShifted,
    if (shiftedTime != null) 'shifted_time': shiftedTime,
    if (shiftedRoom != null) 'shifted_room': shiftedRoom,
    if (shiftedDate != null) 'shifted_date': shiftedDate,
  };
}
