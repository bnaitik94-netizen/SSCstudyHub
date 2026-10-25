import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/developer_info_screen.dart';
import '../utils/app_colors.dart';
import '../services/notification_service.dart';

class ProfileTab extends StatefulWidget {
  final String studentName;
  final ValueChanged<String>? onNameUpdated;

  const ProfileTab({
    super.key,
    required this.studentName,
    this.onNameUpdated,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late String _currentName;

  @override
  void initState() {
    super.initState();
    _currentName = widget.studentName;
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentName != widget.studentName) {
      _currentName = widget.studentName;
    }
  }

  void _showEditNameDialog() {
    HapticFeedback.lightImpact();
    final textController = TextEditingController(text: _currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162544),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: AppColors.accent, size: 20),
            SizedBox(width: 8),
            Text(
              "Edit Student Name",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your full name as registered for your SSC Maharashtra Board studies:",
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                hintText: "Your Name",
                hintStyle: const TextStyle(color: Colors.white38),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('studentName', newName);
                await prefs.setString('student_name', newName);

                setState(() => _currentName = newName);
                widget.onNameUpdated?.call(newName);

                if (ctx.mounted) Navigator.pop(ctx);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Name updated successfully!"),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text("Save Name",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open external URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to open link."),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),

            // 🌟 STUDENT AVATAR WITH LIQUID GLOW RING
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFF162544),
                child: Text(
                  _currentName.isNotEmpty ? _currentName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 38,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _currentName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showEditNameDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn().slideY(begin: 0.1),

            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Text(
                "SSC 10th Board Student",
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 28),

            // 📊 QUICK STATS ROW IN LIQUID GLASS
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: AppColors.liquidGlassCard,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Board", "Maharashtra", Icons.school_rounded),
                  _buildVerticalDivider(),
                  _buildStatItem("Class", "10th Semi", Icons.menu_book_rounded),
                  _buildVerticalDivider(),
                  _buildStatItem(
                      "Status", "Pro Active", Icons.verified_rounded,
                      isAccent: true),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),

            const SizedBox(height: 20),

            // 🔔 NOTIFICATION STATUS & DIAGNOSTICS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: AppColors.liquidGlassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_active_rounded,
                              size: 18, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text(
                            'Live Class Alerts',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: NotificationService.isRegisteredNotifier,
                        builder: (context, isRegistered, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRegistered
                                  ? const Color(0x2610B981)
                                  : const Color(0x266366F1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isRegistered
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF6366F1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isRegistered
                                      ? Icons.check_circle_rounded
                                      : Icons.sync_rounded,
                                  size: 13,
                                  color: isRegistered
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFA5B4FC),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isRegistered ? "Connected" : "Syncing",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isRegistered
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFA5B4FC),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Receive instant alerts when the teacher starts a live class or makes an important study announcement.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            HapticFeedback.lightImpact();
                            await NotificationService()
                                .showNativeNotificationFromDart(
                              title: "SSC Study Hub Pro 🔔",
                              body:
                                  "Device notification system is 100% active and connected!",
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Test notification sent! Check your notification bar."),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text(
                            "Test Alert",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            await NotificationService()
                                .syncTokenAndTopics(maxRetries: 5);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Device token successfully registered in cloud! 🚀"),
                                  backgroundColor: Color(0xFF10B981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.cloud_sync_rounded, size: 15),
                          label: const Text(
                            "Sync Token",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.08),

            const SizedBox(height: 20),

            // 📚 QUICK LEARNING ACCESS CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: AppColors.liquidGlassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_stories_rounded,
                          size: 18, color: AppColors.accent),
                      SizedBox(width: 8),
                      Text(
                        'Direct Learning Portals',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          _launchExternalUrl("https://books.ebalbharati.in/"),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _buildInfoRow(
                          Icons.library_books_rounded,
                          'Official eBalbharti Library',
                          'Maharashtra State Board Portal',
                          trailing: const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08),

            const SizedBox(height: 20),

            // ℹ️ APP INFO CARD IN LIQUID GLASS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: AppColors.liquidGlassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.accent),
                      SizedBox(width: 8),
                      Text(
                        'Application Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DeveloperInfoScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _buildInfoRow(
                          Icons.code_rounded,
                          'Developed By',
                          'Mr. Naitik Bobade',
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  _buildInfoRow(
                    Icons.build_circle_rounded,
                    'Version',
                    'SSC Study Hub 4.0.0 Pro',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  _buildInfoRow(
                    Icons.security_rounded,
                    'Security & Live Sync',
                    'Secured & Connected',
                    isSuccess: true,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.08),

            const SizedBox(
                height: 120), // Bottom clearance for liquid glass tab bar
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      {bool isAccent = false}) {
    return Column(
      children: [
        Icon(icon,
            size: 18, color: isAccent ? AppColors.accent : Colors.white70),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isAccent ? AppColors.accent : Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value, {
    bool isSuccess = false,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primaryLight.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isSuccess ? AppColors.success : Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
