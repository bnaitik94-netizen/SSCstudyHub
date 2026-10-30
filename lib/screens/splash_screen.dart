import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/prewarm_service.dart';
import '../services/notification_service.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';
import 'name_input_screen.dart';
import 'main_dashboard.dart';
import 'live_class_room.dart';
import 'past_class_player.dart';

/// Lightweight, clean splash screen with prewarming and deep link routing.
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
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    _startIntelligentPrewarm();
    if (!kIsWeb) {
      NotificationService().syncTokenAndTopics();
    }
  }

  Future<void> _startIntelligentPrewarm() async {
    String? studentName;

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

    // Minor breathing delay for smooth visual transition
    await Future.delayed(const Duration(milliseconds: 150));

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
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => targetWidget,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppBadge(
                label: "MAHARASHTRA STATE BOARD • CLASS 10",
                variant: AppBadgeVariant.info,
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.school_rounded,
                        size: 36,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    "SSC STUDY HUB",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    "Live Lectures • Question Bank • AI Doubts",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      _quote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: _progressValue,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _currentStep,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
