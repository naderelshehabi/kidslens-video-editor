import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// Button widget for downloading/managing model downloads
class ModelDownloadButton extends StatelessWidget {
  const ModelDownloadButton({
    super.key,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress,
    this.onDownload,
    this.onCancel,
    this.size = 40.0,
  });

  final bool isDownloaded;
  final bool isDownloading;
  final double? downloadProgress;
  final VoidCallback? onDownload;
  final VoidCallback? onCancel;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isDownloaded) {
      return _buildDownloadedState(context);
    }

    if (isDownloading) {
      return _buildDownloadingState(context);
    }

    return _buildNotDownloadedState(context);
  }

  Widget _buildNotDownloadedState(BuildContext context) => FilledButton.icon(
      onPressed: onDownload,
      icon: const Icon(Icons.download, size: 18),
      label: const Text('Download'),
    );

  Widget _buildDownloadingState(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress indicator
          SizedBox(
            width: size - 8,
            height: size - 8,
            child: CircularProgressIndicator(
              value: downloadProgress,
              strokeWidth: 3,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest,
            ),
          ),
          // Cancel button
          if (onCancel != null)
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 16),
              tooltip: 'Cancel download',
              iconSize: 16,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            )
          else if (downloadProgress != null)
            Text(
              '${(downloadProgress! * 100).round()}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );

  Widget _buildDownloadedState(BuildContext context) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check,
        color: AppTheme.successColor,
        size: 20,
      ),
    );
}

/// Compact version of the download button for use in lists
class CompactDownloadButton extends StatelessWidget {
  const CompactDownloadButton({
    super.key,
    this.isDownloaded = false,
    this.isDownloading = false,
    this.downloadProgress,
    this.onDownload,
    this.onCancel,
  });

  final bool isDownloaded;
  final bool isDownloading;
  final double? downloadProgress;
  final VoidCallback? onDownload;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    if (isDownloaded) {
      return const Icon(
        Icons.check_circle,
        color: AppTheme.successColor,
        size: 24,
      );
    }

    if (isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          value: downloadProgress,
          strokeWidth: 2,
        ),
      );
    }

    return IconButton(
      onPressed: onDownload,
      icon: const Icon(Icons.download),
      tooltip: 'Download model',
      iconSize: 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
    );
  }
}
