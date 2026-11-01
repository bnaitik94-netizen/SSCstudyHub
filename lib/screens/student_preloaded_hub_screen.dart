import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/live_class_preload_engine.dart';
import '../widgets/student_live_banner.dart';

class StudentPreloadedHubScreen extends StatefulWidget {
  const StudentPreloadedHubScreen({super.key});

  @override
  State<StudentPreloadedHubScreen> createState() => _StudentPreloadedHubScreenState();
}

class _StudentPreloadedHubScreenState extends State<StudentPreloadedHubScreen> {
  final LiveClassPreloadEngine _engine = LiveClassPreloadEngine();

  @override
  void initState() {
    super.initState();
    _engine.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F19), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _engine,
            builder: (context, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.35)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF00F2FE)),
                                  SizedBox(width: 4),
                                  Text(
                                    "SSC 10th BOARD",
                                    style: TextStyle(
                                      color: Color(0xFF00F2FE),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Hello, ${_engine.cachedStudentName} 👋",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00F2FE), Color(0xFF4F46E5)],
                            ),
                            border: Border.all(color: Colors.white24, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _engine.cachedStudentName.isNotEmpty
                                ? _engine.cachedStudentName[0].toUpperCase()
                                : "S",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Active Live Banner (Pre-loaded 0ms Instant Launch)
                    if (_engine.isClassLive) ...[
                      StudentLiveBanner(engine: _engine),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Standby Offline Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: const Icon(
                                    Icons.tv_off_rounded,
                                    size: 32,
                                    color: Color(0xFF00F2FE),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "No Active Live Broadcast",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Background engines are pre-warmed and ready to launch automatically when the teacher goes live.",
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.4),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
