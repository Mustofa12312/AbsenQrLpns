import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/supabase_service.dart';
import '../widgets/success_dialog.dart';
import '../services/scanner_service.dart';

class ScanController extends GetxController {
  final supabase = SupabaseService.instance;
  final scannerService = ScannerService();

  var isProcessing = false.obs;

  // Untuk mencegah scan berulang cepat
  final Map<int, DateTime> _recentScans = {};
  final duplicateThresholdSeconds = 3;

  /// Fungsi utama pemrosesan barcode
  Future<void> handleBarcode(String code, int selectedRoomId) async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      // --- Tahap 1: Parsing QR ---
      dynamic data;
      try {
        data = jsonDecode(code);
      } catch (_) {
        // Jika bukan JSON, anggap hanya berisi ID
        data = {'student_id': int.tryParse(code.trim())};
      }

      final int? studentId = data['student_id'];
      final int? qrRoomId = data['room_id']; // opsional di QR

      if (studentId == null) {
        Get.snackbar(
          'QR Tidak Valid',
          'Kode QR tidak mengandung ID siswa.',
          backgroundColor: Colors.redAccent.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      // --- Tahap 2: Cegah duplikasi lokal ---
      final now = DateTime.now();
      if (_recentScans.containsKey(studentId)) {
        final prev = _recentScans[studentId]!;
        if (now.difference(prev).inSeconds < duplicateThresholdSeconds) {
          isProcessing.value = false;
          return;
        }
      }
      _recentScans[studentId] = now;

      // --- Tahap 3: Validasi ruangan (jika ada di QR) ---
      if (qrRoomId != null && qrRoomId != selectedRoomId) {
        Get.snackbar(
          'Ruangan Tidak Sesuai',
          'QR ini untuk ruangan lain! Pilih ruangan yang benar sebelum scan.',
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // --- Tahap 4: Ambil data siswa dari database ---
      final student = await supabase.getStudentById(studentId);
      if (student == null) {
        Get.dialog(
          AlertDialog(
            title: const Text('Tidak ditemukan'),
            content: Text('Siswa dengan ID $studentId tidak ditemukan.'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('OK')),
            ],
          ),
        );
        return;
      }

      // --- Tahap 5: Simpan absensi ---
      final message = await supabase.insertAttendance(
        studentId: studentId,
        roomId: selectedRoomId,
      );

      final name = student['name'] ?? '-';
      final kelas = student['class_name'] ?? '-';
      final ruangan = student['room_name'] ?? '-';

      // --- Tahap 6: Tampilkan hasil ---
      if (message.contains('✅')) {
        Get.dialog(
          SuccessDialog(
            title: 'Absensi Tersimpan',
            subtitle: '$name\nKelas: $kelas\nRuangan: $ruangan',
          ),
        );
      } else {
        Get.dialog(
          AlertDialog(
            title: const Text('Sudah Absen'),
            content: Text('$name sudah absen hari ini.'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  /// Fungsi pemanggil dari MobileScanner
  Future<void> handleCapture(BarcodeCapture capture, int roomId) async {
    final code = scannerService.extractFromCapture(capture);
    if (code.isEmpty) return;
    await handleBarcode(code, roomId);
  }
}
