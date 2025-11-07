class Room {
  final int id;
  final String roomName;

  Room({required this.id, required this.roomName});

  factory Room.fromMap(Map<String, dynamic> m) {
    return Room(id: m['id'] as int, roomName: (m['room_name'] as String));
  }
}
