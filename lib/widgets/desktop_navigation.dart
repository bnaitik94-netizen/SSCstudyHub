import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';

class DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final String studentName;
  final bool isCurrentlyLive;
  final String liveTitle;
  final VoidCallback onOpenAiDoubts;
  final VoidCallback onOpenLiveClass;

  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.studentName,
    required this.isCurrentlyLive,
    required this.liveTitle,
    required this.onOpenAiDoubts,
    required this.onOpenLiveClass,
  });

  static const List<_SidebarNavEntry> _navEntries = [
    _SidebarNavEntry(
      index: 0,
      title: "Home",
      subtitle: "Overview & Daily Goals",
      icon: Icons.home_rounded,
      activeIcon: Icons.home_filled,
      tooltip: "Home (Ctrl+1)",
    ),
    _SidebarNavEntry(
      index: 1,
      title: "Study Material",
      subtitle: "Syllabus, PDFs & Notes",
      icon: Icons.menu_book_rounded,
      activeIcon: Icons.menu_book,
      tooltip: "Study Material (Ctrl+2)",
    ),
    _SidebarNavEntry(
      index: 2,
      title: "Live Schedule",
      subtitle: "Lectures & Recordings",
      icon: Icons.play_circle_fill_rounded,
      activeIcon: Icons.play_circle_rounded,
      tooltip: "Live Schedule (Ctrl+3)",
      isLiveTarget: true,
    ),
    _SidebarNavEntry(
      index: 3,
      title: "Profile",
      subtitle: "Analytics & Settings",
      icon: Icons.person_rounded,
      activeIcon: Icons.person,
      tooltip: "Student Profile (Ctrl+4)",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double sidebarWidth = isExpanded ? 256.0 : 76.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.97),
        border: const Border(
          right: BorderSide(color: Colors.white12, width: 1.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BRAND HEADER & COLLAPSE TOGGLE ────────────────────────────────
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white10, width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.school_rounded, color: Colors.white, size: 20),
                  ),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SSC STUDY HUB",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Class 10th Board • Pro",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  tooltip: isExpanded ? "Collapse Sidebar (Ctrl+B)" : "Expand Sidebar (Ctrl+B)",
                  onPressed: onToggleExpand,
                  splashRadius: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          // ── LIVE BROADCAST ALERT (If Live Stream is Active) ────────────────
          if (isCurrentlyLive)
            Padding(
              padding: EdgeInsets.all(isExpanded ? 12.0 : 8.0),
              child: InkWell(
                onTap: onOpenLiveClass,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 12 : 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: isExpanded
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (isExpanded) ...[
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CLASS IN PROGRESS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                "Join Live Lecture",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // ── NAVIGATION ITEMS LIST ─────────────────────────────────────────
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? 10 : 8),
              itemCount: _navEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final entry = _navEntries[index];
                final isSelected = currentIndex == entry.index;

                final itemWidget = _SidebarNavItem(
                  entry: entry,
                  isSelected: isSelected,
                  isExpanded: isExpanded,
                  isCurrentlyLive: isCurrentlyLive && entry.isLiveTarget,
                  onTap: () => onTabSelected(entry.index),
                );

                if (!isExpanded) {
                  return Tooltip(
                    message: entry.tooltip,
                    preferBelow: false,
                    verticalOffset: 20,
                    margin: const EdgeInsets.only(left: 80),
                    child: itemWidget,
                  );
                }
                return itemWidget;
              },
            ),
          ),

          // ── QUICK AI DOUBT SOLVER BUTTON (When Expanded) ──────────────────
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: InkWell(
                onTap: onOpenAiDoubts,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.18),
                        AppColors.accent.withValues(alpha: 0.12),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ask AI Doubt",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                            Text(
                              "Instant Study Assistant",
                              style: TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white60, size: 16),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Tooltip(
                message: "Ask AI Doubt Assistant",
                preferBelow: false,
                margin: const EdgeInsets.only(left: 80),
                child: InkWell(
                  onTap: onOpenAiDoubts,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

          // ── USER PROFILE SECTION (FOOTER) ─────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 14 : 10,
              vertical: 12,
            ),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white10, width: 1.0),
              ),
            ),
            child: InkWell(
              onTap: () => onTabSelected(3),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              "Class 10 Student",
                              style: TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.settings_outlined,
                        color: Colors.white60,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final _SidebarNavEntry entry;
  final bool isSelected;
  final bool isExpanded;
  final bool isCurrentlyLive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.entry,
    required this.isSelected,
    required this.isExpanded,
    required this.isCurrentlyLive,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isExpanded = widget.isExpanded;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          padding: EdgeInsets.symmetric(
            horizontal: isExpanded ? 12 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.22)
                : (_isHovered
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : (_isHovered
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              // Active Indicator Bar (Left Edge)
              if (isSelected && isExpanded)
                Container(
                  width: 3.5,
                  height: 20,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),

              // Icon with Beacon
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    isSelected ? widget.entry.activeIcon : widget.entry.icon,
                    size: 20,
                    color: isSelected
                        ? AppColors.accent
                        : (_isHovered ? Colors.white : Colors.white70),
                  ),
                  if (widget.isCurrentlyLive)
                    Positioned(
                      top: -2,
                      right: -3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.liveRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.liveRed.withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Label & Subtitle (When Expanded)
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (_isHovered ? Colors.white : Colors.white70),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.entry.subtitle,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textSecondary.withValues(alpha: 0.8)
                              : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.isCurrentlyLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.liveRed,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DesktopTopBar extends StatelessWidget {
  final int currentIndex;
  final String studentName;
  final bool isCurrentlyLive;
  final String liveTitle;
  final bool isSidebarExpanded;
  final VoidCallback onToggleSidebar;
  final VoidCallback onOpenAiDoubts;
  final VoidCallback onOpenLiveClass;
  final VoidCallback onNotificationsTap;
  final ValueChanged<int> onTabSelected;

  const DesktopTopBar({
    super.key,
    required this.currentIndex,
    required this.studentName,
    required this.isCurrentlyLive,
    required this.liveTitle,
    required this.isSidebarExpanded,
    required this.onToggleSidebar,
    required this.onOpenAiDoubts,
    required this.onOpenLiveClass,
    required this.onNotificationsTap,
    required this.onTabSelected,
  });

  String get _currentTabTitle {
    switch (currentIndex) {
      case 0:
        return "Home Overview";
      case 1:
        return "Study Material & Syllabus";
      case 2:
        return "Live Schedule & Archives";
      case 3:
        return "Student Profile & Analytics";
      default:
        return "Dashboard";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: Colors.white12, width: 1.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sidebar Toggle Button
          IconButton(
            icon: Icon(
              isSidebarExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: Colors.white70,
              size: 20,
            ),
            tooltip: isSidebarExpanded ? "Collapse Sidebar" : "Expand Sidebar",
            onPressed: onToggleSidebar,
            splashRadius: 20,
          ),
          const SizedBox(width: 8),

          // Breadcrumb Title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Dashboard",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right_rounded, color: Colors.white38, size: 16),
              ),
              Text(
                _currentTabTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Live Broadcast Alert (Center / Right)
          if (isCurrentlyLive) ...[
            InkWell(
              onTap: onOpenLiveClass,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: Text(
                        "LIVE: $liveTitle",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],

          // Quick AI Doubt Pill
          InkWell(
            onTap: onOpenAiDoubts,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 15),
                  SizedBox(width: 6),
                  Text(
                    "AI Doubt Solver",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Notification Bell
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white70, size: 20),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: "Notifications & Updates",
            onPressed: onNotificationsTap,
            splashRadius: 20,
          ),
          const SizedBox(width: 6),

          // Platform Mode Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.dark_mode_rounded, color: AppColors.accent, size: 13),
                SizedBox(width: 5),
                Text(
                  "Dark Pro",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Profile Pill
          InkWell(
            onTap: () => onTabSelected(3),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavEntry {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
  final bool isLiveTarget;

  const _SidebarNavEntry({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
    this.isLiveTarget = false,
  });
}
