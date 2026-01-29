import 'package:flutter/material.dart';

/// Widget showing model download progress
class DownloadProgressWidget extends StatelessWidget {
  const DownloadProgressWidget({
    required this.modelName,
    required this.progress,
    required this.bytesDownloaded,
    required this.totalBytes,
    super.key,
    this.onCancel,
    this.onPause,
    this.onResume,
    this.isPaused = false,
  });

  final String modelName;
  final double progress;
  final int bytesDownloaded;
  final int totalBytes;
  final VoidCallback? onCancel;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final bool isPaused;

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.downloading),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Downloading $modelName',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${_formatSize(bytesDownloaded)} / ${_formatSize(totalBytes)}',
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
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (isPaused)
                  Text(
                    'Paused',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
