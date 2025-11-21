// lib/views/scan_view.dart
import 'dart:ui';
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
  // controller dari GetX (sudah di-register)
  final ScanController scanCtrl = Get.find<ScanController>();
  final RoomController roomCtrl = Get.find<RoomController>();

  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isCameraReady = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureCameraPermissionAndStart();
  }

  /// Cek permission kamera → kalau belum granted, minta.
  /// Kalau sudah/granted → set ready & start kamera.
  Future<void> _ensureCameraPermissionAndStart() async {
    var status = await Permission.camera.status;

    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      if (!mounted) return;
      setState(() => _isCameraReady = true);
      _cameraController.start();
    } else {
      if (status.isPermanentlyDenied) {
        Get.snackbar(
          'Izin Kamera Ditolak',
          'Aktifkan izin kamera di Pengaturan > Aplikasi agar bisa melakukan scan.',
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          colorText: Colors.white,
        );
        await openAppSettings();
      } else {
        Get.snackbar(
          'Izin Kamera Diperlukan',
          'Tanpa izin kamera, scan QR tidak bisa digunakan.',
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  /// Start/stop kamera mengikuti lifecycle app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isCameraReady) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _cameraController.start();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _cameraController.stop();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Absensi Ujian QR',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black.withOpacity(0.25),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🌈 Background gradien
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF020617),
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // blob blur dekorasi
          Positioned(
            top: -60,
            right: -60,
            child: _blurBlob(
              width: 220,
              height: 220,
              color: const Color(0xFF38BDF8).withOpacity(0.45),
            ),
          ),
          Positioned(
            top: size.height * 0.28,
            left: -80,
            child: _blurBlob(
              width: 250,
              height: 250,
              color: const Color(0xFFA855F7).withOpacity(0.35),
            ),
          ),

          // Konten utama
          Container(
            padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
            child: !_isCameraReady
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // === DROPDOWN RUANGAN ===
                      Obx(() {
                        if (roomCtrl.rooms.isEmpty) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                height: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.22),
                                  ),
                                ),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: DropdownButtonFormField<int?>(
                                value: roomCtrl.selectedRoomId.value,
                                dropdownColor: Colors.black.withOpacity(0.9),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'Pilih Ruangan',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  border: InputBorder.none,
                                ),
                                iconEnabledColor: Colors.white70,
                                items: [
                                  const DropdownMenuItem<int?>(
                                    value: null,
                                    child: Text(
                                      'Pilih ruangan...',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  ...roomCtrl.rooms.map(
                                    (r) => DropdownMenuItem<int?>(
                                      value: r['id'] as int,
                                      child: Text(
                                        r['room_name'] as String,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    roomCtrl.selectedRoomId.value = v,
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 18),

                      Text(
                        'Arahkan kamera ke QR Code siswa.',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // === AREA SCAN ===
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(26),
                                color: Colors.black.withOpacity(0.35),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Kamera
                                  MobileScanner(
                                    controller: _cameraController,
                                    onDetect: (capture) {
                                      final roomId =
                                          roomCtrl.selectedRoomId.value;
                                      if (roomId == null) {
                                        Get.snackbar(
                                          'Pilih Ruangan Dulu',
                                          'Sebelum scan, pilih ruangan ujian terlebih dahulu.',
                                          backgroundColor: Colors.redAccent
                                              .withOpacity(0.8),
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

                                  // FRAME kotak scan
                                  Container(
                                    width: 260,
                                    height: 260,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.cyanAccent,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.cyanAccent.withOpacity(
                                            0.3,
                                          ),
                                          blurRadius: 22,
                                          spreadRadius: -4,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // STATUS PROCESSING
                                  Obx(() {
                                    if (scanCtrl.isProcessing.value) {
                                      return Positioned(
                                        bottom: 95,
                                        child: Column(
                                          children: [
                                            const CircularProgressIndicator(
                                              color: Colors.cyanAccent,
                                              strokeWidth: 2,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Memproses scan...',
                                              style: GoogleFonts.poppins(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),

                                  // TOMBOL TORCH & SWITCH
                                  Positioned(
                                    bottom: 18,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.22),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              _torchOn
                                                  ? Icons.flash_on_rounded
                                                  : Icons.flash_off_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed: () async {
                                              await _cameraController
                                                  .toggleTorch();
                                              setState(() {
                                                _torchOn = !_torchOn;
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cameraswitch_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed: () async {
                                              await _cameraController
                                                  .switchCamera();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Blob dekoratif blur untuk background
  Widget _blurBlob({
    required double width,
    required double height,
    required Color color,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withOpacity(0.05)]),
          ),
        ),
      ),
    );
  }
}
