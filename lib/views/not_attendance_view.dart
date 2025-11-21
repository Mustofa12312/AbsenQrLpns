// lib/views/not_attendance_view.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/supabase_service.dart';
import '../controllers/room_controller.dart';

class NotAttendanceView extends StatefulWidget {
  const NotAttendanceView({Key? key}) : super(key: key);

  @override
  State<NotAttendanceView> createState() => _NotAttendanceViewState();
}

class _NotAttendanceViewState extends State<NotAttendanceView>
    with SingleTickerProviderStateMixin {
  final supabase = SupabaseService.instance;
  final RoomController roomCtrl = Get.find<RoomController>();

  int? selectedRoomId;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    // pakai ruangan yang sedang dipilih di controller (kalau ada)
    selectedRoomId = roomCtrl.selectedRoomId.value;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchNotAttendance(int? roomId) async {
    final today = DateTime.now();

    // ambil semua siswa + relasi kelas & ruangan
    final result = await supabase.client
        .from('students')
        .select(
          'id, name, class_id, room_id, classes(class_name), rooms(room_name)',
        )
        .neq('id', 0)
        .order('id', ascending: true);

    // ambil semua yang SUDAH absen hari ini
    final attended = await supabase.client
        .from('attendance')
        .select('student_id')
        .gte(
          'created_at',
          DateTime(today.year, today.month, today.day).toIso8601String(),
        );

    final attendedIds = (attended as List)
        .map((e) => e['student_id'] as int)
        .toSet();

    final allStudents = (result as List).cast<Map<String, dynamic>>();

    // Filter: ruangan (kalau dipilih) + siswa yang belum hadir
    final filtered = allStudents.where((s) {
      final roomMatch = roomId == null || s['room_id'] == roomId;
      final notAttended = !attendedIds.contains(s['id']);
      return roomMatch && notAttended;
    }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    const backgroundGradient = LinearGradient(
      colors: [Color(0xFF020617), Color(0xFF020617), Color(0xFF0F172A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: AppBar(
              backgroundColor: Colors.black.withOpacity(0.3),
              elevation: 0,
              centerTitle: true,
              title: Text(
                'Belum Hadir Hari Ini',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // 🌈 gradient + glow blobs ala iOS
          Container(
            decoration: const BoxDecoration(gradient: backgroundGradient),
          ),
          Positioned(
            top: -70,
            right: -60,
            child: _blurBlob(
              width: 230,
              height: 230,
              color: const Color(0xFFFB7185).withOpacity(0.55),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -50,
            child: _blurBlob(
              width: 250,
              height: 250,
              color: const Color(0xFFA855F7).withOpacity(0.45),
            ),
          ),

          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 96),

                // HEADER KECIL
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent.withOpacity(0.18),
                        ),
                        child: const Icon(
                          Icons.person_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Daftar siswa yang belum melakukan absensi hari ini.',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // FILTER RUANGAN (glass)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(() {
                    final rooms = roomCtrl.rooms;
                    if (rooms.isEmpty) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                              ),
                            ),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonFormField<int?>(
                            value: selectedRoomId,
                            decoration: const InputDecoration(
                              labelText: 'Filter Ruangan',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            dropdownColor: Colors.black.withOpacity(0.9),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            iconEnabledColor: Colors.white70,
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  'Semua ruangan',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                              ...rooms.map(
                                (r) => DropdownMenuItem<int?>(
                                  value: r['id'] as int,
                                  child: Text(r['room_name'] as String),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() {
                                selectedRoomId = v;
                              });
                            },
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 10),

                // LIST SISWA BELUM HADIR
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: fetchNotAttendance(selectedRoomId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Terjadi kesalahan: ${snapshot.error}',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        );
                      }

                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return Center(
                          child: Text(
                            'Semua siswa sudah hadir ✅',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        color: Colors.cyanAccent,
                        onRefresh: () async {
                          setState(() {});
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 16,
                          ),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index];
                            final name = item['name'] ?? '-';
                            final className =
                                item['classes']?['class_name'] ?? '-';
                            final roomName = item['rooms']?['room_name'] ?? '-';

                            return AnimatedOpacity(
                              opacity: 1.0,
                              duration: Duration(
                                milliseconds: 220 + (index * 35),
                              ),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.22),
                                      blurRadius: 26,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 18,
                                      sigmaY: 18,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        color: Colors.white.withOpacity(0.06),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.16),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          // strip warna di kiri ala iOS list
                                          Container(
                                            width: 5,
                                            height: 68,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      18,
                                                    ),
                                                    bottomLeft: Radius.circular(
                                                      18,
                                                    ),
                                                  ),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFFFB7185),
                                                  Color(0xFFF97373),
                                                ],
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 4,
                                                  ),
                                              leading: CircleAvatar(
                                                radius: 20,
                                                backgroundColor: Colors
                                                    .redAccent
                                                    .withOpacity(0.9),
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              title: Text(
                                                name,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Kelas: $className\nRuangan: $roomName',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Blob dekoratif blur ala iOS
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
            gradient: RadialGradient(colors: [color, color.withOpacity(0.04)]),
          ),
        ),
      ),
    );
  }
}
