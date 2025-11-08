import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/room_controller.dart';
import '../providers/summary_provider.dart';
import '../views/login_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  late SummaryProvider summaryProvider;
  final rc = Get.find<RoomController>();

  AnimationController? _animController;
  Animation<double>? _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      summaryProvider.fetchSummary();
      _animController?.forward();
    });
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    Get.offAll(() => const LoginView());
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    summaryProvider = Provider.of<SummaryProvider>(context);
    final now = DateTime.now();
    final hari = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(now);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Dashboard Absensi',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.08),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🌈 Background ala iPhone
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027), // soft blue
                  Color(0xFF203A43), // muted indigo
                  Color(0xFF2C5364), // lavender blue
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🌫️ Konten utama
          RefreshIndicator(
            onRefresh: () async => await summaryProvider.fetchSummary(),
            child: (_fadeAnim != null)
                ? FadeTransition(
                    opacity: _fadeAnim!,
                    child: _buildContent(hari),
                  )
                : _buildContent(hari),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String hari) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
      children: [
        Text(
          'Hari Ini ($hari)',
          style: GoogleFonts.poppins(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        if (summaryProvider.isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        if (summaryProvider.error != null)
          Center(
            child: Text(
              'Terjadi kesalahan: ${summaryProvider.error}',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (!summaryProvider.isLoading && summaryProvider.error == null)
          Column(
            children: [
              _buildGlassCard(
                icon: Icons.check_circle,
                title: 'Hadir: ${summaryProvider.hadir} siswa',
                color: const Color(0xFF8EF6E4),
                iconColor: const Color(0xFF26E1A8),
              ),
              _buildGlassCard(
                icon: Icons.cancel_rounded,
                title: 'Tidak Hadir: ${summaryProvider.tidakHadir} siswa',
                color: const Color(0xFFFFB6B9),
                iconColor: const Color(0xFFFF6B6B),
              ),
              _buildGlassCard(
                icon: Icons.meeting_room,
                title: 'Ruangan Sudah Absen: ${summaryProvider.ruanganAktif}',
                color: const Color(0xFFB5EAEA),
                iconColor: const Color(0xFF6DD5FA),
              ),
            ],
          ),
        const SizedBox(height: 40),
        Text(
          'Data Ruangan:',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            'Dropdown Ruangan (coming soon...)',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ListTile(
            leading: Icon(icon, color: iconColor, size: 30),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
