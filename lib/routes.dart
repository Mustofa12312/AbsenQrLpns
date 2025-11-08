import 'package:get/get.dart';
import 'views/scan_view.dart';

class AppRoutes {
  static void toScanView() {
    Get.to(() => const ScanView());
  }
}
