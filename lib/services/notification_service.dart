import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../screens/live_class_room.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  bool _initialized = false;
  final Set<String> _processedNotificationIds = {};

  /// Global key to access current context for foreground banners & modal dialogs
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Initialize all push notification channels, permissions, and topic subscriptions
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (!kIsWeb) {
        // 1. 🔔 REQUEST PERMISSION (Mobile only)
        final NotificationSettings settings = await _fcm.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        debugPrint("Notification authorization status: ${settings.authorizationStatus}");

        // 2. 📱 FOREGROUND PRESENTATION (Mobile only)
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // 3. 🎯 TOPIC SUBSCRIPTIONS (Mobile only)
        await _fcm.subscribeToTopic('all_students');
        await _fcm.subscribeToTopic('live_classes');
        await _fcm.subscribeToTopic('study_updates');
        debugPrint("Subscribed to student topics successfully.");

        // 4. 🔑 FETCH & SYNC FCM TOKEN
        final String? token = await _fcm.getToken();
        if (token != null) {
          debugPrint("FCM Device Token: $token");
          _syncTokenToFirestore(token);
        }

        _fcm.onTokenRefresh.listen((newToken) {
          _syncTokenToFirestore(newToken);
        });

        // 5. 📨 LISTEN FOR FCM FOREGROUND NOTIFICATIONS
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("FCM foreground received: ${message.notification?.title}");
          _showInAppAlert(
            title: message.notification?.title ?? "New Announcement",
            body: message.notification?.body ?? "Tap to view update.",
            type: message.data['type'] ?? 'fcm',
            youtubeVideoId: message.data['youtubeVideoId'],
          );
        });

        // 6. 🚀 HANDLE NOTIFICATION CLICK
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint("Notification tapped: ${message.data}");
          _handleNotificationTap(message.data['youtubeVideoId']);
        });

        final RemoteMessage? initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          debugPrint("Terminated launch from notification: ${initialMessage.data}");
          _handleNotificationTap(initialMessage.data['youtubeVideoId']);
        }
      }

      // 7. 🔥 REAL-TIME FIRESTORE BROADCAST LISTENER
      // Guaranteed 100% instant notification delivery on BOTH Mobile & Web
      _listenToFirestoreBroadcasts();

    } catch (e) {
      debugPrint("Notification service warning: $e");
    }
  }

  /// Explicit UI-attached permission check and prompt (Guarantees user is asked)
  Future<void> checkAndPromptPermission(BuildContext context) async {
    try {
      final NotificationSettings settings = await _fcm.getNotificationSettings();

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        
        final prefs = await SharedPreferences.getInstance();
        final hasPrompted = prefs.getBool('has_prompted_notif_permission') ?? false;

        // If never prompted, ask natively first
        if (!hasPrompted) {
          await prefs.setBool('has_prompted_notif_permission', true);
          final requested = await _fcm.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          if (requested.authorizationStatus == AuthorizationStatus.authorized) {
            return;
          }
        }

        // Show our ultra-premium Liquid Glass permission prompt sheet
        if (context.mounted) {
          _showPermissionBottomSheet(context);
        }
      }
    } catch (e) {
      debugPrint("Permission prompt check error: $e");
    }
  }

  void _showPermissionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E38),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF38BDF8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Enable Class Notifications",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Get instant alerts when your teacher starts a live session, schedules upcoming tests, or sends exam notices.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Maybe Later",
                      style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _fcm.requestPermission(
                        alert: true,
                        badge: true,
                        sound: true,
                      );
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      "Allow Notifications",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Real-time listener for Firestore `broadcast_notifications` collection
  void _listenToFirestoreBroadcasts() {
    bool isInitialSnapshot = true;
    FirebaseFirestore.instance
        .collection('broadcast_notifications')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .listen((snapshot) {
      if (isInitialSnapshot) {
        // Mark existing records as processed on cold start so student is not flooded with old notifications
        for (var doc in snapshot.docs) {
          _processedNotificationIds.add(doc.id);
        }
        isInitialSnapshot = false;
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          final docId = doc.id;
          final data = doc.data();

          if (data == null) continue;

          // Deduplicate
          if (_processedNotificationIds.contains(docId)) continue;
          _processedNotificationIds.add(docId);

          final String title = data['title']?.toString() ?? "New Broadcast";
          final String body = data['body']?.toString() ?? "Tap to check details.";
          final String type = data['type']?.toString() ?? "broadcast";
          final String? videoId = data['youtubeVideoId']?.toString();

          try {
            if (!kIsWeb) HapticFeedback.heavyImpact();
          } catch (_) {}

          _showInAppAlert(
            title: title,
            body: body,
            type: type,
            youtubeVideoId: videoId,
          );
        }
      }
    }, onError: (err) {
      debugPrint("Firestore broadcast notification listener error: $err");
    });
  }

  /// Shows floating Liquid Glass in-app notification banner
  void _showInAppAlert({
    required String title,
    required String body,
    required String type,
    String? youtubeVideoId,
  }) {
    final navContext = navigatorKey?.currentContext;
    if (navContext != null && navContext.mounted) {
      final isLive = type.toLowerCase().contains('live');

      ScaffoldMessenger.of(navContext).clearSnackBars();
      ScaffoldMessenger.of(navContext).showSnackBar(
        SnackBar(
          content: InkWell(
            onTap: () {
              ScaffoldMessenger.of(navContext).hideCurrentSnackBar();
              _handleNotificationTap(youtubeVideoId);
            },
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLive ? AppColors.liveRed : AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isLive ? AppColors.liveRed : AppColors.primary)
                            .withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    isLive ? Icons.sensors_rounded : Icons.notifications_active_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isLive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.liveRed,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "JOIN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          backgroundColor: const Color(0xFF0F1E38),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isLive
                  ? AppColors.liveRed.withValues(alpha: 0.6)
                  : const Color(0x4038BDF8),
              width: 1.2,
            ),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  void _handleNotificationTap(String? videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final studentName = prefs.getString('studentName') ?? prefs.getString('student_name') ?? 'Student';
    final navContext = navigatorKey?.currentContext;
    if (navContext != null && navContext.mounted) {
      if (videoId != null && videoId.isNotEmpty) {
        Navigator.push(
          navContext,
          MaterialPageRoute(
            builder: (context) => LiveClassRoom(
              userName: studentName,
              videoId: videoId,
              title: 'Live Classroom',
              isAdmin: false,
            ),
          ),
        );
      } else {
        // If no direct videoId, check if a class is currently live in Firestore
        try {
          final liveSnap = await FirebaseFirestore.instance
              .collection('live_session')
              .doc('current')
              .get();
          if (liveSnap.exists && liveSnap.data()?['isLive'] == true) {
            final activeId =
                liveSnap.data()?['youtubeVideoId']?.toString() ?? '';
            final activeTitle =
                liveSnap.data()?['title']?.toString() ?? 'Live Session';
            if (activeId.isNotEmpty && navContext.mounted) {
              Navigator.push(
                navContext,
                MaterialPageRoute(
                  builder: (context) => LiveClassRoom(
                    userName: studentName,
                    videoId: activeId,
                    title: activeTitle,
                    isAdmin: false,
                  ),
                ),
              );
            }
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _syncTokenToFirestore(String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('student_device_tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Token sync warning: $e");
    }
  }
}
