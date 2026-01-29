import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/model_info.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';

/// Screen for managing AI models
class ModelSelectionScreen extends ConsumerWidget {
  const ModelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelState = ref.watch(modelNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Models'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(modelNotifierProvider.notifier).loadAvailableModels(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: modelState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildModelList(context, ref, modelState),
    );
  }

  Widget _buildModelList(
    BuildContext context,
    WidgetRef ref,
    ModelState state,
  ) {
    final models = state.availableModels;

    if (models.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64),
            const SizedBox(height: 16),
            Text(
              'No Models Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('Check your internet connection'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.read(modelNotifierProvider.notifier).loadAvailableModels(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Group models by type
    final grouped = <ModelType, List<ModelInfo>>{};
    for (final model in models) {
      grouped.putIfAbsent(model.type, () => []).add(model);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in grouped.entries) ...[
          _buildCategoryHeader(context, entry.key),
          const SizedBox(height: 8),
          ...entry.value.map(
            (model) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ModelCard(
                model: model,
                isDownloaded: state.downloadedModels.contains(model.id),
                isSelected: _isModelSelected(state, model),
                isDownloading: state.activeDownloads.containsKey(model.id),
                downloadProgress: state.activeDownloads[model.id]?.percentage,
                onDownload: () => _downloadModel(ref, model),
                onDelete: () => _deleteModel(ref, model),
                onSelect: () => _selectModel(ref, model),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildCategoryHeader(BuildContext context, ModelType type) {
    final (icon, label) = switch (type) {
      ModelType.asr => (Icons.mic, 'Speech Recognition'),
      ModelType.visual => (Icons.image, 'Visual Analysis'),
    };

    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }

  void _downloadModel(WidgetRef ref, ModelInfo model) {
    ref.read(modelNotifierProvider.notifier).downloadModel(model.id);
  }

  void _deleteModel(WidgetRef ref, ModelInfo model) {
    ref.read(modelNotifierProvider.notifier).deleteModel(model.id);
  }

  void _selectModel(WidgetRef ref, ModelInfo model) {
    final currentConfig = ref.read(modelNotifierProvider).selectedConfig;
    final newConfig = model.type == ModelType.asr
        ? (currentConfig ?? ModelConfig.defaults()).copyWith(asrModelId: model.id)
        : (currentConfig ?? ModelConfig.defaults()).copyWith(visualModelId: model.id);
    ref.read(modelNotifierProvider.notifier).setSelectedConfig(newConfig);
  }

  bool _isModelSelected(ModelState state, ModelInfo model) {
    final config = state.selectedConfig;
    if (config == null) return false;
    return model.type == ModelType.asr
        ? config.asrModelId == model.id
        : config.visualModelId == model.id;
  }
}

class _ModelCard extends StatelessWidget {
  const _ModelCard({
    required this.model,
    required this.isDownloaded,
    required this.isSelected,
    required this.isDownloading,
    required this.onDownload,
    required this.onDelete,
    required this.onSelect,
    this.downloadProgress,
  });

  final ModelInfo model;
  final bool isDownloaded;
  final bool isSelected;
  final bool isDownloading;
  final double? downloadProgress;
  final VoidCallback onDownload;
  final VoidCallback onDelete;
  final VoidCallback onSelect;

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
                              Container(
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
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          model.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(context),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildChip(context, 'v${model.version ?? '1.0'}', Icons.tag),
                  const SizedBox(width: 8),
                  _buildChip(context, _formatSize(model.sizeBytes), Icons.storage),
                  if (model.requiresGpu) ...[
                    const SizedBox(width: 8),
                    _buildChip(context, 'GPU', Icons.memory),
                  ],
                ],
              ),
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
            onSelect();
          } else if (value == 'delete') {
            onDelete();
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

  Widget _buildChip(BuildContext context, String label, IconData icon) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
