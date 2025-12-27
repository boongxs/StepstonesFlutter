import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class UniversalPlayer extends StatefulWidget {
  final String filePath;
  final bool isAudio;

  const UniversalPlayer({
    super.key,
    required this.filePath,
    required this.isAudio,
  });

  @override
  State<UniversalPlayer> createState() => _UniversalPlayerState();
}

class _UniversalPlayerState extends State<UniversalPlayer> {
  late final Player player; // create the player instance
  late final VideoController controller; // create the video controller

  @override
  void initState() {
    super.initState();

    // initialize player
    player = Player();

    // initialize controller (links the player to the UI)
    controller = VideoController(player);

    player.setVolume(50.0); // initial volume at 50%
    player.open(Media(widget.filePath)); // start playing immediately
  }

  @override
  void dispose() {
    // stop playback and release resources when dialog closes
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioPlaceholder = Container(
      color: const Color(0xFF282828),
      alignment: Alignment.center,
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 120,
      ),
    );

    return Stack(
      children: [
        if (widget.isAudio) 
          Positioned.fill(child: audioPlaceholder),

        Video(
          controller: controller,
          fill: Colors.transparent, 
        ),
      ],
    );
  }
}