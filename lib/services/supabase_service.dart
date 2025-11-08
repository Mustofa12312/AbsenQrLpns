import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  // 🔹 Masukkan URL & anon key project kamu di sini
  static const String supabaseUrl = 'https://umwvjkgiabdhjdaafsvr.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtd3Zqa2dpYWJkaGpkYWFmc3ZyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY0MDQzNDAsImV4cCI6MjA3MTk4MDM0MH0.D7k18xqk_V4yT2n7PwYHpYJHaUkgTAwzVzVnF6IU3hY'; // ganti dengan anon key dari Supabase

  /// Inisialisasi Supabase sebelum aplikasi dijalankan
  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // 🔹 Ambil semua ruangan
  Future<List<Map<String, dynamic>>> getRooms() async {
    final data = await client.from('rooms').select();
    return (data as List).cast<Map<String, dynamic>>();
  }

  // 🔹 Ambil data siswa + kelas + ruangan dari view student_view
  Future<Map<String, dynamic>?> getStudentById(int id) async {
    final result = await client
        .from('student_view')
        .select()
        .eq('id', id)
        .maybeSingle();

    return result;
  }

  // 🔹 Insert absensi pakai function insert_attendance (menolak absen ganda)
  Future<String> insertAttendance({
    required int studentId,
    required int roomId,
  }) async {
    final res = await client.rpc(
      'insert_attendance',
      params: {'p_student_id': studentId, 'p_room_id': roomId},
    );

    // hasil function: "✅ Absensi berhasil disimpan" atau "❌ Siswa sudah absen hari ini"
    return res as String;
  }
}
