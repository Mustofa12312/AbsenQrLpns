// lib/views/scan_view.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/scan_controller.dart';
import '../controllers/room_controller.dart';

class ScanView extends StatefulWidget {
  const ScanView({Key? key}) : super(key: key);

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final ScanController scanCtrl = Get.put(ScanController());
  final RoomController roomCtrl = Get.put(RoomController());

  late final MobileScannerController cameraController;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _scaleAnim = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutExpo));

    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

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
      case AppLifecycleState.hidden:
        cameraController.stop();
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              title: Text(
                'Absensi Ujian - Scan QR',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              backgroundColor: Colors.white.withOpacity(0.05),
              elevation: 0,
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: gradientBG),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              children: [
                const SizedBox(height: 100),

                // Dropdown Filter Ruangan (Glass style)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Obx(() {
                    if (roomCtrl.rooms.isEmpty) {
                      return const SizedBox(
                        height: 56,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.07),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.15),
                                blurRadius: 25,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonFormField<int>(
                            value: roomCtrl.selectedRoomId.value,
                            dropdownColor: Colors.black.withOpacity(0.6),
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Pilih Ruangan',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            iconEnabledColor: Colors.white70,
                            items: roomCtrl.rooms
                                .map(
                                  (r) => DropdownMenuItem<int>(
                                    value: r['id'] as int,
                                    child: Text(
                                      r['room_name'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) roomCtrl.selectRoom(v);
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                // Scanner area
                Expanded(
                  flex: 6,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Scanner camera
                      Obx(() {
                        final processing = scanCtrl.isProcessing.value;
                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: processing ? 0.5 : 1.0,
                          child: MobileScanner(
                            controller: cameraController,
                            fit: BoxFit.cover,
                            onDetect: (capture) {
                              final roomId = roomCtrl.selectedRoomId.value;
                              if (roomId == null) {
                                Get.snackbar(
                                  'Peringatan',
                                  'Silakan pilih ruangan terlebih dahulu',
                                  backgroundColor: Colors.redAccent.withOpacity(
                                    0.8,
                                  ),
                                  colorText: Colors.white,
                                );
                                return;
                              }
                              scanCtrl.handleCapture(capture, roomId);
                            },
                          ),
                        );
                      }),

                      // Focus box (Dynamic Island inspired)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
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
                              color: Colors.cyanAccent.withOpacity(0.25),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // Tombol Torch dan Flip
                      Positioned(
                        bottom: 24,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.2),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.flash_on,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final enabled =
                                          cameraController.torchEnabled;
                                      await cameraController.toggleTorch();
                                      Get.snackbar(
                                        'Torch',
                                        enabled ? 'Dimatikan' : 'Dinyalakan',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.black
                                            .withOpacity(0.6),
                                        colorText: Colors.white,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cameraswitch,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      await cameraController.switchCamera();
                                    },
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

                // Status text
                Expanded(
                  flex: 1,
                  child: Obx(() {
                    return Center(
                      child: scanCtrl.isProcessing.value
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                            )
                          : Text(
                              'Arahkan kamera ke QR Code siswa',
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
