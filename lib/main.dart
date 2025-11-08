import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controllers/nav_provider.dart';
import 'controllers/room_controller.dart';
import 'providers/summary_provider.dart';
import 'services/supabase_service.dart';
import 'views/main_view.dart';
import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inisialisasi Supabase
  await Supabase.initialize(
    url: SupabaseService.supabaseUrl,
    anonKey: SupabaseService.supabaseAnonKey,
  );

  // ✅ Inisialisasi locale Indonesia
  await initializeDateFormatting('id_ID', null);

  // ✅ Register controller untuk GetX
  Get.put(RoomController());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SummaryProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil session saat ini
    final session = Supabase.instance.client.auth.currentSession;

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi Sekolah',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      // Jika belum login → LoginView, jika sudah login → MainView
      home: session == null ? const LoginView() : const MainView(),
    );
  }
}
