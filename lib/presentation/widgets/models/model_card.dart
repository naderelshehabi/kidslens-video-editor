import 'package:flutter/material.dart';

import 'package:kidslens_video_editor/data/models/model_info.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// Card widget for displaying model information
class ModelCard extends StatelessWidget {
  const ModelCard({
    required this.model,
    super.key,
    this.isDownloaded = false,
    this.isSelected = false,
    this.isDownloading = false,
    this.downloadProgress,
    this.onDownload,
    this.onDelete,
    this.onSelect,
  });

  final ModelInfo model;
  final bool isDownloaded;
  final bool isSelected;
  final bool isDownloading;
  final double? downloadProgress;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) => Card(
      child: InkWell(
        onTap: isDownloaded ? onSelect : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getTypeIcon(model.type),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              model.displayName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              _buildActiveTag(context),
                            ],
                          ],
                        ),
                        Text(
                          model.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(context),
                ],
              ),
              const SizedBox(height: 12),
              // Model info chips
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoChip(context, _formatSize(model.sizeBytes), Icons.storage),
                  if (model.requiresGpu)
                    _buildInfoChip(context, 'GPU', Icons.memory),
                  if (isDownloaded)
                    _buildInfoChip(
                      context,
                      'Downloaded',
                      Icons.check_circle,
                      color: AppTheme.successColor,
                    ),
                ],
              ),
              // Download progress
              if (isDownloading && downloadProgress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: downloadProgress),
                const SizedBox(height: 4),
                Text(
                  'Downloading... ${(downloadProgress! * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );

  Widget _buildActiveTag(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'ACTIVE',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.successColor,
        ),
      ),
    );

  Widget _buildActionButton(BuildContext context) {
    if (isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (isDownloaded) {
      return PopupMenuButton<String>(
        itemBuilder: (context) => [
          if (!isSelected)
            const PopupMenuItem(
              value: 'select',
              child: ListTile(
                leading: Icon(Icons.check),
                title: Text('Use Model'),
                dense: true,
              ),
            ),
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              dense: true,
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'select') {
            onSelect?.call();
          } else if (value == 'delete') {
            onDelete?.call();
          }
        },
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: onDownload,
      tooltip: 'Download',
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    String label,
    IconData icon, {
    Color? color,
  }) {
    final chipColor = color ?? Theme.of(context).colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: chipColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: chipColor),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(ModelType type) => switch (type) {
      ModelType.asr => Icons.mic,
      ModelType.visual => Icons.image,
    };

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
