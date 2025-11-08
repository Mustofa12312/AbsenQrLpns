import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../controllers/room_controller.dart';

class AttendanceListView extends StatefulWidget {
  const AttendanceListView({Key? key}) : super(key: key);

  @override
  State<AttendanceListView> createState() => _AttendanceListViewState();
}

class _AttendanceListViewState extends State<AttendanceListView> {
  final supabase = SupabaseService.instance;
  final roomCtrl = Get.find<RoomController>();

  int? selectedRoomId;

  Future<List<Map<String, dynamic>>> fetchAttendance(int? roomId) async {
    final query = supabase.client.from('attendance_today_by_room').select('*');

    final response = roomId != null
        ? await query
              .eq('room_id', roomId)
              .order('created_at', ascending: false)
        : await query.order('created_at', ascending: false);

    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  void initState() {
    super.initState();
    selectedRoomId = roomCtrl.selectedRoomId.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Hadir Hari Ini')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              final rooms = roomCtrl.rooms;
              if (rooms.isEmpty) return const CircularProgressIndicator();
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
                        value: r['id'],
                        child: Text(r['room_name']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedRoomId = v),
              );
            }),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchAttendance(selectedRoomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Belum ada yang absen hari ini.'),
                  );
                }

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final item = data[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Text(
                          '${i + 1}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        title: Text(item['student_name'] ?? '-'),
                        subtitle: Text(
                          'Kelas: ${item['class_name']} | Ruangan: ${item['room_name']}',
                        ),
                        trailing: Text(
                          (item['created_at'] ?? '').toString().substring(
                            11,
                            16,
                          ),
                          style: const TextStyle(color: Colors.grey),
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
