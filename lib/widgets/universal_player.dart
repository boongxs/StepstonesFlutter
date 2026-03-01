import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../services/logger_service.dart';

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
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    // initialize
    player = Player();
    controller = VideoController(player);
    _focusNode = FocusNode();

    player.setVolume(50.0); // initial volume at 50%
    player.open(Media(widget.filePath)); // start playing immediately

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
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

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            // get current volume, add 10, and clamp it between 0 and 100
            final newVol = (player.state.volume + 10.0).clamp(0.0, 100.0);
            player.setVolume(newVol);
            LogService.i("Up arrow key");

            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            // get current volume, subtract 10, and clamp it between 0 and 100
            final newVol = (player.state.volume - 10.0).clamp(0.0, 100.0);
            player.setVolume(newVol);
            LogService.i("Down arrow key");

            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored; // ignore all other keys
      },
      child: Listener(
        onPointerDown: (_) {
          if (!_focusNode.hasFocus) {
            _focusNode.requestFocus();
          }
        },
        child: Stack(
          children: [
            if (widget.isAudio) Positioned.fill(child: audioPlaceholder),
        
            Positioned.fill(
              child: Video(
                controller: controller,
                fill: Colors.transparent,
                controls: (state) {
                  return CustomVideoControls(player: player);
                },
              ),
            ),

            Positioned.fill(
              child: ActionIndicatorOverlay(player: player),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomVideoControls extends StatefulWidget {
  final Player player;
  const CustomVideoControls({
    super.key,
    required this.player
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _wasPlayingBeforeDrag = false;
  bool _isFinished = false;
  late StreamSubscription<bool> _completedSubscription;

  @override
  void initState() {
    super.initState();
    _completedSubscription = widget.player.stream.completed.listen((completed) {
      if (mounted) {
        setState(() {
          _isFinished = completed;
        });
      }
    });
  }

  @override
  void dispose() {
    _completedSubscription.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }

    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // tap to pause background
        // fills all available space
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.player.playOrPause,
          child: const SizedBox.expand(),
        ),

        // bottom control bar
        Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            // opaque makes this bottom container absorb all clicks
            // prevents clicks on bottom bar to pass through to play/pause layer
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // play/pause button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      height: 50,
                      child: StreamBuilder<Duration>(
                        stream: widget.player.stream.position,
                        builder: (context, positionSnapshot) {
                          return StreamBuilder<Duration>(
                            stream: widget.player.stream.duration,
                            builder: (context, durationSnapshot) {
                              final position = positionSnapshot.data ?? Duration.zero;
                              final duration = durationSnapshot.data ?? Duration.zero;
                              final max = duration.inMilliseconds.toDouble();
                              final streamVal = _isFinished
                                ? max
                                : position.inMilliseconds.toDouble().clamp(0.0, max > 0 ? max : 1.0);
                              final currentSliderValue = _isDragging ? _dragValue : streamVal;
                    
                              return SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18.0),
                                ),
                                child: Slider(
                                  value: currentSliderValue,
                                  max: max > 0 ? max : 1.0,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white.withValues(alpha: 0.3),
                                  onChangeStart: (newVal) {
                                    _wasPlayingBeforeDrag = widget.player.state.playing;
                                    widget.player.pause();
                                    setState(() {
                                      _isDragging = true;
                                      _dragValue = newVal;
                                      _isFinished = false;
                                    });
                                  },
                                                    
                                  onChanged: (newVal) {
                                    setState(() {
                                      _dragValue = newVal;
                                    });
                                    widget.player.seek(Duration(milliseconds: newVal.toInt()));
                                  },
                                  onChangeEnd: (newVal) {
                                    setState(() {
                                      _isDragging = false;
                                    });
                                    widget.player.seek(Duration(milliseconds: newVal.toInt()));
                                    if (_wasPlayingBeforeDrag) {
                                      widget.player.play();
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // play/pause & time indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // play/pause button
                        StreamBuilder<bool>(
                          stream: widget.player.stream.playing,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            final icon = _isFinished
                              ? Icons.replay_rounded
                              : (isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded);
                    
                            return IconButton(
                              iconSize: 30.0,
                              icon: Icon(icon),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: widget.player.playOrPause,
                            );
                          },
                        ),

                        const SizedBox(width: 20),

                        _VolumeControl(player: widget.player),
                    
                        const SizedBox(width: 20),
                    
                        // time indicator
                        StreamBuilder<Duration>(
                          stream: widget.player.stream.position,
                          builder: (context, positionSnapshot) {
                            return StreamBuilder<Duration>(
                              stream: widget.player.stream.duration,
                              builder: (context, durationSnapshot) {
                                final duration = durationSnapshot.data ?? Duration.zero;
                    
                                Duration position;
                                if (_isFinished) {
                                  position = duration;
                                } else if (_isDragging) {
                                  position = Duration(milliseconds: _dragValue.toInt());
                                } else {
                                  position = positionSnapshot.data ?? Duration.zero;
                                }
                    
                                return Text(
                                  "${_formatDuration(position)} / ${_formatDuration(duration)}",
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VolumeControl extends StatefulWidget {
  final Player player;

  const _VolumeControl({
    required this.player
  });

  @override
  State<_VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<_VolumeControl> {
  bool _isHovered = false;
  double _lastVolume = 50.0;

  IconData _getVolumeIcon(double volume) {
    if (volume == 0) return Icons.volume_off_rounded;
    if (volume < 50.0) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  void _toggleMute(double currentVolume) {
    if (currentVolume > 0) {
      _lastVolume = currentVolume;
      widget.player.setVolume(0.0);
    } else {
      widget.player.setVolume(_lastVolume > 0 ? _lastVolume : 50.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: StreamBuilder<double>(
        stream: widget.player.stream.volume,
        builder: (context, snapshot) {
          final volume = snapshot.data ?? 50.0;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // volume icon/mute toggle
              IconButton(
                iconSize: 28.0,
                icon: Icon(_getVolumeIcon(volume)),
                color: Colors.white,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _toggleMute(volume),
              ),

              // expanding volume slider
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                width: _isHovered ? 80.0 : 0.0,
                margin: EdgeInsets.only(left: _isHovered ? 8.0 : 0.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: 80.0,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.0,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                      ),
                      child: Slider(
                        value: volume,
                        max: 100.0,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white.withValues(alpha: 0.3),
                        onChanged: (val) {
                          widget.player.setVolume(val);
                          if (val > 0) _lastVolume = val;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ActionIndicatorOverlay extends StatefulWidget {
  final Player player;

  const ActionIndicatorOverlay({
    super.key,
    required this.player,
  });

  @override
  State<ActionIndicatorOverlay> createState() => _ActionIndicatorOverlayState();
}

class _ActionIndicatorOverlayState extends State<ActionIndicatorOverlay> {
  bool _isVisible = false;
  IconData _icon = Icons.play_arrow_rounded;
  String? _text; // will hold the volume percentage
  Timer? _hideTimer;

  bool? _lastPlaying;
  double? _lastVolume;

  late StreamSubscription<bool> _playingSub;
  late StreamSubscription<double> _volumeSub;

  @override
  void initState() {
    super.initState();
    // grab initial states so we don't trigger the animation the second the video loads
    _lastPlaying = widget.player.state.playing;
    _lastVolume = widget.player.state.volume;

    // listen for play/pause changes
    _playingSub = widget.player.stream.playing.listen((isPlaying) {
      if (_lastPlaying != isPlaying) {
        _lastPlaying = isPlaying;
        _showIndicator(
          isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
          null, // no text for play/pause
        );
      }
    });

    // listen for volume changes
    _volumeSub = widget.player.stream.volume.listen((vol) {
      if (_lastVolume != vol) {
        final isUp = vol > (_lastVolume ?? 0);
        _lastVolume = vol;

        IconData icon;
        if (vol == 0) {
          icon = Icons.volume_off_rounded;
        } else if (isUp) {
          icon = Icons.volume_up_rounded;
        } else {
          icon = Icons.volume_down_rounded;
        }

        _showIndicator(
          icon, 
          "${vol.toInt()}%"
        );
      }
    });
  }

  void _showIndicator(IconData icon, String? text) {
    if (!mounted) return;

    // cancel any existing timer so the indicator stays visible for full duration if user is spamming the button
    _hideTimer?.cancel();

    setState(() {
      _isVisible = true;
      _icon = icon;
      _text = text;
    });

    // wait 800ms after last change, then fade out
    _hideTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _playingSub.cancel();
    _volumeSub.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IgnorePointer so clicks pass through onto video if clicked on overlay
    return IgnorePointer(
      child: Center(
        child: AnimatedOpacity(
          opacity: _isVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedScale(
            // shrinks to 80% when hidden, grows to 100% when visible
            scale: _isVisible ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // dark circle icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_icon, color: Colors.white, size: 48),
                ),

                // volume text rectangle (only shows if text is not null)
                if (_text != null) ...[
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _text!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}