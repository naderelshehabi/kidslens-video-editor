import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';
import 'package:kidslens_video_editor/data/models/voting_config.dart';
import 'package:kidslens_video_editor/presentation/widgets/content_category_card.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Tab for configuring content detection categories.
class ContentDetectionTab extends ConsumerStatefulWidget {
  const ContentDetectionTab({super.key});

  @override
  ConsumerState<ContentDetectionTab> createState() =>
      _ContentDetectionTabState();
}

class _ContentDetectionTabState extends ConsumerState<ContentDetectionTab> {
  bool _showAdvanced = false;

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
          'Visual and audio categories share the same policy controls.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Preset buttons
        _buildPresetRow(context, config),
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
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

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

                ],
              ),
            ),
          ),
        ],
      ],
    );
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

  void _updateVotingConfig(VotingConfig votingConfig) {
    ref
        .read(settingsNotifierProvider.notifier)
        .updateVotingConfig(votingConfig);
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

    ref
        .read(settingsNotifierProvider.notifier)
        .updateContentDetectionConfig(config.copyWith(categories: updated));
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
