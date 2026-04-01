import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class UniversalPlayerMobile extends StatefulWidget {
  final String filePath;
  final bool isAudio;
  final bool showControls;
  final VoidCallback onTap;
  final double bottomInset;

  const UniversalPlayerMobile({
    super.key,
    required this.filePath,
    this.isAudio = false,
    required this.showControls,
    required this.onTap,
    required this.bottomInset,
  });

  @override
  State<UniversalPlayerMobile> createState() => _UniversalPlayerMobileState();
}

class _UniversalPlayerMobileState extends State<UniversalPlayerMobile> {
  late final Player player;
  late final VideoController controller;

  bool isPlaying = true;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;

  List<StreamSubscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    player.setVolume(100);

    subscriptions.addAll([
      player.stream.playing.listen((p) {
        if (mounted) setState(() => isPlaying = p);
      }),
      player.stream.position.listen((p) {
        if (mounted) setState(() => position = p);
      }),
      player.stream.duration.listen((d) {
        if (mounted) setState(() => duration = d);
      }),
    ]);

    player.open(Media(widget.filePath));
  }

  @override
  void dispose() {
    for (final s in subscriptions) {
      s.cancel();
    }

    player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${d.inHours}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Media layer
          widget.isAudio
            ? const Center(child: Icon(Icons.audiotrack, size: 64, color: Colors.white54))
            : Video(
              controller: controller,
              controls: NoVideoControls,
            ),
          
          // 2. Mobile controls layer
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: widget.bottomInset + 16.0),
              child: AnimatedOpacity(
                opacity: widget.showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !widget.showControls,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => player.playOrPause(),
                          child: Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
            
                        const SizedBox(width: 8),
            
                        Text(
                          "${_format(position)} / ${_format(duration)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}