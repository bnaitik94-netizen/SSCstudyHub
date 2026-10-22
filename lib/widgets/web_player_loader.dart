import 'package:flutter/material.dart';
import 'web_player_stub.dart'
    if (dart.library.html) 'web_player_impl.dart';

/// Universal Web YouTube Player loader
/// Returns interactive, responsive YouTube player on Web, or stub on native
Widget getWebYouTubePlayer({
  Key? key,
  required String videoId,
  bool isLive = true,
  bool autoPlay = true,
  String? title,
}) {
  return buildWebYouTubePlayer(
    key: key,
    videoId: videoId,
    isLive: isLive,
    autoPlay: autoPlay,
    title: title,
  );
}
