import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/room_controller.dart';
import 'scan_view.dart';

class RoomsSelectView extends StatelessWidget {
  RoomsSelectView({Key? key}) : super(key: key);

  final RoomController roomCtrl = Get.put(RoomController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Ruangan Ujian',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Obx(() {
        if (roomCtrl.rooms.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Silakan pilih ruangan untuk sesi ujian ini:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Daftar ruangan
              Expanded(
                child: ListView.separated(
                  itemCount: roomCtrl.rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final room = roomCtrl.rooms[index];
                    final roomName =
                        room['room_name'] as String? ?? 'Tanpa nama';
                    final selected =
                        roomCtrl.selectedRoomId.value == room['id'];

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.indigo.shade50
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Colors.indigo
                              : Colors.grey.shade300,
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? Colors.indigo
                              : Colors.grey.shade400,
                          child: Icon(
                            Icons.meeting_room_outlined,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          roomName,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? Colors.indigo
                                : Colors.grey.shade800,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.indigo,
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () {
                          roomCtrl.selectRoom(room['id'] as int);
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Tombol Lanjut Scan
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
                  'Lanjut ke Scan QR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  final roomId = roomCtrl.selectedRoomId.value;
                  if (roomId == null) {
                    Get.snackbar(
                      'Peringatan',
                      'Silakan pilih ruangan terlebih dahulu.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.orange.shade100,
                    );
                    return;
                  }
                  Get.to(() => const ScanView());
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
