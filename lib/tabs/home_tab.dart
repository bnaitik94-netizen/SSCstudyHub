import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';
import '../screens/live_class_room.dart';
import '../widgets/doubts_panel.dart';

class HomeTab extends StatefulWidget {
  final String studentName;
  final ValueChanged<int>? onNavigateTab;

  const HomeTab({
    super.key,
    required this.studentName,
    this.onNavigateTab,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return "Good morning";
    if (hour >= 12 && hour < 17) return "Good afternoon";
    if (hour >= 17 && hour < 21) return "Good evening";
    return "Good night";
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {});
  }

  void _openAiDoubtSolver() {
    HapticFeedback.mediumImpact();
    AppBottomSheet.show(
      context: context,
      title: "NICKS AI Tutor",
      builder: (ctx, scrollController) => const DoubtsPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            // ── 1. GREETING & PROFILE BAR ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _getGreeting(),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const AppBadge(
                                label: "SSC 2026",
                                variant: AppBadgeVariant.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.studentName.split(' ')[0],
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AppAvatar(
                      name: widget.studentName,
                      size: 44,
                      hasGradientRing: true,
                    ),
                  ],
                ),
              ),
            ),

            // ── 2. REAL-TIME LIVE CLASS HERO ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.xs,
                ),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('live_session')
                      .doc('current')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                      return _buildStandbyCard(context);
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                    if (data == null) return _buildStandbyCard(context);

                    final bool isLive = data['isLive'] == true;
                    final String videoIdOrUrl = data['youtubeVideoId']?.toString() ?? '';
                    final String title = data['title']?.toString() ?? 'Live Session';

                    if (!isLive || videoIdOrUrl.isEmpty) {
                      return _buildStandbyCard(context);
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
                        const AppSectionHeader(
                          title: "Live Classroom",
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          trailing: AppBadge(
                            label: "LIVE NOW",
                            variant: AppBadgeVariant.error,
                            icon: Icon(Icons.circle, size: 8),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppCard(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LiveClassRoom(
                                  userName: widget.studentName,
                                  videoId: liveVideoId,
                                  title: title,
                                  isAdmin: false,
                                ),
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppSpacing.radiusMd),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: CachedNetworkImage(
                                        imageUrl: maxResThumbnail,
                                        fit: BoxFit.cover,
                                        // PERF: Prevent memory bloat on low-end devices
                                        memCacheWidth: 640,
                                        memCacheHeight: 360,
                                        fadeInDuration: const Duration(milliseconds: 200),
                                        placeholder: (context, url) => const AppLoadingShimmer(
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                        errorWidget: (context, url, error) => CachedNetworkImage(
                                          imageUrl: hqThumbnail,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 640,
                                          memCacheHeight: 360,
                                          errorWidget: (c, u, e) => Container(
                                            color: theme.colorScheme.surfaceContainer,
                                            child: const Center(
                                              child: Icon(Icons.ondemand_video_rounded, size: 48),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 36,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.sensors_rounded,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        Expanded(
                                          child: Text(
                                            "Interactive Broadcast with Live Chat",
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        AppButton.filled(
                                          label: "Join Now",
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => LiveClassRoom(
                                                  userName: widget.studentName,
                                                  videoId: liveVideoId,
                                                  title: title,
                                                  isAdmin: false,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── 3. QUICK LEARNING HUB ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      title: "Quick Hub",
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Responsive Grid/Row of 4 actions
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 600;
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                child: _buildActionTile(
                                  icon: Icons.menu_book_rounded,
                                  title: "Study Material",
                                  subtitle: "Notes & formulas",
                                  onTap: () => widget.onNavigateTab?.call(1),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildActionTile(
                                  icon: Icons.calendar_today_rounded,
                                  title: "Class Schedule",
                                  subtitle: "Timetable & dates",
                                  onTap: () => widget.onNavigateTab?.call(2),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildActionTile(
                                  icon: Icons.auto_awesome_rounded,
                                  title: "AI Tutor",
                                  subtitle: "Doubt solver",
                                  onTap: _openAiDoubtSolver,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: _buildActionTile(
                                  icon: Icons.video_library_rounded,
                                  title: "Past Lectures",
                                  subtitle: "Archive & recap",
                                  onTap: () => widget.onNavigateTab?.call(2),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionTile(
                                    icon: Icons.menu_book_rounded,
                                    title: "Study Material",
                                    subtitle: "Notes & formulas",
                                    onTap: () => widget.onNavigateTab?.call(1),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _buildActionTile(
                                    icon: Icons.calendar_today_rounded,
                                    title: "Schedule",
                                    subtitle: "Upcoming classes",
                                    onTap: () => widget.onNavigateTab?.call(2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildActionTile(
                                    icon: Icons.auto_awesome_rounded,
                                    title: "AI Tutor",
                                    subtitle: "Instant solver",
                                    onTap: _openAiDoubtSolver,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _buildActionTile(
                                    icon: Icons.video_library_rounded,
                                    title: "Past Classes",
                                    subtitle: "Video archives",
                                    onTap: () => widget.onNavigateTab?.call(2),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── 4. UPCOMING SCHEDULE PREVIEW ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
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
                    final subject = data['subject']?.toString() ?? 'Maharashtra State Board';
                    final scheduledTime = data['time']?.toString() ?? '';

                    if (title.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSectionHeader(
                          title: "Upcoming Class",
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          trailing: TextButton(
                            onPressed: () => widget.onNavigateTab?.call(2),
                            child: const Text("View All"),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppCard(
                          onTap: () => widget.onNavigateTab?.call(2),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                ),
                                child: Icon(
                                  Icons.event_note_rounded,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (scheduledTime.isNotEmpty) ...[
                                      Text(
                                        scheduledTime,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Text(
                                      title,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      subject,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxxl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandbyCard(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard.primary(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Live Classroom",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const AppBadge(
                label: "OFFLINE",
                variant: AppBadgeVariant.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            "No live stream broadcast active right now. Browse notes or ask the AI doubt solver.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppButton.outlined(
                label: "Schedule",
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                onPressed: () => widget.onNavigateTab?.call(2),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.filled(
                label: "AI Tutor",
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                onPressed: _openAiDoubtSolver,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return AppCard.data(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primaryAccent,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
