import 'package:flutter/material.dart';

import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// List item widget for a detection
class DetectionListItem extends StatelessWidget {
  const DetectionListItem({
    required this.detection,
    super.key,
    this.isSelected = false,
    this.onTap,
    this.onDismiss,
    this.onRestore,
    this.onJumpTo,
  });

  final Detection detection;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onRestore;
  final VoidCallback? onJumpTo;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getDetectionColor(
      detection.visualContentCategoryId ?? detection.type.name,
    );

    return Card(
      elevation: isSelected ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: detection.userStatus == DetectionUserStatus.rejected ? 0.5 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              border: isSelected
                  ? Border.all(color: color, width: 2)
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Type indicator
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              detection.typeDisplayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(detection.confidence * 100).round()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (detection.userStatus == DetectionUserStatus.rejected) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.visibility_off,
                              size: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detection.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatTime(detection.startTime)} - ${_formatTime(detection.endTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        detection.userStatus == DetectionUserStatus.rejected
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: 20,
                      ),
                      onPressed:
                          detection.userStatus == DetectionUserStatus.rejected ? onRestore : onDismiss,
                      tooltip: detection.userStatus == DetectionUserStatus.rejected ? 'Restore' : 'Dismiss',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 20),
                      onPressed: onJumpTo,
                      tooltip: 'Jump to',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
