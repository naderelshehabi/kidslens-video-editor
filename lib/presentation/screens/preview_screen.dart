import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/detection.dart';
import '../../state/providers/analysis_provider.dart';
import '../../state/providers/timeline_provider.dart';
import '../themes/app_theme.dart';

/// Full-screen video preview with playback controls
class PreviewScreen extends ConsumerStatefulWidget {
  final Duration? initialPosition;

  const PreviewScreen({
    super.key,
    this.initialPosition,
  });

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(timelineNotifierProvider.notifier).setPlayheadPosition(widget.initialPosition!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineNotifierProvider);
    final analysisState = ref.watch(analysisNotifierProvider);
    final detections = analysisState.result?.timeline?.detections ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Video area
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.black,
                  child: const Center(
                    child: Icon(
                      Icons.movie,
                      size: 64,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
            // Detection overlay
            if (_currentDetection(detections, timelineState.playheadPosition)
                    != null)
              _buildDetectionOverlay(context, 
                  _currentDetection(detections, timelineState.playheadPosition)!),
            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: _buildControlsOverlay(context, timelineState, detections),
            ),
          ],
        ),
      ),
    );
  }

  Detection? _currentDetection(List<Detection> detections, Duration position) {
    for (final detection in detections) {
      if (position >= detection.startTime &&
          position <= detection.endTime &&
          detection.userStatus != DetectionUserStatus.rejected) {
        return detection;
      }
    }
    return null;
  }

  Widget _buildDetectionOverlay(BuildContext context, Detection detection) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.getDetectionColor(detection.type.name).withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              detection.type.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay(
    BuildContext context,
    TimelineState state,
    List<Detection> detections,
  ) {
    return Container(
      color: Colors.black26,
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(context),
            const Spacer(),
            // Center play button
            _buildCenterControls(context, state),
            const Spacer(),
            // Bottom controls
            _buildBottomControls(context, state, detections),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: () {
              // TODO: Toggle fullscreen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls(BuildContext context, TimelineState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
          onPressed: () => _skipBackward(10),
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: Icon(
            state.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 64,
          ),
          onPressed: _togglePlayPause,
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
          onPressed: () => _skipForward(10),
        ),
      ],
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    TimelineState state,
    List<Detection> detections,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Seek bar with detection markers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSeekBar(context, state, detections),
        ),
        // Time display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(state.playheadPosition),
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                _formatDuration(state.timeline?.mediaDuration ?? Duration.zero),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeekBar(
    BuildContext context,
    TimelineState state,
    List<Detection> detections,
  ) {
    final totalDuration = state.timeline?.mediaDuration ?? Duration.zero;
    final progress = totalDuration.inMilliseconds > 0
        ? state.playheadPosition.inMilliseconds /
            totalDuration.inMilliseconds
        : 0.0;

    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          // Detection markers
          ...detections.where((d) => d.userStatus != DetectionUserStatus.rejected).map((detection) {
            final start = detection.startTime.inMilliseconds /
                totalDuration.inMilliseconds;
            final end = detection.endTime.inMilliseconds /
                totalDuration.inMilliseconds;

            return Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: end - start,
                child: Container(
                  margin: EdgeInsets.only(left: start * MediaQuery.of(context).size.width),
                  height: 8,
                  color: AppTheme.getDetectionColor(detection.type.name).withOpacity(0.5),
                ),
              ),
            );
          }),
          // Seek slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final position = Duration(
                  milliseconds:
                      (value * totalDuration.inMilliseconds).round(),
                );
                ref.read(timelineNotifierProvider.notifier).setPlayheadPosition(position);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlayPause() {
    final notifier = ref.read(timelineNotifierProvider.notifier);
    final isPlaying = ref.read(timelineNotifierProvider).isPlaying;
    if (isPlaying) {
      notifier.setPlaying(false);
    } else {
      notifier.setPlaying(true);
    }
  }

  void _skipForward(int seconds) {
    final state = ref.read(timelineNotifierProvider);
    final totalDuration = state.timeline?.mediaDuration ?? Duration.zero;
    var newPosition = state.playheadPosition + Duration(seconds: seconds);
    if (newPosition > totalDuration) {
      newPosition = totalDuration;
    }
    ref.read(timelineNotifierProvider.notifier).setPlayheadPosition(newPosition);
  }

  void _skipBackward(int seconds) {
    final state = ref.read(timelineNotifierProvider);
    var newPosition = state.playheadPosition - Duration(seconds: seconds);
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    ref.read(timelineNotifierProvider.notifier).setPlayheadPosition(newPosition);
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
