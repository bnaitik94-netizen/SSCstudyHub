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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.rocket_launch_rounded,
                      size: 40, color: AppColors.primary),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOutBack)
                    .fadeIn(),
                const SizedBox(height: 32),
                Text("Welcome to",
                        style: TextStyle(
                            fontSize: 20,
                            color: isDark
                                ? AppColors.textLight
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500))
                    .animate()
                    .slideY(begin: 0.2, duration: 400.ms, delay: 100.ms)
                    .fadeIn(),
                Text("SSC Study Hub",
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.textDark,
                            letterSpacing: -0.5))
                    .animate()
                    .slideY(begin: 0.2, duration: 400.ms, delay: 200.ms)
                    .fadeIn(),
                const SizedBox(height: 12),
                Text("Enter your name to unlock live lectures, schedules, and instant AI doubt clearing.",
                        style: TextStyle(
                            color: isDark
                                ? Colors.grey.shade400
                                : AppColors.textLight,
                            fontSize: 15,
                            height: 1.5))
                    .animate()
                    .slideY(begin: 0.2, duration: 400.ms, delay: 300.ms)
                    .fadeIn(),
                const SizedBox(height: 48),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveName(),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Your Full Name',
                    labelStyle: TextStyle(
                        color:
                            isDark ? Colors.grey.shade400 : AppColors.textLight,
                        fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppColors.primary),
                    filled: true,
                    fillColor:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2)),
                  ),
                )
                    .animate()
                    .slideY(begin: 0.1, duration: 400.ms, delay: 400.ms)
                    .fadeIn(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0),
                    onPressed: _isLoading ? null : _saveName,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Start Journey',
                              key: ValueKey('text'),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                    ),
                  ),
                )
                    .animate()
                    .slideY(begin: 0.1, duration: 400.ms, delay: 500.ms)
                    .fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
