import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../controllers/room_controller.dart';

class NotAttendanceView extends StatefulWidget {
  const NotAttendanceView({Key? key}) : super(key: key);

  @override
  State<NotAttendanceView> createState() => _NotAttendanceViewState();
}

class _NotAttendanceViewState extends State<NotAttendanceView> {
  final supabase = SupabaseService.instance;
  final RoomController roomCtrl = Get.find();

  int? selectedRoomId;

  Future<List<Map<String, dynamic>>> fetchNotAttendance(int? roomId) async {
    final today = DateTime.now();

    final result = await supabase.client
        .from('students')
        .select('id, name, class_id, room_id, classes(class_name), rooms(room_name)')
        .neq('id', 0)
        .order('id', ascending: true);

    // Ambil semua yang absen hari ini
    final attended = await supabase.client
        .from('attendance')
        .select('student_id')
        .gte('created_at', DateTime(today.year, today.month, today.day).toIso8601String());

    final attendedIds = (attended as List)
        .map((e) => e['student_id'] as int)
        .toSet();

    final allStudents = (result as List).cast<Map<String, dynamic>>();

    // Filter berdasarkan ruangan dan belum hadir
    final filtered = allStudents.where((s) {
      final roomMatch = roomId == null || s['room_id'] == roomId;
      return roomMatch && !attendedIds.contains(s['id']);
    }).toList();

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    selectedRoomId = roomCtrl.selectedRoomId.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Belum Hadir Hari Ini')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final rooms = roomCtrl.rooms;
              if (rooms.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              return DropdownButtonFormField<int>(
                value: selectedRoomId,
                decoration: InputDecoration(
                  labelText: 'Filter Ruangan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: rooms
                    .map(
                      (r) => DropdownMenuItem<int>(
                        value: r['id'] as int,
                        child: Text(r['room_name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedRoomId = v;
                  });
                },
              );
            }),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchNotAttendance(selectedRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan : ${snapshot.error}'),
                  );
                }

                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('Semua siswa sudah hadir ✅'));
                }

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Text('${index + 1}'),
                        title: Text(item['name'] ?? '-'),
                        subtitle: Text(
                          'Kelas: ${item['classes']['class_name'] ?? '-'}\nRuangan: ${item['rooms']['room_name'] ?? '-'}',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
