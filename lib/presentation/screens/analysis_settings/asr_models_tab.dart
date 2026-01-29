import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/huggingface_model_card.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Filter options for ASR models
enum AsrModelFilter {
  all('All'),
  downloaded('Downloaded'),
  englishOnly('English Only');

  const AsrModelFilter(this.label);
  final String label;
}

/// Sort options for ASR models
enum AsrModelSort {
  size('Size'),
  speed('Speed'),
  accuracy('Accuracy');

  const AsrModelSort(this.label);
  final String label;
}

/// Tab for selecting ASR (Automatic Speech Recognition) models
class AsrModelsTab extends ConsumerStatefulWidget {
  const AsrModelsTab({super.key});

  @override
  ConsumerState<AsrModelsTab> createState() => _AsrModelsTabState();
}

class _AsrModelsTabState extends ConsumerState<AsrModelsTab> {
  AsrModelFilter _filter = AsrModelFilter.all;
  AsrModelSort _sort = AsrModelSort.accuracy;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelState = ref.watch(modelNotifierProvider);
    final settingsState = ref.watch(settingsNotifierProvider);
    final registry = HuggingFaceModelRegistry.instance;

    // Get and filter models
    var models = registry.getAsrModels();
    models = _applyFilter(models, modelState.downloadedModels);
    models = _applySort(models);

    final selectedModelId = settingsState.analysisSettings.modelConfig.asrModelId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with filters
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Speech Recognition Models',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Select a Whisper model for transcribing audio. Larger models are more accurate but slower.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              // Filter and sort controls
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Filter chips
                  ...AsrModelFilter.values.map(
                    (filter) => FilterChip(
                      label: Text(filter.label),
                      selected: _filter == filter,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _filter = filter);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Sort dropdown
                  DropdownButton<AsrModelSort>(
                    value: _sort,
                    items: AsrModelSort.values
                        .map(
                          (sort) => DropdownMenuItem(
                            value: sort,
                            child: Text('Sort by ${sort.label}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sort = value);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                    ),
                    onPressed: () {
                      setState(() => _sortAscending = !_sortAscending);
                    },
                    tooltip: _sortAscending ? 'Ascending' : 'Descending',
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Model grid
        Expanded(
          child: models.isEmpty
              ? _buildEmptyState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate number of columns based on width
                    final columns = (constraints.maxWidth / 400).floor().clamp(1, 4);
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: models.length,
                      itemBuilder: (context, index) {
                        final model = models[index];
                        final isDownloaded = modelState.downloadedModels.contains(model.id);
                        final isSelected = model.id == selectedModelId;
                        final downloadProgress = modelState.activeDownloads[model.id];
                        final isDownloading = downloadProgress != null;

                        return HuggingFaceModelCard(
                          model: model,
                          isDownloaded: isDownloaded,
                          isSelected: isSelected,
                          isDownloading: isDownloading,
                          downloadProgress: downloadProgress?.percentage,
                          onDownload: () => _downloadModel(model.id),
                          onDelete: () => _deleteModel(model.id),
                          onSelect: isDownloaded ? () => _selectModel(model.id) : null,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<HuggingFaceModel> _applyFilter(
    List<HuggingFaceModel> models,
    Set<String> downloadedIds,
  ) {
    switch (_filter) {
      case AsrModelFilter.all:
        return models;
      case AsrModelFilter.downloaded:
        return models.where((m) => downloadedIds.contains(m.id)).toList();
      case AsrModelFilter.englishOnly:
        return models.where((m) => m.isEnglishOnly).toList();
    }
  }

  List<HuggingFaceModel> _applySort(List<HuggingFaceModel> models) {
    final sorted = List<HuggingFaceModel>.from(models);
    switch (_sort) {
      case AsrModelSort.size:
        sorted.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
      case AsrModelSort.speed:
        sorted.sort((a, b) => b.speedMultiplier.compareTo(a.speedMultiplier));
      case AsrModelSort.accuracy:
        sorted.sort((a, b) => b.accuracyPercent.compareTo(a.accuracyPercent));
    }
    if (_sortAscending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  Widget _buildEmptyState() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No models match your filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() => _filter = AsrModelFilter.all);
            },
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );

  void _downloadModel(String modelId) {
    ref.read(modelNotifierProvider.notifier).downloadModel(modelId);
  }

  void _deleteModel(String modelId) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Model'),
        content: const Text(
          'Are you sure you want to delete this model? You can download it again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed ?? false) {
        ref.read(modelNotifierProvider.notifier).deleteModel(modelId);
      }
    });
  }

  void _selectModel(String modelId) {
    final currentSettings = ref.read(settingsNotifierProvider).analysisSettings;
    final updatedConfig = currentSettings.modelConfig.copyWith(
      asrModelId: modelId,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(
          currentSettings.copyWith(modelConfig: updatedConfig),
        );
  }
}
