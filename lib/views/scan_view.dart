// lib/views/scan_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/scan_controller.dart';
import '../controllers/room_controller.dart';

class ScanView extends StatefulWidget {
  const ScanView({Key? key}) : super(key: key);

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> with WidgetsBindingObserver {
  final ScanController scanCtrl = Get.put(ScanController());
  final RoomController roomCtrl = Get.put(RoomController());

  late final MobileScannerController cameraController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    super.dispose();
  }

  // Handle lifecycle (Flutter 3.22+ sudah ada state 'hidden')
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!cameraController.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        cameraController.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden: // ✅ ditambahkan biar tidak error
        cameraController.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Ujian - Scan QR'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          // Ruangan dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              if (roomCtrl.rooms.isEmpty) {
                return const SizedBox(
                  height: 56,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return DropdownButtonFormField<int>(
                value: roomCtrl.selectedRoomId.value,
                decoration: InputDecoration(
                  labelText: 'Pilih Ruangan',
                  prefixIcon: const Icon(Icons.meeting_room_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: roomCtrl.rooms
                    .map(
                      (r) => DropdownMenuItem<int>(
                        value: r['id'] as int,
                        child: Text(r['room_name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) roomCtrl.selectRoom(v);
                },
              );
            }),
          ),

          const SizedBox(height: 8),

          // Scanner area
          Expanded(
            flex: 6,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // MobileScanner (tanpa allowDuplicates)
                Obx(() {
                  final processing = scanCtrl.isProcessing.value;
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: processing ? 0.6 : 1.0,
                    child: MobileScanner(
                      controller: cameraController,
                      fit: BoxFit.cover,
                      onDetect: (capture) {
                        final roomId = roomCtrl.selectedRoomId.value;
                        if (roomId == null) {
                          Get.snackbar(
                            'Peringatan',
                            'Silakan pilih ruangan terlebih dahulu',
                          );
                          return;
                        }
                        scanCtrl.handleCapture(capture, roomId);
                      },
                    ),
                  );
                }),

                // Focus box overlay
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.indigoAccent, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                // Tombol torch & flip kamera
                Positioned(
                  bottom: 24,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white70,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Torch'),
                        onPressed: () async {
                          final enabled = cameraController.torchEnabled;
                          await cameraController.toggleTorch();
                          Get.snackbar(
                            'Torch',
                            enabled ? 'Dimatikan' : 'Dinyalakan',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white70,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.cameraswitch),
                        label: const Text('Flip'),
                        onPressed: () async {
                          await cameraController.switchCamera();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status / hint
          Expanded(
            flex: 1,
            child: Obx(() {
              return Center(
                child: scanCtrl.isProcessing.value
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Memproses scan...'),
                        ],
                      )
                    : const Text('Arahkan kamera ke QR Code siswa'),
              );
            }),
          ),
        ],
      ),
    );
  }
}
