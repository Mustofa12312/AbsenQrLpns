import 'package:get/get.dart';
import '../controllers/scan_controller.dart';

class ScanBinding extends Bindings {
  @override
  void dependencies() {
    // RoomController sudah diinisialisasi global lewat InitialBinding,
    // jadi tidak perlu dimasukkan lagi di sini.
    Get.lazyPut<ScanController>(() => ScanController());
  }
}
