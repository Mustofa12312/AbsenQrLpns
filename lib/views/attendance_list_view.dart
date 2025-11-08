// lib/views/attendance_list_view.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../controllers/room_controller.dart';

class AttendanceListView extends StatefulWidget {
  const AttendanceListView({Key? key}) : super(key: key);

  @override
  State<AttendanceListView> createState() => _AttendanceListViewState();
}

class _AttendanceListViewState extends State<AttendanceListView>
    with SingleTickerProviderStateMixin {
  final supabase = SupabaseService.instance;
  final RoomController roomCtrl = Get.find();

  int? selectedRoomId;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    selectedRoomId = roomCtrl.selectedRoomId.value;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  Future<List<Map<String, dynamic>>> fetchAttendance(int? roomId) async {
    final query = supabase.client.from('attendance_today_by_room').select('*');
    final response = roomId != null
        ? await query
              .eq('room_id', roomId)
              .order('created_at', ascending: false)
        : await query.order('created_at', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundGradient = LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
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
              backgroundColor: Colors.white.withOpacity(0.05),
              elevation: 0,
              centerTitle: true,
              title: Text(
                'Daftar Hadir Hari Ini',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: backgroundGradient),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              const SizedBox(height: 100),

              // --- Dropdown filter ruangan ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Obx(() {
                  final rooms = roomCtrl.rooms;
                  if (rooms.isEmpty) {
                    return const SizedBox(
                      height: 56,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonFormField<int>(
                          value: selectedRoomId,
                          dropdownColor: Colors.black.withOpacity(0.6),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Filter Ruangan',
                            labelStyle: TextStyle(color: Colors.white70),
                          ),
                          style: GoogleFonts.poppins(color: Colors.white),
                          iconEnabledColor: Colors.white70,
                          items: rooms.map((r) {
                            return DropdownMenuItem<int>(
                              value: r['id'] as int,
                              child: Text(
                                r['room_name'] as String,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => selectedRoomId = v),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // --- List Siswa Hadir ---
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchAttendance(selectedRoomId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
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
                          'Belum ada yang absen hari ini 📋',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: Colors.cyanAccent,
                      onRefresh: () async => setState(() {}),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          final item = data[index];
                          final no = index + 1;
                          final studentName =
                              item['student_name'] ?? item['name'] ?? '-';
                          final className = item['class_name'] ?? '-';
                          final roomName =
                              item['room_name'] ?? item['room_name'] ?? '-';
                          final createdAt = item['created_at'] ?? '';

                          return AnimatedOpacity(
                            opacity: 1,
                            duration: Duration(
                              milliseconds: 300 + (index * 40),
                            ),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyanAccent.withOpacity(0.15),
                                    blurRadius: 25,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 15,
                                    sigmaY: 15,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.07),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.15),
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Colors.cyanAccent
                                            .withOpacity(0.8),
                                        child: Text(
                                          no.toString(),
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        studentName,
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
                                      trailing: Text(
                                        createdAt.toString().substring(11, 16),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
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
      ),
    );
  }
}
