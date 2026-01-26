import 'package:flutter/material.dart';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// A timeline track showing detections and modifications
class TimelineTrack extends StatelessWidget {
  const TimelineTrack({
    required this.label,
    required this.icon,
    required this.duration,
    required this.zoom,
    required this.detections,
    required this.segments,
    super.key,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Duration duration;
  final double zoom;
  final List<Detection> detections;
  final List<TimelineSegment> segments;
  final ValueChanged<Duration>? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (details) {
          if (onTap != null) {
            final position = Duration(
              milliseconds: (details.localPosition.dx * 10 / zoom).round(),
            );
            onTap!(position);
          }
        },
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Stack(
            children: [
              // Track label
              Positioned(
                left: 8,
                top: 8,
                child: Row(
                  children: [
                    Icon(icon, size: 16),
                    const SizedBox(width: 4),
                    Text(label, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              // Segments with modifications
              ...segments
                  .where((seg) => seg.modification != null)
                  .map((seg) => _buildModificationOverlay(context, seg)),
              // Detections
              ...detections.map((det) => _buildDetectionMarker(context, det)),
            ],
          ),
        ),
      );

  Widget _buildDetectionMarker(BuildContext context, Detection detection) {
    final startX = detection.startTime.inMilliseconds * zoom / 10;
    final width =
        (detection.endTime - detection.startTime).inMilliseconds * zoom / 10;
    final isRejected = detection.userStatus == DetectionUserStatus.rejected;
    final detectionColor = AppTheme.getDetectionColor(detection.type.name);

    return Positioned(
      left: startX,
      top: 28,
      child: Opacity(
        opacity: isRejected ? 0.3 : 1.0,
        child: Container(
          width: width.clamp(2.0, double.infinity),
          height: 24,
          decoration: BoxDecoration(
            color: detectionColor.withValues(alpha: 0.3),
            border: Border(
              bottom: BorderSide(
                color: detectionColor,
                width: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModificationOverlay(
    BuildContext context,
    TimelineSegment segment,
  ) {
    final mod = segment.modification!;
    final startX = segment.start.inMilliseconds * zoom / 10;
    final width = (segment.end - segment.start).inMilliseconds * zoom / 10;
    final modColor = _getModificationColor(mod);

    return Positioned(
      left: startX,
      top: 0,
      bottom: 0,
      child: Container(
        width: width.clamp(2.0, double.infinity),
        decoration: BoxDecoration(
          color: modColor.withValues(alpha: 0.2),
          border: Border.all(color: modColor),
        ),
        child: width > 20
            ? Center(
                child: Icon(
                  _getModificationIcon(mod),
                  size: 16,
                  color: modColor,
                ),
              )
            : null,
      ),
    );
  }

  Color _getModificationColor(Modification mod) => switch (mod) {
        AudioMute() => Colors.blue,
        AudioBeep() => Colors.cyan,
        AudioReplace() => Colors.green,
        VideoBlur() => Colors.purple,
        VideoPixelate() => Colors.indigo,
        VideoBlackBox() => Colors.grey,
        VideoSkip() => Colors.orange,
      };

  IconData _getModificationIcon(Modification mod) => switch (mod) {
        AudioMute() => Icons.volume_off,
        AudioBeep() => Icons.music_note,
        AudioReplace() => Icons.swap_horiz,
        VideoBlur() => Icons.blur_on,
        VideoPixelate() => Icons.grid_view,
        VideoBlackBox() => Icons.crop_square,
        VideoSkip() => Icons.skip_next,
      };
}
