// lib/views/main_view.dart
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/nav_provider.dart';
import 'home_view.dart';
import 'attendance_list_view.dart';
import 'absent_list_view.dart';
import 'scan_view.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _scaleAnim = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // small helper to trigger a quick "pop" feedback
  void _popEffect() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();

    // subtle ocean-neon background (you can swap gradient easily)
    const backgroundGradient = LinearGradient(
      colors: [Color(0xFF101820), Color(0xFF1E3C72), Color(0xFF2A5298)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final pages = <Widget>[
      const HomeView(),
      const ScanView(),
      const AttendanceListView(),
      const AbsentListView(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // background gradient
          Container(
            decoration: const BoxDecoration(gradient: backgroundGradient),
          ),

          // subtle neon particles (non-interactive painter)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _NeonParticlePainter()),
            ),
          ),

          // page transition: AnimatedSwitcher with fade+scale+slide
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 520),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final slide =
                  Tween<Offset>(
                    begin: const Offset(0.03, 0.02),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  );
              final scale = Tween<double>(
                begin: 0.985,
                end: 1.0,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: slide,
                  child: ScaleTransition(scale: scale, child: child),
                ),
              );
            },
            child: IndexedStack(
              key: ValueKey<int>(nav.index),
              index: nav.index,
              children: pages,
            ),
          ),
        ],
      ),

      // floating glass navigation bar
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // neon glow below the bar
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.06),
                            blurRadius: 40,
                            spreadRadius: 6,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.03),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // the glass nav container
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      height: 74,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: NavigationBarTheme(
                        data: NavigationBarThemeData(
                          backgroundColor: Colors.transparent,
                          indicatorColor: Colors.white.withOpacity(0.14),
                          labelTextStyle:
                              WidgetStateProperty.resolveWith<TextStyle>((
                                states,
                              ) {
                                return TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize:
                                      states.contains(WidgetState.selected)
                                      ? 13
                                      : 12,
                                  fontWeight:
                                      states.contains(WidgetState.selected)
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: states.contains(WidgetState.selected)
                                      ? Colors.white
                                      : Colors.white70,
                                );
                              }),
                        ),
                        child: NavigationBar(
                          height: 64,
                          elevation: 0,
                          selectedIndex: nav.index,
                          onDestinationSelected: (int idx) {
                            _popEffect(); // trigger pop animation
                            nav.change(idx);
                          },
                          destinations: const [
                            NavigationDestination(
                              icon: Icon(
                                Icons.home_outlined,
                                color: Colors.white70,
                              ),
                              selectedIcon: Icon(
                                Icons.home,
                                color: Colors.white,
                              ),
                              label: 'Home',
                            ),
                            NavigationDestination(
                              icon: Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white70,
                              ),
                              selectedIcon: Icon(
                                Icons.qr_code_2,
                                color: Colors.white,
                              ),
                              label: 'Scan',
                            ),
                            NavigationDestination(
                              icon: Icon(
                                Icons.people_alt_outlined,
                                color: Colors.white70,
                              ),
                              selectedIcon: Icon(
                                Icons.people,
                                color: Colors.white,
                              ),
                              label: 'Hadir',
                            ),
                            NavigationDestination(
                              icon: Icon(
                                Icons.person_off_outlined,
                                color: Colors.white70,
                              ),
                              selectedIcon: Icon(
                                Icons.person_off,
                                color: Colors.white,
                              ),
                              label: 'Absen',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Neon particle painter (soft, static-ish background)
//    Keep it lightweight: draws several soft blurred circles.
//    For animated particles you'd want a stateful painter with animation controller.
class _NeonParticlePainter extends CustomPainter {
  final Random _rnd = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    // draw a handful of soft circles, deterministic-ish for stability
    final seeds = [12, 6, 9, 5, 8, 3, 7];
    for (int i = 0; i < seeds.length; i++) {
      final r = 20.0 + (i * 6.0);
      final x = (size.width * (0.18 + (i * 0.11))) % size.width;
      final y = (size.height * (0.12 + (i * 0.14))) % size.height;
      paint.color = [
        Colors.cyanAccent.withOpacity(0.06),
        Colors.blueAccent.withOpacity(0.05),
        Colors.tealAccent.withOpacity(0.05),
        Colors.greenAccent.withOpacity(0.04),
      ][i % 4];
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
