import 'package:get/get.dart';
import 'views/home_view.dart';
import 'views/scan_view.dart';
import 'views/attendance_list_view.dart';
import 'bindings/scan_binding.dart';
import 'bindings/room_binding.dart';

class Routes {
  static const home = '/';
  static const scan = '/scan';
  static const attendance = '/attendance';
}

class AppRoutes {
  static final pages = [
    // HomeView otomatis pakai RoomBinding
    GetPage(name: Routes.home, page: () => HomeView(), binding: RoomBinding()),

    // ScanView pakai ScanBinding
    GetPage(name: Routes.scan, page: () => ScanView(), binding: ScanBinding()),

    // AttendanceListView juga pakai RoomBinding
    GetPage(
      name: Routes.attendance,
      page: () => const AttendanceListView(),
      binding: RoomBinding(),
    ),
  ];
}
