class ScheduleEntry {
  final int lessonId;
  final String day;
  final String time;
  final String room;
  bool isShifted;
  String? shiftedTime;
  String? shiftedRoom;
  String? shiftedDate;

  ScheduleEntry({
    required this.lessonId,
    required this.day,
    required this.time,
    required this.room,
    this.isShifted = false,
    this.shiftedTime,
    this.shiftedRoom,
    this.shiftedDate,
  });
}
