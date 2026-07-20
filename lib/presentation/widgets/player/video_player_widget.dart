import 'package:flutter/material.dart';

/// Video player widget for displaying media
class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({
    super.key,
    this.mediaPath,
    this.currentPosition = Duration.zero,
    this.isPlaying = false,
    this.onPlayPause,
    this.onSeek,
  });

  final String? mediaPath;
  final Duration currentPosition;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final ValueChanged<Duration>? onSeek;

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    if (widget.mediaPath == null) {
      return _buildPlaceholder(context);
    }

    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video frame placeholder
          const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Icon(
                Icons.movie,
                size: 64,
                color: Colors.white24,
              ),
            ),
          ),
          // Play/Pause overlay
          if (_showControls) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.video_library,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'No media loaded',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );

  Widget _buildControlsOverlay() => AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: ColoredBox(
          color: Colors.black38,
          child: Center(
            child: IconButton(
              iconSize: 64,
              icon: Icon(
                widget.isPlaying ? Icons.pause_circle : Icons.play_circle,
                color: Colors.white,
              ),
              onPressed: widget.onPlayPause,
            ),
          ),
        ),
      );
}
