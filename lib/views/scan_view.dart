import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../controllers/scan_controller.dart';
import '../controllers/room_controller.dart';

class ScanView extends StatefulWidget {
  const ScanView({Key? key}) : super(key: key);

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> with WidgetsBindingObserver {
  final ScanController scanCtrl = Get.put(ScanController());
  final RoomController roomCtrl = Get.find<RoomController>();

  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal, // lebih stabil
    facing: CameraFacing.back,
  );

  bool _isCameraReady = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _isCameraReady = true);
    } else {
      Get.snackbar(
        'Izin Kamera Diperlukan',
        'Aktifkan izin kamera di pengaturan aplikasi agar bisa melakukan scan.',
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _cameraController.start();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _cameraController.stop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    const gradientBG = LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Absensi Ujian - Scan QR',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.2),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: gradientBG),
        child: !_isCameraReady
            ? const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              )
            : Column(
                children: [
                  const SizedBox(height: 100),

                  /// === DROPDOWN RUANGAN ===
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      if (roomCtrl.rooms.isEmpty) {
                        return const SizedBox(
                          height: 56,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonFormField<int>(
                          value: roomCtrl.selectedRoomId.value,
                          dropdownColor: Colors.black.withOpacity(0.8),
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Pilih Ruangan',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          iconEnabledColor: Colors.white70,
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text(
                                'Pilih ruangan...',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                            ...roomCtrl.rooms.map(
                              (r) => DropdownMenuItem<int>(
                                value: r['id'] as int,
                                child: Text(
                                  r['room_name'] as String,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) => roomCtrl.selectedRoomId.value = v,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  /// === AREA SCAN ===
                  Expanded(
                    flex: 6,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        MobileScanner(
                          controller: _cameraController,
                          onDetect: (capture) {
                            final roomId = roomCtrl.selectedRoomId.value;
                            if (roomId == null) {
                              Get.snackbar(
                                'Pilih Ruangan Dulu',
                                'Sebelum scan, pilih ruangan ujian terlebih dahulu.',
                                backgroundColor: Colors.redAccent.withOpacity(
                                  0.8,
                                ),
                                colorText: Colors.white,
                              );
                              return;
                            }
                            // Hanya proses 1 scan pada satu waktu
                            if (!scanCtrl.isProcessing.value) {
                              scanCtrl.handleCapture(capture, roomId);
                            }
                          },
                        ),

                        /// FRAME
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.cyanAccent,
                              width: 3,
                            ),
                          ),
                        ),

                        /// TOMBOL TORCH DAN SWITCH
                        Positioned(
                          bottom: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _torchOn ? Icons.flash_on : Icons.flash_off,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await _cameraController.toggleTorch();
                                    setState(() {
                                      _torchOn = !_torchOn;
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cameraswitch,
                                    color: Colors.white,
                                  ),
                                  onPressed: () async {
                                    await _cameraController.switchCamera();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        /// STATUS PROCESSING
                        Obx(() {
                          if (scanCtrl.isProcessing.value) {
                            return Positioned(
                              bottom: 100,
                              child: Column(
                                children: [
                                  const CircularProgressIndicator(
                                    color: Colors.cyanAccent,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Memproses scan...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// INFO BAWAH
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Arahkan kamera ke QR Code siswa',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
