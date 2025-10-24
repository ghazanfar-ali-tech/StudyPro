import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomMaterialControls extends StatefulWidget {
  final double rotationAngle;

  const CustomMaterialControls({super.key, required this.rotationAngle});

  @override
  State<StatefulWidget> createState() => _CustomMaterialControlsState();
}

class _CustomMaterialControlsState extends State<CustomMaterialControls> with SingleTickerProviderStateMixin {
  late AnimationController _controlsFadeController;
  late Animation<double> controlsFadeAnimation;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _controlsFadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    controlsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controlsFadeController, curve: Curves.easeInOut),
    );
    _controlsFadeController.forward();
  }

  @override
  void dispose() {
    _controlsFadeController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
      debugPrint('Controls visibility toggled: $_controlsVisible');
    });
    if (_controlsVisible) {
      _controlsFadeController.forward();
    } else {
      _controlsFadeController.reverse();
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return hours > 0
        ? '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}'
        : '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final chewieController = ChewieController.of(context);
    return Transform.rotate(
      angle: widget.rotationAngle,
      child: GestureDetector(
        onTap: _toggleControls,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
           
            Positioned.fill(
              child: VideoPlayer(chewieController.videoPlayerController),
            ),
          
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                       
                          Row(
                            children: [
                              ValueListenableBuilder(
                                valueListenable: chewieController.videoPlayerController,
                                builder: (context, VideoPlayerValue value, child) {
                                  return Text(
                                    _formatDuration(value.position),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 20,
                                  child: VideoProgressIndicator(
                                    chewieController.videoPlayerController,
                                    allowScrubbing: true,
                                    colors: VideoProgressColors(
                                      playedColor: Theme.of(context).primaryColor,
                                  
                                      backgroundColor: Colors.grey.withOpacity(0.3),
                                      bufferedColor: Colors.grey.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ValueListenableBuilder(
                                valueListenable: chewieController.videoPlayerController,
                                builder: (context, VideoPlayerValue value, child) {
                                  return Text(
                                    _formatDuration(value.duration),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                       
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                         
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.replay_10,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    final position = chewieController.videoPlayerController.value.position;
                                    final newPosition = position - const Duration(seconds: 10);
                                    debugPrint('Rewind pressed: seeking to $newPosition');
                                    chewieController.seekTo(
                                      newPosition < Duration.zero ? Duration.zero : newPosition,
                                    );
                                  },
                                ),
                              ),
                             
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: ValueListenableBuilder(
                                  valueListenable: chewieController.videoPlayerController,
                                  builder: (context, VideoPlayerValue value, child) {
                                    return IconButton(
                                      iconSize: 32,
                                      icon: Icon(
                                        value.isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        debugPrint('Play/pause pressed, current state: ${value.isPlaying}');
                                        chewieController.togglePause();
                                      },
                                    );
                                  },
                                ),
                              ),
                    
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.forward_10,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    final position = chewieController.videoPlayerController.value.position;
                                    final duration = chewieController.videoPlayerController.value.duration;
                                    final newPosition = position + const Duration(seconds: 10);
                                    debugPrint('Forward pressed: seeking to $newPosition');
                                    chewieController.seekTo(
                                      newPosition > duration ? duration : newPosition,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
           
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(
                              chewieController.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: () {
                              debugPrint('Fullscreen toggle pressed: ${chewieController.isFullScreen}');
                              chewieController.toggleFullScreen();
                            },
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
      ),
    );
  }
}