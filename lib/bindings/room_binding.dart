import 'package:get/get.dart';
import '../controllers/room_controller.dart';

class RoomBinding extends Bindings {
  @override
  void dependencies() {
    // Memastikan RoomController tersedia dan permanen
    if (!Get.isRegistered<RoomController>()) {
      Get.put(RoomController(), permanent: true);
    }
  }
}
