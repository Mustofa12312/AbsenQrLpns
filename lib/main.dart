import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bindings/initial_binding.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'app_routes.dart';
import 'bindings/room_binding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://svosrxzprmyjsruomofm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN2b3NyeHpwcm15anNydW9tb2ZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzMDI1MDcsImV4cCI6MjA3Njg3ODUwN30.ylkvAzZ03D_gvOK_sbO9YH15GeX5HMl-xNIODx5su14',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialRoute = Supabase.instance.client.auth.currentUser == null
        ? '/login'
        : '/home';

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/login', page: () => const LoginView()),
        GetPage(name: '/home', page: () => HomeView(), binding: RoomBinding()),
        ...AppRoutes.pages, // scan & attendance
      ],
    );
  }
}
