import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../tabs/home_tab.dart';
import '../tabs/study_material_tab.dart';
import '../tabs/upcoming_classes_tab.dart';
import '../tabs/profile_tab.dart';
import '../utils/app_colors.dart';
import '../screens/live_class_room.dart';
import '../services/notification_service.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkAndPromptPermission(context);
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
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF162544),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Color(0x66FFFFFF), width: 1.2),
          ),
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          child: DoubtsPanel(),
        ),
      ),
    );
  }

  void _openLiveClass(String liveVideoId, String liveTitle) {
    if (liveVideoId.isEmpty) return;
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 140),
        pageBuilder: (_, __, ___) => LiveClassRoom(
          userName: _studentName,
          videoId: liveVideoId,
          title: liveTitle,
          isAdmin: false,
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  void _showNotificationsDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: AppColors.accent, size: 22),
            SizedBox(width: 10),
            Text(
              "Announcements",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationItem(
              title: "Welcome to SSC Study Hub Pro",
              body: "All syllabus PDFs, live lectures, and AI doubt clearing are active.",
              time: "Just now",
              icon: Icons.school_rounded,
            ),
            const Divider(color: Colors.white12, height: 20),
            _buildNotificationItem(
              title: "Exam Countdown Active",
              body: "Check the Live Schedule tab for daily revision class timings.",
              time: "Today",
              icon: Icons.event_note_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Got it", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String body,
    required String time,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 3),
              Text(body, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 850;

    return StreamBuilder<DocumentSnapshot>(
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

        Widget content;
        if (isDesktop) {
          content = CallbackShortcuts(
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
                backgroundColor: Colors.transparent,
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
        } else {
          content = Scaffold(
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: Stack(
              children: [
                RepaintBoundary(child: pageBody),
                if (isCurrentlyLive && liveVideoId.isNotEmpty)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 140),
                            pageBuilder: (_, __, ___) => LiveClassRoom(
                              userName: _studentName,
                              videoId: liveVideoId,
                              title: liveTitle,
                              isAdmin: false,
                            ),
                            transitionsBuilder: (_, anim, __, child) =>
                                FadeTransition(opacity: anim, child: child),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "🔴 LIVE NOW: $liveTitle",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "JOIN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: RepaintBoundary(
              child: _LiquidGlassNavBar(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
              ),
            ),
          );
        }

        if (kIsWeb) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: content,
              ),
            ),
          );
        }

        return content;
      },
    );
  }
}

class _LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LiquidGlassNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_TabItemData> _items = [
    _TabItemData(
      index: 0,
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: "Home",
    ),
    _TabItemData(
      index: 1,
      activeIcon: Icons.menu_book_rounded,
      inactiveIcon: Icons.menu_book_outlined,
      label: "Study",
    ),
    _TabItemData(
      index: 2,
      activeIcon: Icons.play_circle_fill_rounded,
      inactiveIcon: Icons.play_circle_outline_rounded,
      label: "Schedule",
      isLiveTarget: true,
    ),
    _TabItemData(
      index: 3,
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      label: "Profile",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // 🚀 CACHED TOP-LEVEL STREAM: Only one listener for the entire navbar
      stream: FirebaseFirestore.instance
          .collection('live_session')
          .doc('current')
          .snapshots(),
      builder: (context, snapshot) {
        bool isCurrentlyLive = false;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          isCurrentlyLive = data?['isLive'] == true;
        }

        return SafeArea(
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Container(
              height: 72,
              decoration: AppColors.liquidGlassTab,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double tabWidth = constraints.maxWidth / _items.length;

                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // 🌊 GLIDING LIQUID PILL INDICATOR
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutBack,
                            left: currentIndex * tabWidth + 4,
                            width: tabWidth - 8,
                            top: 2,
                            bottom: 2,
                            child: Container(
                              decoration: AppColors.liquidPill,
                            ),
                          ),

                          // TAB ITEMS
                          Row(
                            children: _items.map((item) {
                              final bool isSelected = currentIndex == item.index;

                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => onTap(item.index),
                                  behavior: HitTestBehavior.opaque,
                                  child: _LiquidNavItem(
                                    data: item,
                                    isSelected: isSelected,
                                    isCurrentlyLive: isCurrentlyLive,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
      },
    );
  }
}

class _TabItemData {
  final int index;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isLiveTarget;

  const _TabItemData({
    required this.index,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    this.isLiveTarget = false,
  });
}

class _LiquidNavItem extends StatelessWidget {
  final _TabItemData data;
  final bool isSelected;
  final bool isCurrentlyLive;

  const _LiquidNavItem({
    required this.data,
    required this.isSelected,
    required this.isCurrentlyLive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Icon(
                isSelected ? data.activeIcon : data.inactiveIcon,
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.65),
                size: 24,
                shadows: isSelected
                    ? [
                        Shadow(
                          color: AppColors.accent.withValues(alpha: 0.8),
                          blurRadius: 10,
                        )
                      ]
                    : null,
              ),
            ),

            // Pulsing live class beacon if live (Zero extra streams)
            if (data.isLiveTarget && isCurrentlyLive)
              Positioned(
                top: -2,
                right: -6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.liveRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.liveRed.withValues(alpha: 0.9),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 250),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.60),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 10.5,
            letterSpacing: isSelected ? 0.2 : 0.0,
          ),
          child: Text(data.label),
        ),
      ],
    );
  }
}
