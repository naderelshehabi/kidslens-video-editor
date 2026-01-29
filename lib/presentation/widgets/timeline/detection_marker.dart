import 'package:flutter/material.dart';

import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// Marker widget for a detection on the timeline
class DetectionMarker extends StatelessWidget {
  const DetectionMarker({
    required this.detection,
    required this.zoom,
    super.key,
    this.onTap,
    this.onDismiss,
    this.onAction,
  });

  final Detection detection;
  final double zoom;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getDetectionColor(detection.type.name);
    final width = (detection.endTime - detection.startTime).inMilliseconds *
        zoom /
        10;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: detection.userStatus == DetectionUserStatus.rejected ? 0.4 : 1.0,
        child: Container(
          width: width.clamp(24.0, double.infinity),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(detection.type),
                size: 14,
                color: color,
              ),
              if (width > 60) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    detection.type.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (width > 80 && onAction != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onAction,
                  child: Icon(
                    Icons.more_vert,
                    size: 14,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(ContentType type) => switch (type) {
      ContentType.profanity => Icons.mic_off,
      ContentType.nsfw => Icons.visibility_off,
      ContentType.violence => Icons.warning,
      ContentType.blood => Icons.water_drop,
      ContentType.weapons => Icons.gpp_bad,
    };
}
