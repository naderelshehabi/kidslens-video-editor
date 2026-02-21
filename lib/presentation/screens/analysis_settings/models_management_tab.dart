import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
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
    final allModels = _applySort(_applyFilter(registry.getAllModels(), modelState));

    final grouped = <HuggingFaceModelType, List<HuggingFaceModel>>{};
    for (final type in HuggingFaceModelType.values) {
      final modelsOfType = allModels.where((m) => m.modelType == type).toList();
      if (modelsOfType.isNotEmpty) {
        grouped[type] = modelsOfType;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Models Management', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Download and manage all AI models in one place. Selection and download behavior is consistent across model types.',
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
          ...grouped.entries.map(
            (entry) => _buildSection(
              context,
              entry.key,
              entry.value,
              modelState,
              settingsState,
            ),
          ),
          _buildComingSoonSection(context),
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

  Widget _buildSection(
    BuildContext context,
    HuggingFaceModelType type,
    List<HuggingFaceModel> models,
    ModelState modelState,
    SettingsState settingsState,
  ) {
    final theme = Theme.of(context);
    final (title, subtitle, icon, color) = _typeInfo(type);
    final selectedIds = _selectedModelIds(type, settingsState);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: models.map((model) {
              final isDownloaded = modelState.downloadedModels.contains(model.id);
              final downloadProgress = modelState.activeDownloads[model.id];
              final canSelect = _canSelect(type);
              return SizedBox(
                width: 340,
                child: HuggingFaceModelCard(
                  model: model,
                  isDownloaded: isDownloaded,
                  isDownloading: downloadProgress != null,
                  downloadProgress: downloadProgress?.percentage,
                  isSelected: selectedIds.contains(model.id),
                  hardwareWarning: !isDownloaded && selectedIds.contains(model.id)
                      ? 'Selected model is not available on disk. Download required.'
                      : null,
                  onDownload: () => _download(model.id),
                  onDelete: () => _delete(model.id),
                  onSelect: isDownloaded && canSelect
                      ? () => _selectModel(type, model.id, settingsState)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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

  bool _canSelect(HuggingFaceModelType type) =>
      type == HuggingFaceModelType.asr ||
      type == HuggingFaceModelType.nsfw ||
      type == HuggingFaceModelType.violence ||
      type == HuggingFaceModelType.blood ||
      type == HuggingFaceModelType.weapons ||
      type == HuggingFaceModelType.nudeNet;

  Set<String> _selectedModelIds(
    HuggingFaceModelType type,
    SettingsState settingsState,
  ) {
    final modelConfig = settingsState.analysisSettings.modelConfig;
    switch (type) {
      case HuggingFaceModelType.asr:
        return {modelConfig.asrModelId};
      case HuggingFaceModelType.nsfw:
        return {modelConfig.nsfwModelId};
      case HuggingFaceModelType.violence:
        return {modelConfig.violenceModelId};
      case HuggingFaceModelType.blood:
        return {modelConfig.bloodModelId};
      case HuggingFaceModelType.weapons:
        return {modelConfig.weaponsModelId};
      case HuggingFaceModelType.nudeNet:
        return {modelConfig.nudeNetModelId};
      case HuggingFaceModelType.clip:
        return {modelConfig.clipVisionModelId, modelConfig.clipTextModelId};
    }
  }

  void _selectModel(
    HuggingFaceModelType type,
    String modelId,
    SettingsState settingsState,
  ) {
    final current = settingsState.analysisSettings;
    final modelConfig = current.modelConfig;
    final updatedConfig = switch (type) {
      HuggingFaceModelType.asr => modelConfig.copyWith(asrModelId: modelId),
      HuggingFaceModelType.nsfw => modelConfig.copyWith(
          nsfwModelId: modelId,
          visualModelId: modelId,
        ),
      HuggingFaceModelType.violence => modelConfig.copyWith(violenceModelId: modelId),
      HuggingFaceModelType.blood => modelConfig.copyWith(bloodModelId: modelId),
      HuggingFaceModelType.weapons => modelConfig.copyWith(weaponsModelId: modelId),
      HuggingFaceModelType.nudeNet => modelConfig.copyWith(nudeNetModelId: modelId),
      HuggingFaceModelType.clip => modelConfig,
    };

    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(
          current.copyWith(modelConfig: updatedConfig),
        );
  }

  (String, String, IconData, Color) _typeInfo(HuggingFaceModelType type) {
    switch (type) {
      case HuggingFaceModelType.asr:
        return ('ASR', 'Speech recognition models', Icons.mic, Colors.blue);
      case HuggingFaceModelType.nsfw:
        return (
          'NSFW',
          'Adult content classification',
          Icons.no_adult_content,
          AppTheme.nsfwColor,
        );
      case HuggingFaceModelType.violence:
        return (
          'Violence',
          'Violence scene classification',
          Icons.sports_mma,
          AppTheme.violenceColor,
        );
      case HuggingFaceModelType.blood:
        return (
          'Blood/Gore',
          'Graphic blood and gore classification',
          Icons.water_drop,
          AppTheme.bloodColor,
        );
      case HuggingFaceModelType.weapons:
        return (
          'Weapons',
          'Weapons detection models',
          Icons.gpp_bad,
          AppTheme.weaponsColor,
        );
      case HuggingFaceModelType.nudeNet:
        return (
          'NudeNet',
          'Specialized region/body-part detector',
          Icons.person_search,
          AppTheme.nsfwColor,
        );
      case HuggingFaceModelType.clip:
        return (
          'CLIP',
          'Specialized zero-shot encoder models',
          Icons.image_search,
          Colors.indigo,
        );
    }
  }

  Widget _buildComingSoonSection(BuildContext context) => Card(
      child: ListTile(
        leading: const Icon(Icons.smart_toy_outlined),
        title: const Text('LLM Models'),
        subtitle: Text(
          'No LLM model family is registered yet. This section will populate automatically when LLM models are added to the registry.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
}
