import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../utils/app_colors.dart';
import '../screens/live_class_room.dart';
import '../widgets/doubts_panel.dart';

class HomeTab extends StatefulWidget {
  final String studentName;
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onNotificationsTap;

  const HomeTab({
    super.key,
    required this.studentName,
    this.onNavigateTab,
    this.onNotificationsTap,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        backgroundColor: const Color(0xFF162544),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // ── 1. CLEAN GREETING HEADER ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(alpha: 0.40),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 13, color: AppColors.accent),
                                SizedBox(width: 4),
                                Text(
                                  "SSC 10th BOARD",
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Hello, ${widget.studentName.split(' ')[0]} 👋",
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onNotificationsTap != null) ...[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E293B),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.notifications_active_outlined,
                                color: AppColors.accent,
                                size: 21,
                              ),
                              onPressed: widget.onNotificationsTap,
                              tooltip: "Announcements",
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.primary, AppColors.accent],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.45),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.studentName.isNotEmpty
                                ? widget.studentName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.05),
              ),
            ),

            // ── 2. REAL-TIME LIVE CLASSROOM HERO CARD ────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('live_session')
                      .doc('current')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                      return _buildOfflineCard();
                    }

                    var data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null) return _buildOfflineCard();

                    bool isLive = data['isLive'] == true;
                    String videoIdOrUrl = data['youtubeVideoId']?.toString() ?? '';
                    String title = data['title']?.toString() ?? 'Live Session';

                    if (!isLive || videoIdOrUrl.isEmpty) {
                      return _buildOfflineCard();
                    }

                    String liveVideoId = videoIdOrUrl;
                    if (videoIdOrUrl.contains('http')) {
                      liveVideoId = YoutubePlayer.convertUrlToId(videoIdOrUrl) ?? '';
                    }

                    final String maxResThumbnail =
                        "https://img.youtube.com/vi/$liveVideoId/maxresdefault.jpg";
                    final String hqThumbnail =
                        "https://img.youtube.com/vi/$liveVideoId/hqdefault.jpg";

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Live Classroom",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.liveRed.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.liveRed.withValues(alpha: 0.65),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.liveRed.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _PulsingBeaconDot(),
                                  SizedBox(width: 6),
                                  Text(
                                    "LIVE NOW",
                                    style: TextStyle(
                                      color: AppColors.liveRed,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  transitionDuration: const Duration(milliseconds: 140),
                                  pageBuilder: (_, __, ___) => LiveClassRoom(
                                    userName: widget.studentName,
                                    videoId: liveVideoId,
                                    title: title,
                                    isAdmin: false,
                                  ),
                                  transitionsBuilder: (_, anim, __, child) =>
                                      FadeTransition(opacity: anim, child: child),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: AppColors.liquidGlassCard,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: CachedNetworkImage(
                                            imageUrl: maxResThumbnail,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              color: const Color(0xFF162544),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: AppColors.accent,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => CachedNetworkImage(
                                              imageUrl: hqThumbnail,
                                              fit: BoxFit.cover,
                                              errorWidget: (c, u, e) => Container(
                                                color: const Color(0xFF162544),
                                                child: const Icon(
                                                  Icons.ondemand_video_rounded,
                                                  color: Colors.white38,
                                                  size: 48,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.4),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.liveRed.withValues(alpha: 0.4),
                                                blurRadius: 16,
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(14),
                                          child: const Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                            height: 1.35,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.workspace_premium_rounded,
                                              size: 16,
                                              color: AppColors.accent,
                                            ),
                                            const SizedBox(width: 6),
                                            const Expanded(
                                              child: Text(
                                                "Live Interactive Class",
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [AppColors.primary, AppColors.accent],
                                                ),
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withValues(alpha: 0.35),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                              child: const Row(
                                                children: [
                                                  Text(
                                                    "Join Now",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Icon(
                                                    Icons.arrow_forward_rounded,
                                                    size: 14,
                                                    color: Colors.white,
                                                  ),
                                                ],
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
                          ),
                        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.05),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── 3. 100% FUNCTIONAL INTERACTIVE ACTION HUB ────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3.5,
                          height: 18,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.accent, AppColors.primary],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Quick Learning Hub",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Responsive Quick Action Hub (4 in a row on desktop, 2x2 on mobile)
                    if (MediaQuery.of(context).size.width >= 850)
                      Row(
                        children: [
                          Expanded(
                            child: _buildInteractiveActionCard(
                              icon: Icons.menu_book_rounded,
                              iconColor: const Color(0xFF38BDF8),
                              title: "Study Material",
                              subtitle: "PDF notes & formulas",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onNavigateTab?.call(1);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildInteractiveActionCard(
                              icon: Icons.event_note_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              title: "Class Schedule",
                              subtitle: "Upcoming lectures",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onNavigateTab?.call(2);
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildInteractiveActionCard(
                              icon: Icons.auto_awesome_rounded,
                              iconColor: const Color(0xFFA855F7),
                              title: "NICKS AI Tutor",
                              subtitle: "Instant doubt solver",
                              onTap: _openAiDoubtSolver,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildInteractiveActionCard(
                              icon: Icons.video_library_rounded,
                              iconColor: const Color(0xFF10B981),
                              title: "Recorded Classes",
                              subtitle: "Class archive & recap",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onNavigateTab?.call(2);
                              },
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 350.ms, delay: 100.ms)
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildInteractiveActionCard(
                              icon: Icons.menu_book_rounded,
                              iconColor: const Color(0xFF38BDF8),
                              title: "Study Material",
                              subtitle: "PDF notes & formulas",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onNavigateTab?.call(1);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInteractiveActionCard(
                              icon: Icons.event_note_rounded,
                              iconColor: const Color(0xFFF59E0B),
                              title: "Class Schedule",
                              subtitle: "Upcoming lectures",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onNavigateTab?.call(2);
                              },
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 350.ms, delay: 100.ms),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInteractiveActionCard(
                              icon: Icons.auto_awesome_rounded,
                              iconColor: const Color(0xFFA855F7),
                              title: "NICKS AI Tutor",
                              subtitle: "Instant doubt solver",
                              onTap: _openAiDoubtSolver,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInteractiveActionCard(
                              icon: Icons.video_library_rounded,
                              iconColor: const Color(0xFF10B981),
                              title: "Recorded Classes",
                              subtitle: "Class archive & recap",
                              onTap: () {
                                HapticFeedback.lightImpact();
                                widget.onNavigateTab?.call(2);
                              },
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 350.ms, delay: 150.ms),
                    ],
                  ],
                ),
              ),
            ),

            // ── 4. UPCOMING LECTURE PREVIEW (Live Sync with admin.html) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    22, 10, 22, MediaQuery.of(context).size.width >= 850 ? 40 : 120),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('live_session')
                      .doc('upcoming')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const SizedBox.shrink();
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null) return const SizedBox.shrink();

                    final title = data['title']?.toString() ?? '';
                    final subject = data['subject']?.toString() ?? 'Maharashtra SSC Board';
                    final scheduledTime = data['time']?.toString() ?? '';

                    if (title.isEmpty) return const SizedBox.shrink();

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: AppColors.liquidGlassCard,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "UPCOMING",
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.accent,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      scheduledTime.isNotEmpty ? "• $scheduledTime" : "",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subject,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accent),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              widget.onNavigateTab?.call(2);
                            },
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Clean card when no class is live ─────────────────────────────────────
  Widget _buildOfflineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: AppColors.liquidGlassCard,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.tv_off_rounded,
              size: 32,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "No Active Live Broadcast",
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Check scheduled upcoming lectures or solve academic doubts with AI.",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }

  Widget _buildInteractiveActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: AppColors.liquidGlassCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingBeaconDot extends StatefulWidget {
  const _PulsingBeaconDot();

  @override
  State<_PulsingBeaconDot> createState() => _PulsingBeaconDotState();
}

class _PulsingBeaconDotState extends State<_PulsingBeaconDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.liveRed.withValues(alpha: 0.5 + (_controller.value * 0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.liveRed.withValues(alpha: _controller.value * 0.8),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
