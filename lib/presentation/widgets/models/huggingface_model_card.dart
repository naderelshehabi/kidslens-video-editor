import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/model_download_button.dart';

/// Card widget for displaying HuggingFace model information
class HuggingFaceModelCard extends StatelessWidget {
  const HuggingFaceModelCard({
    required this.model,
    super.key,
    this.isDownloaded = false,
    this.isSelected = false,
    this.isDownloading = false,
    this.downloadProgress,
    this.hardwareWarning,
    this.onDownload,
    this.onDelete,
    this.onSelect,
  });

  final HuggingFaceModel model;
  final bool isDownloaded;
  final bool isSelected;
  final bool isDownloading;
  final double? downloadProgress;
  final String? hardwareWarning;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isDownloaded ? onSelect : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row with name and badge
              _buildHeader(context),
              const SizedBox(height: 8),

              // Description
              if (model.description != null)
                Text(
                  model.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // Stats row
              _buildStats(context),
              const SizedBox(height: 16),

              // Hardware warning if any
              if (hardwareWarning != null) ...[
                _buildWarning(context),
                const SizedBox(height: 8),
              ],

              // Download progress or action buttons
              if (isDownloading)
                _buildDownloadProgress(context)
              else
                _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      model.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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
                    ),
                ],
              ),
              if (model.hasBadge)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _buildBadge(context, model.badge!),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, String badge) {
    Color badgeColor;
    if (badge.toLowerCase().contains('recommend')) {
      badgeColor = AppTheme.successColor;
    } else if (badge.toLowerCase().contains('best')) {
      badgeColor = AppTheme.primaryColor;
    } else {
      badgeColor = AppTheme.infoColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        badge.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Parameters
        _buildStatChip(
          context,
          icon: Icons.memory,
          label: model.parameters,
          tooltip: 'Parameters: ${model.parameters}',
        ),
        // Size
        _buildStatChip(
          context,
          icon: Icons.storage,
          label: model.sizeFormatted,
          tooltip: 'Download size: ${model.sizeFormatted}',
        ),
        // RAM
        _buildStatChip(
          context,
          icon: Icons.sd_card,
          label: model.ramFormatted,
          tooltip: 'RAM required: ${model.ramFormatted}',
        ),
        // Speed indicator
        _buildSpeedIndicator(context),
        // Accuracy indicator
        _buildAccuracyIndicator(context),
      ],
    );

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? tooltip,
  }) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: chip);
    }
    return chip;
  }

  Widget _buildSpeedIndicator(BuildContext context) {
    final color = model.speedMultiplier >= 7
        ? AppTheme.successColor
        : model.speedMultiplier >= 3
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return Tooltip(
      message: 'Speed: ${model.speedDescription} (${model.speedMultiplier}x realtime)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              model.speedDescription,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyIndicator(BuildContext context) {
    final color = model.accuracyPercent >= 94
        ? AppTheme.successColor
        : model.accuracyPercent >= 88
            ? AppTheme.infoColor
            : AppTheme.warningColor;

    return Tooltip(
      message: _getAccuracyTooltip(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              '${model.accuracyPercent}%',
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }

  String _getAccuracyTooltip() {
    final accuracyType = switch (model.modelType) {
      HuggingFaceModelType.asr => 'Word Error Rate (WER) on LibriSpeech/CommonVoice benchmarks',
    };
    return 'Accuracy: ${model.accuracyPercent}%\n\nMeasured using: $accuracyType\n\nHigher is better. Scores ≥94% are excellent, ≥88% are good.';
  }

  Widget _buildWarning(BuildContext context) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber,
            size: 16,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hardwareWarning!,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.warningColor,
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildDownloadProgress(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: downloadProgress,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          downloadProgress != null
              ? 'Downloading... ${(downloadProgress! * 100).toStringAsFixed(1)}%'
              : 'Downloading...',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );

  Widget _buildActions(BuildContext context) {
    if (!isDownloaded) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ModelDownloadButton(
            onDownload: onDownload,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Delete button
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete model',
          iconSize: 20,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 8),
        // Select button (only if not already selected)
        if (!isSelected)
          FilledButton.icon(
            onPressed: onSelect,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Use'),
          )
        else
          FilledButton.tonalIcon(
            onPressed: null,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Active'),
          ),
      ],
    );
  }
}
