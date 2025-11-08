import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SummaryProvider with ChangeNotifier {
  final supabase = SupabaseService.instance;

  int hadir = 0;
  int tidakHadir = 0;
  int ruanganAktif = 0;
  DateTime? tanggal;

  bool isLoading = false;
  String? error;

  Future<void> fetchSummary() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final response = await supabase.client
          .from('attendance_summary_today')
          .select()
          .single();

      hadir = response['hadir'] ?? 0;
      tidakHadir = response['tidak_hadir'] ?? 0;
      ruanganAktif = response['ruangan_sudah_absen'] ?? 0;
      tanggal = DateTime.tryParse(response['tanggal'] ?? '');
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
