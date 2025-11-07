import 'package:get/get.dart';
import '../controllers/room_controller.dart';
import '../controllers/scan_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 🔹 RoomController dijadikan global dan permanent
    Get.put<RoomController>(RoomController(), permanent: true);

    // 🔹 ScanController hanya dibuat saat dibutuhkan (lazy)
    Get.lazyPut<ScanController>(() => ScanController());
  }
}
