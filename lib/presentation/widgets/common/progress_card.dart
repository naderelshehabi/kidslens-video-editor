import 'package:flutter/material.dart';

/// Card showing progress with status
class ProgressCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double progress;
  final String? status;
  final IconData? icon;
  final VoidCallback? onCancel;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final bool isPaused;
  final Duration? estimatedTimeRemaining;

  const ProgressCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.progress,
    this.status,
    this.icon,
    this.onCancel,
    this.onPause,
    this.onResume,
    this.isPaused = false,
    this.estimatedTimeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 24),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                if (onPause != null || onResume != null)
                  IconButton(
                    icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                    onPressed: isPaused ? onResume : onPause,
                    tooltip: isPaused ? 'Resume' : 'Pause',
                  ),
                if (onCancel != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                    tooltip: 'Cancel',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  status ?? '${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (estimatedTimeRemaining != null)
                  Text(
                    'ETA: ${_formatDuration(estimatedTimeRemaining!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
