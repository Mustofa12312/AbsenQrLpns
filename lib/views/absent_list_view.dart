// lib/views/absent_list_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../controllers/room_controller.dart';

class AbsentListView extends StatefulWidget {
  const AbsentListView({Key? key}) : super(key: key);

  @override
  State<AbsentListView> createState() => _AbsentListViewState();
}

class _AbsentListViewState extends State<AbsentListView> {
  final supabase = SupabaseService.instance;
  final RoomController roomCtrl = Get.find();

  int? selectedRoomId;

  @override
  void initState() {
    super.initState();
    selectedRoomId = roomCtrl.selectedRoomId.value;
  }

  Future<List<Map<String, dynamic>>> fetchAbsent(int? roomId) async {
    final baseQuery = supabase.client.from('absent_today_by_room').select('*');

    dynamic resp;
    if (roomId != null) {
      resp = await baseQuery
          .eq('room_id', roomId)
          .order('student_id', ascending: true);
    } else {
      resp = await baseQuery.order('student_id', ascending: true);
    }

    return (resp as List).cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Tidak Hadir')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              final rooms = roomCtrl.rooms;
              if (rooms.isEmpty)
                return const SizedBox(
                  height: 56,
                  child: Center(child: CircularProgressIndicator()),
                );
              return DropdownButtonFormField<int>(
                value: selectedRoomId,
                decoration: InputDecoration(
                  labelText: 'Filter Ruangan',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: rooms.map((r) {
                  return DropdownMenuItem<int>(
                    value: r['id'] as int,
                    child: Text(r['room_name'] as String),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selectedRoomId = v),
              );
            }),
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchAbsent(selectedRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'),
                  );
                }

                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Semua siswa sudah hadir 🎉'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final no = index + 1;
                      final studentName =
                          item['student_name'] ?? item['name'] ?? '-';
                      final className = item['class_name'] ?? '-';
                      final roomName =
                          item['room_name'] ?? item['room_name'] ?? '-';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Text(
                              no.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(studentName),
                          subtitle: Text(
                            'Kelas: $className\nRuangan: $roomName',
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
