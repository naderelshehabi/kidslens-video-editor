import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/voting_config.dart';
import 'package:kidslens_video_editor/presentation/widgets/content_category_card.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Tab for configuring content detection categories with MoE voting.
///
/// Displays all visual and audio categories as expandable cards. Each card
/// allows toggling model contributions, adjusting thresholds, and selecting
/// remediation actions.
class ContentDetectionTab extends ConsumerStatefulWidget {
  const ContentDetectionTab({super.key});

  @override
  ConsumerState<ContentDetectionTab> createState() =>
      _ContentDetectionTabState();
}

class _ContentDetectionTabState extends ConsumerState<ContentDetectionTab> {
  bool _showAdvanced = false;
  bool _isDownloadingRequiredModels = false;

  @override
  void initState() {
    super.initState();
    // Ensure defaults are populated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(settingsNotifierProvider.notifier)
          .ensureContentDetectionDefaults();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsState = ref.watch(settingsNotifierProvider);
    final modelState = ref.watch(modelNotifierProvider);
    final config = settingsState.analysisSettings.contentDetectionConfig;
    final requiredModelIds = _requiredModelIds(settingsState);
    final missingModelIds =
        requiredModelIds.difference(modelState.downloadedModels);
    final modelNameById = {
      for (final model in modelState.availableModels)
        model.id: model.displayName,
    };

    final visualCategories =
        config.categories.where((c) => c.isVisual).toList();
    final audioCategories = config.categories.where((c) => c.isAudio).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Text(
          'Content Detection',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Configure which content categories to detect and how to handle them. '
          'Each category can use multiple AI models via Mixture-of-Experts voting.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Preset buttons
        _buildPresetRow(context, config),
        const SizedBox(height: 24),

        _buildRequiredModelsCard(
          context,
          requiredModelIds: requiredModelIds,
          missingModelIds: missingModelIds,
          modelNameById: modelNameById,
        ),
        const SizedBox(height: 24),

        // Visual categories section
        if (visualCategories.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            icon: Icons.visibility,
            title: 'Visual Categories',
            subtitle:
                '${visualCategories.where((c) => c.enabled).length} of ${visualCategories.length} enabled',
          ),
          const SizedBox(height: 8),
          ...visualCategories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ContentCategoryCard(
                category: cat,
                downloadedModelIds: modelState.downloadedModels,
                onToggleEnabled: (enabled) => _toggleCategory(cat.id, enabled),
                onThresholdChanged: (value) =>
                    _setCategoryThreshold(cat.id, value),
                onActionChanged: (action) => _setCategoryAction(cat.id, action),
                onToggleModel: (modelId, {required enabled}) =>
                    _toggleModel(cat.id, modelId, enabled),
                onDelete: cat.isBuiltIn ? null : () => _deleteCategory(cat.id),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Audio categories section
        if (audioCategories.isNotEmpty) ...[
          _buildSectionHeader(
            context,
            icon: Icons.hearing,
            title: 'Audio Categories',
            subtitle:
                '${audioCategories.where((c) => c.enabled).length} of ${audioCategories.length} enabled',
          ),
          const SizedBox(height: 8),
          ...audioCategories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ContentCategoryCard(
                category: cat,
                downloadedModelIds: modelState.downloadedModels,
                onToggleEnabled: (enabled) => _toggleCategory(cat.id, enabled),
                onThresholdChanged: (value) =>
                    _setCategoryThreshold(cat.id, value),
                onActionChanged: (action) => _setCategoryAction(cat.id, action),
                onToggleModel: (modelId, {required enabled}) =>
                    _toggleModel(cat.id, modelId, enabled),
                onDelete: cat.isBuiltIn ? null : () => _deleteCategory(cat.id),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Add custom category button
        OutlinedButton.icon(
          onPressed: _showAddCategoryDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Custom Category'),
        ),
        const SizedBox(height: 24),

        // Advanced settings (collapsible)
        _buildAdvancedSection(context, config),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildPresetRow(BuildContext context, ContentDetectionConfig config) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text('Presets:', style: theme.textTheme.labelLarge),
        const SizedBox(width: 12),
        _PresetButton(
          label: 'Strict',
          icon: Icons.shield,
          tooltip: 'Lower thresholds, more categories enabled',
          onPressed: () => _applyPreset(_Preset.strict),
        ),
        const SizedBox(width: 8),
        _PresetButton(
          label: 'Balanced',
          icon: Icons.balance,
          tooltip: 'Default settings for most use cases',
          onPressed: () => _applyPreset(_Preset.balanced),
        ),
        const SizedBox(width: 8),
        _PresetButton(
          label: 'Permissive',
          icon: Icons.tune,
          tooltip: 'Higher thresholds, fewer false positives',
          onPressed: () => _applyPreset(_Preset.permissive),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium),
        const Spacer(),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection(
    BuildContext context,
    ContentDetectionConfig config,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showAdvanced ? Icons.expand_less : Icons.expand_more,
                  color: colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
        if (_showAdvanced) ...[
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Voting strategy
                  Text(
                    'Voting Strategy',
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How multiple model scores are combined into a final detection score.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<VotingStrategy>(
                    segments: const [
                      ButtonSegment(
                        value: VotingStrategy.weightedAverage,
                        label: Text('Weighted Avg'),
                        icon: Icon(Icons.balance, size: 16),
                      ),
                      ButtonSegment(
                        value: VotingStrategy.maximum,
                        label: Text('Maximum'),
                        icon: Icon(Icons.arrow_upward, size: 16),
                      ),
                      ButtonSegment(
                        value: VotingStrategy.minimum,
                        label: Text('Minimum'),
                        icon: Icon(Icons.arrow_downward, size: 16),
                      ),
                    ],
                    selected: {config.votingConfig.strategy},
                    onSelectionChanged: (selected) {
                      _updateVotingConfig(
                        config.votingConfig.copyWith(
                          strategy: selected.first,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Min voters
                  Row(
                    children: [
                      Text(
                        'Minimum Voters',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message:
                            'Minimum number of models that must return a score '
                            'for a valid detection. Set to 2+ to require agreement.',
                        child: Icon(
                          Icons.help_outline,
                          size: 16,
                          color: colorScheme.outline,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 60,
                        child: DropdownButton<int>(
                          value: config.votingConfig.minVoters,
                          isExpanded: true,
                          items: [1, 2, 3]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              _updateVotingConfig(
                                config.votingConfig.copyWith(minVoters: value),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Use accuracy weights
                  SwitchListTile(
                    title: const Text('Use Accuracy Weights'),
                    subtitle: const Text(
                      "Weight each model's vote by its accuracy from the registry",
                    ),
                    value: config.votingConfig.useAccuracyWeights,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      _updateVotingConfig(
                        config.votingConfig.copyWith(useAccuracyWeights: value),
                      );
                    },
                  ),

                  const Divider(),

                  // NSFW pre-filter
                  SwitchListTile(
                    title: const Text('NSFW Pre-Filter'),
                    subtitle: const Text(
                      'Gate NudeNet inference behind a fast NSFW classifier check',
                    ),
                    value: config.useNsfwPreFilter,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      _updateConfig(
                        config.copyWith(useNsfwPreFilter: value),
                      );
                    },
                  ),
                  if (config.useNsfwPreFilter) ...[
                    Row(
                      children: [
                        const Text('Pre-filter threshold:'),
                        Expanded(
                          child: Slider(
                            value: config.preFilterThreshold,
                            min: 0.05,
                            max: 0.8,
                            divisions: 15,
                            label:
                                '${(config.preFilterThreshold * 100).round()}%',
                            onChanged: (value) {
                              _updateConfig(
                                config.copyWith(preFilterThreshold: value),
                              );
                            },
                          ),
                        ),
                        Text(
                          '${(config.preFilterThreshold * 100).round()}%',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRequiredModelsCard(
    BuildContext context, {
    required Set<String> requiredModelIds,
    required Set<String> missingModelIds,
    required Map<String, String> modelNameById,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final missing = missingModelIds.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('Required Models', style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  '${requiredModelIds.length} total',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              missing.isEmpty
                  ? 'All required models are downloaded.'
                  : '${missing.length} required model(s) are missing.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: missing.isEmpty
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: missing
                    .map(
                      (id) => Chip(
                        avatar: const Icon(Icons.cloud_download, size: 16),
                        label: Text(modelNameById[id] ?? id),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: missing.isEmpty || _isDownloadingRequiredModels
                  ? null
                  : () => _downloadMissingModels(missing),
              icon: _isDownloadingRequiredModels
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_for_offline),
              label: Text(
                _isDownloadingRequiredModels
                    ? 'Downloading...'
                    : 'Download All Required',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<String> _requiredModelIds(SettingsState settingsState) {
    final settings = settingsState.analysisSettings;
    final ids = <String>{};

    if (settings.contentDetectionConfig.hasVisualCategories) {
      ids
        ..add(settings.modelConfig.nudeNetModelId)
        ..add(settings.modelConfig.clipVisionModelId)
        ..add(settings.modelConfig.clipTextModelId);
    }

    if (settings.contentDetectionConfig.hasAudioCategories ||
        settings.enableProfanity) {
      ids.add(settings.modelConfig.asrModelId);
    }
    return ids;
  }

  // ─────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────

  void _toggleCategory(String categoryId, bool enabled) {
    final settingsNotifier = ref.read(settingsNotifierProvider.notifier);
    final config = ref
        .read(settingsNotifierProvider)
        .analysisSettings
        .contentDetectionConfig;
    final categories = config.categories
        .map((c) => c.id == categoryId ? c.copyWith(enabled: enabled) : c)
        .toList();
    settingsNotifier
        .updateContentDetectionConfig(config.copyWith(categories: categories));
  }

  void _setCategoryThreshold(String categoryId, double threshold) {
    ref
        .read(settingsNotifierProvider.notifier)
        .setCategoryThreshold(categoryId, threshold);
  }

  void _setCategoryAction(String categoryId, RemediationAction action) {
    ref
        .read(settingsNotifierProvider.notifier)
        .setCategoryAction(categoryId, action);
  }

  void _toggleModel(String categoryId, String modelId, bool enabled) {
    ref
        .read(settingsNotifierProvider.notifier)
        .toggleModelContribution(categoryId, modelId, enabled: enabled);
  }

  void _deleteCategory(String categoryId) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Category'),
        content: const Text(
          'Are you sure you want to remove this custom category?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed ?? false) {
        ref
            .read(settingsNotifierProvider.notifier)
            .removeCustomContentCategory(categoryId);
      }
    });
  }

  void _updateVotingConfig(VotingConfig votingConfig) {
    ref
        .read(settingsNotifierProvider.notifier)
        .updateVotingConfig(votingConfig);
  }

  void _updateConfig(ContentDetectionConfig config) {
    ref
        .read(settingsNotifierProvider.notifier)
        .updateContentDetectionConfig(config);
  }

  void _applyPreset(_Preset preset) {
    final config = ref
        .read(settingsNotifierProvider)
        .analysisSettings
        .contentDetectionConfig;
    final defaults = ContentCategoryDefaults.allCategories;

    List<ContentCategory> updated;
    switch (preset) {
      case _Preset.strict:
        // Enable all, lower thresholds
        updated = defaults
            .map(
              (def) => def.copyWith(
                enabled: true,
                threshold: (def.threshold - 0.15).clamp(0.1, 0.95),
              ),
            )
            .toList();
      case _Preset.balanced:
        updated = List.of(defaults); // Reset to defaults
      case _Preset.permissive:
        // Keep enabled, raise thresholds
        updated = defaults
            .map(
              (def) => def.copyWith(
                threshold: (def.threshold + 0.15).clamp(0.1, 0.95),
              ),
            )
            .toList();
    }

    // Preserve any custom categories the user added
    final customCategories =
        config.categories.where((c) => !c.isBuiltIn).toList();
    updated.addAll(customCategories);

    ref
        .read(settingsNotifierProvider.notifier)
        .updateContentDetectionConfig(config.copyWith(categories: updated));
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var selectedType = CategoryType.visual;
    var selectedAction = RemediationAction.blurFullFrame;

    showDialog<ContentCategory>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Custom Category'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Smoking',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What this category detects',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Type: '),
                    const SizedBox(width: 8),
                    SegmentedButton<CategoryType>(
                      segments: const [
                        ButtonSegment(
                          value: CategoryType.visual,
                          label: Text('Visual'),
                        ),
                        ButtonSegment(
                          value: CategoryType.audio,
                          label: Text('Audio'),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (s) {
                        setDialogState(() {
                          selectedType = s.first;
                          // Reset action to match type
                          selectedAction = selectedType == CategoryType.visual
                              ? RemediationAction.blurFullFrame
                              : RemediationAction.mute;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RemediationAction>(
                  initialValue: selectedAction,
                  decoration: const InputDecoration(
                    labelText: 'Default Action',
                  ),
                  items: (selectedType == CategoryType.visual
                          ? [
                              RemediationAction.blurRegion,
                              RemediationAction.pixelateRegion,
                              RemediationAction.blurFullFrame,
                              RemediationAction.cutScene,
                            ]
                          : [
                              RemediationAction.mute,
                              RemediationAction.beep,
                            ])
                      .map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedAction = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final id =
                    name.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '_');
                Navigator.pop(
                  context,
                  ContentCategory(
                    id: id,
                    name: name,
                    description: descriptionController.text.trim(),
                    type: selectedType,
                    action: selectedAction,
                    isBuiltIn: false,
                    modelContributions: [
                      if (selectedType == CategoryType.visual)
                        ModelContribution(
                          modelId: 'clip-vit-b32-vision-fp16',
                          displayName: 'CLIP Zero-Shot',
                          modelType: HuggingFaceModelType.clip,
                          clipPrompts: [name.toLowerCase()],
                          clipNegativePrompts: ['normal scene'],
                        ),
                    ],
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    ).then((category) {
      if (category != null) {
        ref
            .read(settingsNotifierProvider.notifier)
            .addCustomContentCategory(category);
      }
    });
  }

  Future<void> _downloadMissingModels(List<String> modelIds) async {
    if (modelIds.isEmpty) return;
    setState(() => _isDownloadingRequiredModels = true);

    final failed = <String>[];
    for (final modelId in modelIds) {
      try {
        await ref.read(modelNotifierProvider.notifier).downloadModel(modelId);
      } catch (_) {
        failed.add(modelId);
      }
    }

    if (!mounted) return;
    setState(() => _isDownloadingRequiredModels = false);

    final message = failed.isEmpty
        ? 'All required models downloaded.'
        : 'Failed to download: ${failed.join(', ')}';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _Preset { strict, balanced, permissive }

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
      );
}
