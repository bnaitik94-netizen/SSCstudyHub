import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLiveControlScreen extends StatefulWidget {
  const AdminLiveControlScreen({super.key});

  @override
  State<AdminLiveControlScreen> createState() => _AdminLiveControlScreenState();
}

class _AdminLiveControlScreenState extends State<AdminLiveControlScreen> {
  final _subjectCtrl = TextEditingController(text: "Mathematics Part 1");
  final _topicCtrl = TextEditingController(text: "Quadratic Equations Board Revision");
  final _youtubeCtrl = TextEditingController();
  final _jitsiCtrl = TextEditingController();

  bool _isYoutubeLive = true;
  bool _isLive = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLiveStatus();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _topicCtrl.dispose();
    _youtubeCtrl.dispose();
    _jitsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLiveStatus() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('live_lectures').doc('current_live').get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _subjectCtrl.text = data['subject'] ?? _subjectCtrl.text;
          _topicCtrl.text = data['topic'] ?? _topicCtrl.text;
          _youtubeCtrl.text = data['youtube_url'] ?? "";
          _jitsiCtrl.text = data['jitsi_room_name'] ?? "";
          _isYoutubeLive = data['is_youtube_live'] ?? true;
          _isLive = data['is_live'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Fetch admin current live error: $e");
    }
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    HapticFeedback.lightImpact();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && mounted) {
      setState(() {
        controller.text = data!.text!.trim();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Link pasted successfully"),
          duration: Duration(milliseconds: 900),
          backgroundColor: Color(0xFF1E293B),
        ),
      );
    }
  }

  Future<void> _saveAndBroadcast(bool activateLive) async {
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      await FirebaseFirestore.instance.collection('live_lectures').doc('current_live').set({
        'subject': _subjectCtrl.text.trim(),
        'topic': _topicCtrl.text.trim(),
        'youtube_url': _youtubeCtrl.text.trim(),
        'jitsi_room_name': _jitsiCtrl.text.trim(),
        'is_youtube_live': _isYoutubeLive,
        'is_live': activateLive,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _isLive = activateLive;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: activateLive ? const Color(0xFF00F2FE) : const Color(0xFFEF4444),
            content: Text(
              activateLive ? "🚀 Live Class Distributed to All Students Instantly!" : "⏹️ Live Class Stopped",
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: const Text("Teacher Broadcast Console", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F19), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Glassmorphic Status Header
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isLive ? const Color(0xFF00F2FE) : Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: (_isLive ? const Color(0xFF00F2FE) : Colors.red).withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLive ? "BROADCAST IS CURRENTLY ACTIVE" : "BROADCAST IS OFFLINE",
                                style: TextStyle(
                                  color: _isLive ? const Color(0xFF00F2FE) : Colors.white70,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Students will see pre-loaded action cards in real-time.",
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildGlassInput("Subject Name", _subjectCtrl, Icons.school_rounded),
              const SizedBox(height: 16),
              _buildGlassInput("Topic / Chapter", _topicCtrl, Icons.menu_book_rounded),
              const SizedBox(height: 16),

              // YouTube Paste Field
              _buildPasteField(
                label: "Paste YouTube Live / Video Link",
                controller: _youtubeCtrl,
                icon: Icons.video_collection_rounded,
                accentColor: const Color(0xFFFF0055),
              ),
              const SizedBox(height: 8),

              // YouTube Live Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Stream Type: Live Broadcast", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  Switch(
                    value: _isYoutubeLive,
                    activeThumbColor: const Color(0xFFFF0055),
                    onChanged: (val) => setState(() => _isYoutubeLive = val),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Jitsi Paste Field
              _buildPasteField(
                label: "Paste Jitsi Meet Link or Room Name",
                controller: _jitsiCtrl,
                icon: Icons.groups_rounded,
                accentColor: const Color(0xFF00F2FE),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              if (_isSaving)
                const Center(child: CircularProgressIndicator(color: Color(0xFF00F2FE)))
              else ...[
                ElevatedButton.icon(
                  onPressed: () => _saveAndBroadcast(true),
                  icon: const Icon(Icons.podcasts_rounded, color: Colors.black),
                  label: const Text("START CLASS & DISTRIBUTE LINKS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F2FE),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _saveAndBroadcast(false),
                  icon: const Icon(Icons.stop_circle_rounded, color: Color(0xFFFF0055)),
                  label: const Text("STOP LIVE CLASS", style: TextStyle(color: Color(0xFFFF0055), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF0055)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInput(String label, TextEditingController controller, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
              prefixIcon: Icon(icon, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasteField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color accentColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    labelText: label,
                    labelStyle: TextStyle(color: accentColor.withValues(alpha: 0.9)),
                    prefixIcon: Icon(icon, color: accentColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _pasteFromClipboard(controller),
                icon: Icon(Icons.content_paste_rounded, color: accentColor),
                tooltip: "Paste from clipboard",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
