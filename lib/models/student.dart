class Student {
  final int id;
  final String name;
  final int? classId;

  Student({required this.id, required this.name, this.classId});

  factory Student.fromMap(Map<String, dynamic> m) {
    return Student(
      id: m['id'] as int,
      name: m['name'] as String,
      classId: m['class_id'] as int?,
    );
  }
}
