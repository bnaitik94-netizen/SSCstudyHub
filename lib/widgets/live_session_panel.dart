import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../services/prewarm_service.dart';
import 'floating_reactions.dart';

class LiveSessionPanel extends StatefulWidget {
  final String userName;
  final bool isAdmin;

  const LiveSessionPanel({
    super.key,
    required this.userName,
    required this.isAdmin,
  });

  @override
  State<LiveSessionPanel> createState() => _LiveSessionPanelState();
}

class _LiveSessionPanelState extends State<LiveSessionPanel>
    with AutomaticKeepAliveClientMixin {
  late final Stream<DocumentSnapshot> _sessionStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // 🚀 STABLE STREAM SUBSCRIPTION: Created once in initState so rebuilds never reload
    _sessionStream = FirebaseFirestore.instance
        .collection('live_session')
        .doc('current')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: _sessionStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Chat connection issue. Please retry.",
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          );
        }

    final prewarmedData = AppPrewarmService.instance.currentSessionData;
    final Map<String, dynamic> data = (snapshot.hasData && snapshot.data!.exists)
        ? (snapshot.data!.data() as Map<String, dynamic>? ?? {})
        : (prewarmedData ?? {});

    final String chatMode = data['chatMode']?.toString() ?? AppPrewarmService.instance.chatMode;
    final String pinnedMessage = data['pinnedMessage']?.toString() ?? AppPrewarmService.instance.pinnedMessage;

        return _LiveChatWidget(
          userName: widget.userName,
          isAdmin: widget.isAdmin,
          chatMode: chatMode,
          pinnedMessage: pinnedMessage,
        );
      },
    );
  }
}

class _LiveChatWidget extends StatefulWidget {
  final String userName;
  final bool isAdmin;
  final String chatMode;
  final String pinnedMessage;

  const _LiveChatWidget({
    required this.userName,
    required this.isAdmin,
    required this.chatMode,
    required this.pinnedMessage,
  });

  @override
  State<_LiveChatWidget> createState() => _LiveChatWidgetState();
}

class _LiveChatWidgetState extends State<_LiveChatWidget>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  static List<QueryDocumentSnapshot> _persistentMemoryDocs = [];
  List<QueryDocumentSnapshot> _cachedDocs = List.from(_persistentMemoryDocs);
  late final Stream<QuerySnapshot> _chatStream;
  bool _isSending = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (_persistentMemoryDocs.isEmpty &&
        AppPrewarmService.instance.prewarmedChatDocs.isNotEmpty) {
      _persistentMemoryDocs = AppPrewarmService.instance.prewarmedChatDocs
          .whereType<QueryDocumentSnapshot>()
          .toList();
      _cachedDocs = List.from(_persistentMemoryDocs);
    }
    // 🚀 CACHED QUERY STREAM: Stream is pinned in state and never recreated on build
    _chatStream = FirebaseFirestore.instance
        .collection('live_session')
        .doc('current')
        .collection('chat')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _chatFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isSending) return;

    _chatController.clear();
    HapticFeedback.lightImpact();
    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance
          .collection('live_session')
          .doc('current')
          .collection('chat')
          .add({
        'sender': widget.userName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isAdmin': widget.isAdmin,
      });

      // Smooth scroll to bottom/latest
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint("Live chat send error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "Now";
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final bool isLockedForStudent =
        (!widget.isAdmin && widget.chatMode == 'locked');
    final bool isPrivateForStudent =
        (!widget.isAdmin && widget.chatMode == 'private');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        children: [
          // 📌 PINNED ANNOUNCEMENT BANNER
          if (widget.pinnedMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      widget.pinnedMessage,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFFFDE68A),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 💬 CHAT MESSAGES LIST WITH RIGHT-SIDE EMOJI COLUMN
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _chatStream,
                  builder: (context, chatSnapshot) {
                    if (chatSnapshot.hasData) {
                      _cachedDocs = chatSnapshot.data!.docs;
                      _persistentMemoryDocs = _cachedDocs;
                    }

                // If loading initially with NO cache, show a subtle spinner
                if (chatSnapshot.connectionState == ConnectionState.waiting &&
                    _cachedDocs.isEmpty) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  );
                }

                if (_cachedDocs.isEmpty) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 40,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Welcome to Live Chat!",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Be respectful and ask your questions.",
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                  reverse: true,
                  padding:
                      const EdgeInsets.fromLTRB(14, 8, 48, 8),
                  itemCount: _cachedDocs.length,
                  itemBuilder: (context, index) {
                    final msg =
                        _cachedDocs[index].data() as Map<String, dynamic>;
                    final bool msgIsAdmin = msg['isAdmin'] == true;
                    final bool isMe = msg['sender'] == widget.userName;

                    if (!widget.isAdmin && widget.chatMode == 'private') {
                      if (!isMe && !msgIsAdmin) return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: msgIsAdmin
                                ? const Color(0xFFB45309).withValues(alpha: 0.3)
                                : isMe
                                    ? AppColors.primary.withValues(alpha: 0.85)
                                    : const Color(0xFF1E293B)
                                        .withValues(alpha: 0.85),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                            border: Border.all(
                              color: msgIsAdmin
                                  ? const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.6)
                                  : isMe
                                      ? AppColors.primaryLight
                                          .withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (msgIsAdmin) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        "TEACHER",
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    msg['sender']?.toString() ?? 'User',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: msgIsAdmin
                                          ? const Color(0xFFFDE68A)
                                          : isMe
                                              ? Colors.white
                                              : AppColors.accent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(msg['timestamp'] as Timestamp?),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              SelectableText(
                                msg['text']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
            // 🎈 Floating Reactions Layer: Realtime floating bubbles directly over chat
            const Positioned.fill(
              child: IgnorePointer(
                child: FloatingReactionsLayer(),
              ),
            ),
            // Right-side floating reaction emojis column
            Positioned(
              right: 6,
              bottom: 8,
              child: EmojiReactionColumn(
                userName: widget.userName,
              ),
            ),
          ],
        ),
      ),

          // 🔒 CHAT LOCKED OR COMPOSER INPUT
          SafeArea(
            bottom: true,
            child: isLockedForStudent
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    width: double.infinity,
                    color: const Color(0xFF1E1E2C),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_rounded,
                            color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Text(
                          "Chat is currently locked by the instructor.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xDD0F172A),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isPrivateForStudent)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A)
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "🔒 Private Mode: Only the instructor can see your questions.",
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _chatController,
                                  focusNode: _chatFocusNode,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.white,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: isPrivateForStudent
                                        ? "Ask teacher privately..."
                                        : "Chat publicly with class...",
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color:
                                          Colors.white.withValues(alpha: 0.45),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _sendMessage,
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
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
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
