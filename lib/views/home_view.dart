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
        backgroundColor: Colors.white.withOpacity(0.04),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.black.withOpacity(0.25)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Logout',
            onPressed: logout,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 🌈 Latar belakang gradien + glow blob
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF020617),
                  Color(0xFF071426),
                  Color(0xFF102A43),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _blurBlob(
              width: 240,
              height: 240,
              color: const Color(0xFF38BDF8).withOpacity(0.45),
            ),
          ),
          Positioned(
            top: 180,
            left: -80,
            child: _blurBlob(
              width: 260,
              height: 260,
              color: const Color(0xFFA855F7).withOpacity(0.35),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -40,
            child: _blurBlob(
              width: 220,
              height: 220,
              color: const Color(0xFF22C55E).withOpacity(0.3),
            ),
          ),

          // 🌫️ Konten utama + pull to refresh
          RefreshIndicator(
            onRefresh: () async => await summaryProvider.fetchSummary(),
            child: _fadeAnim != null
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
      padding: const EdgeInsets.fromLTRB(16, 110, 16, 24),
      children: [
        // Header hari + subtitle
        Text(
          'Hari Ini',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hari,
          style: GoogleFonts.poppins(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ringkasan absensi ujian hari ini.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 20),

        if (summaryProvider.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        if (summaryProvider.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: _buildErrorCard(summaryProvider.error!),
          ),

        if (!summaryProvider.isLoading && summaryProvider.error == null)
          Column(
            children: [
              _buildGlassCard(
                icon: Icons.check_circle_rounded,
                title: 'Hadir',
                value: '${summaryProvider.hadir} siswa',
                gradientColors: const [Color(0xFF22C55E), Color(0xFF4ADE80)],
              ),
              _buildGlassCard(
                icon: Icons.cancel_rounded,
                title: 'Tidak Hadir',
                value: '${summaryProvider.tidakHadir} siswa',
                gradientColors: const [Color(0xFFFB7185), Color(0xFFF97373)],
              ),
              _buildGlassCard(
                icon: Icons.meeting_room_rounded,
                title: 'Ruangan Sudah Absen',
                value: summaryProvider.ruanganAktif.toString(),
                gradientColors: const [Color(0xFF38BDF8), Color(0xFF60A5FA)],
              ),
            ],
          ),

        const SizedBox(height: 32),

        Text(
          'Data Ruangan',
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.white.withOpacity(0.94),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Placeholder info ruangan (logika tidak diubah)
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: Colors.white.withOpacity(0.08),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.16),
                    ),
                    child: const Icon(
                      Icons.view_list_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Dropdown Ruangan (coming soon...)',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Kartu error ringkas
  Widget _buildErrorCard(String error) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFEF4444).withOpacity(0.18),
            border: Border.all(
              color: Colors.redAccent.withOpacity(0.6),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Terjadi kesalahan: $error',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu glass untuk ringkasan (Hadir / Tidak Hadir / Ruangan)
  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required String value,
    required List<Color> gradientColors,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.06),
              border: Border.all(color: Colors.white.withOpacity(0.22)),
            ),
            child: Row(
              children: [
                // lingkaran gradient icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Blob dekoratif blur untuk background
  Widget _blurBlob({
    required double width,
    required double height,
    required Color color,
  }) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withOpacity(0.05)]),
          ),
        ),
      ),
    );
  }
}
