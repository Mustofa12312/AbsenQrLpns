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

  // Cegah scan berulang cepat (3 detik)
  final Map<int, DateTime> _recentScans = {};
  final duplicateThresholdSeconds = 3;

  Future<void> handleBarcode(String code, int roomId) async {
    if (isProcessing.value) return;
    isProcessing.value = true;

    try {
      final id = int.tryParse(code.trim());
      if (id == null) {
        Get.snackbar('Scan gagal', 'Kode QR tidak valid');
        return;
      }

      // Cegah duplikasi lokal
      final now = DateTime.now();
      if (_recentScans.containsKey(id)) {
        final prev = _recentScans[id]!;
        if (now.difference(prev).inSeconds < duplicateThresholdSeconds) {
          return;
        }
      }
      _recentScans[id] = now;

      // Cek apakah siswa ada di database
      final student = await supabase.getStudentById(id);
      if (student == null) {
        Get.dialog(
          AlertDialog(
            title: const Text('Tidak ditemukan'),
            content: Text('Siswa dengan ID $id tidak ditemukan.'),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('OK')),
            ],
          ),
        );
        return;
      }

      // Insert absensi pakai Supabase Function
      final message = await supabase.insertAttendance(
        studentId: id,
        roomId: roomId,
      );

      final name = student['name'] ?? '-';
      final kelas = student['class_name'] ?? '-';
      final ruangan = student['room_name'] ?? '-';

      // Tampilkan dialog hasil
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
      Get.snackbar('Error', e.toString());
    } finally {
      isProcessing.value = false;
    }
  }

  // Dipanggil dari MobileScanner
  Future<void> handleCapture(BarcodeCapture capture, int roomId) async {
    final code = scannerService.extractFromCapture(capture);
    if (code.isEmpty) return;
    await handleBarcode(code, roomId);
  }
}
