import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data/models/detection.dart';
import '../../../data/models/edit_action.dart';
import '../../../data/models/media_file.dart';

/// Timeline panel with tracks and detection indicators
class TimelinePanel extends StatefulWidget {
  final MediaFile? media;
  final List<Detection> detections;
  final List<EditAction> editActions;
  final void Function(Duration) onSeek;
  final void Function(EditAction) onAddEditAction;

  const TimelinePanel({
    super.key,
    required this.media,
    required this.detections,
    required this.editActions,
    required this.onSeek,
    required this.onAddEditAction,
  });

  @override
  State<TimelinePanel> createState() => _TimelinePanelState();
}

class _TimelinePanelState extends State<TimelinePanel> {
  double _zoom = 1.0;
  double _scrollOffset = 0.0;
  Duration _playheadPosition = Duration.zero;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Timeline toolbar
          _buildToolbar(context),
          
          // Timeline content
          Expanded(
            child: widget.media == null
                ? _buildEmptyState(context)
                : Row(
                    children: [
                      // Track labels
                      _buildTrackLabels(context),
                      
                      // Timeline area
                      Expanded(
                        child: _buildTimelineArea(context),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Timeline',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(width: 24),
          
          // Zoom controls
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 16),
            onPressed: () => setState(() => _zoom = math.max(0.5, _zoom - 0.25)),
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom Out',
          ),
          SizedBox(
            width: 100,
            child: Slider(
              value: _zoom,
              min: 0.5,
              max: 4.0,
              onChanged: (value) => setState(() => _zoom = value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 16),
            onPressed: () => setState(() => _zoom = math.min(4.0, _zoom + 0.25)),
            visualDensity: VisualDensity.compact,
            tooltip: 'Zoom In',
          ),
          
          const Spacer(),
          
          // Edit action buttons
          _ToolButton(
            icon: Icons.content_cut,
            label: 'Cut',
            onPressed: _cutSelection,
          ),
          const SizedBox(width: 4),
          _ToolButton(
            icon: Icons.volume_off,
            label: 'Mute',
            onPressed: _muteSelection,
          ),
          const SizedBox(width: 4),
          _ToolButton(
            icon: Icons.blur_on,
            label: 'Blur',
            onPressed: _blurSelection,
          ),
          const SizedBox(width: 4),
          _ToolButton(
            icon: Icons.notifications,
            label: 'Beep',
            onPressed: _beepSelection,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Text(
        'Select a media file to view timeline',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildTrackLabels(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Time ruler placeholder
          Container(
            height: 24,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
          // Video track label
          _TrackLabel(
            icon: Icons.videocam,
            label: 'Video',
            color: colorScheme.primary,
          ),
          // Audio track label
          _TrackLabel(
            icon: Icons.audiotrack,
            label: 'Audio',
            color: colorScheme.secondary,
          ),
          // Detections track label
          _TrackLabel(
            icon: Icons.warning_amber,
            label: 'Detections',
            color: Colors.orange,
          ),
          // Edits track label
          _TrackLabel(
            icon: Icons.edit,
            label: 'Edits',
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineArea(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.media?.duration ?? Duration.zero;
    final timelineWidth = duration.inSeconds * 20.0 * _zoom;

    return GestureDetector(
      onTapDown: (details) {
        if (duration.inMilliseconds == 0) return;
        final position = Duration(
          milliseconds: ((details.localPosition.dx + _scrollOffset) /
              timelineWidth * duration.inMilliseconds).round(),
        );
        setState(() => _playheadPosition = position);
        widget.onSeek(position);
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: math.max(timelineWidth, 500),
          child: Column(
            children: [
              // Time ruler
              _buildTimeRuler(context, timelineWidth),
              
              // Video track
              _buildTrack(
                context,
                height: 30,
                color: colorScheme.primary.withOpacity(0.3),
                child: _buildMediaClip(context, timelineWidth),
              ),
              
              // Audio track
              _buildTrack(
                context,
                height: 30,
                color: colorScheme.secondary.withOpacity(0.3),
                child: _buildWaveformTrack(context, timelineWidth),
              ),
              
              // Detections track
              _buildTrack(
                context,
                height: 30,
                color: Colors.orange.withOpacity(0.1),
                child: _buildDetectionMarkers(context, timelineWidth),
              ),
              
              // Edits track
              _buildTrack(
                context,
                height: 30,
                color: Colors.purple.withOpacity(0.1),
                child: _buildEditMarkers(context, timelineWidth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRuler(BuildContext context, double timelineWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.media?.duration ?? Duration.zero;

    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: CustomPaint(
        painter: _TimeRulerPainter(
          duration: duration,
          zoom: _zoom,
          textColor: colorScheme.onSurface,
          tickColor: colorScheme.outline,
        ),
        size: Size(timelineWidth, 24),
      ),
    );
  }

  Widget _buildTrack(
    BuildContext context, {
    required double height,
    required Color color,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Stack(
        children: [
          child,
          // Playhead
          _buildPlayhead(height),
        ],
      ),
    );
  }

  Widget _buildPlayhead(double height) {
    final duration = widget.media?.duration ?? Duration.zero;
    if (duration.inMilliseconds == 0) return const SizedBox.shrink();

    final timelineWidth = duration.inSeconds * 20.0 * _zoom;
    final playheadX = (_playheadPosition.inMilliseconds / 
        duration.inMilliseconds) * timelineWidth;

    return Positioned(
      left: playheadX - 1,
      top: 0,
      bottom: 0,
      child: Container(
        width: 2,
        color: Colors.red,
      ),
    );
  }

  Widget _buildMediaClip(BuildContext context, double timelineWidth) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.primary),
      ),
      child: Center(
        child: Text(
          widget.media?.name ?? '',
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildWaveformTrack(BuildContext context, double timelineWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = widget.media?.duration ?? Duration.zero;

    return CustomPaint(
      painter: _MiniWaveformPainter(
        color: colorScheme.secondary,
        duration: duration,
        detections: widget.detections.where((d) => d.isAudioDetection).toList(),
      ),
      size: Size(timelineWidth, 30),
    );
  }

  Widget _buildDetectionMarkers(BuildContext context, double timelineWidth) {
    final duration = widget.media?.duration ?? Duration.zero;
    if (duration.inMilliseconds == 0) return const SizedBox.shrink();

    return Stack(
      children: widget.detections.where((d) => !d.isRejected).map((detection) {
        final startX = (detection.startTime.inMilliseconds /
            duration.inMilliseconds) * timelineWidth;
        final width = ((detection.endTime.inMilliseconds -
            detection.startTime.inMilliseconds) /
            duration.inMilliseconds) * timelineWidth;

        return Positioned(
          left: startX,
          top: 2,
          bottom: 2,
          child: Container(
            width: math.max(width, 8),
            decoration: BoxDecoration(
              color: _getDetectionColor(detection.type).withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: _getDetectionColor(detection.type),
              ),
            ),
            child: Tooltip(
              message: '${detection.typeDisplayName}\n${_formatDuration(detection.startTime)} - ${_formatDuration(detection.endTime)}',
              child: Icon(
                _getDetectionIcon(detection.type),
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditMarkers(BuildContext context, double timelineWidth) {
    final duration = widget.media?.duration ?? Duration.zero;
    if (duration.inMilliseconds == 0) return const SizedBox.shrink();

    return Stack(
      children: widget.editActions.where((e) => e.enabled).map((action) {
        final startX = (action.startTime.inMilliseconds /
            duration.inMilliseconds) * timelineWidth;
        final width = ((action.endTime.inMilliseconds -
            action.startTime.inMilliseconds) /
            duration.inMilliseconds) * timelineWidth;

        return Positioned(
          left: startX,
          top: 2,
          bottom: 2,
          child: Container(
            width: math.max(width, 8),
            decoration: BoxDecoration(
              color: _getEditColor(action.type).withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: _getEditColor(action.type),
              ),
            ),
            child: Tooltip(
              message: '${action.typeLabel}\n${_formatDuration(action.startTime)} - ${_formatDuration(action.endTime)}',
              child: Icon(
                _getEditIcon(action.type),
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _cutSelection() {
    // TODO: Implement cut
  }

  void _muteSelection() {
    // TODO: Implement mute
  }

  void _blurSelection() {
    // TODO: Implement blur
  }

  void _beepSelection() {
    // TODO: Implement beep
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

  IconData _getDetectionIcon(ContentType type) {
    switch (type) {
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

  Color _getEditColor(EditActionType type) {
    switch (type) {
      case EditActionType.mute:
        return Colors.purple;
      case EditActionType.beep:
        return Colors.indigo;
      case EditActionType.blur:
        return Colors.blue;
      case EditActionType.cut:
        return Colors.red;
      case EditActionType.skip:
        return Colors.grey;
    }
  }

  IconData _getEditIcon(EditActionType type) {
    switch (type) {
      case EditActionType.mute:
        return Icons.volume_off;
      case EditActionType.beep:
        return Icons.notifications;
      case EditActionType.blur:
        return Icons.blur_on;
      case EditActionType.cut:
        return Icons.content_cut;
      case EditActionType.skip:
        return Icons.skip_next;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _TrackLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _TrackLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _TimeRulerPainter extends CustomPainter {
  final Duration duration;
  final double zoom;
  final Color textColor;
  final Color tickColor;

  _TimeRulerPainter({
    required this.duration,
    required this.zoom,
    required this.textColor,
    required this.tickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: 9,
    );

    // Draw second markers
    final pixelsPerSecond = 20.0 * zoom;
    final totalSeconds = duration.inSeconds;
    final majorInterval = zoom < 1 ? 10 : zoom < 2 ? 5 : 1;

    for (int s = 0; s <= totalSeconds; s++) {
      final x = s * pixelsPerSecond;
      
      if (s % majorInterval == 0) {
        // Major tick
        canvas.drawLine(
          Offset(x, size.height - 12),
          Offset(x, size.height),
          tickPaint,
        );

        // Label
        final span = TextSpan(
          text: _formatSeconds(s),
          style: textStyle,
        );
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 2));
      } else if (s % (majorInterval ~/ 2 + 1) == 0) {
        // Minor tick
        canvas.drawLine(
          Offset(x, size.height - 6),
          Offset(x, size.height),
          tickPaint,
        );
      }
    }
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _TimeRulerPainter oldDelegate) {
    return oldDelegate.duration != duration || oldDelegate.zoom != zoom;
  }
}

class _MiniWaveformPainter extends CustomPainter {
  final Color color;
  final Duration duration;
  final List<Detection> detections;

  _MiniWaveformPainter({
    required this.color,
    required this.duration,
    required this.detections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (duration.inMilliseconds == 0) return;

    // Draw detection regions
    for (final detection in detections) {
      final startX = (detection.startTime.inMilliseconds /
          duration.inMilliseconds) * size.width;
      final endX = (detection.endTime.inMilliseconds /
          duration.inMilliseconds) * size.width;

      final regionPaint = Paint()
        ..color = Colors.orange.withOpacity(0.3);
      canvas.drawRect(
        Rect.fromLTRB(startX, 0, endX, size.height),
        regionPaint,
      );
    }

    // Draw mini waveform
    final wavePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1;

    final centerY = size.height / 2;
    final random = math.Random(42);

    for (double x = 0; x < size.width; x += 3) {
      final amplitude = random.nextDouble() * size.height * 0.3;
      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniWaveformPainter oldDelegate) {
    return oldDelegate.duration != duration ||
        oldDelegate.detections != detections;
  }
}
