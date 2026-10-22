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
      title: "Student Profile",
      subtitle: "Analytics & Settings",
      icon: Icons.person_rounded,
      activeIcon: Icons.person,
      tooltip: "Student Profile (Ctrl+4)",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double sidebarWidth = isExpanded ? 260.0 : 76.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: sidebarWidth,
      decoration: const BoxDecoration(
        color: Color(0xFF0B101E),
        border: Border(
          right: BorderSide(color: Color(0xFF1E293B), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BRAND HEADER & COLLAPSE BUTTON ────────────────────────────────
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x4D4F46E5),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.school_rounded, color: Colors.white, size: 21),
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
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Class 10th Board • Pro",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
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
                    color: const Color(0xFF94A3B8),
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

          // ── LIVE CLASS BROADCAST ALERT ────────────────────────────────────
          if (isCurrentlyLive)
            Padding(
              padding: EdgeInsets.all(isExpanded ? 12.0 : 8.0),
              child: InkWell(
                onTap: onOpenLiveClass,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isExpanded ? 12 : 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66DC2626),
                        blurRadius: 10,
                        offset: Offset(0, 3),
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
                                "LIVE IN PROGRESS",
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

          // ── NAVIGATION SECTION HEADER ─────────────────────────────────────
          if (isExpanded)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "NAVIGATION",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            )
          else
            const SizedBox(height: 12),

          // ── NAVIGATION ITEMS LIST ─────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? 10 : 8),
              itemCount: _navEntries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 5),
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

          // ── QUICK AI DOUBT SOLVER CARD ────────────────────────────────────
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: InkWell(
                onTap: onOpenAiDoubts,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0x264F46E5), Color(0x1A06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0x4D6366F1),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x336366F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF38BDF8),
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
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 16),
                    ],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Tooltip(
                message: "Ask AI Doubt Assistant (Ctrl+K)",
                preferBelow: false,
                margin: const EdgeInsets.only(left: 80),
                child: InkWell(
                  onTap: onOpenAiDoubts,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: const Color(0x264F46E5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x4D6366F1)),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF38BDF8),
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
                top: BorderSide(color: Color(0xFF1E293B), width: 1.0),
              ),
            ),
            child: InkWell(
              onTap: () => onTabSelected(3),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
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
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0B101E), width: 1.5),
                            ),
                          ),
                        ),
                      ],
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
                              "Class 10 Student • Online",
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
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
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (_isHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x404F46E5),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment:
                isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              // Icon with Beacon
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    isSelected ? widget.entry.activeIcon : widget.entry.icon,
                    size: 20,
                    color: isSelected
                        ? Colors.white
                        : (_isHovered ? Colors.white : const Color(0xFF94A3B8)),
                  ),
                  if (widget.isCurrentlyLive)
                    Positioned(
                      top: -2,
                      right: -3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.liveRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xCCFF2A4B),
                              blurRadius: 6,
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
                              : (_isHovered ? Colors.white : const Color(0xFFE2E8F0)),
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.entry.subtitle,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFC7D2FE) : const Color(0xFF64748B),
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
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
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
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
            tooltip: isSidebarExpanded ? "Collapse Sidebar (Ctrl+B)" : "Expand Sidebar (Ctrl+B)",
            onPressed: onToggleSidebar,
            splashRadius: 20,
          ),
          const SizedBox(width: 8),

          // Breadcrumbs
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dashboard_rounded, color: Color(0xFF38BDF8), size: 15),
              const SizedBox(width: 6),
              const Text(
                "Dashboard",
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  "/",
                  style: TextStyle(color: Color(0xFF475569), fontSize: 13),
                ),
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

          // Search Pill (Direct shortcut to Study Material Tab)
          InkWell(
            onTap: () => onTabSelected(1),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 220,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Search syllabus & notes...",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    "Ctrl+2",
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Live Broadcast Alert (If live)
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
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66DC2626),
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
                      constraints: const BoxConstraints(maxWidth: 200),
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
            const SizedBox(width: 12),
          ],

          // Quick AI Doubt Pill
          InkWell(
            onTap: onOpenAiDoubts,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0x264F46E5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x4D6366F1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 15),
                  SizedBox(width: 6),
                  Text(
                    "AI Doubt",
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
                const Icon(Icons.notifications_outlined, color: Color(0xFF94A3B8), size: 20),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: "Announcements & Updates",
            onPressed: onNotificationsTap,
            splashRadius: 20,
          ),
          const SizedBox(width: 6),

          // Platform Mode Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0x1A10B981),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x3310B981)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 12),
                SizedBox(width: 4),
                Text(
                  "SSC 2026",
                  style: TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Profile Pill
          InkWell(
            onTap: () => onTabSelected(3),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF1E293B)),
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
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8), size: 16),
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
