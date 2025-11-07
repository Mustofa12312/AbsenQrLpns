import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../controllers/room_controller.dart';

class HomeView extends StatelessWidget {
  final RoomController rc = Get.find();
  final AuthService auth = AuthService();

  HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Ujian'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              Get.offAllNamed('/login'); // Kembali ke login
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Ruangan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final rooms = rc.rooms;
              if (rooms.isEmpty)
                return const Center(child: CircularProgressIndicator());
              return DropdownButtonFormField<int>(
                value: rc.selectedRoomId.value,
                items: rooms
                    .map(
                      (r) => DropdownMenuItem<int>(
                        value: r['id'] as int,
                        child: Text(r['room_name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) rc.selectRoom(v);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Mulai Scan'),
                onPressed: () {
                  if (rc.selectedRoomId.value == null) {
                    Get.snackbar(
                      'Pilih Ruangan',
                      'Silakan pilih ruangan terlebih dahulu',
                    );
                    return;
                  }
                  Get.toNamed('/scan');
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.people),
                label: const Text('Lihat Daftar Hadir'),
                onPressed: () {
                  if (rc.selectedRoomId.value == null) {
                    Get.snackbar(
                      'Pilih Ruangan',
                      'Silakan pilih ruangan terlebih dahulu',
                    );
                    return;
                  }
                  Get.toNamed('/attendance');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
