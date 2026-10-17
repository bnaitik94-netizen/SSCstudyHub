import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';

class DeveloperInfoScreen extends StatefulWidget {
  const DeveloperInfoScreen({super.key});

  @override
  State<DeveloperInfoScreen> createState() => _DeveloperInfoScreenState();
}

class _DeveloperInfoScreenState extends State<DeveloperInfoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Stream<List<Map<String, dynamic>>> _linksStream;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // CRITICAL FIX: Cache the stream in initState.
    // Calling this directly in build() caused continuous re-renders and massive lag.
    _linksStream = _getDynamicLinks();

    if (mounted) {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.trim().isEmpty) return;
    String cleanUrl = urlString.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final Uri url = Uri.parse(cleanUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $cleanUrl');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Could not open link. Please check your connection.',
                style: TextStyle(fontWeight: FontWeight.w600)),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getStyleForType(String type) {
    switch (type.toLowerCase()) {
      case 'youtube':
        return {'icon': Icons.video_library_rounded, 'color': Colors.redAccent};
      case 'instagram':
        return {'icon': Icons.camera_alt_rounded, 'color': Colors.purpleAccent};
      case 'whatsapp':
        return {
          'icon': Icons.chat_rounded,
          'color': Colors.greenAccent.shade400
        };
      case 'website':
        return {'icon': Icons.language_rounded, 'color': Colors.blueAccent};
      case 'github':
        return {'icon': Icons.code_rounded, 'color': Colors.blueGrey};
      case 'linkedin':
        return {
          'icon': Icons.business_center_rounded,
          'color': Colors.lightBlue
        };
      case 'telegram':
        return {'icon': Icons.send_rounded, 'color': Colors.cyan};
      default:
        return {'icon': Icons.link_rounded, 'color': AppColors.primary};
    }
  }

  static const List<Map<String, dynamic>> _defaultLinks = [
    {
      "type": "youtube",
      "title": "YouTube Channel",
      "subtitle": "Cybersecurity & Coding Content",
      "url": "https://youtube.com/@mr._coder_boy?si=0shzEMdoyFM23U1c"
    },
    {
      "type": "instagram",
      "title": "Instagram",
      "subtitle": "@mr._naitik_bobade_23 • DM for questions & feedback",
      "url": "https://instagram.com/mr._naitik_bobade_23"
    },
    {
      "type": "whatsapp",
      "title": "WhatsApp Community",
      "subtitle": "Join our official student discussion group",
      "url": "https://whatsapp.com/channel/0029VbDQg7U4o7qEp3dC293s"
    },
    {
      "type": "website",
      "title": "GitHub / Projects",
      "subtitle": "Explore projects & source code repositories",
      "url": "https://github.com/mr-coder-boy"
    },
  ];

  Stream<List<Map<String, dynamic>>> _getDynamicLinks() {
    return FirebaseFirestore.instance
        .collection('app_settings')
        .doc('developer_info')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists &&
          snapshot.data() != null &&
          snapshot.data()!.containsKey('links')) {
        List<dynamic> rawLinks = snapshot.data()!['links'];
        if (rawLinks.isNotEmpty) {
          return rawLinks.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      return _defaultLinks;
    }).handleError((_) => _defaultLinks);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      // Ensure the animated root background shows through seamlessly
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35), width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 5)
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.code_rounded,
                      size: 50, color: AppColors.primary),
                ),
              )
                  .animate(controller: _animController)
                  .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 600.ms,
                      curve: Curves.easeOutBack)
                  .fadeIn(),
              const SizedBox(height: 24),
              Column(
                children: [
                  Text(
                    "Mr. Naitik Bobade",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text(
                      "App Developer & Cybersecurity Creator",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Passionate about building offline educational applications using Flutter & Python, and creating Hindi cybersecurity content. Dedicated to crafting seamless digital experiences.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                        height: 1.6,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              )
                  .animate(controller: _animController)
                  .slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOut)
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Connect with me",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.grey.shade400 : Colors.grey)),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                  initialData: _defaultLinks,
                  stream: _linksStream,
                  builder: (context, snapshot) {
                    final links = (snapshot.hasData && snapshot.data!.isNotEmpty)
                        ? snapshot.data!
                        : _defaultLinks;

                    return Container(
                      decoration: AppColors.liquidGlassCard,
                      child: Column(
                        children: List.generate(links.length, (index) {
                          final link = links[index];
                          final style = _getStyleForType(link['type'] ?? '');

                          return Column(
                            children: [
                              _buildTouchableLinkTile(
                                icon: style['icon'],
                                iconColor: style['color'],
                                title: link['title'] ?? 'Link',
                                subtitle: link['subtitle'] ??
                                    'Tap to open external link',
                                isDark: isDark,
                                onTap: () => _launchURL(link['url'] ?? ''),
                              ),
                              if (index < links.length - 1)
                                Divider(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100,
                                    height: 1,
                                    indent: 64,
                                    endIndent: 20),
                            ],
                          );
                        }),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 250.ms);
                  }),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Visual Interactive Button Format
  Widget _buildTouchableLinkTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: iconColor.withValues(alpha: 0.2),
        highlightColor: iconColor.withValues(alpha: 0.1),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.open_in_new_rounded,
                    size: 16,
                    color:
                        isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
