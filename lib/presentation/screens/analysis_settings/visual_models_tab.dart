import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/huggingface_model_card.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Tab for selecting visual detection models
class VisualModelsTab extends ConsumerWidget {
  const VisualModelsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final modelState = ref.watch(modelNotifierProvider);
    final settingsState = ref.watch(settingsNotifierProvider);
    final registry = HuggingFaceModelRegistry.instance;

    // Group models by type
    final modelGroups = <HuggingFaceModelType, List<HuggingFaceModel>>{
      HuggingFaceModelType.nsfw: registry.getNsfwModels(),
      HuggingFaceModelType.violence: registry.getViolenceModels(),
      HuggingFaceModelType.blood: registry.getBloodModels(),
      HuggingFaceModelType.weapons: registry.getWeaponsModels(),
    };

    final selectedVisualModelId =
        settingsState.analysisSettings.modelConfig.visualModelId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visual Detection Models',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select models for detecting inappropriate visual content in video frames.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          // Model groups by type
          ...modelGroups.entries.map((entry) => _buildModelSection(
              context,
              ref,
              entry.key,
              entry.value,
              modelState,
              selectedVisualModelId,
            ),),
        ],
      ),
    );
  }

  Widget _buildModelSection(
    BuildContext context,
    WidgetRef ref,
    HuggingFaceModelType modelType,
    List<HuggingFaceModel> models,
    ModelState modelState,
    String selectedModelId,
  ) {
    final theme = Theme.of(context);
    final (title, description, icon, color) = _getTypeInfo(modelType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Model cards in a horizontal scroll or wrap
        LayoutBuilder(
          builder: (context, constraints) {
            const cardWidth = 320.0;

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: models.map((model) {
                final isDownloaded = modelState.downloadedModels.contains(model.id);
                final isSelected = model.id == selectedModelId;
                final downloadProgress = modelState.activeDownloads[model.id];
                final isDownloading = downloadProgress != null;

                return SizedBox(
                  width: cardWidth,
                  child: HuggingFaceModelCard(
                    model: model,
                    isDownloaded: isDownloaded,
                    isSelected: isSelected,
                    isDownloading: isDownloading,
                    downloadProgress: downloadProgress?.percentage,
                    onDownload: () => _downloadModel(ref, model.id),
                    onDelete: () => _deleteModel(context, ref, model.id),
                    onSelect: isDownloaded
                        ? () => _selectModel(ref, model.id)
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  (String, String, IconData, Color) _getTypeInfo(HuggingFaceModelType type) {
    switch (type) {
      case HuggingFaceModelType.nsfw:
        return (
          'NSFW Detection',
          'Detects adult content and nudity',
          Icons.no_adult_content,
          AppTheme.nsfwColor,
        );
      case HuggingFaceModelType.violence:
        return (
          'Violence Detection',
          'Detects violent actions and scenes',
          Icons.sports_mma,
          AppTheme.violenceColor,
        );
      case HuggingFaceModelType.blood:
        return (
          'Blood/Gore Detection',
          'Detects blood, gore, and graphic content',
          Icons.water_drop,
          AppTheme.bloodColor,
        );
      case HuggingFaceModelType.weapons:
        return (
          'Weapons Detection',
          'Detects weapons such as guns and knives',
          Icons.gpp_bad,
          AppTheme.weaponsColor,
        );
      case HuggingFaceModelType.asr:
        return (
          'ASR',
          'Speech recognition',
          Icons.mic,
          Colors.blue,
        );
      case HuggingFaceModelType.nudeNet:
        return (
          'NudeNet Detection',
          'Body part detection with bounding boxes',
          Icons.person_search,
          AppTheme.nsfwColor,
        );
      case HuggingFaceModelType.clip:
        return (
          'CLIP Classification',
          'Zero-shot scene classification',
          Icons.image_search,
          Colors.indigo,
        );
    }
  }

  void _downloadModel(WidgetRef ref, String modelId) {
    ref.read(modelNotifierProvider.notifier).downloadModel(modelId);
  }

  void _deleteModel(BuildContext context, WidgetRef ref, String modelId) {
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

  void _selectModel(WidgetRef ref, String modelId) {
    final currentSettings = ref.read(settingsNotifierProvider).analysisSettings;
    final updatedConfig = currentSettings.modelConfig.copyWith(
      visualModelId: modelId,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(
          currentSettings.copyWith(modelConfig: updatedConfig),
        );
  }
}
