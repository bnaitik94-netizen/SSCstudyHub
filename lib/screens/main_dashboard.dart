import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tabs/home_tab.dart';
import '../tabs/study_material_tab.dart';
import '../tabs/upcoming_classes_tab.dart';
import '../tabs/profile_tab.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';
import '../screens/live_class_room.dart';
import '../services/notification_service.dart';
import '../services/background_music_service.dart';
import '../utils/web_navigation_helper.dart';
import '../widgets/desktop_navigation.dart';
import '../widgets/doubts_panel.dart';

class MainDashboard extends StatefulWidget {
  final String studentName;
  final int initialTab;

  const MainDashboard({
    super.key,
    required this.studentName,
    this.initialTab = 0,
  });

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  late int _currentIndex;
  late String _studentName;
  StreamSubscription? _popStateSub;
  bool _isSidebarExpanded = true;

  static const List<String> _tabRoutes = [
    '/home',
    '/study',
    '/classes',
    '/profile',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = (widget.initialTab >= 0 && widget.initialTab < _tabRoutes.length)
        ? widget.initialTab
        : 0;
    _studentName = widget.studentName;

    if (kIsWeb) {
      WebNavigationHelper.replaceUrl(_tabRoutes[_currentIndex]);
      final sub = WebNavigationHelper.listenPopState((path) {
        if (!mounted) return;
        if (path.contains('/study')) {
          setState(() => _currentIndex = 1);
        } else if (path.contains('/classes') || path.contains('/schedule')) {
          setState(() => _currentIndex = 2);
        } else if (path.contains('/profile')) {
          setState(() => _currentIndex = 3);
        } else if (path.contains('/home') || path == '/') {
          setState(() => _currentIndex = 0);
        }
      });
      if (sub is StreamSubscription) {
        _popStateSub = sub;
      }
    }

    // PERF: Post-frame initialization for non-critical setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkAndPromptPermission(context);
      NotificationService().syncTokenAndTopics();
      // 🎵 Seamless background study anthem
      BackgroundMusicService.instance.startAutoMusic();
    });
  }

  @override
  void dispose() {
    _popStateSub?.cancel();
    super.dispose();
  }

  void _updateStudentName(String newName) {
    setState(() => _studentName = newName);
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    if (kIsWeb && index >= 0 && index < _tabRoutes.length) {
      WebNavigationHelper.updateUrl(_tabRoutes[index]);
    }
  }

  void _openAiDoubtSolver() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DoubtsPanel(),
    );
  }

  void _openLiveClass(String liveVideoId, String liveTitle) {
    if (liveVideoId.isEmpty) return;
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveClassRoom(
          userName: _studentName,
          videoId: liveVideoId,
          title: liveTitle,
          isAdmin: false,
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Text(
              "Announcements",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: StreamBuilder<QuerySnapshot>(
            stream: NotificationService.broadcastNotificationsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.mark_email_read_rounded,
                  title: "No announcements yet",
                  subtitle: "You're all caught up with live classes and notices.",
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 380),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const AppDivider(),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>? ?? {};
                    final title = data['title']?.toString() ?? 'Announcement';
                    final body = data['body']?.toString() ?? '';
                    final type = data['type']?.toString() ?? 'broadcast';
                    final videoId = data['youtubeVideoId']?.toString();
                    final isLive = type.toLowerCase().contains('live');

                    String timeStr = "Recent";
                    final timestamp = data['timestamp'];
                    if (timestamp is Timestamp) {
                      final dt = timestamp.toDate();
                      final diff = DateTime.now().difference(dt);
                      if (diff.inMinutes < 1) {
                        timeStr = "Just now";
                      } else if (diff.inHours < 1) {
                        timeStr = "${diff.inMinutes}m ago";
                      } else if (diff.inDays < 1) {
                        timeStr = "${diff.inHours}h ago";
                      } else {
                        timeStr = "${diff.inDays}d ago";
                      }
                    }

                    return InkWell(
                      onTap: (videoId != null && videoId.isNotEmpty)
                          ? () {
                              Navigator.pop(ctx);
                              _openLiveClass(videoId, title);
                            }
                          : null,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: isLive
                                    ? AppColors.error
                                    : theme.colorScheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Icon(
                                isLive ? Icons.sensors_rounded : Icons.campaign_rounded,
                                color: isLive ? Colors.white : theme.colorScheme.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (isLive)
                                        const AppBadge(
                                          label: "LIVE",
                                          variant: AppBadgeVariant.error,
                                        ),
                                    ],
                                  ),
                                  if (body.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      body,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        timeStr,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      if (videoId != null && videoId.isNotEmpty)
                                        Text(
                                          "Tap to join →",
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          if (!kIsWeb)
            AppButton.text(
              label: "Test System Alert",
              icon: const Icon(Icons.notifications_active, size: 16),
              onPressed: () {
                NotificationService().showNativeNotificationFromDart(
                  title: "🔔 SSC Study Hub Alert",
                  body: "Phone notification bar is active & working properly!",
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Test notification sent to phone status bar!"),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          AppButton.text(
            label: "Close",
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isDesktopPlatform = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    final bool isDesktop = isDesktopPlatform || screenWidth >= 768;

    return StreamBuilder<DocumentSnapshot>(
      // PERF: Single top-level Firestore stream subscription for live status
      stream: FirebaseFirestore.instance
          .collection('live_session')
          .doc('current')
          .snapshots(),
      builder: (context, snapshot) {
        bool isCurrentlyLive = false;
        String liveTitle = "Live Lecture";
        String liveVideoId = "";

        if (snapshot.hasData && snapshot.data!.exists) {
          final doc = snapshot.data!.data() as Map<String, dynamic>?;
          if (doc != null && doc['isLive'] == true) {
            isCurrentlyLive = true;
            liveTitle = doc['title']?.toString() ?? "Live Lecture";
            liveVideoId = doc['youtubeVideoId']?.toString() ?? "";
          }
        }

        Widget pageBody = IndexedStack(
          index: _currentIndex,
          children: [
            HomeTab(
              studentName: _studentName,
              onNavigateTab: _onTabTapped,
            ),
            const StudyMaterialTab(),
            const UpcomingClassesTab(),
            ProfileTab(
              studentName: _studentName,
              onNameUpdated: _updateStudentName,
            ),
          ],
        );

        if (isDesktop) {
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyB, control: true): () {
                setState(() => _isSidebarExpanded = !_isSidebarExpanded);
              },
              const SingleActivator(LogicalKeyboardKey.keyB, meta: true): () {
                setState(() => _isSidebarExpanded = !_isSidebarExpanded);
              },
              const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => _onTabTapped(0),
              const SingleActivator(LogicalKeyboardKey.digit1, meta: true): () => _onTabTapped(0),
              const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => _onTabTapped(1),
              const SingleActivator(LogicalKeyboardKey.digit2, meta: true): () => _onTabTapped(1),
              const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => _onTabTapped(2),
              const SingleActivator(LogicalKeyboardKey.digit3, meta: true): () => _onTabTapped(2),
              const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => _onTabTapped(3),
              const SingleActivator(LogicalKeyboardKey.digit4, meta: true): () => _onTabTapped(3),
              const SingleActivator(LogicalKeyboardKey.keyK, control: true): _openAiDoubtSolver,
              const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _openAiDoubtSolver,
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                body: Row(
                  children: [
                    DesktopSidebar(
                      currentIndex: _currentIndex,
                      onTabSelected: _onTabTapped,
                      isExpanded: _isSidebarExpanded,
                      onToggleExpand: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isSidebarExpanded = !_isSidebarExpanded);
                      },
                      studentName: _studentName,
                      isCurrentlyLive: isCurrentlyLive,
                      liveTitle: liveTitle,
                      onOpenAiDoubts: _openAiDoubtSolver,
                      onOpenLiveClass: () => _openLiveClass(liveVideoId, liveTitle),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          DesktopTopBar(
                            currentIndex: _currentIndex,
                            studentName: _studentName,
                            isCurrentlyLive: isCurrentlyLive,
                            liveTitle: liveTitle,
                            isSidebarExpanded: _isSidebarExpanded,
                            onToggleSidebar: () {
                              HapticFeedback.lightImpact();
                              setState(() => _isSidebarExpanded = !_isSidebarExpanded);
                            },
                            onOpenAiDoubts: _openAiDoubtSolver,
                            onOpenLiveClass: () => _openLiveClass(liveVideoId, liveTitle),
                            onNotificationsTap: _showNotificationsDialog,
                            onTabSelected: _onTabTapped,
                          ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 1360),
                                child: RepaintBoundary(child: pageBody),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Mobile Layout with Custom Floating Island Navigation Bar
        return Scaffold(
          extendBody: true,
          body: Stack(
            children: [
              RepaintBoundary(child: pageBody),
              if (isCurrentlyLive && liveVideoId.isNotEmpty)
                Positioned(
                  top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
                  left: AppSpacing.screenHorizontal,
                  right: AppSpacing.screenHorizontal,
                  child: Semantics(
                    button: true,
                    label: "Join live class: $liveTitle",
                    child: AppCard.primary(
                      onTap: () => _openLiveClass(liveVideoId, liveTitle),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          const AppBadge(
                            label: "LIVE NOW",
                            variant: AppBadgeVariant.error,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              liveTitle,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Studio-Grade Floating Island Navigation Bar
          bottomNavigationBar: AppFloatingIslandNav(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            destinations: [
              const AppNavDestination(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: "Home",
              ),
              const AppNavDestination(
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                label: "Study",
              ),
              AppNavDestination(
                icon: Icons.calendar_today_outlined,
                selectedIcon: Icons.calendar_today_rounded,
                label: "Classes",
                isBadgeVisible: isCurrentlyLive,
                badgeText: "LIVE",
              ),
              const AppNavDestination(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: "Profile",
              ),
            ],
          ),
        );
      },
    );
  }
}
