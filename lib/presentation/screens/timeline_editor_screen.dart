import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/detection.dart';
import '../../data/models/modification.dart';
import '../../data/models/timeline.dart' hide TimelineTrack;
import '../../state/providers/media_provider.dart';
import '../../state/providers/timeline_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/timeline/timeline_ruler.dart';
import '../widgets/timeline/timeline_track.dart';
import 'export_screen.dart';

/// Timeline editor screen for precise editing
class TimelineEditorScreen extends ConsumerStatefulWidget {
  const TimelineEditorScreen({super.key});

  @override
  ConsumerState<TimelineEditorScreen> createState() =>
      _TimelineEditorScreenState();
}

class _TimelineEditorScreenState extends ConsumerState<TimelineEditorScreen> {
  double _zoom = 1.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineNotifierProvider);
    final mediaState = ref.watch(mediaNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline Editor'),
        actions: [
          // TODO: Implement undo/redo history if needed
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: null, // Undo not implemented yet
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: null, // Redo not implemented yet
            tooltip: 'Redo',
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _openExport(context),
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Video preview area
          Expanded(
            flex: 2,
            child: _buildPreviewArea(context, mediaState, timelineState),
          ),
          const Divider(height: 1),
          // Transport controls
          _buildTransportControls(context, timelineState),
          const Divider(height: 1),
          // Timeline area
          Expanded(
            flex: 3,
            child: _buildTimelineArea(
              context,
              timelineState,
              timelineState.timeline?.detections ?? [],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(
    BuildContext context,
    MediaState mediaState,
    TimelineState timelineState,
  ) {
    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Placeholder for video preview
          const Icon(
            Icons.movie,
            size: 64,
            color: Colors.white24,
          ),
          // Current time overlay
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(timelineState.playheadPosition),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportControls(
    BuildContext context,
    TimelineState timelineState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () => ref
                .read(timelineNotifierProvider.notifier)
                .setPlayheadPosition(Duration.zero),
            tooltip: 'Go to start',
          ),
          IconButton(
            icon: const Icon(Icons.fast_rewind),
            onPressed: () => _skipBackward(),
            tooltip: 'Back 5s',
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () => _togglePlayPause(),
            child: Icon(
              timelineState.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.fast_forward),
            onPressed: () => _skipForward(),
            tooltip: 'Forward 5s',
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () => ref
                .read(timelineNotifierProvider.notifier)
                .setPlayheadPosition(
                    timelineState.timeline?.mediaDuration ?? Duration.zero),
            tooltip: 'Go to end',
          ),
          const Spacer(),
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _zoom > 0.5 ? () => setState(() => _zoom *= 0.8) : null,
            tooltip: 'Zoom out',
          ),
          Text('${(_zoom * 100).round()}%'),
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _zoom < 4 ? () => setState(() => _zoom *= 1.25) : null,
            tooltip: 'Zoom in',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineArea(
    BuildContext context,
    TimelineState timelineState,
    List<Detection> detections,
  ) {
    return Column(
      children: [
        // Timeline ruler
        SizedBox(
          height: 32,
          child: TimelineRuler(
            duration: timelineState.timeline?.mediaDuration ?? Duration.zero,
            zoom: _zoom,
            scrollController: _scrollController,
          ),
        ),
        const Divider(height: 1),
        // Timeline tracks
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (timelineState.timeline?.mediaDuration.inMilliseconds ?? 0) * _zoom / 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Video track
                  SizedBox(
                    height: 60,
                    child: TimelineTrack(
                      label: 'Video',
                      icon: Icons.movie,
                      duration: timelineState.timeline?.mediaDuration ?? Duration.zero,
                      zoom: _zoom,
                      detections: detections
                          .where((d) => d.type != ContentType.profanity)
                          .toList(),
                      segments: _getVideoSegments(timelineState),
                      onTap: (Duration position) => _seekTo(position),
                    ),
                  ),
                  const Divider(height: 1),
                  // Audio track
                  SizedBox(
                    height: 60,
                    child: TimelineTrack(
                      label: 'Audio',
                      icon: Icons.audiotrack,
                      duration: timelineState.timeline?.mediaDuration ?? Duration.zero,
                      zoom: _zoom,
                      detections: detections
                          .where((d) => d.type == ContentType.profanity)
                          .toList(),
                      segments: _getAudioSegments(timelineState),
                      onTap: (Duration position) => _seekTo(position),
                    ),
                  ),
                  const Divider(height: 1),
                  // Detections track
                  SizedBox(
                    height: 80,
                    child: _buildDetectionsTrack(context, detections),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Playhead indicator
        _buildPlayhead(context, timelineState),
      ],
    );
  }

  Widget _buildDetectionsTrack(
    BuildContext context,
    List<Detection> detections,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Stack(
        children: [
          // Track label
          Positioned(
            left: 8,
            top: 8,
            child: Text(
              'Detections',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          // Detection markers
          ...detections.map((detection) {
            final startX = detection.startTime.inMilliseconds * _zoom / 10;
            final width = (detection.endTime - detection.startTime)
                    .inMilliseconds *
                _zoom /
                10;

            return Positioned(
              left: startX,
              top: 24,
              child: GestureDetector(
                onTap: () => _showDetectionActions(context, detection),
                child: Container(
                  width: width.clamp(4.0, double.infinity),
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.getDetectionColor(detection.type.name)
                        .withOpacity(0.5),
                    border: Border.all(
                      color: AppTheme.getDetectionColor(detection.type.name),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: width > 40
                        ? Text(
                            detection.type.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPlayhead(BuildContext context, TimelineState state) {
    final totalDuration = state.timeline?.mediaDuration ?? Duration.zero;
    return Container(
      height: 4,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final progress = totalDuration.inMilliseconds > 0
              ? state.playheadPosition.inMilliseconds /
                  totalDuration.inMilliseconds
              : 0.0;

          return Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: constraints.maxWidth * progress,
                child: Container(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _togglePlayPause() {
    final notifier = ref.read(timelineNotifierProvider.notifier);
    final isPlaying = ref.read(timelineNotifierProvider).isPlaying;
    notifier.setPlaying(!isPlaying);
  }

  void _skipForward() {
    final state = ref.read(timelineNotifierProvider);
    ref.read(timelineNotifierProvider.notifier).setPlayheadPosition(
          state.playheadPosition + const Duration(seconds: 5),
        );
  }

  void _skipBackward() {
    final state = ref.read(timelineNotifierProvider);
    var newPosition = state.playheadPosition - const Duration(seconds: 5);
    if (newPosition < Duration.zero) newPosition = Duration.zero;
    ref.read(timelineNotifierProvider.notifier).setPlayheadPosition(newPosition);
  }

  void _seekTo(Duration position) {
    ref.read(timelineNotifierProvider.notifier).setPlayheadPosition(position);
  }

  /// Helper to get video track segments with modifications
  List<TimelineSegment> _getVideoSegments(TimelineState state) {
    final timeline = state.timeline;
    if (timeline == null) return [];
    return timeline.videoTrack?.segments ?? [];
  }

  /// Helper to get audio track segments with modifications
  List<TimelineSegment> _getAudioSegments(TimelineState state) {
    final timeline = state.timeline;
    if (timeline == null) return [];
    return timeline.audioTrack?.segments ?? [];
  }

  void _showDetectionActions(BuildContext context, Detection detection) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${detection.type.name.toUpperCase()} Detection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${_formatDuration(detection.startTime)} - ${_formatDuration(detection.endTime)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(detection.description),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (detection.type == ContentType.profanity) ...[
                  FilledButton.icon(
                    onPressed: () {
                      _applyAudioModification(detection, const Modification.audioMute());
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.volume_off),
                    label: const Text('Mute'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _applyAudioModification(detection, const Modification.audioBeep());
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.music_note),
                    label: const Text('Bleep'),
                  ),
                ] else ...[
                  FilledButton.icon(
                    onPressed: () {
                      _applyVideoModification(detection, const Modification.videoBlur());
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.blur_on),
                    label: const Text('Blur'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _applyVideoModification(detection, const Modification.videoSkip());
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.content_cut),
                    label: const Text('Cut'),
                  ),
                ],
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(timelineNotifierProvider.notifier)
                        .rejectDetection(detection.id);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('Dismiss'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyAudioModification(Detection detection, Modification modification) {
    ref.read(timelineNotifierProvider.notifier).applyModification(
      detection.id,
      modification,
    );
  }

  void _applyVideoModification(Detection detection, Modification modification) {
    ref.read(timelineNotifierProvider.notifier).applyModification(
      detection.id,
      modification,
    );
  }

  void _openExport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ExportScreen(),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    final frames = (duration.inMilliseconds % 1000) ~/ 33;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}:'
          '${frames.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}:'
        '${frames.toString().padLeft(2, '0')}';
  }
}
