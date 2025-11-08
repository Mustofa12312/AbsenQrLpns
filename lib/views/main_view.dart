// lib/views/main_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/nav_provider.dart';
import 'home_view.dart';
import 'attendance_list_view.dart';
import 'absent_list_view.dart';
import 'scan_view.dart';

class MainView extends StatelessWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();

    // NOTE: pages tidak diberi `const` karena beberapa view mungkin non-const
    final pages = <Widget>[
      const HomeView(),
      const ScanView(),
      const AttendanceListView(),
      const AbsentListView(), // now defined below
    ];

    return Scaffold(
      body: IndexedStack(index: nav.index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.index,
        onDestinationSelected: (int idx) => nav.change(idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            selectedIcon: Icon(Icons.qr_code_2),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people),
            label: 'Hadir',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_off_outlined),
            selectedIcon: Icon(Icons.person_off),
            label: 'Tidak Hadir',
          ),
        ],
      ),
    );
  }
}
