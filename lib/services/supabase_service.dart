import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  final SupabaseClient client = Supabase.instance.client;

  SupabaseService._internal();

  // Ambil semua ruangan
  Future<List<Map<String, dynamic>>> getRooms() async {
    final data = await client.from('rooms').select();
    return (data as List).cast<Map<String, dynamic>>();
  }

  // Ambil data siswa + kelas + ruangan dari view
  Future<Map<String, dynamic>?> getStudentById(int id) async {
    final result = await client
        .from('student_view')
        .select()
        .eq('id', id)
        .maybeSingle();

    return result;
  }

  // Insert absensi pakai function yang menolak absen ganda
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
