import 'package:flutter/material.dart';

import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// Overlay widget for displaying active detections
class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    this.currentDetection,
    this.onDismiss,
    this.onAction,
  });

  final Detection? currentDetection;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (currentDetection == null) return const SizedBox.shrink();

    final detection = currentDetection!;
    final color = AppTheme.getDetectionColor(detection.type.name);

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _getIcon(detection.type),
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detection.type.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      detection.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onAction != null)
                IconButton(
                  icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                  onPressed: onAction,
                  tooltip: 'Quick action',
                ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: onDismiss,
                  tooltip: 'Dismiss',
                ),
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
      ContentType.nudity => Icons.visibility_off,
      ContentType.sexualContent => Icons.block,
      ContentType.kissing => Icons.favorite,
      ContentType.immodestDress => Icons.checkroom,
      ContentType.custom => Icons.category,
    };
}
