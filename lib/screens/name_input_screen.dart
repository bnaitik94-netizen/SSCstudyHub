import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../services/notification_service.dart';
import 'main_dashboard.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});
  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      NotificationService().syncTokenAndTopics();
    }
  }

  Future<void> _saveName() async {
    if (_isLoading) return;

    String name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please enter a valid full name"),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
      return;
    }

    _nameFocusNode.unfocus();
    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentName', name);
      await prefs.setString('student_name', name);
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => MainDashboard(studentName: name)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to save name. Please try again."),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. BOARD BADGE ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: AppColors.accent),
                          SizedBox(width: 6),
                          Text(
                            "MAHARASHTRA SSC 10TH BOARD",
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms),

                    const SizedBox(height: 24),

                    // ── 2. HERO EMBLEM ──────────────────────────────────
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.surfaceCardBorder,
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          size: 34,
                          color: AppColors.accent,
                        ),
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 24),

                    // ── 3. TITLE & DESCRIPTION ──────────────────────────
                    const Text(
                      "Welcome to\nSSC Study Hub",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                    const SizedBox(height: 10),

                    const Text(
                      "Enter your student name to access live broadcasts, official textbooks, formulas, and 24/7 AI doubt assistance.",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                    const SizedBox(height: 36),

                    // ── 4. MODERN INPUT FIELD ────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.surfaceCardBorder,
                          width: 1.0,
                        ),
                      ),
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveName(),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Your Full Name',
                          labelStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                          hintText: "e.g. Naitik Bobade",
                          hintStyle: TextStyle(
                            color: Colors.white24,
                            fontSize: 13.5,
                          ),
                          prefixIcon: Icon(
                            Icons.person_rounded,
                            color: AppColors.accent,
                            size: 22,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                    const SizedBox(height: 24),

                    // ── 5. GRADIENT CTA BUTTON ───────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isLoading ? null : _saveName,
                        child: Ink(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, Color(0xFF0284C7)],
                            ),
                            borderRadius: BorderRadius.all(Radius.circular(16)),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x406366F1),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _isLoading
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Start Learning Now',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                    const SizedBox(height: 36),

                    // ── 6. TRUST BADGES ──────────────────────────────────
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _buildMicroBadge(Icons.sensors_rounded, "Live Broadcasts", AppColors.liveRed),
                          _buildMicroBadge(Icons.auto_awesome_rounded, "AI Doubts", const Color(0xFFA855F7)),
                          _buildMicroBadge(Icons.menu_book_rounded, "Official Notes", AppColors.accent),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicroBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.surfaceCardBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
