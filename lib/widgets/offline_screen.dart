import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/connectivity_service.dart';
import '../utils/app_colors.dart';

/// 📚 PROFESSIONAL ANIMATED STUDENT-THEMED OFFLINE SCREEN
/// Features an animated boy studying at his desk with desk lamp glow,
/// open book, laptop, live connectivity recovery, and cached offline mode.
class OfflineScreen extends StatefulWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onContinueOffline;

  const OfflineScreen({
    super.key,
    this.onRetry,
    this.onContinueOffline,
  });

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _isRetrying = false;
  String? _statusFeedback;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    HapticFeedback.lightImpact();

    setState(() {
      _isRetrying = true;
      _statusFeedback = "Checking connection...";
    });

    final isReachable = await ConnectivityService.instance.checkReachability();

    if (!mounted) return;

    if (isReachable) {
      setState(() {
        _statusFeedback = "Connection restored! Resuming...";
      });
      await Future.delayed(const Duration(milliseconds: 400));
      widget.onRetry?.call();
    } else {
      setState(() {
        _isRetrying = false;
        _statusFeedback = "Still offline. Please check your Wi-Fi or data connection.";
      });
    }
  }

  void _handleContinueOffline() {
    HapticFeedback.lightImpact();
    ConnectivityService.instance.continueOffline();
    widget.onContinueOffline?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 850;

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B), // Deep slate midnight
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _buildIllustrationContainer(),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          flex: 5,
                          child: _buildContentPanel(),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIllustrationContainer(),
                        const SizedBox(height: 32),
                        _buildContentPanel(),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustrationContainer() {
    return AspectRatio(
      aspectRatio: 1.15,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF162544).withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                painter: _StudentDeskPainter(
                  animationProgress: _animController.value,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContentPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Offline Status Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.amber.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.amber, size: 16),
              SizedBox(width: 8),
              Text(
                "NO INTERNET DETECTED",
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Main Heading
        const Text(
          "You're Offline",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),

        // Description
        const Text(
          "It looks like your internet connection is unavailable. Don't worry! You can check your Wi-Fi/data to reconnect, or continue reading your saved offline study materials.",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14.5,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            // Primary "Try Again" Button
            ElevatedButton(
              onPressed: _isRetrying ? null : _handleRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: const Color(0xFF0B132B),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: _isRetrying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B132B)),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          "Try Again",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),

            // Secondary "Continue Offline" Button
            OutlinedButton(
              onPressed: _handleContinueOffline,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_rounded, size: 17, color: Colors.white70),
                  SizedBox(width: 8),
                  Text(
                    "Continue Offline",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Status Feedback (if retrying or failed)
        if (_statusFeedback != null) ...[
          const SizedBox(height: 14),
          Text(
            _statusFeedback!,
            style: TextStyle(
              color: _statusFeedback!.contains("restored")
                  ? Colors.greenAccent
                  : Colors.amberAccent,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        const SizedBox(height: 28),

        // Offline Capabilities Checklist
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "READY IN OFFLINE MODE:",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              _buildFeatureItem(Icons.check_circle_rounded, "Maharashtra Class 10 Syllabus Structure"),
              const SizedBox(height: 6),
              _buildFeatureItem(Icons.check_circle_rounded, "Cached Textbook Chapters & Study Index"),
              const SizedBox(height: 6),
              _buildFeatureItem(Icons.check_circle_rounded, "Student Profile, Streaks & Local Notes"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF00F2FE)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// 🎨 CUSTOM VECTOR PAINTER: Animated Student Boy Studying at Desk
/// Lightweight, zero external dependencies, 60fps native Flutter rendering.
class _StudentDeskPainter extends CustomPainter {
  final double animationProgress;

  _StudentDeskPainter({required this.animationProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Ambient Background Glow
    final bgGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF1E3A8A).withValues(alpha: 0.35),
          Colors.transparent,
        ],
        radius: 0.75,
      ).createShader(Rect.fromCircle(
        center: Offset(w * 0.5, h * 0.45),
        radius: w * 0.45,
      ));
    canvas.drawCircle(Offset(w * 0.5, h * 0.45), w * 0.45, bgGlowPaint);

    // 2. Desk Lamp Light Beam
    final lampGlowIntensity = 0.35 + 0.15 * math.sin(animationProgress * math.pi);
    final lampBeamPath = Path()
      ..moveTo(w * 0.28, h * 0.38)
      ..lineTo(w * 0.12, h * 0.74)
      ..lineTo(w * 0.62, h * 0.74)
      ..close();

    final lampLightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFDE68A).withValues(alpha: lampGlowIntensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(w * 0.12, h * 0.38, w * 0.5, h * 0.36));
    canvas.drawPath(lampBeamPath, lampLightPaint);

    // 3. Wooden Desk Surface
    final deskPaint = Paint()..color = const Color(0xFF334155);
    final deskRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.14, h * 0.70, w * 0.72, h * 0.05),
      const Radius.circular(8),
    );
    canvas.drawRRect(deskRect, deskPaint);

    final deskTopLine = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(w * 0.14, h * 0.70),
      Offset(w * 0.86, h * 0.70),
      deskTopLine,
    );

    // Desk Legs
    final legPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.22, h * 0.75), Offset(w * 0.22, h * 0.90), legPaint);
    canvas.drawLine(Offset(w * 0.78, h * 0.75), Offset(w * 0.78, h * 0.90), legPaint);

    // 4. Desk Lamp Body (Left)
    final lampPaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final lampBasePaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.24, h * 0.69), width: 34, height: 10),
      lampBasePaint,
    );

    // Lamp Stem
    final lampStem = Path()
      ..moveTo(w * 0.24, h * 0.69)
      ..quadraticBezierTo(w * 0.20, h * 0.52, w * 0.27, h * 0.38);
    canvas.drawPath(lampStem, lampPaint);

    // Lamp Head / Shade
    final shadePaint = Paint()..color = const Color(0xFF38BDF8);
    final shadePath = Path()
      ..moveTo(w * 0.25, h * 0.36)
      ..lineTo(w * 0.32, h * 0.40)
      ..lineTo(w * 0.24, h * 0.44)
      ..close();
    canvas.drawPath(shadePath, shadePaint);

    // Glowing Bulb inside Lamp
    final bulbPaint = Paint()..color = const Color(0xFFFDE047);
    canvas.drawCircle(Offset(w * 0.27, h * 0.41), 5, bulbPaint);

    // 5. Open Book on Desk (Center-Left)
    // Subtle page flutter based on animationProgress
    final pageFlutter = 3 * math.sin(animationProgress * math.pi * 2);
    final bookCenter = Offset(w * 0.42, h * 0.69);

    final bookCover = Paint()..color = const Color(0xFF0284C7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: bookCenter, width: 68, height: 16),
        const Radius.circular(4),
      ),
      bookCover,
    );

    final pagePaint = Paint()..color = const Color(0xFFF8FAFC);
    // Left Page
    final leftPage = Path()
      ..moveTo(bookCenter.dx, bookCenter.dy - 6)
      ..lineTo(bookCenter.dx - 30, bookCenter.dy - 9)
      ..lineTo(bookCenter.dx - 30, bookCenter.dy + 3)
      ..lineTo(bookCenter.dx, bookCenter.dy + 5)
      ..close();
    canvas.drawPath(leftPage, pagePaint);

    // Right Page (with flutter)
    final rightPage = Path()
      ..moveTo(bookCenter.dx, bookCenter.dy - 6)
      ..lineTo(bookCenter.dx + 30, bookCenter.dy - 9 + pageFlutter)
      ..lineTo(bookCenter.dx + 30, bookCenter.dy + 3 + pageFlutter)
      ..lineTo(bookCenter.dx, bookCenter.dy + 5)
      ..close();
    canvas.drawPath(rightPage, pagePaint);

    // Small Text lines on Book
    final textLinePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(bookCenter.dx - 24, bookCenter.dy - 4),
      Offset(bookCenter.dx - 8, bookCenter.dy - 4),
      textLinePaint,
    );
    canvas.drawLine(
      Offset(bookCenter.dx - 24, bookCenter.dy - 1),
      Offset(bookCenter.dx - 10, bookCenter.dy - 1),
      textLinePaint,
    );

    // 6. Laptop on Desk (Right)
    final laptopPaint = Paint()..color = const Color(0xFF475569);
    // Laptop Base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.65, h * 0.69), width: 56, height: 8),
        const Radius.circular(3),
      ),
      laptopPaint,
    );

    // Laptop Screen
    final screenPath = Path()
      ..moveTo(w * 0.62, h * 0.69)
      ..lineTo(w * 0.64, h * 0.54)
      ..lineTo(w * 0.76, h * 0.54)
      ..lineTo(w * 0.74, h * 0.69)
      ..close();
    final screenPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawPath(screenPath, screenPaint);

    // Glowing Laptop Display
    final displayPath = Path()
      ..moveTo(w * 0.63, h * 0.67)
      ..lineTo(w * 0.65, h * 0.56)
      ..lineTo(w * 0.74, h * 0.56)
      ..lineTo(w * 0.73, h * 0.67)
      ..close();
    final displayPaint = Paint()..color = const Color(0xFF38BDF8).withValues(alpha: 0.55);
    canvas.drawPath(displayPath, displayPaint);

    // 7. Pen Stand with Study Stationery
    final penStandPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.63, 14, 22),
        const Radius.circular(3),
      ),
      penStandPaint,
    );
    final pen1 = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final pen2 = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.34, h * 0.63), Offset(w * 0.33, h * 0.57), pen1);
    canvas.drawLine(Offset(w * 0.37, h * 0.63), Offset(w * 0.38, h * 0.55), pen2);

    // 8. THE STUDYING STUDENT (Boy at Desk)
    // Gentle breathing offset
    final breathOffset = 2.5 * math.sin(animationProgress * math.pi);

    // Chair Backrest
    final chairPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.52, h * 0.54), width: 62, height: 85),
        const Radius.circular(16),
      ),
      chairPaint,
    );

    // Student Body (Hoodie / Shirt)
    final bodyPaint = Paint()..color = const Color(0xFF2563EB); // Navy study hoodie
    final bodyPath = Path()
      ..moveTo(w * 0.44, h * 0.68)
      ..lineTo(w * 0.46, h * 0.46 + breathOffset)
      ..lineTo(w * 0.58, h * 0.46 + breathOffset)
      ..lineTo(w * 0.60, h * 0.68)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Student Head / Face
    final skinPaint = Paint()..color = const Color(0xFFFFD1A9);
    canvas.drawCircle(
      Offset(w * 0.52, h * 0.39 + breathOffset),
      19,
      skinPaint,
    );

    // Hair (Neat modern boy haircut)
    final hairPaint = Paint()..color = const Color(0xFF1E1B4B);
    final hairPath = Path()
      ..moveTo(w * 0.46, h * 0.39 + breathOffset)
      ..quadraticBezierTo(w * 0.48, h * 0.30 + breathOffset, w * 0.54, h * 0.30 + breathOffset)
      ..quadraticBezierTo(w * 0.59, h * 0.32 + breathOffset, w * 0.58, h * 0.39 + breathOffset)
      ..lineTo(w * 0.54, h * 0.34 + breathOffset)
      ..close();
    canvas.drawPath(hairPath, hairPaint);

    // Eye (Thoughtful reading glance towards book)
    final eyePaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(
      Offset(w * 0.49, h * 0.40 + breathOffset),
      2,
      eyePaint,
    );

    // Study Glasses
    final glassesPaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(w * 0.49, h * 0.39 + breathOffset), 5, glassesPaint);
    canvas.drawLine(
      Offset(w * 0.54, h * 0.39 + breathOffset),
      Offset(w * 0.57, h * 0.38 + breathOffset),
      glassesPaint,
    );

    // Student Arms resting on Desk holding study notes
    final armPaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.47, h * 0.54 + breathOffset),
      Offset(w * 0.42, h * 0.69),
      armPaint,
    );
    canvas.drawLine(
      Offset(w * 0.57, h * 0.54 + breathOffset),
      Offset(w * 0.62, h * 0.69),
      armPaint,
    );

    // Student Hand on Book
    canvas.drawCircle(Offset(w * 0.42, h * 0.69), 4.5, skinPaint);

    // 9. Floating Disconnected Cloud / WiFi Alert (Above Student)
    final cloudY = h * 0.20 + 3 * math.sin(animationProgress * math.pi * 2);
    final alertBg = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.52, cloudY), width: 88, height: 32),
        const Radius.circular(16),
      ),
      alertBg,
    );

    final alertBorder = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.52, cloudY), width: 88, height: 32),
        const Radius.circular(16),
      ),
      alertBorder,
    );

    // Mini Disconnected Icon and Text in cloud
    final iconPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    // Dot
    canvas.drawCircle(Offset(w * 0.46, cloudY + 4), 2, Paint()..color = const Color(0xFFF59E0B));
    // Arc
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w * 0.46, cloudY + 4), width: 14, height: 14),
      math.pi * 1.2,
      math.pi * 0.6,
      false,
      iconPaint,
    );
    // Strike line
    canvas.drawLine(
      Offset(w * 0.43, cloudY - 2),
      Offset(w * 0.49, cloudY + 8),
      Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _StudentDeskPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
}
