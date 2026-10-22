import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

/// 🌐 Enterprise-Grade Cross-Platform Connectivity Service
/// Supports Android, Windows PC, Web, iOS, macOS, and Linux
class ConnectivityService with ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool _isChecking = false;
  bool _bypassedOffline = false;
  DateTime? _lastCheckedTime;

  bool get isOnline => _isOnline;
  bool get isChecking => _isChecking;
  bool get bypassedOffline => _bypassedOffline;

  /// Initialize continuous connectivity monitoring
  void initialize() {
    _subscription?.cancel();
    
    // Initial check
    checkReachability(silent: true);

    // Listen to network interface changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasInterface = results.any((r) => r != ConnectivityResult.none);
      if (!hasInterface) {
        _setOnline(false);
      } else {
        // Debounce reachability verification
        final now = DateTime.now();
        if (_lastCheckedTime == null || now.difference(_lastCheckedTime!).inSeconds >= 2) {
          checkReachability(silent: true);
        }
      }
    });
  }

  /// Verify actual internet reachability (not just local Wi-Fi / LAN connection)
  Future<bool> checkReachability({bool silent = false}) async {
    if (_isChecking) return _isOnline;

    if (!silent) {
      _isChecking = true;
      notifyListeners();
    }

    bool reachable = false;
    _lastCheckedTime = DateTime.now();

    try {
      if (kIsWeb) {
        // On Web, test against Google's ultra-fast 204 captive endpoint or Firebase
        final res = await http
            .get(Uri.parse('https://www.gstatic.com/generate_204'))
            .timeout(const Duration(seconds: 3));
        reachable = (res.statusCode == 204 || res.statusCode == 200);
      } else {
        // Native (Android/Windows/iOS): Test HTTP reachability
        final res = await http
            .get(Uri.parse('https://www.gstatic.com/generate_204'))
            .timeout(const Duration(seconds: 3));
        reachable = (res.statusCode == 204 || res.statusCode == 200);
      }
    } catch (_) {
      // Secondary fallback verification
      try {
        final fallback = await http
            .get(Uri.parse('https://cloudflare.com/cdn-cgi/trace'))
            .timeout(const Duration(seconds: 3));
        reachable = (fallback.statusCode == 200);
      } catch (_) {
        reachable = false;
      }
    }

    _isChecking = false;
    _setOnline(reachable);
    return reachable;
  }

  void _setOnline(bool value) {
    if (_isOnline != value) {
      _isOnline = value;
      // If we came back online, reset any bypass
      if (value) {
        _bypassedOffline = false;
      }
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  /// User explicitly chose to browse cached/offline study materials
  void continueOffline() {
    _bypassedOffline = true;
    notifyListeners();
  }

  /// Reset bypass to show offline screen again if still disconnected
  void resetBypass() {
    _bypassedOffline = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
