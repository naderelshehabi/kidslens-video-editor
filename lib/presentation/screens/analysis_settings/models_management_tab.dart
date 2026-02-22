import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/huggingface_model_card.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

enum ModelsFilter {
  all('All'),
  downloaded('Downloaded');

  const ModelsFilter(this.label);
  final String label;
}

enum ModelsSort {
  accuracy('Accuracy'),
  speed('Speed'),
  size('Size');

  const ModelsSort(this.label);
  final String label;
}

class ModelsManagementTab extends ConsumerStatefulWidget {
  const ModelsManagementTab({super.key});

  @override
  ConsumerState<ModelsManagementTab> createState() => _ModelsManagementTabState();
}

class _ModelsManagementTabState extends ConsumerState<ModelsManagementTab> {
  ModelsFilter _filter = ModelsFilter.all;
  ModelsSort _sort = ModelsSort.accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelState = ref.watch(modelNotifierProvider);
    final settingsState = ref.watch(settingsNotifierProvider);
    final registry = HuggingFaceModelRegistry.instance;

    final asrModels = _applySort(
      _applyFilter(registry.getAsrModels(), modelState),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Models Management', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Manage ASR models used by the analysis pipeline.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download folder: ${(settingsState.modelCachePath?.isNotEmpty ?? false) ? settingsState.modelCachePath : 'Default (App Support)'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...ModelsFilter.values.map(
                (value) => FilterChip(
                  selected: _filter == value,
                  label: Text(value.label),
                  onSelected: (_) => setState(() => _filter = value),
                ),
              ),
              DropdownButton<ModelsSort>(
                value: _sort,
                items: ModelsSort.values
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.mic, color: Colors.blue),
              const SizedBox(width: 8),
              Text('ASR', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Text(
                'Speech recognition models',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: asrModels.map((model) {
              final isDownloaded = modelState.downloadedModels.contains(model.id);
              final downloadProgress = modelState.activeDownloads[model.id];
              final selectedAsrModelId =
                  settingsState.analysisSettings.modelConfig.asrModelId;
              return SizedBox(
                width: 340,
                child: HuggingFaceModelCard(
                  model: model,
                  isDownloaded: isDownloaded,
                  isDownloading: downloadProgress != null,
                  downloadProgress: downloadProgress?.percentage,
                  isSelected: selectedAsrModelId == model.id,
                  onDownload: () => _download(model.id),
                  onDelete: () => _delete(model.id),
                  onSelect: isDownloaded ? () => _selectModel(model.id, settingsState) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<HuggingFaceModel> _applyFilter(
    List<HuggingFaceModel> models,
    ModelState modelState,
  ) {
    switch (_filter) {
      case ModelsFilter.all:
        return models;
      case ModelsFilter.downloaded:
        return models.where((m) => modelState.downloadedModels.contains(m.id)).toList();
    }
  }

  List<HuggingFaceModel> _applySort(List<HuggingFaceModel> models) {
    final sorted = List<HuggingFaceModel>.from(models);
    switch (_sort) {
      case ModelsSort.accuracy:
        sorted.sort((a, b) => b.accuracyPercent.compareTo(a.accuracyPercent));
      case ModelsSort.speed:
        sorted.sort((a, b) => b.speedMultiplier.compareTo(a.speedMultiplier));
      case ModelsSort.size:
        sorted.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
    }
    return sorted;
  }

  void _download(String modelId) {
    ref.read(modelNotifierProvider.notifier).downloadModel(modelId);
  }

  void _delete(String modelId) {
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

  void _selectModel(String modelId, SettingsState settingsState) {
    final current = settingsState.analysisSettings;
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(
          current.copyWith(
            modelConfig: current.modelConfig.copyWith(asrModelId: modelId),
          ),
        );
  }
}
