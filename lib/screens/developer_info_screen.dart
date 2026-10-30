import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';

class DeveloperInfoScreen extends StatefulWidget {
  const DeveloperInfoScreen({super.key});

  @override
  State<DeveloperInfoScreen> createState() => _DeveloperInfoScreenState();
}

class _DeveloperInfoScreenState extends State<DeveloperInfoScreen> {
  late Stream<List<Map<String, dynamic>>> _linksStream;

  @override
  void initState() {
    super.initState();
    // Cache the stream in initState to prevent build loop re-renders
    _linksStream = _getDynamicLinks();
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
          const SnackBar(
            content: Text(
              'Could not open link. Please check your connection.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getStyleForType(String type, Color primaryColor) {
    switch (type.toLowerCase()) {
      case 'youtube':
        return {'icon': Icons.video_library_rounded, 'color': Colors.redAccent};
      case 'instagram':
        return {'icon': Icons.camera_alt_rounded, 'color': Colors.purpleAccent};
      case 'whatsapp':
        return {'icon': Icons.chat_rounded, 'color': Colors.green};
      case 'website':
        return {'icon': Icons.language_rounded, 'color': Colors.blue};
      case 'github':
        return {'icon': Icons.code_rounded, 'color': Colors.blueGrey};
      case 'linkedin':
        return {'icon': Icons.business_center_rounded, 'color': Colors.lightBlue};
      case 'telegram':
        return {'icon': Icons.send_rounded, 'color': Colors.cyan};
      default:
        return {'icon': Icons.link_rounded, 'color': primaryColor};
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
      "subtitle": "@mr._naitik_bobade_23 • Questions & feedback",
      "url": "https://instagram.com/mr._naitik_bobade_23"
    },
    {
      "type": "whatsapp",
      "title": "WhatsApp Community",
      "subtitle": "Official student discussion group",
      "url": "https://whatsapp.com/channel/0029VbDQg7U4o7qEp3dC293s"
    },
    {
      "type": "website",
      "title": "GitHub Projects",
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Developer Info"),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const AppAvatar(
              name: "Naitik Bobade",
              size: 84,
              hasGradientRing: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "Mr. Naitik Bobade",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const AppBadge(
              label: "App Developer & Cybersecurity Creator",
              variant: AppBadgeVariant.info,
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                "Passionate about building offline educational applications using Flutter & Python, and creating cybersecurity content. Dedicated to crafting seamless digital experiences.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(
              title: "Connect & Channels",
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _linksStream,
              builder: (context, snapshot) {
                final links = snapshot.data ?? _defaultLinks;

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: links.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.listItemGap),
                  itemBuilder: (context, index) {
                    final item = links[index];
                    final styleInfo = _getStyleForType(
                      item['type'] ?? '',
                      theme.colorScheme.primary,
                    );
                    final IconData iconData = styleInfo['icon'];
                    final Color iconColor = styleInfo['color'];

                    return RepaintBoundary(
                      child: AppCard.listItem(
                        onTap: () => _launchURL(item['url'] ?? ''),
                        accentBarColor: iconColor,
                        leading: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Icon(
                            iconData,
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? '',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['subtitle'] ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}
