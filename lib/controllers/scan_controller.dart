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

  // Mencegah scan ganda terlalu cepat
  final Map<int, DateTime> _recentScans = {};
  final duplicateThresholdSeconds = 3;

  // Fungsi utama ketika QR terdeteksi
  Future<void> handleBarcode(String code, int selectedRoomId) async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      if (code.trim().isEmpty) return;

      int? studentId;

      // 🧩 Coba parsing JSON atau angka murni
      try {
        final parsed = jsonDecode(code);
        if (parsed is Map && parsed['student_id'] != null) {
          studentId = int.tryParse(parsed['student_id'].toString());
        } else if (parsed is int) {
          studentId = parsed;
        } else {
          studentId = int.tryParse(code.trim());
        }
      } catch (_) {
        studentId = int.tryParse(code.trim());
      }

      if (studentId == null) {
        Get.snackbar(
          'QR Tidak Valid',
          'Kode QR tidak berisi ID siswa yang valid.',
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      // ⏳ Cegah duplikasi lokal (scan cepat berulang)
      final now = DateTime.now();
      if (_recentScans.containsKey(studentId)) {
        final prev = _recentScans[studentId]!;
        if (now.difference(prev).inSeconds < duplicateThresholdSeconds) {
          return;
        }
      }
      _recentScans[studentId] = now;

      // 🔍 Ambil data siswa dari Supabase
      final student = await supabase.getStudentById(studentId);
      if (student == null) {
        Get.snackbar(
          'Tidak Ditemukan',
          'Siswa dengan ID $studentId tidak ada di database.',
          backgroundColor: Colors.redAccent.withOpacity(0.9),
          colorText: Colors.white,
        );
        return;
      }

      final name = student['name'] ?? '-';
      final kelas = student['class_name'] ?? '-';
      final ruangan = student['room_name'] ?? '-';
      final studentRoomId = student['room_id'];

      // 🧠 Pastikan ruangan sesuai (konversi ke string untuk amannya)
      if (studentRoomId?.toString() != selectedRoomId.toString()) {
        Get.snackbar(
          'Ruangan Tidak Sesuai',
          'Siswa $name terdaftar di ruangan $ruangan.\n'
              'Silakan pindah ke ruangan yang benar.',
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // 📝 Jalankan fungsi insert attendance di Supabase
      final message = await supabase.insertAttendance(
        studentId: studentId,
        roomId: selectedRoomId,
      );

      // 💬 Tampilkan dialog hasil
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
    } catch (e, st) {
      debugPrint('❌ Error handleBarcode: $e\n$st');
      Get.snackbar(
        'Terjadi Kesalahan',
        e.toString(),
        backgroundColor: Colors.redAccent.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      isProcessing.value = false;
    }
  }

  // Dipanggil langsung dari MobileScanner widget
  Future<void> handleCapture(BarcodeCapture capture, int roomId) async {
    final code = scannerService.extractFromCapture(capture);
    if (code.isEmpty) return;
    await handleBarcode(code, roomId);
  }
}
