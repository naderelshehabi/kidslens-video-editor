import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';
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
  ConsumerState<ModelsManagementTab> createState() =>
      _ModelsManagementTabState();
}

class _ModelsManagementTabState extends ConsumerState<ModelsManagementTab> {
  ModelsFilter _filter = ModelsFilter.all;
  ModelsSort _sort = ModelsSort.accuracy;

  static const Map<HuggingFaceModelType,
      ({IconData icon, String title, String subtitle})> _sectionMetadata = {
    HuggingFaceModelType.asr: (
      icon: Icons.mic,
      title: 'ASR',
      subtitle: 'Speech recognition models',
    ),
    HuggingFaceModelType.nsfw: (
      icon: Icons.visibility_off,
      title: 'NSFW Classifier',
      subtitle: 'Whole-frame NSFW classifier variants',
    ),
    HuggingFaceModelType.parser: (
      icon: Icons.accessibility_new,
      title: 'Human Parser',
      subtitle: 'Body-part and clothing segmentation helpers for modesty rules',
    ),
    HuggingFaceModelType.genderHelper: (
      icon: Icons.diversity_3,
      title: 'Gender Helper',
      subtitle:
          'Conservative helper models for routing modesty rules when confidence is high',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelState = ref.watch(modelNotifierProvider);
    final settingsState = ref.watch(settingsNotifierProvider);
    final registry = HuggingFaceModelRegistry.instance;

    final modelsByType = <HuggingFaceModelType, List<HuggingFaceModel>>{
      for (final type in _sectionMetadata.keys)
        type: _applySort(
          _applyFilter(registry.getModelsByType(type), modelState),
        ),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Models Management', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Manage speech, moderation, parsing, and helper models used by the analysis pipeline.',
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
          ..._sectionMetadata.entries.expand((entry) {
            final type = entry.key;
            final data = entry.value;
            final models = modelsByType[type] ?? const <HuggingFaceModel>[];
            if (models.isEmpty) {
              return const <Widget>[];
            }

            return <Widget>[
              _buildModelSectionHeader(
                context,
                icon: data.icon,
                title: data.title,
                subtitle: data.subtitle,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: models.map((model) {
                  final isDownloaded =
                      modelState.downloadedModels.contains(model.id);
                  final downloadProgress = modelState.activeDownloads[model.id];
                  final selectedModelId = _selectedModelIdForType(
                    settingsState.analysisSettings,
                    type,
                  );

                  return SizedBox(
                    width: 340,
                    child: HuggingFaceModelCard(
                      model: model,
                      isDownloaded: isDownloaded,
                      isDownloading: downloadProgress != null,
                      downloadProgress: downloadProgress?.percentage,
                      isSelected: selectedModelId == model.id,
                      onDownload: () => _download(model.id),
                      onDelete: () => _delete(model.id),
                      onSelect: isDownloaded
                          ? () => _selectModel(model.id, type)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ];
          }),
          _buildModelSectionHeader(
            context,
            icon: Icons.grid_on,
            title: 'Nudity Detector',
            subtitle: 'Region-based nudity detector models',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _applySort(
              _applyFilter(registry.getNudeNetModels(), modelState),
            ).map((model) {
              final isDownloaded =
                  modelState.downloadedModels.contains(model.id);
              final downloadProgress = modelState.activeDownloads[model.id];
              final selected = _isNudityModelSelected(
                settingsState.analysisSettings,
                model.id,
              );
              return SizedBox(
                width: 340,
                child: HuggingFaceModelCard(
                  model: model,
                  isDownloaded: isDownloaded,
                  isDownloading: downloadProgress != null,
                  downloadProgress: downloadProgress?.percentage,
                  isSelected: selected,
                  onDownload: () => _download(model.id),
                  onDelete: () => _delete(model.id),
                  onSelect:
                      isDownloaded ? () => _selectNudityModel(model.id) : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(width: 8),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
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
        return models
            .where((m) => modelState.downloadedModels.contains(m.id))
            .toList();
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

  void _selectModel(String modelId, HuggingFaceModelType type) {
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    final current = ref.read(settingsNotifierProvider).analysisSettings;
    switch (type) {
      case HuggingFaceModelType.asr:
        settingsNotifier.updateAnalysisSettings(
          current.copyWith(
            modelConfig: current.modelConfig.copyWith(asrModelId: modelId),
          ),
        );
      case HuggingFaceModelType.nsfw:
        settingsNotifier.updateAnalysisSettings(
          current.copyWith(
            modelConfig: current.modelConfig.copyWith(nsfwModelId: modelId),
          ),
        );
      case HuggingFaceModelType.parser:
        settingsNotifier.updateAnalysisSettings(
          current.copyWith(
            modelConfig: current.modelConfig.copyWith(parserModelId: modelId),
          ),
        );
      case HuggingFaceModelType.genderHelper:
        settingsNotifier.updateAnalysisSettings(
          current.copyWith(
            modelConfig: current.modelConfig.copyWith(genderModelId: modelId),
          ),
        );
    }
  }

  String _selectedModelIdForType(
    AnalysisSettings settings,
    HuggingFaceModelType type,
  ) {
    switch (type) {
      case HuggingFaceModelType.asr:
        return settings.modelConfig.asrModelId;
      case HuggingFaceModelType.nsfw:
        return settings.modelConfig.nsfwModelId;
      case HuggingFaceModelType.parser:
        return settings.modelConfig.parserModelId;
      case HuggingFaceModelType.genderHelper:
        return settings.modelConfig.genderModelId;
    }
  }

  bool _isNudityModelSelected(AnalysisSettings settings, String modelId) {
    ContentCategory? nudityCategory;
    for (final category in settings.contentDetectionConfig.categories) {
      if (category.id == 'nudity') {
        nudityCategory = category;
        break;
      }
    }
    if (nudityCategory == null) return false;
    return nudityCategory.modelContributions
        .where((model) => model.modelId == modelId)
        .any((model) => model.enabled);
  }

  void _selectNudityModel(String modelId) {
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final current = ref.read(settingsNotifierProvider).analysisSettings;
    final categories =
        current.contentDetectionConfig.categories.map((category) {
      if (category.id != 'nudity') return category;

      final updatedContributions = category.modelContributions
          .map(
            (model) => model.copyWith(enabled: model.modelId == modelId),
          )
          .toList(growable: true);

      final exists = updatedContributions.any(
        (model) => model.modelId == modelId,
      );
      if (!exists) {
        ModelContribution? defaultContribution;
        for (final contribution
            in ContentCategoryDefaults.nudity.modelContributions) {
          if (contribution.modelId == modelId) {
            defaultContribution = contribution;
            break;
          }
        }

        updatedContributions.add(
          (defaultContribution ??
                  ModelContribution(
                    modelId: modelId,
                    displayName: modelId,
                    modelType: HuggingFaceModelType.nsfw,
                  ))
              .copyWith(enabled: true),
        );
      }

      return category.copyWith(modelContributions: updatedContributions);
    }).toList(growable: false);

    notifier.updateContentDetectionConfig(
      current.contentDetectionConfig.copyWith(categories: categories),
    );
  }
}
