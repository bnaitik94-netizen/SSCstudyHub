import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../screens/past_class_player.dart';
import '../screens/live_class_room.dart';

class UpcomingClassesTab extends StatefulWidget {
  const UpcomingClassesTab({super.key});

  @override
  State<UpcomingClassesTab> createState() => _UpcomingClassesTabState();
}

class _UpcomingClassesTabState extends State<UpcomingClassesTab> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          "Schedule & Recorded",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceDark,
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 22.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event_note_rounded,
                            size: 18, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          "Next Scheduled Lecture",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    _UpcomingStreamCard(),
                    SizedBox(height: 28),
                    Row(
                      children: [
                        Icon(Icons.video_library_rounded,
                            size: 18, color: AppColors.primaryLight),
                        SizedBox(width: 8),
                        Text(
                          "Recorded Classes & Archives",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            _PastClassesList(),
            SliverToBoxAdapter(
              child: SizedBox(height: 120), // Clearance for floating liquid glass tab bar
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
    // 1. Instant Synchronous Memory Read (0ms latency, eliminates flicker)
    if (_reminderMemoryCache.containsKey(lectureId)) {
      final cached = _reminderMemoryCache[lectureId]!;
      if (_isReminderSet != cached) {
        setState(() => _isReminderSet = cached);
      }
    }

    // 2. Disk Verification
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
      setState(() {
        _isReminderSet = newState;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_$lectureId', newState);

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              newState ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                newState
                    ? "Reminder Saved! You will be alerted when '$lectureTitle' begins."
                    : "Reminder removed for '$lectureTitle'.",
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: newState ? const Color(0xFF10B981) : const Color(0xFF475569),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _joinLiveClass(String videoId, String? title) async {
    final prefs = await SharedPreferences.getInstance();
    final studentName = prefs.getString('studentName') ?? prefs.getString('student_name') ?? 'Student';
    if (mounted) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 140),
          pageBuilder: (_, __, ___) => LiveClassRoom(
            userName: studentName,
            videoId: videoId,
            title: title ?? "Live Lecture",
            isAdmin: false,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_session')
          .doc('upcoming')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();

        if (!snapshot.hasData) {
          return Shimmer.fromColors(
            baseColor: Colors.white10,
            highlightColor: Colors.white24,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          );
        }

        var data = snapshot.data?.data() as Map<String, dynamic>?;

        if (data == null ||
            data.isEmpty ||
            (data['title'] ?? '').toString().trim().isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
            decoration: AppColors.liquidGlassCard,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    size: 34,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "No upcoming lectures scheduled.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Check back later or watch recorded past lectures below.",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms);
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

            return Container(
              width: double.infinity,
              decoration: AppColors.liquidGlassCard,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Stack(
                      children: [
                        if (thumbnail != null)
                          AspectRatio(
                            aspectRatio: 16 / 8.5,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CachedNetworkImage(
                                  imageUrl: thumbnail,
                                  fit: BoxFit.cover,
                                  errorWidget: (c, u, e) => Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.cosmicBlueVibrant,
                                          AppColors.cosmicIndigo,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.2),
                                        Colors.black.withValues(alpha: 0.65),
                                      ],
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: (isClassCurrentlyLive ? AppColors.liveRed : AppColors.primary)
                                          .withValues(alpha: 0.85),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isClassCurrentlyLive ? AppColors.liveRed : AppColors.accent)
                                              .withValues(alpha: 0.5),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isClassCurrentlyLive ? Icons.play_arrow_rounded : Icons.schedule_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            height: 120,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cosmicBlueVibrant,
                                  AppColors.cosmicIndigo,
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.school_rounded,
                                  size: 44, color: Colors.white30),
                            ),
                          ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isClassCurrentlyLive
                                  ? AppColors.liveRed
                                  : Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isClassCurrentlyLive
                                    ? Colors.white
                                    : AppColors.accent.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              boxShadow: [
                                if (isClassCurrentlyLive)
                                  BoxShadow(
                                    color: AppColors.liveRed.withValues(alpha: 0.6),
                                    blurRadius: 10,
                                  ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isClassCurrentlyLive ? Icons.sensors_rounded : Icons.stars_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isClassCurrentlyLive ? "LIVE NOW" : "SCHEDULED PREMIERE",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10.5,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(Icons.school_rounded,
                                  color: AppColors.accent, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          subject,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.access_time_rounded,
                                          size: 13, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          lectureTime,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: isClassCurrentlyLive
                              ? ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.liveRed,
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: AppColors.liveRed.withValues(alpha: 0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                                  label: const Text(
                                    "CLASS IS LIVE — JOIN NOW",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  onPressed: () => _joinLiveClass(cleanId, title),
                                )
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isReminderSet
                                        ? const Color(0xFF10B981)
                                        : AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: _isReminderSet
                                            ? const Color(0xFF34D399)
                                            : AppColors.primaryLight.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                  ),
                                  icon: Icon(
                                    _isReminderSet
                                        ? Icons.check_circle_rounded
                                        : Icons.notifications_active_outlined,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _isReminderSet ? "Reminder Active (Tap to remove)" : "Remind Me",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onPressed: () => _toggleRemindMe(lectureId, title, lectureTime),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ).animate().slideY(begin: 0.05, duration: 400.ms).fadeIn();
      },
    );
  }
}

class _PastClassesList extends StatelessWidget {
  const _PastClassesList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('past_classes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
                child: Text(
                  "Failed to load records.",
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }

        var pastDocs = snapshot.data!.docs;

        if (pastDocs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: AppColors.liquidGlassCard,
                child: const Column(
                  children: [
                    Icon(Icons.video_collection_outlined,
                        size: 36, color: Colors.white38),
                    SizedBox(height: 10),
                    Text(
                      "No past classes available yet.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              var data = pastDocs[index].data() as Map<String, dynamic>;
              DateTime? date;
              if (data['timestamp'] != null) {
                date = (data['timestamp'] as Timestamp).toDate();
              }
              String formattedDate = date != null
                  ? DateFormat('dd MMM, yyyy • hh:mm a').format(date)
                  : "Recently added";

              final rawVideoId = data['youtubeVideoId']?.toString() ?? '';
              final cleanVideoId = rawVideoId.contains('http')
                  ? (YoutubePlayer.convertUrlToId(rawVideoId) ?? rawVideoId)
                  : rawVideoId;

              return Container(
                margin: const EdgeInsets.only(left: 22, right: 22, bottom: 12),
                decoration: AppColors.liquidGlassCard,
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      data['title'] ?? 'Recorded Class',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                    ),
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
                  ),
                ),
              )
                  .animate()
                  .slideY(begin: 0.05, duration: 300.ms)
                  .fadeIn(delay: Duration(milliseconds: 30 * index));
            },
            childCount: pastDocs.length,
          ),
        );
      },
    );
  }
}
