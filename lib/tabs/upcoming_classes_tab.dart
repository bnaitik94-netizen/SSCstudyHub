import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/widgets/app_widgets.dart';
import '../screens/past_class_player.dart';
import '../screens/live_class_room.dart';

class UpcomingClassesTab extends StatefulWidget {
  const UpcomingClassesTab({super.key});

  @override
  State<UpcomingClassesTab> createState() => _UpcomingClassesTabState();
}

class _UpcomingClassesTabState extends State<UpcomingClassesTab> {
  int _filterIndex = 0; // 0: All, 1: Scheduled, 2: Recorded

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Class Schedule"),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // M3 Segmented Button Filter
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<int>(
                        segments: const [
                          ButtonSegment<int>(
                            value: 0,
                            label: Text("All"),
                            icon: Icon(Icons.apps_rounded, size: 16),
                          ),
                          ButtonSegment<int>(
                            value: 1,
                            label: Text("Scheduled"),
                            icon: Icon(Icons.event_note_rounded, size: 16),
                          ),
                          ButtonSegment<int>(
                            value: 2,
                            label: Text("Recorded"),
                            icon: Icon(Icons.video_library_rounded, size: 16),
                          ),
                        ],
                        selected: {_filterIndex},
                        onSelectionChanged: (newSelection) {
                          HapticFeedback.selectionClick();
                          setState(() => _filterIndex = newSelection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (_filterIndex == 0 || _filterIndex == 1) ...[
                      const AppSectionHeader(
                        title: "Next Scheduled Lecture",
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      const _UpcomingStreamCard(),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    if (_filterIndex == 0 || _filterIndex == 2) ...[
                      const AppSectionHeader(
                        title: "Recorded Lecture Archives",
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
            ),
            if (_filterIndex == 0 || _filterIndex == 2)
              const _PastClassesList(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingStreamCard extends StatefulWidget {
  const _UpcomingStreamCard();

  @override
  State<_UpcomingStreamCard> createState() => _UpcomingStreamCardState();
}

class _UpcomingStreamCardState extends State<_UpcomingStreamCard> {
  static final Map<String, bool> _reminderMemoryCache = {};
  bool _isReminderSet = false;
  String _currentUpcomingId = '';

  Future<void> _loadReminderState(String lectureId) async {
    if (_reminderMemoryCache.containsKey(lectureId)) {
      final cached = _reminderMemoryCache[lectureId]!;
      if (_isReminderSet != cached) {
        setState(() => _isReminderSet = cached);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('reminder_$lectureId') ?? false;
    _reminderMemoryCache[lectureId] = saved;
    if (mounted && _isReminderSet != saved) {
      setState(() => _isReminderSet = saved);
    }
  }

  Future<void> _toggleRemindMe(String lectureId, String lectureTitle, String lectureTime) async {
    final newState = !_isReminderSet;
    _reminderMemoryCache[lectureId] = newState;

    if (mounted) {
      setState(() => _isReminderSet = newState);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_$lectureId', newState);

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newState
              ? "Reminder set for '$lectureTitle'"
              : "Reminder removed for '$lectureTitle'",
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _joinLiveClass(String videoId, String? title) async {
    final prefs = await SharedPreferences.getInstance();
    final studentName = prefs.getString('studentName') ?? prefs.getString('student_name') ?? 'Student';
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveClassRoom(
            userName: studentName,
            videoId: videoId,
            title: title ?? "Live Lecture",
            isAdmin: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_session')
          .doc('upcoming')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();

        if (!snapshot.hasData) {
          return const AppLoadingShimmer.card(height: 200);
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;

        if (data == null ||
            data.isEmpty ||
            (data['title'] ?? '').toString().trim().isEmpty) {
          return const AppEmptyState(
            icon: Icons.event_available_rounded,
            title: "No upcoming lectures scheduled",
            subtitle: "Check back later or watch past recorded classes below.",
          );
        }

        final String title = data['title'] ?? 'Upcoming Lecture';
        final String lectureTime = data['time'] ?? 'Time TBA';
        final String subject = data['subject'] ?? 'General';
        final String videoIdOrUrl = (data['youtubeVideoId'] ?? data['youtubeUrl'] ?? '').toString();
        final String cleanId = videoIdOrUrl.contains('http')
            ? (YoutubePlayer.convertUrlToId(videoIdOrUrl) ?? '')
            : videoIdOrUrl;

        final String lectureId = cleanId.isNotEmpty ? cleanId : title;
        if (lectureId != _currentUpcomingId) {
          _currentUpcomingId = lectureId;
          _loadReminderState(lectureId);
        }

        final String? thumbnail = cleanId.isNotEmpty
            ? "https://img.youtube.com/vi/$cleanId/hqdefault.jpg"
            : null;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('live_session')
              .doc('current')
              .snapshots(),
          builder: (context, currentSnap) {
            final currentData = currentSnap.data?.data() as Map<String, dynamic>?;
            final bool isClassCurrentlyLive = currentData?['isLive'] == true &&
                (cleanId.isNotEmpty && currentData?['youtubeVideoId'] == cleanId ||
                    currentData?['title'] == title);

            return AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thumbnail != null)
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
                              imageUrl: thumbnail,
                              fit: BoxFit.cover,
                              memCacheWidth: 640,
                              memCacheHeight: 360,
                              placeholder: (context, url) => const AppLoadingShimmer(
                                width: double.infinity,
                                height: double.infinity,
                              ),
                              errorWidget: (c, u, e) => Container(
                                color: theme.colorScheme.surfaceContainer,
                                child: const Center(
                                  child: Icon(Icons.school_rounded, size: 40),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: AppSpacing.sm,
                            left: AppSpacing.sm,
                            child: AppBadge(
                              label: isClassCurrentlyLive ? "LIVE NOW" : "SCHEDULED",
                              variant: isClassCurrentlyLive
                                  ? AppBadgeVariant.error
                                  : AppBadgeVariant.info,
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
                        Row(
                          children: [
                            AppBadge(
                              label: subject,
                              variant: AppBadgeVariant.neutral,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lectureTime,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        isClassCurrentlyLive
                            ? AppButton.filled(
                                label: "Class is Live — Join Now",
                                icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                                isFullWidth: true,
                                onPressed: () => _joinLiveClass(cleanId, title),
                              )
                            : AppButton.outlined(
                                label: _isReminderSet ? "Reminder Set" : "Remind Me",
                                icon: Icon(
                                  _isReminderSet
                                      ? Icons.check_circle_rounded
                                      : Icons.notifications_active_outlined,
                                  size: 18,
                                ),
                                isFullWidth: true,
                                onPressed: () => _toggleRemindMe(lectureId, title, lectureTime),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PastClassesList extends StatelessWidget {
  const _PastClassesList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('past_classes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: Center(child: Text("Failed to load records")),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.screenHorizontal),
              child: AppLoadingShimmer.card(height: 80),
            ),
          );
        }

        final pastDocs = snapshot.data!.docs;

        if (pastDocs.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.screenHorizontal,
                vertical: AppSpacing.lg,
              ),
              child: AppEmptyState(
                icon: Icons.video_collection_outlined,
                title: "No recorded classes yet",
                subtitle: "Recorded sessions will appear here after live broadcasts end.",
              ),
            ),
          );
        }

        final bool isDesktop = MediaQuery.sizeOf(context).width >= 850;

        Widget buildPastClassCard(Map<String, dynamic> data) {
          DateTime? date;
          if (data['timestamp'] != null) {
            date = (data['timestamp'] as Timestamp).toDate();
          }
          final String formattedDate = date != null
              ? DateFormat('dd MMM, yyyy • hh:mm a').format(date)
              : "Recently recorded";

          final rawVideoId = data['youtubeVideoId']?.toString() ?? '';
          final cleanVideoId = rawVideoId.contains('http')
              ? (YoutubePlayer.convertUrlToId(rawVideoId) ?? rawVideoId)
              : rawVideoId;

          return RepaintBoundary(
            child: AppCard.listItem(
              onTap: () {
                if (cleanVideoId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PastClassPlayerScreen(
                        videoId: cleanVideoId,
                        title: data['title'] ?? 'Recorded Class',
                        restoreOrientations: const [
                          DeviceOrientation.portraitUp,
                          DeviceOrientation.portraitDown,
                        ],
                      ),
                    ),
                  );
                }
              },
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primaryAccent,
                  size: 22,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Recorded Class',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (isDesktop) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.sm,
            ),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 72,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => buildPastClassCard(
                  pastDocs[index].data() as Map<String, dynamic>,
                ),
                childCount: pastDocs.length,
                addRepaintBoundaries: true,
                addAutomaticKeepAlives: false,
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.xs,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.listItemGap),
                child: buildPastClassCard(
                  pastDocs[index].data() as Map<String, dynamic>,
                ),
              ),
              childCount: pastDocs.length,
              addRepaintBoundaries: true,
              addAutomaticKeepAlives: false,
            ),
          ),
        );
      },
    );
  }
}
