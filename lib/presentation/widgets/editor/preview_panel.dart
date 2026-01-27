import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../data/models/detection.dart';
import '../../../data/models/edit_action.dart';
import '../../../data/models/media_file.dart';

/// Preview panel for video/audio with playback controls using media_kit
class PreviewPanel extends StatefulWidget {
  final MediaFile? media;
  final List<Detection> detections;
  final List<EditAction> editActions;

  const PreviewPanel({
    super.key,
    required this.media,
    required this.detections,
    required this.editActions,
  });

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  Player? _player;
  VideoController? _videoController;
  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  double _volume = 1.0;
  String? _currentMediaPath;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _player = Player();
    _videoController = VideoController(_player!);

    // Listen to player streams
    _player!.stream.position.listen((position) {
      if (mounted) {
        setState(() => _currentPosition = position);
      }
    });

    _player!.stream.duration.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _player!.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    _player!.stream.volume.listen((volume) {
      if (mounted) {
        setState(() => _volume = volume / 100.0);
      }
    });

    // Load initial media if available
    _loadMedia();
  }

  @override
  void didUpdateWidget(PreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if media changed
    if (widget.media?.path != oldWidget.media?.path) {
      _loadMedia();
    }
  }

  void _loadMedia() {
    if (widget.media == null) {
      _player?.stop();
      _currentMediaPath = null;
      return;
    }

    final mediaPath = widget.media!.path;
    if (mediaPath == _currentMediaPath) return;

    _currentMediaPath = mediaPath;

    // Check if file exists
    final file = File(mediaPath);
    if (!file.existsSync()) {
      debugPrint('Media file not found: $mediaPath');
      return;
    }

    // Open media file
    _player?.open(Media(mediaPath), play: false);
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          // Preview area
          Expanded(
            child: widget.media == null
                ? _buildEmptyState(context)
                : widget.media!.isVideo
                    ? _buildVideoPreview(context)
                    : _buildAudioPreview(context),
          ),
          
          // Playback controls
          if (widget.media != null)
            _buildPlaybackControls(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a media file to preview',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    // Detection overlays for current position
    final activeDetections = widget.detections
        .where((d) => d.containsTime(_currentPosition) && !d.isRejected)
        .toList();

    return Stack(
      children: [
        // Video player
        Center(
          child: AspectRatio(
            aspectRatio: widget.media!.aspectRatio > 0 
                ? widget.media!.aspectRatio 
                : 16 / 9,
            child: _videoController != null
                ? Video(
                    controller: _videoController!,
                    controls: (state) => const SizedBox.shrink(), // Custom controls below
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
          ),
        ),
        
        // Detection overlays
        if (activeDetections.isNotEmpty)
          Center(
            child: AspectRatio(
              aspectRatio: widget.media!.aspectRatio > 0 
                  ? widget.media!.aspectRatio 
                  : 16 / 9,
              child: Stack(
                children: activeDetections.map((detection) => 
                  _buildDetectionOverlay(detection)).toList(),
              ),
            ),
          ),
        
        // Detection indicators on the side
        if (activeDetections.isNotEmpty)
          Positioned(
            top: 8,
            right: 8,
            child: Column(
              children: activeDetections.map((d) => 
                _buildDetectionBadge(context, d)).toList(),
            ),
          ),

        // Play/Pause overlay on tap
        Positioned.fill(
          child: GestureDetector(
            onTap: () => _player?.playOrPause(),
            behavior: HitTestBehavior.translucent,
            child: !_isPlaying
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionOverlay(Detection detection) {
    // For visual detections, we would show bounding boxes here
    if (detection.isVisualDetection) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _getDetectionColor(detection),
            width: 3,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDetectionBadge(BuildContext context, Detection detection) {
    final color = _getDetectionColor(detection);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getDetectionIcon(detection),
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            detection.typeDisplayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Detection indicators for audio
    final activeDetections = widget.detections
        .where((d) => d.containsTime(_currentPosition) && !d.isRejected)
        .toList();

    return Column(
      children: [
        // Audio info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.audiotrack,
                size: 32,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                widget.media!.name,
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
        
        // Waveform visualization
        Expanded(
          child: _buildWaveform(context),
        ),
        
        // Active detections
        if (activeDetections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: activeDetections.map((d) => 
                _buildDetectionBadge(context, d)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildWaveform(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return CustomPaint(
      painter: _WaveformPainter(
        color: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHigh,
        position: _currentPosition,
        duration: _duration.inMilliseconds > 0 ? _duration : (widget.media?.duration ?? Duration.zero),
        detections: widget.detections,
        editActions: widget.editActions,
      ),
      size: Size.infinite,
    );
  }

  Widget _buildPlaybackControls(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final duration = _duration.inMilliseconds > 0 
        ? _duration 
        : (widget.media?.duration ?? Duration.zero);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Timeline scrubber
          Row(
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: duration.inMilliseconds > 0
                        ? (_currentPosition.inMilliseconds / 
                           duration.inMilliseconds).clamp(0.0, 1.0)
                        : 0,
                    onChanged: (value) {
                      final seekPosition = Duration(
                        milliseconds: (value * duration.inMilliseconds).round(),
                      );
                      _player?.seek(seekPosition);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(duration),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Playback buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () => _player?.seek(Duration.zero),
              ),
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  final newPosition = Duration(
                    milliseconds: math.max(0, _currentPosition.inMilliseconds - 10000),
                  );
                  _player?.seek(newPosition);
                },
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                onPressed: () => _player?.playOrPause(),
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {
                  final newPosition = Duration(
                    milliseconds: math.min(
                      duration.inMilliseconds,
                      _currentPosition.inMilliseconds + 10000,
                    ),
                  );
                  _player?.seek(newPosition);
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => _player?.seek(duration),
              ),
              
              const SizedBox(width: 24),
              
              // Volume control
              IconButton(
                icon: Icon(
                  _volume == 0 ? Icons.volume_off : Icons.volume_up,
                  size: 18,
                ),
                onPressed: () {
                  _player?.setVolume(_volume == 0 ? 100 : 0);
                },
              ),
              SizedBox(
                width: 100,
                child: Slider(
                  value: _volume,
                  onChanged: (value) {
                    _player?.setVolume(value * 100);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getDetectionColor(Detection detection) {
    switch (detection.type) {
      case ContentType.profanity:
        return Colors.orange;
      case ContentType.nsfw:
        return Colors.red;
      case ContentType.violence:
        return Colors.deepOrange;
      case ContentType.blood:
        return Colors.red.shade900;
      case ContentType.weapons:
        return Colors.amber;
    }
  }

  IconData _getDetectionIcon(Detection detection) {
    switch (detection.type) {
      case ContentType.profanity:
        return Icons.volume_off;
      case ContentType.nsfw:
        return Icons.visibility_off;
      case ContentType.violence:
        return Icons.sports_mma;
      case ContentType.blood:
        return Icons.water_drop;
      case ContentType.weapons:
        return Icons.warning;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final frames = ((duration.inMilliseconds % 1000) / 33.33).round();

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${frames.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}:${frames.toString().padLeft(2, '0')}';
  }
}

/// Custom painter for waveform visualization
class _WaveformPainter extends CustomPainter {
  final Color color;
  final Color backgroundColor;
  final Duration position;
  final Duration duration;
  final List<Detection> detections;
  final List<EditAction> editActions;

  _WaveformPainter({
    required this.color,
    required this.backgroundColor,
    required this.position,
    required this.duration,
    required this.detections,
    required this.editActions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    if (duration.inMilliseconds == 0) return;

    // Draw detection regions
    for (final detection in detections) {
      if (detection.isRejected) continue;
      
      final startX = (detection.startTime.inMilliseconds / 
          duration.inMilliseconds) * size.width;
      final endX = (detection.endTime.inMilliseconds / 
          duration.inMilliseconds) * size.width;
      
      final detectionPaint = Paint()
        ..color = _getDetectionColor(detection.type).withOpacity(0.3);
      
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        detectionPaint,
      );
    }

    // Draw fake waveform
    final wavePaint = Paint()
      ..color = color
      ..strokeWidth = 1;
    
    final centerY = size.height / 2;
    final random = math.Random(42); // Fixed seed for consistent waveform
    
    for (double x = 0; x < size.width; x += 2) {
      final amplitude = random.nextDouble() * size.height * 0.35;
      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        wavePaint,
      );
    }

    // Draw position indicator
    final positionX = (position.inMilliseconds / 
        duration.inMilliseconds) * size.width;
    final positionPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(positionX, 0),
      Offset(positionX, size.height),
      positionPaint,
    );
  }

  Color _getDetectionColor(ContentType type) {
    switch (type) {
      case ContentType.profanity:
        return Colors.orange;
      case ContentType.nsfw:
        return Colors.red;
      case ContentType.violence:
        return Colors.deepOrange;
      case ContentType.blood:
        return Colors.red.shade900;
      case ContentType.weapons:
        return Colors.amber;
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.duration != duration ||
        oldDelegate.detections != detections;
  }
}
