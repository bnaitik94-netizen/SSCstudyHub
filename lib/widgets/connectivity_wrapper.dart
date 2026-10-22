import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import 'offline_screen.dart';

/// 🌐 GLOBAL CONNECTIVITY WRAPPER
/// Seamlessly intercepts when internet is lost and presents the animated
/// student offline screen with real-time automatic recovery and cached offline mode.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _service = ConnectivityService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onConnectivityChanged);
    _service.initialize();
  }

  @override
  void dispose() {
    _service.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _service.isOnline;
    final bypassed = _service.bypassedOffline;

    // If completely offline and user hasn't explicitly chosen to continue offline:
    if (!isOnline && !bypassed) {
      return OfflineScreen(
        onRetry: () => setState(() {}),
        onContinueOffline: () => setState(() {}),
      );
    }

    // Normal app experience (with a subtle top banner if in bypassed offline mode)
    return Stack(
      children: [
        widget.child,
        if (!isOnline && bypassed)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFD97706),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.offline_pin_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        "Offline Mode · Browsing cached notes & syllabus",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          _service.checkReachability();
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            "RECONNECT",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
