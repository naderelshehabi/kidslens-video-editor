import 'package:flutter/material.dart';

/// Transport controls for media playback
class TransportControls extends StatelessWidget {
  const TransportControls({
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    super.key,
    this.onPlay,
    this.onPause,
    this.onStop,
    this.onSkipForward,
    this.onSkipBackward,
    this.onPrevious,
    this.onNext,
    this.onSeek,
  });

  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;
  final VoidCallback? onSkipForward;
  final VoidCallback? onSkipBackward;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek bar
          Slider(
            value: _progressValue,
            onChanged: (value) {
              if (onSeek != null) {
                final position = Duration(
                  milliseconds: (value * totalDuration.inMilliseconds).round(),
                );
                onSeek!(position);
              }
            },
          ),
          // Time display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(currentPosition)),
                Text(_formatDuration(totalDuration)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onPrevious != null)
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: onPrevious,
                  tooltip: 'Previous',
                ),
              if (onSkipBackward != null)
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: onSkipBackward,
                  tooltip: 'Back 10s',
                ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: isPlaying ? onPause : onPlay,
                child: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 8),
              if (onSkipForward != null)
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: onSkipForward,
                  tooltip: 'Forward 10s',
                ),
              if (onNext != null)
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: onNext,
                  tooltip: 'Next',
                ),
              if (onStop != null)
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: onStop,
                  tooltip: 'Stop',
                ),
            ],
          ),
        ],
      );

  double get _progressValue {
    if (totalDuration.inMilliseconds == 0) return 0;
    return (currentPosition.inMilliseconds / totalDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
