import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static final List<ChatMessage> _persistedDoubtsHistory = [];
  late final List<ChatMessage> _doubtsList;
  bool _isDoubtLoading = false;
  int _lastStreamedIndex = -1;

  @override
  void initState() {
    super.initState();
    _doubtsList = _persistedDoubtsHistory;
  }

  @override
  void dispose() {
    _doubtController.dispose();
    _doubtFocusNode.dispose();
    super.dispose();
  }

  void _clearChat() {
    HapticFeedback.lightImpact();
    setState(() {
      _persistedDoubtsHistory.clear();
      _lastStreamedIndex = -1;
    });
  }

  Future<void> _askAiDoubt([String? presetQuery]) async {
    String text = presetQuery ?? _doubtController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    setState(() {
      _doubtsList.insert(0, ChatMessage(text: text, isUser: true));
      _isDoubtLoading = true;
    });

    _doubtController.clear();

    try {
      List<ChatMessage> chronologicalHistory = _doubtsList.reversed.toList();
      String response =
          await GeminiAiService.generateResponse(chronologicalHistory);

      if (mounted) {
        setState(() {
          _doubtsList.insert(0, ChatMessage(text: response, isUser: false));
          _lastStreamedIndex = 0; // Trigger typewriter for latest AI reply
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _doubtsList.insert(
            0,
            ChatMessage(
              text: "I could not connect to Gemini servers. Please check your internet connection.",
              isUser: false,
            ),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isDoubtLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        children: [
          // ── TOP HEADER (AI Title, Status, and Clear Chat) ────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x331E293B),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.primary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "NICKS AI Tutor",
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      "Powered by Google Gemini",
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_doubtsList.isNotEmpty)
                  IconButton(
                    tooltip: "Clear Conversation",
                    icon: const Icon(Icons.refresh_rounded, size: 19, color: Colors.white70),
                    onPressed: _clearChat,
                  ),
              ],
            ),
          ),

          // ── CHAT CONTENT OR WELCOME EMPTY STATE ──────────────────────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: _doubtsList.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.25),
                                    AppColors.accent.withValues(alpha: 0.18),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.45),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.30),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.psychology_alt_rounded,
                                size: 46,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Instant AI Academic Tutor",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Ask any question from Maharashtra State Board (Class 10) syllabus. NICKS AI provides clean, step-by-step explanations.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildQuickChip("Linear Equations in 2 Variables"),
                                _buildQuickChip("Gravitation 3 Key Points"),
                                _buildQuickChip("Periodic Table Trends"),
                                _buildQuickChip("Heredity & Evolution"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 350.ms)
                  : ListView.builder(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      reverse: true,
                      itemCount: _doubtsList.length + (_isDoubtLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                      // Loading indicator at top of reverse list
                      if (index == 0 && _isDoubtLoading) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: AppColors.liquidGlassCard,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "NICKS AI is formulating your answer...",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final actualIndex = _isDoubtLoading ? index - 1 : index;
                      final msg = _doubtsList[actualIndex];
                      final bool isStudent = msg.isUser;
                      final bool shouldAnimateTypewriter = !isStudent && actualIndex == _lastStreamedIndex;

                      return Align(
                        alignment: isStudent ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.86,
                          ),
                          child: isStudent
                              ? _buildStudentBubble(msg.text)
                              : _buildAiBubble(msg.text, shouldAnimateTypewriter),
                        ),
                      ).animate().slideY(begin: 0.05, duration: 200.ms).fadeIn();
                    },
                  ),
            ),
          ),

          // ── INPUT BAR IN FROSTED LIQUID GLASS ─────────────────────────────
          SafeArea(
            bottom: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: BoxDecoration(
                color: const Color(0xE6162544),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _doubtController,
                        focusNode: _doubtFocusNode,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          if (!_isDoubtLoading) _askAiDoubt();
                        },
                        style: const TextStyle(fontSize: 13.5, color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Ask doubt from SSC syllabus...",
                          hintStyle: TextStyle(fontSize: 13, color: Colors.white54),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isDoubtLoading ? null : () => _askAiDoubt(),
                        borderRadius: BorderRadius.circular(22),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF4F46E5),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SelectableText(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildAiBubble(String text, bool shouldAnimate) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.liquidGlassCard.copyWith(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Brand tag & Copy CTA
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 12, color: AppColors.accent),
              const SizedBox(width: 5),
              const Text(
                "Gemini AI",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Copied answer to clipboard!"),
                      duration: Duration(milliseconds: 1400),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 12, color: Colors.white.withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Text(
                        "Copy",
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Rich Formatted Text (Cleaned from raw *#, ###, **)
          shouldAnimate
              ? _StreamingAiMessage(
                  text: text,
                  onCompleted: () {
                    if (mounted) setState(() => _lastStreamedIndex = -1);
                  },
                )
              : _CleanMarkdownViewer(rawText: text),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String title) {
    return ActionChip(
      backgroundColor: Colors.white.withValues(alpha: 0.10),
      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.35)),
      label: Text(
        title,
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: () => _askAiDoubt(title),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMOOTH TYPEWRITER STREAMING EFFECT
// ─────────────────────────────────────────────────────────────────────────────

class _StreamingAiMessage extends StatefulWidget {
  final String text;
  final VoidCallback onCompleted;

  const _StreamingAiMessage({
    required this.text,
    required this.onCompleted,
  });

  @override
  State<_StreamingAiMessage> createState() => _StreamingAiMessageState();
}

class _StreamingAiMessageState extends State<_StreamingAiMessage> {
  String _displayedText = "";
  Timer? _streamTimer;
  late final List<String> _words;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _words = widget.text.split(" ");
    _startStreaming();
  }

  void _startStreaming() {
    _streamTimer = Timer.periodic(const Duration(milliseconds: 22), (timer) {
      if (_currentIndex < _words.length) {
        setState(() {
          _displayedText += (_currentIndex == 0 ? "" : " ") + _words[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _streamTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Fast-forward on tap
        _streamTimer?.cancel();
        setState(() => _displayedText = widget.text);
        widget.onCompleted();
      },
      child: _CleanMarkdownViewer(rawText: _displayedText, showCursor: _currentIndex < _words.length),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CLEAN MARKDOWN & SYMBOL SANITIZER VIEWER (ELIMINATES *# AND ###)
// ─────────────────────────────────────────────────────────────────────────────

class _CleanMarkdownViewer extends StatelessWidget {
  final String rawText;
  final bool showCursor;

  const _CleanMarkdownViewer({
    required this.rawText,
    this.showCursor = false,
  });

  @override
  Widget build(BuildContext context) {
    final lines = rawText.split("\n");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < lines.length; i++) _buildLine(lines[i].trim()),
        if (showCursor)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 400.ms),
      ],
    );
  }

  Widget _buildLine(String line) {
    if (line.isEmpty) {
      return const SizedBox(height: 6);
    }

    // Sanitize any ugly *# or trailing hash leftovers
    String sanitized = line.replaceAll(RegExp(r'\*#+'), '').trim();

    // 1. Check if line is a Heading (# or ## or ###)
    if (sanitized.startsWith(RegExp(r'#+\s*'))) {
      final headerText = sanitized.replaceFirst(RegExp(r'#+\s*'), '').trim();
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3.5,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _cleanAsterisks(headerText),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Check if line is a Bullet Item (* or - or •)
    if (sanitized.startsWith(RegExp(r'^[\*\-\•]\s+'))) {
      final content = sanitized.replaceFirst(RegExp(r'^[\*\-\•]\s+'), '').trim();
      return Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6, right: 8),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: _buildRichSpans(content),
            ),
          ],
        ),
      );
    }

    // 3. Check if line is a Numbered Step (1., 2., etc.)
    final numberMatch = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(sanitized);
    if (numberMatch != null) {
      final number = numberMatch.group(1)!;
      final content = numberMatch.group(2)!;
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(
              child: _buildRichSpans(content),
            ),
          ],
        ),
      );
    }

    // 4. Regular Paragraph Text
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: _buildRichSpans(sanitized),
    );
  }

  /// Parses **bold** segments into bright bold spans and regular text into clean readable spans
  Widget _buildRichSpans(String text) {
    final List<InlineSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');

    int lastIndex = 0;
    for (final match in boldPattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: _cleanAsterisks(text.substring(lastIndex, match.start)),
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: _cleanAsterisks(match.group(1) ?? ""),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.45,
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: _cleanAsterisks(text.substring(lastIndex)),
          style: const TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  String _cleanAsterisks(String str) {
    // Strip any remaining lone asterisks or hash combinations
    return str.replaceAll('*#', '').replaceAll('**', '').replaceAll('*', '');
  }
}
