import 'package:get/get.dart';
import '../services/supabase_service.dart';

class RoomController extends GetxController {
  final supabase = SupabaseService.instance;

  /// Daftar semua ruangan dari Supabase
  var rooms = <Map<String, dynamic>>[].obs;

  /// Ruangan yang dipilih user (null artinya belum dipilih)
  var selectedRoomId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    loadRooms();
  }

  /// Ambil data ruangan dari server Supabase
  Future<void> loadRooms() async {
    try {
      final data = await supabase.getRooms();
      rooms.assignAll(data);
      // ⚠️ Jangan pilih default room otomatis, biarkan user memilih sendiri
      selectedRoomId.value = null;
    } catch (e) {
      print('❌ Error loading rooms: $e');
    }
  }

  /// Saat user memilih ruangan dari dropdown
  void selectRoom(int id) {
    selectedRoomId.value = id;
  }

  /// Cek apakah user sudah memilih ruangan
  bool get hasSelectedRoom => selectedRoomId.value != null;
}
