import 'dart:math';
import 'dart:ui';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:studypro/components/appColor.dart';
import 'package:studypro/components/custom_material_controller.dart';
import 'package:studypro/components/size_config.dart';
import 'package:studypro/models/courseModel.dart';
import 'package:studypro/providers/course_provider.dart';
import 'package:studypro/providers/theme_provider.dart';
import 'package:studypro/services/progressive_services.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PlayVideoScreen extends StatefulWidget {
  final String? courseId;
  final VideoData video;

  const PlayVideoScreen({
    super.key,
    this.courseId,
    required this.video,
  });

  @override
  State<PlayVideoScreen> createState() => _PlayVideoScreenState();
}

class _PlayVideoScreenState extends State<PlayVideoScreen> with TickerProviderStateMixin {
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;
  bool _isLoading = true;
  String? _error;
  bool _isFullScreen = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDisposed = false;
  bool _lockOrientation = false;
  double _manualRotationAngle = 0.0;
  bool _isPlaying = false;
  bool _isRotating = false;
  int _lastProgressUpdate = 0;
  CourseProvider? _courseProvider;
  
  

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _courseProvider = Provider.of<CourseProvider>(context, listen: false);
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Initializing video with URL: ${widget.video.videoUrl}');
      if (widget.video.videoUrl.isNotEmpty) {
        final uri = Uri.tryParse(widget.video.videoUrl);
        if (uri == null || !uri.hasScheme) {
          throw Exception('Invalid video URL: ${widget.video.videoUrl}');
        }

        _videoPlayerController = VideoPlayerController.networkUrl(
          uri,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
           
          ),
        );

        await _videoPlayerController!.initialize();
        if (!mounted || _isDisposed) return;

        debugPrint('Video initialized: aspectRatio=${_videoPlayerController!.value.aspectRatio}, '
            'size=${_videoPlayerController!.value.size}');

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
          showControlsOnInitialize: true,
          hideControlsTimer: const Duration(seconds: 3),
          customControls: CustomMaterialControls(rotationAngle: _manualRotationAngle),
          materialProgressColors: ChewieProgressColors(
            playedColor: Theme.of(context).primaryColor,
            handleColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.grey.withOpacity(0.3),
            bufferedColor: Colors.grey.withOpacity(0.5),
          ),
          errorBuilder: (context, errorMessage) => _buildErrorWidget(errorMessage),
        );

        if (!_isDisposed && mounted) {
          _videoPlayerController!.addListener(_videoListener);
          _chewieController!.addListener(_fullScreenListener);
          _fadeController.forward();
        }
      } else {
        _error = 'No video URL provided';
        debugPrint('Error: Empty video URL');
      }
    } catch (e, stackTrace) {
      _error = 'Failed to load video: $e';
      debugPrint('Error loading video: $e\nStackTrace: $stackTrace');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


void _updateVideoProgress() {
  if (_videoPlayerController == null || widget.courseId == null || _isDisposed || !mounted) {
    debugPrint('Cannot update progress: controller=${_videoPlayerController != null}, courseId=${widget.courseId}, disposed=$_isDisposed, mounted=$mounted');
    return;
  }

  if (_courseProvider == null) {
    debugPrint('Cannot update progress: courseProvider is null');
    return;
  }

  final course = _courseProvider!.selectedCourse;

  if (course == null) {
    debugPrint('Cannot update progress: course is null');
    return;
  }

  List<String> skills = [];
  if (course.category == 'Programming') {
    skills = ['Programming', 'Problem Solving', 'Code Structure'];
  } else if (course.category == 'Design') {
    skills = ['Design Principles', 'Creativity', 'Visual Communication'];
  } else if (course.category == 'Data Science') {
    skills = ['Data Analysis', 'Statistics', 'Machine Learning'];
  } else {
    skills = [course.category, 'Critical Thinking', 'Knowledge Application'];
  }

  ProgressService.updateVideoProgress(
    videoId: widget.video.title.hashCode.toString(), 
    videoTitle: widget.video.title,
    courseId: widget.courseId!,
    courseTitle: course.title,
    watchedDuration: _currentPosition,
    totalDuration: _totalDuration,
    skillsLearned: skills,
  );
  debugPrint('Progress updated for video: ${widget.video.title}, position: $_currentPosition');
  _lastProgressUpdate = _currentPosition.inSeconds;
}



  void _videoListener() {
    if (_isDisposed || !mounted || _videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
      return;
    }

    setState(() {
      _currentPosition = _videoPlayerController!.value.position;
      _totalDuration = _videoPlayerController!.value.duration;
      _isPlaying = _videoPlayerController!.value.isPlaying;
    });

    if (_currentPosition.inSeconds > 0 && _currentPosition.inSeconds % 30 == 0 && _currentPosition.inSeconds != _lastProgressUpdate) {
      _updateVideoProgress();
    }

    if (_currentPosition >= _totalDuration && _currentPosition.inSeconds != _lastProgressUpdate) {
      _updateVideoProgress();
    }
  }

  void _fullScreenListener() {
    if (_isDisposed || !mounted || _chewieController == null) {
      return;
    }
    final bool isNowFullScreen = _chewieController!.isFullScreen;
    if (_isFullScreen != isNowFullScreen) {
      setState(() {
        _isFullScreen = isNowFullScreen;
      });

      if (_isFullScreen && !_lockOrientation) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]).then((_) {
          debugPrint('Set landscape orientation');
        }).catchError((e) {
          debugPrint('Error setting orientation: $e');
        });
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
          debugPrint('Reset to portrait orientation');
        }).catchError((e) {
          debugPrint('Error resetting orientation: $e');
        });
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    }
  }

  void _rotateVideoManually() async {
    if (_isDisposed || !mounted || _isRotating || _chewieController == null || _videoPlayerController == null) {
      debugPrint('Rotation blocked: disposed=$_isDisposed, mounted=$mounted, rotating=$_isRotating, controller=${_chewieController != null}');
      return;
    }

    if (_videoPlayerController!.value.isPlaying) {
      await _videoPlayerController!.pause();
      debugPrint('Paused video for rotation');
    }

    setState(() {
      _isRotating = true;
      _manualRotationAngle += pi / 2;
      if (_manualRotationAngle >= 2 * pi) _manualRotationAngle = 0.0;
      _lockOrientation = true;
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: false,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: true,
        hideControlsTimer: const Duration(seconds: 3),
        customControls: CustomMaterialControls(rotationAngle: _manualRotationAngle),
        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
          backgroundColor: Colors.grey.withOpacity(0.3),
          bufferedColor: Colors.grey.withOpacity(0.5),
        ),
        errorBuilder: (context, errorMessage) => _buildErrorWidget(errorMessage),
      );
    });

    try {
      final currentOrientation = MediaQuery.of(context).orientation;
      await SystemChrome.setPreferredOrientations([
        currentOrientation == Orientation.portrait
            ? DeviceOrientation.portraitUp
            : DeviceOrientation.landscapeLeft,
      ]);
      debugPrint('Locked orientation for manual rotation: $currentOrientation');
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Error locking orientation: $e');
      if (mounted) _showSnackBar('Error rotating video: $e');
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isRotating = false;
          if (_isPlaying && _videoPlayerController != null) {
            _videoPlayerController!.play();
            debugPrint('Resumed video after rotation');
          }
        });
      }
    }
  }

  void _toggleOrientationLock() {
    if (_isDisposed || !mounted) return;

    setState(() {
      _lockOrientation = !_lockOrientation;
      if (!_lockOrientation) {
        _manualRotationAngle = 0.0;
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
          showControlsOnInitialize: true,
          hideControlsTimer: const Duration(seconds: 3),
          customControls: CustomMaterialControls(rotationAngle: _manualRotationAngle),
          materialProgressColors: ChewieProgressColors(
            playedColor: Theme.of(context).primaryColor,
            handleColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.grey.withOpacity(0.3),
            bufferedColor: Colors.grey.withOpacity(0.5),
          ),
          errorBuilder: (context, errorMessage) => _buildErrorWidget(errorMessage),
        );
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
          debugPrint('Unlocked orientation to portrait');
        }).catchError((e) {
          debugPrint('Error unlocking orientation: $e');
        });
      }
    });
  }

  @override
  void dispose() {
    if (_currentPosition.inSeconds > 0 && _currentPosition.inSeconds != _lastProgressUpdate) {
      _updateVideoProgress();
    }
    _isDisposed = true;
    _videoPlayerController?.pause();
    _videoPlayerController?.removeListener(_videoListener);
    _chewieController?.removeListener(_fullScreenListener);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _fadeController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
      debugPrint('Restored portrait orientation on dispose');
    }).catchError((e) {
      debugPrint('Error restoring orientation: $e');
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    debugPrint('Widget disposed');
    super.dispose();
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      width: double.infinity,
      height: SizeConfig().scaleHeight(200, context),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red[400],
          ),
           SizedBox(height: SizeConfig().scaleHeight(16, context)),
          Text(
            'Failed to load video',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
           SizedBox(height: SizeConfig().scaleHeight(8, context)),
          Text(
            errorMessage,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
           SizedBox(height: SizeConfig().scaleHeight(16, context)),
          ElevatedButton.icon(
            onPressed: _initializeVideoPlayer,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

 
Widget _buildVideoPlayer() {
    if (_isDisposed || _chewieController == null || !_chewieController!.videoPlayerController.value.isInitialized) {
      debugPrint('Video player not rendered: disposed=$_isDisposed, controller=${_chewieController != null}');
      return const Center(child: CircularProgressIndicator());
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        if (_isDisposed || _chewieController == null || _isRotating) {
          debugPrint('OrientationBuilder skipped: disposed=$_isDisposed, controller=${_chewieController != null}, rotating=$_isRotating');
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 12),
            boxShadow: _isFullScreen
                ? null
                : [
                    BoxShadow(
                      color: AppColors.shadow(context),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 12),
            child: AspectRatio(
              aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
              child: Chewie(controller: _chewieController!),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoInfo() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
              height: 1.3,
            ),
          ),
           SizedBox(height: SizeConfig().scaleHeight(8, context)),
          if (widget.video.description.isNotEmpty)
            Text(
              widget.video.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary(context),
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                color: AppColors.iconPrimary,
                size: 20,
              ),
               SizedBox(width: SizeConfig().scaleWidth(8, context)),
              Text(
                'Playback Controls',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
           SizedBox(height: SizeConfig().scaleHeight(16, context)),
          _buildSpeedControl(),
           SizedBox(height: SizeConfig().scaleHeight(16, context)),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildSpeedControl() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.speed_rounded,
              color: AppColors.iconPrimary,
              size: 18,
            ),
             SizedBox(width: SizeConfig().scaleWidth(8, context)),
            Text(
              'Playback Speed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
         SizedBox(height: SizeConfig().scaleHeight(12, context)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardBackground(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<double>(
              value: _chewieController?.videoPlayerController.value.playbackSpeed ?? 1.0,
              isExpanded: true,
              dropdownColor: AppColors.cardBackground(context),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.iconSecondary(context),
              ),
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                DropdownMenuItem(value: 0.25, child: Text('🐌 0.25x (Slow)')),
                DropdownMenuItem(value: 0.5, child: Text('🚶 0.5x (Half)')),
                DropdownMenuItem(value: 0.75, child: Text('⚡ 0.75x')),
                DropdownMenuItem(value: 1.0, child: Text('▶️ 1.0x (Normal)')),
                DropdownMenuItem(value: 1.25, child: Text('🏃 1.25x')),
                DropdownMenuItem(value: 1.5, child: Text('🚀 1.5x (Fast)')),
                DropdownMenuItem(value: 2.0, child: Text('⚡ 2.0x (Fastest)')),
              ],
              onChanged: (value) {
                if (value != null && _chewieController != null && mounted) {
                  debugPrint('Setting playback speed to $value');
                  _chewieController!.videoPlayerController.setPlaybackSpeed(value);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Speed changed to ${value}x'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickActionChip(
          context: context,
          icon: Icons.replay_10_rounded,
          label: 'Rewind 10s',
          onPressed: () {
            if (_videoPlayerController != null && mounted) {
              final newPosition = _currentPosition - const Duration(seconds: 10);
              debugPrint('Rewinding to $newPosition');
              _videoPlayerController!.seekTo(
                newPosition < Duration.zero ? Duration.zero : newPosition,
              );
            }
          },
        ),
        _buildQuickActionChip(
          context: context,
          icon: _videoPlayerController?.value.isPlaying ?? false
              ? Icons.pause_circle_rounded
              : Icons.play_circle_rounded,
          label: _videoPlayerController?.value.isPlaying ?? false ? 'Pause' : 'Play',
          onPressed: () {
            if (_videoPlayerController != null && mounted) {
              if (_videoPlayerController!.value.isPlaying) {
                _videoPlayerController!.pause();
              } else {
                _videoPlayerController!.play();
              }
              setState(() {});
            }
          },
        ),
        _buildQuickActionChip(
          context: context,
          icon: Icons.forward_10_rounded,
          label: 'Forward 10s',
          onPressed: () {
            if (_videoPlayerController != null && mounted) {
              final newPosition = _currentPosition + const Duration(seconds: 10);
              debugPrint('Forwarding to $newPosition');
              _videoPlayerController!.seekTo(
                newPosition > _totalDuration ? _totalDuration : newPosition,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBackground(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: AppColors.iconPrimary,
                  size: 24,
                ),
                 SizedBox(height: SizeConfig().scaleHeight(4, context)),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResourcesSection() {
    final hasUrls = widget.video.urls.isNotEmpty;
    final hasPdfs = widget.video.pdfUrls.isNotEmpty;

    if (!hasUrls && !hasPdfs) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resources',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
           SizedBox(height: SizeConfig().scaleHeight(12, context)),
          if (hasUrls) ...[
            _buildResourceList(
              title: 'Related Links',
              icon: Icons.link,
              items: widget.video.urls,
              onTap: _launchUrl,
            ),
            if (hasPdfs)  SizedBox(height: SizeConfig().scaleHeight(12, context)),
          ],
          if (hasPdfs)
            _buildResourceList(
              title: 'Downloadable PDFs',
              icon: Icons.picture_as_pdf,
              items: widget.video.pdfUrls,
              onTap: (url) => _downloadPdf(url, 'course_${widget.courseId}_pdf'),
              trailing: Icon(Icons.download, size: 20, color: AppColors.iconSecondary(context)),
            ),
        ],
      ),
    );
  }

  Widget _buildResourceList({
    required String title,
    required IconData icon,
    required List<String> items,
    required Function(String) onTap,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.iconSecondary(context)),
             SizedBox(width: SizeConfig().scaleWidth(8, context)),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ],
        ),
         SizedBox(height: SizeConfig().scaleHeight(8, context)),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border(context)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              title: Text(
                '${title.contains('PDF') ? 'PDF' : 'Link'} ${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
              ),
              trailing: trailing ??
                  Icon(
                    Icons.open_in_new,
                    size: 20,
                    color: AppColors.iconSecondary(context),
                  ),
              onTap: () => onTap(item),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCourseInfo() {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    final course = courseProvider.selectedCourse;

    if (course == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Course Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
           SizedBox(height: SizeConfig().scaleHeight(12, context)),
          _buildInfoRow(Icons.school, 'Course', course.title),
          _buildInfoRow(Icons.person, 'Instructor', '${course.createdByUsername} (${course.createdBy})'),
          _buildInfoRow(Icons.schedule, 'Duration', course.duration),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.iconSecondary(context)),
           SizedBox(width: SizeConfig().scaleWidth(12, context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

void _launchUrl(String url) async {
  if (url.isEmpty) return;

  final Uri uri = Uri.parse(
      url.startsWith('http://') || url.startsWith('https://') ? url : 'https://$url');

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.platformDefault); 
  } else {
    debugPrint('Could not launch $url');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }
}

Future<void> _requestStoragePermission() async {
  if (Platform.isAndroid) {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  } else {
    await Permission.storage.request();
  }
}

Future<void> _downloadPdf(String pdfUrl, String fileName) async {
  await _requestStoragePermission();

  try {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(days: 1), 
          content: Row(
            children:  [
              SizedBox(
                width: SizeConfig().scaleWidth(16, context),
                height: SizeConfig().scaleHeight(16, context),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: SizeConfig().scaleWidth(12, context)),
              Text('Downloading PDF...'),
            ],
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }

    debugPrint('Attempting to download PDF from: $pdfUrl');
    final response = await http.get(Uri.parse(pdfUrl));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (response.statusCode == 200) {
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final filePath = '${downloadsDir.path}/$fileName.pdf';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) {
        _showSnackBar('PDF saved to Downloads');
      }

      debugPrint('PDF downloaded to: $filePath');
    } else {
      if (mounted) {
        _showSnackBar('Failed to download PDF (${response.statusCode})');
      }
      debugPrint('Download failed with status: ${response.statusCode}');
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackBar('Error downloading PDF: $e');
    }
    debugPrint('Error downloading PDF: $e');
  }
}

  void _showSnackBar(String message, {bool isLoading = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (isLoading) ...[
                 SizedBox(
                  width: SizeConfig().scaleWidth(16, context),
                  height: SizeConfig().scaleHeight(16, context),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                 SizedBox(width: SizeConfig().scaleWidth(12, context)),
              ],
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isLoading ? Colors.blue : null,
        ),
      );
    }
  }

@override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: _isFullScreen
          ? null
          : AppBar(
              elevation: 0,
              backgroundColor: AppColors.cardBackground(context),
              foregroundColor: AppColors.textPrimary(context),
              title: Text(
                widget.video.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.rotate_right, color: AppColors.iconPrimary),
                  onPressed: (_chewieController != null && !_isRotating && !_isDisposed)
                      ? _rotateVideoManually
                      : null,
                  tooltip: 'Rotate Video Manually',
                ),
                IconButton(
                  icon: Icon(
                    _lockOrientation ? Icons.lock : Icons.lock_open,
                    color: AppColors.iconPrimary,
                  ),
                  onPressed: (_chewieController != null && !_isDisposed) ? _toggleOrientationLock : null,
                  tooltip: _lockOrientation ? 'Unlock Orientation' : 'Lock Orientation',
                ),
              ],
            ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                   SizedBox(height: SizeConfig().scaleHeight(16, context)),
                  Text(
                    'Loading video...',
                    style: TextStyle(
                      color: AppColors.textPrimary(context),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildErrorWidget(_error!),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: _isFullScreen
                      ? _buildVideoPlayer()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet = constraints.maxWidth > 600;
                            final padding = isTablet ? 24.0 : 16.0;
                            return SingleChildScrollView(
                              padding: EdgeInsets.all(padding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildVideoPlayer(),
                                  SizedBox(height: padding),
                                  isTablet
                                      ? Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Column(
                                                children: [
                                                  _buildVideoInfo(),
                                                  SizedBox(height: padding),
                                                  _buildPlaybackControls(),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: padding),
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _buildResourcesSection(),
                                                  SizedBox(height: padding),
                                                  _buildCourseInfo(),
                                                ],
                                              ),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          children: [
                                            _buildVideoInfo(),
                                            SizedBox(height: padding),
                                            _buildPlaybackControls(),
                                            SizedBox(height: padding),
                                            _buildResourcesSection(),
                                            SizedBox(height: padding),
                                            _buildCourseInfo(),
                                          ],
                                        ),
                                  SizedBox(height: padding),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

