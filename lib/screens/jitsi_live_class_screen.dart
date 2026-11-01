import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import '../services/live_class_preload_engine.dart';

class JitsiLiveClassScreen extends StatefulWidget {
  const JitsiLiveClassScreen({super.key});

  @override
  State<JitsiLiveClassScreen> createState() => _JitsiLiveClassScreenState();
}

class _JitsiLiveClassScreenState extends State<JitsiLiveClassScreen> {
  final JitsiMeet _jitsiMeet = JitsiMeet();
  final LiveClassPreloadEngine _engine = LiveClassPreloadEngine();

  @override
  void initState() {
    super.initState();
    _joinPreloadedConference();
  }

  Future<void> _joinPreloadedConference() async {
    final options = _engine.jitsiConferenceOptions;
    if (options == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      await _jitsiMeet.join(
        options,
        JitsiMeetEventListener(
          conferenceJoined: (url) {
            debugPrint("Jitsi Joined: $url");
          },
          conferenceTerminated: (url, error) {
            debugPrint("Jitsi Terminated: $url, error: $error");
            if (mounted) Navigator.pop(context);
          },
          conferenceWillJoin: (url) {
            debugPrint("Jitsi Will Join: $url");
          },
          readyToClose: () {
            if (mounted) Navigator.pop(context);
          },
        ),
      );
    } catch (e) {
      debugPrint("Jitsi Launch Error: $e");
      if (mounted) Navigator.pop(context);
    }
  }

  void _leaveConference() async {
    await _jitsiMeet.hangUp();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: SafeArea(
        child: Column(
          children: [
            // Dark Classroom Status Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF111827),
                border: Border(bottom: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: _leaveConference,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _engine.subject,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Connected as: ${_engine.cachedStudentName}",
                          style: const TextStyle(color: Color(0xFF00F2FE), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _leaveConference,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0055),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Leave", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            // Video Conference Connecting Fallback Area
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00F2FE)),
                    const SizedBox(height: 18),
                    Text(
                      "Connecting ${_engine.cachedStudentName}...",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Pre-loaded directly without lobby prompts.",
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
