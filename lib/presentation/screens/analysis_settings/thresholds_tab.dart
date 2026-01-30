import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
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
          _buildSectionHeader(
            context,
            'Visual Detection',
            Icons.visibility,
          ),
          const SizedBox(height: 16),

          // NSFW threshold
          _buildThresholdSlider(
            context,
            ref,
            label: 'NSFW Threshold',
            value: settings.nsfwThreshold,
            enabled: settings.enableNsfw,
            color: AppTheme.nsfwColor,
            description: 'Adult content detection sensitivity',
            onChanged: (value) => _updateThreshold(
              ref,
              settings,
              nsfwThreshold: value,
            ),
            onEnabledChanged: (enabled) => _updateEnabled(
              ref,
              settings,
              enableNsfw: enabled,
            ),
          ),
          const SizedBox(height: 24),

          // Violence threshold
          _buildThresholdSlider(
            context,
            ref,
            label: 'Violence Threshold',
            value: settings.violenceThreshold,
            enabled: settings.enableViolence,
            color: AppTheme.violenceColor,
            description: 'Violence detection sensitivity',
            onChanged: (value) => _updateThreshold(
              ref,
              settings,
              violenceThreshold: value,
            ),
            onEnabledChanged: (enabled) => _updateEnabled(
              ref,
              settings,
              enableViolence: enabled,
            ),
          ),
          const SizedBox(height: 24),

          // Blood/Gore threshold
          _buildThresholdSlider(
            context,
            ref,
            label: 'Blood/Gore Threshold',
            value: settings.bloodThreshold,
            enabled: settings.enableBlood,
            color: AppTheme.bloodColor,
            description: 'Blood and gore detection sensitivity',
            onChanged: (value) => _updateThreshold(
              ref,
              settings,
              bloodThreshold: value,
            ),
            onEnabledChanged: (enabled) => _updateEnabled(
              ref,
              settings,
              enableBlood: enabled,
            ),
          ),
          const SizedBox(height: 24),

          // Weapons threshold
          _buildThresholdSlider(
            context,
            ref,
            label: 'Weapons Threshold',
            value: settings.weaponsThreshold,
            enabled: settings.enableWeapons,
            color: AppTheme.weaponsColor,
            description: 'Weapons detection sensitivity',
            onChanged: (value) => _updateThreshold(
              ref,
              settings,
              weaponsThreshold: value,
            ),
            onEnabledChanged: (enabled) => _updateEnabled(
              ref,
              settings,
              enableWeapons: enabled,
            ),
          ),
          const SizedBox(height: 32),

          // Audio detection thresholds
          _buildSectionHeader(
            context,
            'Audio Detection',
            Icons.mic,
          ),
          const SizedBox(height: 16),

          // Profanity fuzzy match threshold
          _buildThresholdSlider(
            context,
            ref,
            label: 'Profanity Fuzzy Match',
            value: settings.profanityConfig.fuzzyThreshold,
            enabled: settings.enableProfanity,
            color: AppTheme.profanityColor,
            description: 'Fuzzy matching sensitivity for profanity detection',
            onChanged: (value) => _updateProfanityThreshold(ref, settings, value),
            onEnabledChanged: (enabled) => _updateEnabled(
              ref,
              settings,
              enableProfanity: enabled,
            ),
          ),
          const SizedBox(height: 48),

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

  Widget _buildPresetButtons(
    BuildContext context,
    WidgetRef ref,
    AnalysisSettings settings,
  ) => Card(
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
                  description: 'Maximum protection, may have false positives',
                  icon: Icons.shield,
                  color: Colors.green,
                  onTap: () => _applyPreset(ref, AnalysisSettings.strict()),
                ),
                _buildPresetChip(
                  context,
                  label: 'Balanced',
                  description: 'Good balance of detection and accuracy',
                  icon: Icons.balance,
                  color: Colors.blue,
                  onTap: () => _applyPreset(ref, AnalysisSettings.defaults()),
                ),
                _buildPresetChip(
                  context,
                  label: 'Permissive',
                  description: 'Fewer false positives, may miss some content',
                  icon: Icons.tune,
                  color: Colors.orange,
                  onTap: () => _applyPreset(ref, AnalysisSettings.permissive()),
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
  }) => InkWell(
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
  ) => Row(
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
  }) => Opacity(
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

  void _updateThreshold(
    WidgetRef ref,
    AnalysisSettings settings, {
    double? nsfwThreshold,
    double? violenceThreshold,
    double? bloodThreshold,
    double? weaponsThreshold,
  }) {
    final updated = settings.copyWith(
      nsfwThreshold: nsfwThreshold ?? settings.nsfwThreshold,
      violenceThreshold: violenceThreshold ?? settings.violenceThreshold,
      bloodThreshold: bloodThreshold ?? settings.bloodThreshold,
      weaponsThreshold: weaponsThreshold ?? settings.weaponsThreshold,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }

  void _updateEnabled(
    WidgetRef ref,
    AnalysisSettings settings, {
    bool? enableNsfw,
    bool? enableViolence,
    bool? enableBlood,
    bool? enableWeapons,
    bool? enableProfanity,
  }) {
    final updated = settings.copyWith(
      enableNsfw: enableNsfw ?? settings.enableNsfw,
      enableViolence: enableViolence ?? settings.enableViolence,
      enableBlood: enableBlood ?? settings.enableBlood,
      enableWeapons: enableWeapons ?? settings.enableWeapons,
      enableProfanity: enableProfanity ?? settings.enableProfanity,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }

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
    // Keep current model config but apply preset thresholds
    final currentSettings = ref.read(settingsNotifierProvider).analysisSettings;
    final updated = preset.copyWith(
      modelConfig: currentSettings.modelConfig,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }

  void _resetToDefaults(WidgetRef ref) {
    final currentSettings = ref.read(settingsNotifierProvider).analysisSettings;
    final defaults = AnalysisSettings.defaults().copyWith(
      modelConfig: currentSettings.modelConfig,
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
                      'Example: NSFW Detection at 60% Threshold',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Frame with 75% confidence → Flagged as NSFW ✓\n'
                      '• Frame with 45% confidence → Not flagged (below threshold)\n'
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
