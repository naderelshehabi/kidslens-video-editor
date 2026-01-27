import 'package:flutter/material.dart';

import '../../../data/models/media_file.dart';

/// Panel showing imported media files (media bin)
class MediaBinPanel extends StatelessWidget {
  final List<MediaFile> mediaFiles;
  final String? selectedMediaId;
  final void Function(String) onMediaSelected;
  final VoidCallback onImportMedia;
  final void Function(String) onRemoveMedia;

  const MediaBinPanel({
    super.key,
    required this.mediaFiles,
    required this.selectedMediaId,
    required this.onMediaSelected,
    required this.onImportMedia,
    required this.onRemoveMedia,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.perm_media, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Media Bin',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: onImportMedia,
                  tooltip: 'Import Media',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          
          // Media list
          Expanded(
            child: mediaFiles.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: mediaFiles.length,
                    itemBuilder: (context, index) {
                      final media = mediaFiles[index];
                      final isSelected = media.id == selectedMediaId;
                      return _MediaTile(
                        media: media,
                        isSelected: isSelected,
                        onTap: () => onMediaSelected(media.id),
                        onRemove: () => onRemoveMedia(media.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No media files',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onImportMedia,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Import Media'),
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final MediaFile media;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _MediaTile({
    required this.media,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? colorScheme.primaryContainer 
          : colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 60,
                height: 45,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  media.isVideo 
                      ? Icons.videocam 
                      : Icons.audiotrack,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(media.duration),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          media.fileSizeFormatted,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Remove button
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove from project',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
