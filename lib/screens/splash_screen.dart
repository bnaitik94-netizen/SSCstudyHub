import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/prewarm_service.dart';
import '../services/notification_service.dart';
import 'name_input_screen.dart';
import 'main_dashboard.dart';
import 'live_class_room.dart';
import 'past_class_player.dart';

/// 🌙 SIMPLE, SLEEK & DARK LOADING SCREEN
/// Fast, clean, lag-free minimal dark study theme matching the app aesthetic
class SplashScreen extends StatefulWidget {
  final String? targetRoute;
  final Map<String, String>? queryParams;

  const SplashScreen({
    super.key,
    this.targetRoute,
    this.queryParams,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _currentStep = "Setting up your study space...";
  double _progressValue = 0.20;

  final List<String> _motivationalQuotes = [
    "\"स्वप्न ती नव्हे जी झोपेत पडतात, स्वप्न ती जी झोपू देत नाहीत.\"",
    "\"Daily consistent practice in Class 10 creates state toppers.\"",
    "\"Every chapter you master brings you closer to 95%+!\"",
    "\"Study hard in silence, let your SSC result make the noise.\"",
  ];
  late final String _quote;

  @override
  void initState() {
    super.initState();
    _quote = (_motivationalQuotes..shuffle()).first;

    if (!kIsWeb) {
      // Set light system icons for clean dark theme
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
    }

    _startIntelligentPrewarm();
    if (!kIsWeb) {
      NotificationService().syncTokenAndTopics();
    }
  }

  Future<void> _startIntelligentPrewarm() async {
    String? studentName;

    // Load user preferences (checking both keys for bulletproof persistence)
    try {
      final prefs = await SharedPreferences.getInstance();
      studentName = prefs.getString('studentName') ?? prefs.getString('student_name');
    } catch (e) {
      debugPrint("Prefs error: $e");
    }

    // Warm up live class, chats, thumbnails, upcoming schedule
    await AppPrewarmService.instance.warmUp(
      onProgress: (stepText, progress) {
        if (mounted) {
          setState(() {
            _currentStep = stepText;
            _progressValue = progress;
          });
        }
      },
    );

    // Minor breathing delay (200ms) for smooth visual finish
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    final hasValidName = studentName != null && studentName.trim().isNotEmpty;
    final effectiveName = hasValidName ? studentName.trim() : 'Student';

    Widget targetWidget;
    int tabIndex = 0;
    if (widget.targetRoute == '/study') {
      tabIndex = 1;
    } else if (widget.targetRoute == '/classes' || widget.targetRoute == '/schedule') {
      tabIndex = 2;
    } else if (widget.targetRoute == '/profile') {
      tabIndex = 3;
    }

    if (!hasValidName) {
      targetWidget = const NameInputScreen();
    } else if (widget.targetRoute == '/live') {
      final videoId = widget.queryParams?['v'] ??
          AppPrewarmService.instance.currentVideoId ??
          '';
      final title = AppPrewarmService.instance.currentSessionData?['title'] ?? 'Live Lecture';
      targetWidget = LiveClassRoom(
        userName: effectiveName,
        videoId: videoId,
        title: title,
        isAdmin: false,
      );
    } else if (widget.targetRoute == '/watch' || widget.targetRoute == '/player') {
      final videoId = widget.queryParams?['v'] ?? '';
      final title = widget.queryParams?['title'] ?? 'Recorded Class';
      targetWidget = PastClassPlayerScreen(
        videoId: videoId,
        title: title,
      );
    } else {
      targetWidget = MainDashboard(
        studentName: effectiveName,
        initialTab: tabIndex,
      );
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => targetWidget,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // Deep sleek midnight dark
      body: Container(
        color: const Color(0xFF0B1120),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isShort = constraints.maxHeight < 560;
              final isLandscape = constraints.maxWidth > constraints.maxHeight;

              final children = <Widget>[
                // ── 1. MINIMAL TOP BADGE ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF162032),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF38BDF8),
                        size: 13,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "SSC STUDY HUB • v2.0",
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),

                // ── 2. SIMPLE SLEEK CENTERPIECE ───────────────────────
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clean Study Emblem
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF162238),
                            border: Border.all(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3338BDF8),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.school_rounded,
                              size: 50,
                              color: Color(0xFF38BDF8),
                            ),
                          ),
                        ).animate().scale(
                              duration: 400.ms,
                              curve: Curves.easeOutBack,
                              begin: const Offset(0.85, 0.85),
                              end: const Offset(1.0, 1.0),
                            ),
                        const SizedBox(height: 24),
                        const Text(
                          "SSC STUDY HUB",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
                        const SizedBox(height: 6),
                        const Text(
                          "Class 10 • Maharashtra State Board",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ).animate().fadeIn(duration: 350.ms, delay: 150.ms),
                        const SizedBox(height: 24),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111C2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _quote,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFFCBD5E1),
                              fontStyle: FontStyle.italic,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                      ],
                    ),
                  ),
                ),

                // ── 3. SIMPLE SLEEK PROGRESS BAR ──────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x6610B981),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentStep,
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${(_progressValue * 100).toInt()}%",
                          style: const TextStyle(
                            color: Color(0xFF38BDF8),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Ultra-smooth simple progress bar (zero frame drops)
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(
                        begin: 0.15,
                        end: _progressValue.clamp(0.0, 1.0),
                      ),
                      builder: (context, value, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            height: 4.5,
                            child: LinearProgressIndicator(
                              value: value,
                              backgroundColor: const Color(0xFF1E293B),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Instant Live Streaming • Zero Delay • Offline Sync",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 350.ms, delay: 150.ms),
              ];

              final content = Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 40.0 : 24.0,
                  vertical: isShort ? 14.0 : 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: children,
                ),
              );

              if (isShort) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? 40.0 : 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: children,
                      ),
                    ),
                  ),
                );
              }

              return content;
            },
          ),
        ),
      ),
    );
  }
}
