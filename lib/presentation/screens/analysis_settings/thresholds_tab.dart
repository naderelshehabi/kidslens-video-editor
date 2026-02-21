import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/parameter_slider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Tab for configuring detection thresholds
class ThresholdsTab extends ConsumerWidget {
  const ThresholdsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsState = ref.watch(settingsNotifierProvider);
    final settings = settingsState.analysisSettings;
    final categories = settings.contentDetectionConfig.categories;
    final visualCategories =
        categories.where((c) => c.type == CategoryType.visual).toList();
    final audioCategories =
        categories.where((c) => c.type == CategoryType.audio).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detection Thresholds',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust confidence thresholds for content detection. Lower values catch more but may include false positives.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          // Threshold explanation card
          _buildThresholdExplanation(theme),
          const SizedBox(height: 24),

          // Preset buttons
          _buildPresetButtons(context, ref, settings),
          const SizedBox(height: 32),

          // Visual detection thresholds
          if (visualCategories.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Visual Detection',
              Icons.visibility,
            ),
            const SizedBox(height: 16),
            ...visualCategories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildCategoryThresholdSlider(
                  context,
                  ref,
                  category: category,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Audio detection thresholds
          if (audioCategories.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Audio Detection',
              Icons.mic,
            ),
            const SizedBox(height: 16),
            ...audioCategories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildCategoryThresholdSlider(
                  context,
                  ref,
                  category: category,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Profanity fuzzy match threshold (legacy audio setting)
          if (settings.enableProfanity) ...[
            _buildSectionHeader(
              context,
              'Profanity Fuzzy Match',
              Icons.text_fields,
            ),
            const SizedBox(height: 16),
            _buildThresholdSlider(
              context,
              ref,
              label: 'Profanity Fuzzy Match',
              value: settings.profanityConfig.fuzzyThreshold,
              enabled: settings.enableProfanity,
              color: AppTheme.profanityColor,
              description: 'Fuzzy matching sensitivity for profanity detection',
              onChanged: (value) =>
                  _updateProfanityThreshold(ref, settings, value),
              onEnabledChanged: (enabled) {
                final updated = settings.copyWith(enableProfanity: enabled);
                ref
                    .read(settingsNotifierProvider.notifier)
                    .updateAnalysisSettings(updated);
              },
            ),
            const SizedBox(height: 24),
          ],

          // Empty state when no categories are configured
          if (categories.isEmpty)
            Card(
              color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.tune,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No content categories configured',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Go to the Content Detection tab to set up detection categories.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Reset button
          Center(
            child: OutlinedButton.icon(
              onPressed: () => _resetToDefaults(ref),
              icon: const Icon(Icons.restore),
              label: const Text('Reset to Defaults'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryThresholdSlider(
    BuildContext context,
    WidgetRef ref, {
    required ContentCategory category,
  }) {
    final color = AppTheme.getDetectionColor(category.id);

    return Opacity(
      opacity: category.enabled ? 1.0 : 0.5,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          category.description,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: category.enabled,
                    onChanged: (enabled) {
                      ref
                          .read(settingsNotifierProvider.notifier)
                          .updateContentCategory(
                            category.id,
                            category.copyWith(enabled: enabled),
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ParameterSlider(
                value: category.threshold,
                min: 0,
                max: 1,
                divisions: 20,
                label: '${(category.threshold * 100).round()}%',
                minLabel: 'Sensitive',
                maxLabel: 'Strict',
                onChanged: category.enabled
                    ? (value) {
                        ref
                            .read(settingsNotifierProvider.notifier)
                            .setCategoryThreshold(category.id, value);
                      }
                    : null,
                activeColor: color,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'More detections',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  Text(
                    'Fewer false positives',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButtons(
    BuildContext context,
    WidgetRef ref,
    AnalysisSettings settings,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Presets',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Quickly configure thresholds for common use cases',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildPresetChip(
                    context,
                    label: 'Strict',
                    description:
                        'Maximum protection, may have false positives',
                    icon: Icons.shield,
                    color: Colors.green,
                    onTap: () =>
                        _applyPreset(ref, AnalysisSettings.strict()),
                  ),
                  _buildPresetChip(
                    context,
                    label: 'Balanced',
                    description: 'Good balance of detection and accuracy',
                    icon: Icons.balance,
                    color: Colors.blue,
                    onTap: () =>
                        _applyPreset(ref, AnalysisSettings.defaults()),
                  ),
                  _buildPresetChip(
                    context,
                    label: 'Permissive',
                    description:
                        'Fewer false positives, may miss some content',
                    icon: Icons.tune,
                    color: Colors.orange,
                    onTap: () =>
                        _applyPreset(ref, AnalysisSettings.permissive()),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildPresetChip(
    BuildContext context, {
    required String label,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) =>
      Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      );

  Widget _buildThresholdSlider(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required double value,
    required bool enabled,
    required Color color,
    required String description,
    required ValueChanged<double> onChanged,
    required ValueChanged<bool> onEnabledChanged,
  }) =>
      Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            description,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: enabled,
                      onChanged: onEnabledChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ParameterSlider(
                  value: value,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  label: '${(value * 100).round()}%',
                  minLabel: 'Sensitive',
                  maxLabel: 'Strict',
                  onChanged: enabled ? onChanged : null,
                  activeColor: color,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'More detections',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      'Fewer false positives',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  void _updateProfanityThreshold(
    WidgetRef ref,
    AnalysisSettings settings,
    double threshold,
  ) {
    final updatedProfanityConfig = settings.profanityConfig.copyWith(
      fuzzyThreshold: threshold,
    );
    final updated = settings.copyWith(
      profanityConfig: updatedProfanityConfig,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }

  void _applyPreset(WidgetRef ref, AnalysisSettings preset) {
    // Keep current model config and content detection config but apply preset thresholds
    final currentSettings =
        ref.read(settingsNotifierProvider).analysisSettings;
    final updated = preset.copyWith(
      modelConfig: currentSettings.modelConfig,
      contentDetectionConfig: currentSettings.contentDetectionConfig,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }

  void _resetToDefaults(WidgetRef ref) {
    final currentSettings =
        ref.read(settingsNotifierProvider).analysisSettings;
    final defaults = AnalysisSettings.defaults().copyWith(
      modelConfig: currentSettings.modelConfig,
      contentDetectionConfig: currentSettings.contentDetectionConfig,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(defaults);
  }

  Widget _buildThresholdExplanation(ThemeData theme) => Card(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'How Thresholds Work',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Each AI model outputs a confidence score (0-100%) indicating how likely the content matches the detection category.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _buildThresholdExplanationRow(
                theme,
                'Lower threshold (40%)',
                'Catches more potential issues but may flag innocent content (false positives). Good for maximum safety.',
                Icons.arrow_downward,
                Colors.orange,
              ),
              const SizedBox(height: 8),
              _buildThresholdExplanationRow(
                theme,
                'Default threshold (60%)',
                'Balanced setting. Catches clear violations while minimizing false positives.',
                Icons.balance,
                Colors.blue,
              ),
              const SizedBox(height: 8),
              _buildThresholdExplanationRow(
                theme,
                'Higher threshold (80%)',
                'Only flags high-confidence detections. May miss subtle or borderline content.',
                Icons.arrow_upward,
                Colors.green,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example: Detection at 60% Threshold',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Frame with 75% confidence -> Flagged as detected\n'
                      '• Frame with 45% confidence -> Not flagged (below threshold)\n'
                      '• Lower the threshold to 40% to catch the second frame',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildThresholdExplanationRow(
    ThemeData theme,
    String title,
    String description,
    IconData icon,
    Color color,
  ) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      );
}
