import 'package:get/get.dart';
import '../services/supabase_service.dart';

class RoomController extends GetxController {
  final supabase = SupabaseService.instance;

  var rooms = <Map<String, dynamic>>[].obs;
  var selectedRoomId = RxnInt();

  @override
  void onInit() {
    super.onInit();
    loadRooms();
  }

  Future<void> loadRooms() async {
    try {
      final data = await supabase.getRooms();
      rooms.assignAll(data);

      // pilih default room pertama
      if (rooms.isNotEmpty && selectedRoomId.value == null) {
        selectedRoomId.value = rooms.first['id'] as int;
      }
    } catch (e) {
      print('❌ Error loading rooms: $e');
    }
  }

  void selectRoom(int id) {
    selectedRoomId.value = id;
  }
}
