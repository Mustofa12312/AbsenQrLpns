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
  final RoomController roomCtrl = Get.find();

  int? selectedRoomId;

  Future<List<Map<String, dynamic>>> fetchAttendance(int? roomId) async {
    final queryBase = supabase.client
        .from('attendance_today_by_room')
        .select('*');

    dynamic response;

    if (roomId != null) {
      response = await queryBase
          .eq('room_id', roomId)
          .order('created_at', ascending: false);
    } else {
      response = await queryBase.order('created_at', ascending: false);
    }

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
          // 🔽 Dropdown filter ruangan
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

          // 📋 Daftar siswa yang sudah absen
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchAttendance(selectedRoomId),
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
                  return const Center(
                    child: Text('Belum ada yang absen hari ini.'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final no = index + 1;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              no.toString(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            item['student_name'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Kelas: ${item['class_name'] ?? '-'}\nRuangan: ${item['room_name'] ?? '-'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Text(
                            (item['created_at'] ?? '').toString().substring(
                              11,
                              16,
                            ),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
