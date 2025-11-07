class Attendance {
  final int id;
  final int studentId;
  final int? roomId;
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.studentId,
    this.roomId,
    required this.createdAt,
  });

  factory Attendance.fromMap(Map<String, dynamic> m) {
    return Attendance(
      id: m['id'] as int,
      studentId: m['student_id'] as int,
      roomId: m['room_id'] as int?,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}
