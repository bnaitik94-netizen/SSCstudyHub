class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
  });
}
