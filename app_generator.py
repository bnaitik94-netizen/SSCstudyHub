import os

def create_full_app_structure():
    files = {
        "pubspec.yaml": r"""name: ssc_study_hub
description: SSC Study Hub App with Live Classes, AI Doubts, and Black Screen Mode.
publish_to: 'none'
version: 3.2.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  cloud_firestore: ^5.0.0
  firebase_messaging: ^15.2.10
  youtube_player_flutter: ^9.1.3
  shared_preferences: ^2.2.3
  flutter_animate: ^4.5.0
  google_fonts: ^6.2.1
  shimmer: ^3.0.0
  intl: ^0.19.0
  http: ^1.2.0
  googleapis_auth: ^1.4.1
  app_links: ^3.5.1
  url_launcher: ^6.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
""",

        "android/app/src/main/AndroidManifest.xml": r"""<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application 
        android:label="SSC Study Hub" 
        android:name="${applicationName}" 
        android:icon="@mipmap/launcher_icon">
        
        <activity 
            android:name=".MainActivity" 
            android:exported="true" 
            android:launchMode="singleTop" 
            android:taskAffinity="" 
            android:theme="@style/LaunchTheme" 
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode" 
            android:hardwareAccelerated="true" 
            android:windowSoftInputMode="adjustResize">
            
            <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
            
            <!-- 🚀 Custom Scheme: Bypasses Android Domain Verification for Deep Links -->
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="sscstudyhub" android:host="live" />
            </intent-filter>

        </activity>
        
        <meta-data android:name="flutterEmbedding" android:value="2"/>

        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="high_importance_channel" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />

    </application>
    
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <category android:name="android.intent.category.BROWSABLE" />
            <data android:scheme="https" />
        </intent>
    </queries>
</manifest>
""",

        "lib/utils/app_colors.dart": r"""import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4F46E5); 
  static const Color primaryDark = Color(0xFF312E81);
  static const Color accent = Color(0xFF0EA5E9);
  
  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF0F172A);
  
  // Black Screen Mode Colors (Dark Theme)
  static const Color backgroundDark = Color(0xFF000000); // Pitch Black
  static const Color surfaceDark = Color(0xFF111111); // Deep Grey Surface
  static const Color textLight = Color(0xFFCBD5E1);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  static const Color lockedChatBg = Color(0xFF1E1E2C);
  static const Color privateChatBg = Color(0xFF1E3A8A);
  static const Color pinnedBg = Color(0xFFFEF3C7);
  static const Color pinnedBorder = Color(0xFFFDE68A);
  static const Color pinnedText = Color(0xFF92400E);
  
  static List<BoxShadow> softShadow(bool isDark) => [
    BoxShadow(
      color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.04), 
      blurRadius: 10, 
      offset: const Offset(0, 4)
    )
  ];
}
""",

        "lib/models/chat_models.dart": r"""class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
  });
}
""",

        "lib/services/gemini_service.dart": r"""import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_models.dart';

class GeminiAiService {
  static const String _userApiKey = "AIzaSyDvJF-19NLwk5rvVRTl8jE0zxa3sCSwrIY";
  static const String _apiUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  static Future<String> generateResponse(List<ChatMessage> history) async {
    try {
      final url = Uri.parse("$_apiUrl?key=$_userApiKey");
      
      List<Map<String, dynamic>> contents = [];
      for (var msg in history) {
        if (msg.text.trim().isEmpty) continue;
        contents.add({
          "role": msg.isUser ? "user" : "model", 
          "parts": [{"text": msg.text.trim()}]
        });
      }

      if (contents.isEmpty) {
        return "Please ask a valid question.";
      }

      const String systemInstruction = 
          "You are NICKS AI, an advanced assistant powered by Google Gemini, and the expert for the Maharashtra State Board (SSC Balbharti) curriculum.\n\n"
          "CORE DIRECTIVES:\n"
          "1. STRICTLY CONCISE: Give EXACT but SHORT answers.\n"
          "2. CONTEXTUAL: Remember previous messages naturally to ensure a smooth flow.\n"
          "3. FORMATTING: STRICTLY DO NOT use LaTeX or \$ symbols. Always use standard markdown.\n"
          "4. LANGUAGE: Always respond in a mix of Marathi and English (Hinglish/Marathi script).";

      final Map<String, dynamic> body = {
        "systemInstruction": {
          "parts": [{"text": systemInstruction}]
        },
        "contents": contents,
        "generationConfig": {"temperature": 0.35}
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15)); 

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final candidates = decoded['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text']?.toString().trim();
            if (text != null && text.isNotEmpty) {
              return text.replaceAll(RegExp(r'\$'), '');
            }
          }
        }
        return "I couldn't process that. Could you please rephrase?";
      } else {
        return "Our AI servers are currently busy. Please try asking again in a moment.";
      }
    } on TimeoutException {
      return "The connection timed out. Please check your internet and try again.";
    } catch (e) {
      return "I'm having trouble connecting right now. Please check your network and try again.";
    }
  }
}
""",

        "lib/main.dart": r"""import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/app_colors.dart';
import 'screens/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Background message handled: ${message.messageId}");
}

// Global Notifier for Black Screen Mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // Load Saved Theme
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // 🚀 ORIENTATION FREE APP: We do NOT lock orientation here anymore.
  SystemChrome.setPreferredOrientations(DeviceOrientation.values);

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              const Text("Oops! Something went wrong.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                "We are working to fix this. Please restart the app.", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const SSCStudyHubApp());
}

class SSCStudyHubApp extends StatelessWidget {
  const SSCStudyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'SSC Study Hub',
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.backgroundLight,
            textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: AppColors.surfaceLight,
              foregroundColor: AppColors.textDark,
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.backgroundDark, // Black Screen Mode
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              backgroundColor: AppColors.surfaceDark,
              foregroundColor: Colors.white,
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
          ),
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
        );
      }
    );
  }
}
""",

        "lib/screens/splash_screen.dart": r"""import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import 'name_input_screen.dart';
import 'main_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    String? name;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      name = prefs.getString('studentName');
    } catch (e) {
      debugPrint("Prefs error: $e");
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => (name != null && name.trim().isNotEmpty)
              ? MainDashboard(studentName: name)
              : const NameInputScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary], 
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), 
                shape: BoxShape.circle, 
              ),
              child: const Icon(Icons.school_rounded, size: 72, color: Colors.white),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
            const SizedBox(height: 24),
            const Text(
              "SSC STUDY HUB", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)
            ).animate().slideY(begin: 0.2, duration: 400.ms).fadeIn(),
            const SizedBox(height: 8),
            const Text(
              "Premium Learning Experience", 
              style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)
            ).animate().slideY(begin: 0.2, duration: 400.ms, delay: 100.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
""",

        "lib/screens/name_input_screen.dart": r"""import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import 'main_dashboard.dart';

class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});
  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _saveName() async {
    if (_isLoading) return;
    
    String name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid full name"), 
          backgroundColor: AppColors.error, 
          behavior: SnackBarBehavior.floating
        )
      );
      return;
    }
    
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('studentName', name);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MainDashboard(studentName: name)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to save name. Please try again.")));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.rocket_launch_rounded, size: 40, color: AppColors.primary),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 32),
                Text("Welcome to", style: TextStyle(fontSize: 20, color: isDark ? AppColors.textLight : Colors.grey.shade600, fontWeight: FontWeight.w500)),
                Text("SSC Study Hub", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.textDark, letterSpacing: -0.5)),
                const SizedBox(height: 12),
                Text(
                  "Enter your name to unlock live lectures, schedules, and instant AI doubt clearing.", 
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : AppColors.textLight, fontSize: 15, height: 1.5)
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _saveName(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textDark),
                  decoration: InputDecoration(
                    labelText: 'Your Full Name',
                    labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : AppColors.textLight, fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                    filled: true,
                    fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, 
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                      elevation: 0
                    ),
                    onPressed: _isLoading ? null : _saveName,
                    child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                      : const Text('Start Journey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
""",

        "lib/screens/main_dashboard.dart": r"""import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart';
import '../utils/app_colors.dart';
import '../tabs/home_tab.dart';
import '../tabs/upcoming_classes_tab.dart';
import '../tabs/profile_tab.dart';
import 'live_class_room.dart';

class MainDashboard extends StatefulWidget {
  final String studentName;
  const MainDashboard({super.key, required this.studentName});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;
  DateTime? _lastPressedAt;
  
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _enforceNotificationPermissions();
    _initDeepLinks();
  }

  Future<void> _enforceNotificationPermissions() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false, 
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Notifications Recommended", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
              content: const Text("Allowing notifications ensures you never miss a live class alert.", style: TextStyle(color: Colors.grey)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Dismiss", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () async {
                    await messaging.requestPermission(alert: true, badge: true, sound: true);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Allow", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          );
        }
      } else {
        await messaging.subscribeToTopic('live_classes');
      }
    } catch (e) {
      debugPrint("FCM Permissions error: $e");
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    try {
      _appLinks.getInitialAppLink().then((uri) {
        if (uri != null) _handleDeepLink(uri);
      });

      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        _handleDeepLink(uri);
      }, onError: (err) {
        debugPrint("Deep link stream error: $err");
      });
    } catch (e) {
      debugPrint("AppLinks Init Error: $e");
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.path.contains('/live')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Connecting to Live Class..."), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating)
        );
      }
      
      try {
        var doc = await FirebaseFirestore.instance.collection('live_session').doc('current').get();
        if (!doc.exists) return;
        
        var data = doc.data();
        if (data != null && data['isLive'] == true && data['youtubeVideoId'] != null) {
          if (mounted) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => LiveClassRoom(
              userName: widget.studentName,
              videoId: data['youtubeVideoId'],
              title: data['title'] ?? 'Live Session',
              isAdmin: false, // Student Mode Only
            )));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No active live class right now."), behavior: SnackBarBehavior.floating)
            );
          }
        }
      } catch (e) {
        debugPrint("Deep Link Routing Error: $e");
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> pages = [
      HomeTab(studentName: widget.studentName),
      const UpcomingClassesTab(),
      ProfileTab(studentName: widget.studentName),
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Press back again to exit app"), 
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            backgroundColor: isDark ? Colors.grey.shade900 : AppColors.textDark,
          ));
          return;
        }
        SystemNavigator.pop(); 
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: IndexedStack(index: _currentIndex, children: pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4))]
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: isDark ? Colors.grey.shade600 : AppColors.textLight.withOpacity(0.6),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded, size: 24)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded, size: 26)), label: "Home"),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.video_library_rounded, size: 24)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.video_library_rounded, size: 26)), label: "Schedule"),
              BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded, size: 24)), activeIcon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded, size: 26)), label: "Profile"),
            ],
          ),
        ),
      ),
    );
  }
}
""",

        "lib/tabs/home_tab.dart": r"""import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../screens/live_class_room.dart';

class HomeTab extends StatefulWidget {
  final String studentName;
  const HomeTab({super.key, required this.studentName});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.primary,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100.0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                "Hello, ${widget.studentName.split(' ')[0]} 👋", 
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: isDark ? Colors.white : AppColors.textDark, letterSpacing: -0.5)
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _LiveStreamSection(studentName: widget.studentName, isDark: isDark),
                  const SizedBox(height: 32),
                  Text("Maharashtra Board (10th)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textDark, letterSpacing: -0.2)),
                  const SizedBox(height: 16),
                  _SubjectGrid(isDark: isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStreamSection extends StatelessWidget {
  final String studentName;
  final bool isDark;
  const _LiveStreamSection({required this.studentName, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('live_session').doc('current').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _EmptyStateCard(icon: Icons.wifi_off_rounded, title: "Connection Error", subtitle: "Unable to load live status.", isDark: isDark);
        }
        
        if (!snapshot.hasData) {
          return Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200, 
            highlightColor: isDark ? Colors.grey.shade800 : Colors.white,
            child: Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
          );
        }

        var data = snapshot.data?.data() as Map<String, dynamic>?;
        bool isLive = data?['isLive'] ?? false;
        String videoId = data?['youtubeVideoId'] ?? '';
        String title = data?['title'] ?? 'Live Session';

        if (!isLive || videoId.isEmpty) {
          return _EmptyStateCard(icon: Icons.tv_off_rounded, title: "No Active Lectures", subtitle: "Take a break and revise concepts.", isDark: isDark).animate().fadeIn(duration: 300.ms);
        }

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LiveClassRoom(userName: studentName, videoId: videoId, title: title, isAdmin: false))),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
              boxShadow: isDark ? [] : [BoxShadow(color: AppColors.error.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 160,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        color: AppColors.textDark,
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 1.seconds),
                      ),
                    ),
                    Positioned(
                      top: 16, left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: const [
                            Icon(Icons.circle, size: 8, color: Colors.white), 
                            SizedBox(width: 6), 
                            Text("LIVE NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5))
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textDark, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.workspace_premium, size: 16, color: AppColors.primary)),
                          const SizedBox(width: 10),
                          const Text("Join Class", style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Icon(Icons.arrow_forward_rounded, size: 18, color: isDark ? Colors.grey.shade600 : AppColors.textLight),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.05, duration: 400.ms).fadeIn(),
        );
      },
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  const _EmptyStateCard({required this.icon, required this.title, required this.subtitle, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200) 
      ),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? Colors.black : AppColors.backgroundLight, shape: BoxShape.circle), child: Icon(icon, size: 36, color: isDark ? Colors.grey.shade600 : AppColors.textLight)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: isDark ? Colors.grey.shade500 : AppColors.textLight, fontSize: 13), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SubjectGrid extends StatelessWidget {
  final bool isDark;
  const _SubjectGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> subjects = [
      {"name": "Science 1", "icon": Icons.science_rounded, "color": const Color(0xFF3B82F6)},
      {"name": "Science 2", "icon": Icons.biotech_rounded, "color": const Color(0xFF10B981)},
      {"name": "Algebra", "icon": Icons.calculate_rounded, "color": const Color(0xFFF59E0B)},
      {"name": "Geometry", "icon": Icons.architecture_rounded, "color": const Color(0xFF8B5CF6)},
      {"name": "History", "icon": Icons.account_balance_rounded, "color": const Color(0xFFEC4899)},
      {"name": "Geography", "icon": Icons.public_rounded, "color": const Color(0xFF14B8A6)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: subjects.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.15),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
            boxShadow: AppColors.softShadow(isDark),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: subjects[index]['color'].withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(subjects[index]['icon'], color: subjects[index]['color'], size: 28),
              ),
              const SizedBox(height: 12),
              Text(subjects[index]['name'], style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textDark)),
            ],
          ),
        ).animate().scale(delay: Duration(milliseconds: 50 * index), duration: 300.ms, curve: Curves.easeOut).fadeIn();
      },
    );
  }
}
""",

        "lib/tabs/upcoming_classes_tab.dart": r"""import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';
import '../screens/past_class_player.dart';

class UpcomingClassesTab extends StatefulWidget {
  const UpcomingClassesTab({super.key});
  @override
  State<UpcomingClassesTab> createState() => _UpcomingClassesTabState();
}

class _UpcomingClassesTabState extends State<UpcomingClassesTab> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {}); 
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Schedule & Past", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Next Scheduled Lecture", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textDark)),
                    const SizedBox(height: 16),
                    _UpcomingStreamCard(isDark: isDark),
                    const SizedBox(height: 32),
                    Text("Recorded Classes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textDark)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _PastClassesList(isDark: isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _UpcomingStreamCard extends StatelessWidget {
  final bool isDark;
  const _UpcomingStreamCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('live_session').doc('upcoming').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink();
        
        if (!snapshot.hasData) {
          return Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200, 
            highlightColor: isDark ? Colors.grey.shade800 : Colors.white,
            child: Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
          );
        }

        var data = snapshot.data?.data() as Map<String, dynamic>?;

        if (data == null || data.isEmpty || (data['title'] ?? '').toString().trim().isEmpty) {
          return Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200)),
            child: Column(
              children: [
                Icon(Icons.event_available_rounded, size: 40, color: isDark ? Colors.grey.shade700 : AppColors.textLight.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text("No upcoming lectures scheduled.", style: TextStyle(color: isDark ? Colors.grey.shade500 : AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms);
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), 
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  color: AppColors.textDark,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                        child: const Text("PREMIERE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? 'Lecture Topic', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text("${data['subject'] ?? 'General'} • Scheduled", style: const TextStyle(fontSize: 12, color: Colors.white60)),
                          const SizedBox(height: 4),
                          Text(data['time'] ?? 'Time TBA', style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ).animate().slideY(begin: 0.05, duration: 400.ms).fadeIn();
      },
    );
  }
}

class _PastClassesList extends StatelessWidget {
  final bool isDark;
  const _PastClassesList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('past_classes').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return SliverToBoxAdapter(child: Center(child: Text("Failed to load records.", style: TextStyle(color: isDark ? Colors.grey.shade500 : AppColors.textLight))));
        
        if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppColors.primary))));
        
        var pastDocs = snapshot.data!.docs;

        if (pastDocs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(child: Text("No past classes available yet.", style: TextStyle(color: Colors.grey.shade500, fontSize: 13))),
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
              String formattedDate = date != null ? DateFormat('dd MMM, yyyy • hh:mm a').format(date) : "Recently added";

              return Container(
                margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100), 
                  boxShadow: AppColors.softShadow(isDark)
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), 
                    child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary)
                  ),
                  title: Text(data['title'] ?? 'Recorded Class', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(formattedDate, style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500, fontSize: 11))),
                  trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey.shade600 : AppColors.textLight),
                  onTap: () {
                    if (data['youtubeVideoId'] != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PastClassPlayerScreen(videoId: data['youtubeVideoId'], title: data['title'] ?? 'Recorded Class')));
                    }
                  },
                ),
              ).animate().slideY(begin: 0.05, duration: 300.ms).fadeIn(delay: Duration(milliseconds: 30 * index));
            },
            childCount: pastDocs.length,
          ),
        );
      }
    );
  }
}
""",

        "lib/tabs/profile_tab.dart": r"""import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../screens/developer_info_screen.dart';
import '../main.dart'; 

class ProfileTab extends StatefulWidget {
  final String studentName;
  const ProfileTab({super.key, required this.studentName});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  void _toggleDarkMode(bool isEnabled) async {
    themeNotifier.value = isEnabled ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                widget.studentName.isNotEmpty ? widget.studentName[0].toUpperCase() : 'S',
                style: const TextStyle(fontSize: 40, color: AppColors.primary, fontWeight: FontWeight.w800),
              ),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
            const SizedBox(height: 20),
            Text(widget.studentName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.textDark, letterSpacing: -0.5)),
            const SizedBox(height: 40),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
                boxShadow: AppColors.softShadow(isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("App Preferences & Info", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.grey.shade400 : AppColors.textLight, textBaseline: TextBaseline.alphabetic)),
                  const SizedBox(height: 24),
                  
                  // Black Screen Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? Colors.black : AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.dark_mode_rounded, color: isDark ? Colors.grey.shade400 : AppColors.textLight, size: 20)),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Black Screen Mode", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : AppColors.textLight, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Text(isDark ? "On" : "Off", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textDark)),
                            ],
                          )
                        ],
                      ),
                      Switch(
                        value: isDark,
                        onChanged: _toggleDarkMode,
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  
                  Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: isDark ? Colors.white10 : AppColors.backgroundLight)),
                  
                  // Touchable Developer Info Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeveloperInfoScreen())),
                      borderRadius: BorderRadius.circular(8),
                      splashColor: AppColors.primary.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            _buildInfoRow(Icons.code_rounded, "Developed By", "Naitik", isDark),
                            const Spacer(),
                            Icon(Icons.open_in_new_rounded, size: 16, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: isDark ? Colors.white10 : AppColors.backgroundLight)),
                  _buildInfoRow(Icons.build_circle_rounded, "Version", "SSC Study Hub 3.2.0", isDark),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: isDark ? Colors.white10 : AppColors.backgroundLight)),
                  _buildInfoRow(Icons.security_rounded, "Status", "Secured & Live", isDark, isSuccess: true),
                ],
              ),
            ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, bool isDark, {bool isSuccess = false}) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDark ? Colors.black : AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: isDark ? Colors.grey.shade400 : AppColors.textLight, size: 20)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : AppColors.textLight, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isSuccess ? AppColors.success : (isDark ? Colors.white : AppColors.textDark))),
          ],
        )
      ],
    );
  }
}
""",

        "lib/screens/developer_info_screen.dart": r"""import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/app_colors.dart';

class DeveloperInfoScreen extends StatefulWidget {
  const DeveloperInfoScreen({super.key});

  @override
  State<DeveloperInfoScreen> createState() => _DeveloperInfoScreenState();
}

class _DeveloperInfoScreenState extends State<DeveloperInfoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open link. Please check your connection.', style: TextStyle(fontWeight: FontWeight.w600)),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getStyleForType(String type) {
    switch (type.toLowerCase()) {
      case 'youtube':
        return {'icon': Icons.video_library_rounded, 'color': Colors.redAccent};
      case 'instagram':
        return {'icon': Icons.camera_alt_rounded, 'color': Colors.purpleAccent};
      case 'whatsapp':
        return {'icon': Icons.chat_rounded, 'color': Colors.greenAccent.shade400};
      case 'website':
        return {'icon': Icons.language_rounded, 'color': Colors.blueAccent};
      case 'github':
        return {'icon': Icons.code_rounded, 'color': Colors.blueGrey};
      case 'linkedin':
        return {'icon': Icons.business_center_rounded, 'color': Colors.lightBlue};
      case 'telegram':
        return {'icon': Icons.send_rounded, 'color': Colors.cyan};
      default:
        return {'icon': Icons.link_rounded, 'color': AppColors.primary};
    }
  }

  Stream<List<Map<String, dynamic>>> _getDynamicLinks() {
    return FirebaseFirestore.instance
        .collection('app_settings')
        .doc('developer_info')
        .snapshots()
        .map((snapshot) {
      
      if (snapshot.exists && snapshot.data() != null && snapshot.data()!.containsKey('links')) {
        List<dynamic> rawLinks = snapshot.data()!['links'];
        return rawLinks.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      
      return [
        {"type": "youtube", "title": "YouTube Channel", "subtitle": "Cybersecurity Content", "url": "https://youtube.com/@mr._coder_boy?si=0shzEMdoyFM23U1c"},
        {"type": "instagram", "title": "Instagram", "subtitle": "Give us Your Response to Make Better", "url": "https://instagram.com/mr._naitik_bobade_23"},
        {"type": "whatsapp", "title": "WhatsApp", "subtitle": "Join our WhatsApp group", "url": "https://wa.me/910000000000"},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.1),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 3),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 30, spreadRadius: 5)
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.code_rounded, size: 50, color: AppColors.primary),
                ),
              ).animate(controller: _animController).scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),

              const SizedBox(height: 24),

              Column(
                children: [
                  Text(
                    "Mr. Naitik Bobade",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Text(
                      "App Developer & Cybersecurity Creator",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Passionate about building offline educational applications using Flutter & Python, and creating Hindi cybersecurity content. Dedicated to crafting seamless digital experiences.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                ],
              ).animate(controller: _animController).slideY(begin: 0.2, duration: 600.ms, curve: Curves.easeOut).fadeIn(delay: 200.ms),

              const SizedBox(height: 32),
              
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Connect with me", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: isDark ? Colors.grey.shade500 : Colors.grey)),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 12),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _getDynamicLinks(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Shimmer.fromColors(
                      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      highlightColor: isDark ? Colors.grey.shade700 : Colors.white,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      ),
                    );
                  }

                  final links = snapshot.data ?? [];

                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      boxShadow: AppColors.softShadow(isDark),
                    ),
                    child: Column(
                      children: List.generate(links.length, (index) {
                        final link = links[index];
                        final style = _getStyleForType(link['type'] ?? '');

                        return Column(
                          children: [
                            _buildTouchableLinkTile(
                              icon: style['icon'],
                              iconColor: style['color'],
                              title: link['title'] ?? 'Link',
                              subtitle: link['subtitle'] ?? 'Tap to open external link',
                              isDark: isDark,
                              onTap: () => _launchURL(link['url'] ?? ''),
                            ),
                            if (index < links.length - 1)
                              Divider(color: isDark ? Colors.white10 : Colors.grey.shade100, height: 1, indent: 64, endIndent: 20),
                          ],
                        );
                      }),
                    ),
                  ).animate(controller: _animController).slideY(begin: 0.1, duration: 600.ms, curve: Curves.easeOut).fadeIn(delay: 400.ms);
                }
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Visual Interactive Button Format
  Widget _buildTouchableLinkTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        splashColor: iconColor.withOpacity(0.2),
        highlightColor: iconColor.withOpacity(0.1),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.open_in_new_rounded, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
""",

        "lib/screens/live_class_room.dart": r"""import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';
import '../widgets/live_session_panel.dart';
import '../widgets/doubts_panel.dart';

class LiveClassRoom extends StatefulWidget {
  final String userName;
  final String videoId;
  final String title;
  final bool isAdmin; 
  const LiveClassRoom({super.key, required this.userName, required this.videoId, required this.title, required this.isAdmin});
  @override
  State<LiveClassRoom> createState() => _LiveClassRoomState();
}

class _LiveClassRoomState extends State<LiveClassRoom> with WidgetsBindingObserver {
  late YoutubePlayerController _playerController;
  bool _isSidePanelOpen = false;
  String _activeTab = 'chat'; 
  bool _wasLandscape = false;

  bool _showOverlays = true;
  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _playerController = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true, 
        isLive: true, 
        forceHD: false, 
        mute: widget.isAdmin, 
        hideControls: true, 
        disableDragSeek: false, 
      ),
    );
    _registerAttendance(true);
    _startOverlayTimer();
  }

  @override
  void dispose() {
    _registerAttendance(false);
    WidgetsBinding.instance.removeObserver(this);
    _overlayTimer?.cancel();
    _playerController.dispose();
    
    // Maintain orientation-free mode when exiting the player
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _registerAttendance(false);
    } else if (state == AppLifecycleState.resumed) {
      _registerAttendance(true);
    }
  }

  void _registerAttendance(bool isEntering) {
    if (widget.isAdmin) return;
    final doc = FirebaseFirestore.instance.collection('live_session').doc('current');
    if (isEntering) {
      doc.update({'active_viewers': FieldValue.arrayUnion([widget.userName])}).catchError((_) {});
    } else {
      doc.update({'active_viewers': FieldValue.arrayRemove([widget.userName])}).catchError((_) {});
    }
  }

  void _toggleOverlays() {
    if (!mounted) return;
    setState(() => _showOverlays = !_showOverlays);
    if (_showOverlays) _startOverlayTimer();
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _showOverlays) setState(() => _showOverlays = false);
    });
  }

  void _toggleFullScreen() {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    _startOverlayTimer();
  }

  Widget _buildCustomControls(bool isLandscape) {
    return Positioned(
      bottom: isLandscape ? 32 : 12, 
      left: 16, 
      right: isLandscape ? 16 : 55, 
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.red, size: 10).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),
          const SizedBox(width: 6),
          const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.0)),
          const SizedBox(width: 14),
          Expanded(
            child: ProgressBar(
              controller: _playerController,
              isExpanded: true,
              colors: const ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.red,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OrientationBuilder(
      builder: (context, orientation) {
        bool isLandscape = orientation == Orientation.landscape;

        if (isLandscape && !_wasLandscape) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          _wasLandscape = true;
        } else if (!isLandscape && _wasLandscape) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          _wasLandscape = false;
        }

        return PopScope(
          onPopInvoked: (didPop) {
            if (didPop) _registerAttendance(false);
          },
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: isLandscape ? Colors.black : Theme.of(context).scaffoldBackgroundColor, 
              resizeToAvoidBottomInset: true, 
              appBar: isLandscape ? null : AppBar(
                backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                foregroundColor: isDark ? Colors.white : AppColors.textDark,
                title: const Text('Live Class', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
              ),
              body: isLandscape ? _buildLandscapeLayout(isDark) : _buildPortraitLayout(isDark),
            ),
          ),
        );
      }
    );
  }

  Widget _buildLandscapeLayout(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Center(
                child: YoutubePlayer(
                  controller: _playerController,
                  showVideoProgressIndicator: false,
                  onReady: () => _playerController.play(),
                  bottomActions: const [],
                ),
              ),

              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleOverlays,
                  child: Container(color: Colors.transparent),
                ),
              ),

              if (_showOverlays) ...[
                _buildCustomControls(true),

                Positioned(
                  top: 16, left: 16,
                  child: InkWell(
                    onTap: () {
                      _registerAttendance(false);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: const [Icon(Icons.arrow_back, color: Colors.white, size: 18), SizedBox(width: 6), Text("Exit", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))]),
                    ),
                  ).animate().fadeIn(duration: 200.ms),
                ),

                if (!widget.isAdmin)
                  Positioned(
                    top: 16, right: 16,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 16, color: Colors.white),
                      label: const Text("SYNC LIVE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      onPressed: () {
                        _playerController.load(widget.videoId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Synced to Live Edge!"), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)));
                        _startOverlayTimer();
                      },
                    ).animate().fadeIn(duration: 200.ms),
                  ),

                Positioned(
                  bottom: 70, right: 16,
                  child: Row(
                    children: [
                      _buildOverlayBtn(Icons.fullscreen_exit_rounded, "Minimize", _toggleFullScreen),
                      const SizedBox(width: 8),
                      _buildOverlayBtn(Icons.chat_bubble_outline, "Chat", () => setState(() { _isSidePanelOpen = true; _activeTab = 'chat'; _showOverlays = false; })),
                      const SizedBox(width: 8),
                      _buildOverlayBtn(Icons.psychology_alt_outlined, "Doubts", () => setState(() { _isSidePanelOpen = true; _activeTab = 'doubts'; _showOverlays = false; })),
                    ],
                  ).animate().fadeIn(duration: 200.ms),
                ),
              ],
            ],
          ),
        ),

        if (_isSidePanelOpen)
          Container(
            width: 340,
            color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_activeTab == 'chat' ? "Live Chat" : "AI Doubts", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textDark)),
                      IconButton(icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white : AppColors.textDark), onPressed: () => setState(() => _isSidePanelOpen = false), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12),
                Expanded(child: _activeTab == 'chat' ? LiveSessionPanel(userName: widget.userName, isAdmin: widget.isAdmin) : const DoubtsPanel()),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildPortraitLayout(bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            YoutubePlayer(
              controller: _playerController,
              showVideoProgressIndicator: false,
              onReady: () => _playerController.play(),
              bottomActions: const [],
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleOverlays,
                child: Container(color: Colors.transparent),
              ),
            ),
            if (_showOverlays) ...[
              _buildCustomControls(false), 
              Positioned(
                bottom: 8, right: 8,
                child: InkWell(
                  onTap: _toggleFullScreen,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                  ),
                ).animate().fadeIn(duration: 200.ms),
              )
            ],
          ],
        ),
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.circle, color: AppColors.error, size: 8).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
              
              InkWell(
                onTap: () {
                  _playerController.load(widget.videoId);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Synced!"), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 1)));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Row(
                    children: [
                      Icon(Icons.sync_rounded, color: AppColors.primary, size: 14),
                      SizedBox(width: 4),
                      Text("Sync Live", style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ]
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeTab = 'chat'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _activeTab == 'chat' ? AppColors.primary : Colors.transparent, width: 2))),
                    child: Center(child: Text("Live Chat", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _activeTab == 'chat' ? AppColors.primary : (isDark ? Colors.grey.shade500 : AppColors.textLight)))),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeTab = 'doubts'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _activeTab == 'doubts' ? AppColors.primary : Colors.transparent, width: 2))),
                    child: Center(child: Text("Ask Doubts", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _activeTab == 'doubts' ? AppColors.primary : (isDark ? Colors.grey.shade500 : AppColors.textLight)))),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
        Expanded(
          child: _activeTab == 'chat' ? LiveSessionPanel(userName: widget.userName, isAdmin: widget.isAdmin) : const DoubtsPanel(),
        ),
      ],
    );
  }

  Widget _buildOverlayBtn(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]),
      ),
    );
  }
}
""",

        "lib/screens/past_class_player.dart": r"""import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_colors.dart';
import '../widgets/doubts_panel.dart';

class PastClassPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;

  const PastClassPlayerScreen({super.key, required this.videoId, required this.title});

  @override
  State<PastClassPlayerScreen> createState() => _PastClassPlayerScreenState();
}

class _PastClassPlayerScreenState extends State<PastClassPlayerScreen> {
  late YoutubePlayerController _playerController;
  bool _isSidePanelOpen = false;
  bool _showOverlays = true;
  Timer? _overlayTimer;
  bool _wasLandscape = false;

  @override
  void initState() {
    super.initState();
    String safeVideoId = YoutubePlayer.convertUrlToId(widget.videoId) ?? widget.videoId;

    _playerController = YoutubePlayerController(
      initialVideoId: safeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true, 
        isLive: false,
        forceHD: false,
        mute: false,
        hideControls: true, 
      ),
    );
    _startOverlayTimer();
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _playerController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  void _toggleOverlays() {
    if (!mounted) return;
    setState(() => _showOverlays = !_showOverlays);
    if (_showOverlays) _startOverlayTimer();
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _showOverlays) setState(() => _showOverlays = false);
    });
  }

  void _toggleFullScreen() {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    _startOverlayTimer();
  }

  Widget _buildCustomControls(bool isLandscape) {
    return Positioned(
      bottom: isLandscape ? 32 : 12, left: 16, right: isLandscape ? 16 : 55,
      child: Row(
        children: [
          CurrentPosition(controller: _playerController),
          const SizedBox(width: 8),
          Expanded(
            child: ProgressBar(
              controller: _playerController,
              isExpanded: true,
              colors: const ProgressBarColors(playedColor: Colors.red, handleColor: Colors.red, bufferedColor: Colors.white30, backgroundColor: Colors.white24),
            ),
          ),
          const SizedBox(width: 8),
          RemainingDuration(controller: _playerController),
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }

  Widget _buildPlayPauseButton() {
    return ValueListenableBuilder<YoutubePlayerValue>(
      valueListenable: _playerController,
      builder: (context, value, child) {
        return Center(
          child: GestureDetector(
            onTap: () {
              value.isPlaying ? _playerController.pause() : _playerController.play();
              _startOverlayTimer();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 36),
            ),
          ).animate().scale(duration: 150.ms),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OrientationBuilder(
      builder: (context, orientation) {
        bool isLandscape = orientation == Orientation.landscape;
        
        if (isLandscape && !_wasLandscape) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          _wasLandscape = true;
        } else if (!isLandscape && _wasLandscape) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          _wasLandscape = false;
        }

        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: isLandscape ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
            appBar: isLandscape ? null : AppBar(
                backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                foregroundColor: isDark ? Colors.white : AppColors.textDark,
                title: Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.3))
            ),
            body: isLandscape ? _buildLandscapeLayout(isDark) : _buildPortraitLayout(isDark),
          ),
        );
      }
    );
  }

  Widget _buildLandscapeLayout(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Center(
                child: YoutubePlayer(
                  controller: _playerController,
                  showVideoProgressIndicator: false,
                  onReady: () => _playerController.play(),
                  bottomActions: const [], 
                ),
              ),

              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleOverlays,
                  child: Container(color: Colors.transparent),
                ),
              ),

              if (_showOverlays) ...[
                Positioned(
                  top: 16, left: 16,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: const [Icon(Icons.arrow_back, color: Colors.white, size: 18), SizedBox(width: 6), Text("Back", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))]),
                    ),
                  ).animate().fadeIn(),
                ),

                Positioned(
                  top: 16, right: 16,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: PlaybackSpeedButton(controller: _playerController, icon: const Icon(Icons.settings, color: Colors.white, size: 20)),
                  ).animate().fadeIn(),
                ),

                _buildPlayPauseButton(),
                _buildCustomControls(true), 

                Positioned(
                  bottom: 70, right: 16,
                  child: Row(
                    children: [
                      InkWell(
                        onTap: _toggleFullScreen,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => setState(() { _isSidePanelOpen = true; _showOverlays = false; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                          child: Row(children: const [Icon(Icons.psychology_alt_outlined, color: Colors.white, size: 16), SizedBox(width: 6), Text("Ask Doubt", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))]),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                ),
              ]
            ]
          )
        ),
        if (_isSidePanelOpen)
          Container(
            width: 340,
            color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("AI Doubts", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textDark)),
                      IconButton(icon: Icon(Icons.close, size: 20, color: isDark ? Colors.white : AppColors.textDark), onPressed: () => setState(() => _isSidePanelOpen = false), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: isDark ? Colors.white10 : Colors.black12),
                const Expanded(child: DoubtsPanel()),
              ],
            ),
          )
      ]
    );
  }

  Widget _buildPortraitLayout(bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            YoutubePlayer(
              controller: _playerController,
              showVideoProgressIndicator: false,
              onReady: () => _playerController.play(),
              bottomActions: const [],
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _toggleOverlays,
                child: Container(color: Colors.transparent),
              ),
            ),
            if (_showOverlays) ...[
              _buildPlayPauseButton(),
              _buildCustomControls(false), 
              Positioned(
                top: 8, right: 8,
                child: Container(
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                  child: PlaybackSpeedButton(controller: _playerController, icon: const Icon(Icons.settings, color: Colors.white, size: 18)),
                ).animate().fadeIn(),
              ),
              Positioned(
                bottom: 8, right: 8,
                child: InkWell(
                  onTap: _toggleFullScreen,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                  ),
                ).animate().fadeIn(),
              )
            ],
          ],
        ),
        Container(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isDark ? Colors.white : AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, border: const Border(bottom: BorderSide(color: AppColors.primary, width: 2))),
          child: const Center(child: Text("Ask AI Doubts", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary))),
        ),
        Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
        const Expanded(child: DoubtsPanel()),
      ],
    );
  }
}
""",

        "lib/widgets/live_session_panel.dart": r"""import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';

class LiveSessionPanel extends StatelessWidget {
  final String userName;
  final bool isAdmin;
  const LiveSessionPanel({super.key, required this.userName, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('live_session').doc('current').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Chat unavailable."));
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        
        var data = snapshot.data!.data() as Map<String, dynamic>;
        String chatMode = data['chatMode'] ?? 'public';
        String pinnedMessage = data['pinnedMessage'] ?? '';
        return _LiveChatWidget(userName: userName, isAdmin: isAdmin, chatMode: chatMode, pinnedMessage: pinnedMessage);
      }
    );
  }
}

class _LiveChatWidget extends StatefulWidget {
  final String userName;
  final bool isAdmin;
  final String chatMode;
  final String pinnedMessage;
  const _LiveChatWidget({required this.userName, required this.isAdmin, required this.chatMode, required this.pinnedMessage});
  @override
  State<_LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<_LiveChatWidget> {
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();

  @override
  void dispose() {
    _chatController.dispose();
    _chatFocusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;
    _chatFocusNode.unfocus(); 
    FirebaseFirestore.instance.collection('live_session').doc('current').collection('chat').add({
      'sender': widget.userName,
      'text': _chatController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'isAdmin': false,
    }).catchError((e) => debugPrint("Chat send error: $e"));
    _chatController.clear();
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Now";
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isLockedForStudent = (!widget.isAdmin && widget.chatMode == 'locked');
    bool isPrivateForStudent = (!widget.isAdmin && widget.chatMode == 'private');

    return GestureDetector(
      onTap: () => _chatFocusNode.unfocus(),
      child: Column(
        children: [
          if (widget.pinnedMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.pinnedBg, borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.pinnedBorder, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.push_pin_rounded, size: 14, color: AppColors.pinnedText),
                  const SizedBox(width: 8),
                  Expanded(child: Text(widget.pinnedMessage, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.pinnedText))),
                ],
              ),
            ).animate().slideY(begin: -0.1).fadeIn(duration: 300.ms),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('live_session').doc('current').collection('chat').orderBy('timestamp', descending: true).limit(50).snapshots(),
              builder: (context, chatSnapshot) {
                if (chatSnapshot.hasError) return Center(child: Text("Error loading chat.", style: TextStyle(color: isDark ? Colors.grey.shade500 : AppColors.textLight, fontSize: 12)));
                if (!chatSnapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                var messages = chatSnapshot.data!.docs;

                return ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var msg = messages[index].data() as Map<String, dynamic>;
                    bool msgIsAdmin = msg['isAdmin'] ?? false;
                    bool isMe = msg['sender'] == widget.userName;

                    if (!widget.isAdmin && widget.chatMode == 'private') {
                      if (!isMe && !msgIsAdmin) return const SizedBox.shrink(); 
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: msgIsAdmin ? (isDark ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade50) : (isMe ? AppColors.primary : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)),
                          borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                          border: Border.all(color: msgIsAdmin ? (isDark ? Colors.amber.shade700 : Colors.amber.shade200) : (isMe ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade200))),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(msg['sender'] ?? 'User', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: msgIsAdmin ? (isDark ? Colors.amber.shade300 : Colors.amber.shade900) : (isMe ? Colors.white70 : AppColors.primary))),
                                const SizedBox(width: 8),
                                Text(_formatTime(msg['timestamp'] as Timestamp?), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: isMe ? Colors.white54 : (isDark ? Colors.grey.shade500 : AppColors.textLight))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(msg['text'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, height: 1.3, color: isMe ? Colors.white : (isDark ? Colors.white : AppColors.textDark))),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          SafeArea( 
            bottom: true,
            child: isLockedForStudent 
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  width: double.infinity,
                  color: AppColors.lockedChatBg, 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.lock_outline, color: Colors.white70, size: 14),
                      SizedBox(width: 6),
                      Text("Chat is locked by the teacher.", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPrivateForStudent)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        width: double.infinity,
                        color: AppColors.privateChatBg,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text("Private Q&A mode is active.", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200))),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              focusNode: _chatFocusNode,
                              textInputAction: TextInputAction.send, 
                              onSubmitted: (_) => _sendMessage(), 
                              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textDark),
                              decoration: InputDecoration(
                                hintText: isPrivateForStudent ? "Message privately..." : "Type a message...",
                                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade500 : AppColors.textLight),
                                filled: true,
                                fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
""",

        "lib/widgets/doubts_panel.dart": r"""import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/chat_models.dart';
import '../services/gemini_service.dart';
import '../utils/app_colors.dart';

class DoubtsPanel extends StatefulWidget {
  const DoubtsPanel({super.key});
  @override
  State<DoubtsPanel> createState() => _DoubtsPanelState();
}

class _DoubtsPanelState extends State<DoubtsPanel> {
  final TextEditingController _doubtController = TextEditingController();
  final FocusNode _doubtFocusNode = FocusNode();
  final List<ChatMessage> _doubtsList = [];
  bool _isDoubtLoading = false;

  @override
  void dispose() {
    _doubtController.dispose();
    _doubtFocusNode.dispose();
    super.dispose();
  }

  Future<void> _askAiDoubt() async {
    String text = _doubtController.text.trim();
    if (text.isEmpty) return;

    _doubtFocusNode.unfocus(); 

    setState(() {
      _doubtsList.insert(0, ChatMessage(text: text, isUser: true));
      _isDoubtLoading = true;
    });
    _doubtController.clear();

    try {
      List<ChatMessage> chronologicalHistory = _doubtsList.reversed.toList();
      String response = await GeminiAiService.generateResponse(chronologicalHistory);
      
      if (mounted) setState(() => _doubtsList.insert(0, ChatMessage(text: response, isUser: false)));
    } catch (e) {
      if (mounted) {
        setState(() => _doubtsList.insert(0, ChatMessage(text: "Connection failed. Please check your network and try again.", isUser: false)));
      }
    } finally {
      if (mounted) setState(() => _isDoubtLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _doubtFocusNode.unfocus(),
      child: Column(
        children: [
          Expanded(
            child: _doubtsList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.psychology_alt_rounded, size: 48, color: AppColors.primary)),
                      const SizedBox(height: 16),
                      Text("Got an academic doubt?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.textDark)),
                      const SizedBox(height: 6),
                      Text("Ask our AI assistant instantly.", style: TextStyle(color: isDark ? Colors.grey.shade400 : AppColors.textLight, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms)
              : ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  reverse: true,
                  itemCount: _doubtsList.length + (_isDoubtLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0 && _isDoubtLoading) {
                      return const Align(
                        alignment: Alignment.centerLeft, 
                        child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                      );
                    }
                    var msg = _doubtsList[_isDoubtLoading ? index - 1 : index];
                    bool isStudent = msg.isUser;
                    return Align(
                      alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                        decoration: BoxDecoration(
                          color: isStudent ? AppColors.primary : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                          borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isStudent ? 16 : 4), bottomRight: Radius.circular(isStudent ? 4 : 16)),
                          border: isStudent ? null : Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                        ),
                        child: Text(msg.text, style: TextStyle(color: isStudent ? Colors.white : (isDark ? Colors.white : AppColors.textDark), fontSize: 13, fontWeight: FontWeight.w500, height: 1.4)),
                      ),
                    ).animate().slideY(begin: 0.1, duration: 250.ms).fadeIn();
                  },
                ),
          ),
          SafeArea( 
            bottom: true,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight, border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200))),
              child: Column(
                children: [
                  TextField(
                    controller: _doubtController,
                    focusNode: _doubtFocusNode,
                    textInputAction: TextInputAction.send, 
                    onSubmitted: (_) { if (!_isDoubtLoading) _askAiDoubt(); }, 
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: "Type your doubt here...",
                      hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade500 : AppColors.textLight),
                      filled: true,
                      fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
                      onPressed: _isDoubtLoading ? null : _askAiDoubt,
                      label: const Text("Ask AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
"""
    }

    for path, content in files.items():
        directory = os.path.dirname(path)
        if directory and not os.path.exists(directory):
            os.makedirs(directory, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(content.strip() + "\n")
    print("Files successfully generated.")

if __name__ == "__main__":
    create_full_app_structure()