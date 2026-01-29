import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/parameter_slider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Tab for configuring model parameters
class ModelConfigTab extends ConsumerWidget {
  const ModelConfigTab({super.key});

  /// Supported languages for ASR
  static const Map<String, String> _languages = {
    'auto': 'Auto Detect',
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'nl': 'Dutch',
    'pl': 'Polish',
    'ru': 'Russian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'vi': 'Vietnamese',
    'th': 'Thai',
    'id': 'Indonesian',
    'ms': 'Malay',
  };

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
            'Model Configuration',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure speech recognition and visual analysis parameters.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          // ASR Configuration Section
          _buildSectionHeader(context, 'Speech Recognition', Icons.mic),
          const SizedBox(height: 16),

          // Language selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio Language',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select the language spoken in the video audio',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: settings.modelConfig.asrLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                    ),
                    items: _languages.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _updateModelConfig(
                          ref,
                          settings,
                          asrLanguage: value,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Translate to English toggle
          Card(
            child: SwitchListTile(
              title: const Text('Translate to English'),
              subtitle: const Text(
                'Automatically translate non-English speech to English',
              ),
              value: settings.modelConfig.translateToEnglish,
              onChanged: (value) {
                _updateModelConfig(
                  ref,
                  settings,
                  translateToEnglish: value,
                );
              },
              secondary: const Icon(Icons.translate),
            ),
          ),
          const SizedBox(height: 16),

          // Word-level timestamps toggle
          Card(
            child: SwitchListTile(
              title: const Text('Word-level Timestamps'),
              subtitle: const Text(
                'Get precise timing for each word (slower but more accurate)',
              ),
              value: settings.modelConfig.wordLevelTimestamps,
              onChanged: (value) {
                _updateModelConfig(
                  ref,
                  settings,
                  wordLevelTimestamps: value,
                );
              },
              secondary: const Icon(Icons.access_time),
            ),
          ),
          const SizedBox(height: 16),

          // Beam search size
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beam Search Size',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Higher values improve accuracy but increase processing time',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ParameterSlider(
                    value: settings.modelConfig.beamSize.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '${settings.modelConfig.beamSize}',
                    minLabel: '1 (Fast)',
                    maxLabel: '5 (Accurate)',
                    onChanged: (value) {
                      _updateModelConfig(
                        ref,
                        settings,
                        beamSize: value.round(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Visual Analysis Section
          _buildSectionHeader(context, 'Visual Analysis', Icons.visibility),
          const SizedBox(height: 16),

          // Frame sampling rate
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Frame Sampling Rate',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Analyze every Nth frame. Lower values are more accurate but slower.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ParameterSlider(
                    value: settings.frameSamplingRate.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: 'Every ${settings.frameSamplingRate} frames',
                    minLabel: '1 (All)',
                    maxLabel: '10 (Sparse)',
                    onChanged: (value) {
                      _updateSettings(
                        ref,
                        settings,
                        frameSamplingRate: value.round(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildFrameRateInfo(context, settings.frameSamplingRate),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scene detection toggle
          Card(
            child: SwitchListTile(
              title: const Text('Scene Detection'),
              subtitle: const Text(
                'Use adaptive frame sampling based on scene changes',
              ),
              value: settings.useSceneDetection,
              onChanged: (value) {
                _updateSettings(
                  ref,
                  settings,
                  useSceneDetection: value,
                );
              },
              secondary: const Icon(Icons.movie_filter),
            ),
          ),
          const SizedBox(height: 16),

          // Merge adjacent detections
          Card(
            child: SwitchListTile(
              title: const Text('Merge Adjacent Detections'),
              subtitle: const Text(
                'Combine nearby detections of the same type',
              ),
              value: settings.mergeAdjacentDetections,
              onChanged: (value) {
                _updateSettings(
                  ref,
                  settings,
                  mergeAdjacentDetections: value,
                );
              },
              secondary: const Icon(Icons.compress),
            ),
          ),
          const SizedBox(height: 16),

          // Minimum segment duration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minimum Segment Duration',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ignore detections shorter than this duration',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ParameterSlider(
                    value: settings.minSegmentDurationMs.toDouble(),
                    min: 100,
                    max: 2000,
                    divisions: 19,
                    label: '${settings.minSegmentDurationMs}ms',
                    minLabel: '100ms',
                    maxLabel: '2000ms',
                    onChanged: (value) {
                      _updateSettings(
                        ref,
                        settings,
                        minSegmentDurationMs: value.round(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildFrameRateInfo(BuildContext context, int samplingRate) {
    // Assuming 30fps video
    const fps = 30;
    final analyzedFps = fps / samplingRate;
    final analyzedPerMinute = (analyzedFps * 60).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'At 30fps: Analyzes ~${analyzedFps.toStringAsFixed(1)} frames/sec ($analyzedPerMinute/min)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  void _updateModelConfig(
    WidgetRef ref,
    AnalysisSettings settings, {
    String? asrLanguage,
    bool? translateToEnglish,
    bool? wordLevelTimestamps,
    int? beamSize,
  }) {
    final updatedConfig = settings.modelConfig.copyWith(
      asrLanguage: asrLanguage ?? settings.modelConfig.asrLanguage,
      translateToEnglish:
          translateToEnglish ?? settings.modelConfig.translateToEnglish,
      wordLevelTimestamps:
          wordLevelTimestamps ?? settings.modelConfig.wordLevelTimestamps,
      beamSize: beamSize ?? settings.modelConfig.beamSize,
    );
    final updated = settings.copyWith(modelConfig: updatedConfig);
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }

  void _updateSettings(
    WidgetRef ref,
    AnalysisSettings settings, {
    int? frameSamplingRate,
    bool? useSceneDetection,
    bool? mergeAdjacentDetections,
    int? minSegmentDurationMs,
  }) {
    final updated = settings.copyWith(
      frameSamplingRate: frameSamplingRate ?? settings.frameSamplingRate,
      useSceneDetection: useSceneDetection ?? settings.useSceneDetection,
      mergeAdjacentDetections:
          mergeAdjacentDetections ?? settings.mergeAdjacentDetections,
      minSegmentDurationMs:
          minSegmentDurationMs ?? settings.minSegmentDurationMs,
    );
    ref.read(settingsNotifierProvider.notifier).updateAnalysisSettings(updated);
  }
}
