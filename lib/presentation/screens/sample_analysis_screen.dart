import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

/// Sample analysis screen for testing analysis on a video segment
class SampleAnalysisScreen extends ConsumerStatefulWidget {
  const SampleAnalysisScreen({
    required this.videoPath, required this.videoDuration, super.key,
    this.onApplyToFullVideo,
  });

  final String videoPath;
  final Duration videoDuration;
  final void Function(AnalysisSettings settings)? onApplyToFullVideo;

  @override
  ConsumerState<SampleAnalysisScreen> createState() =>
      _SampleAnalysisScreenState();
}

class _SampleAnalysisScreenState extends ConsumerState<SampleAnalysisScreen> {
  // Sample segment state
  late Duration _sampleStart;
  late Duration _sampleEnd;
  static const Duration _defaultSampleDuration = Duration(seconds: 5);

  // Analysis state
  bool _isAnalyzing = false;
  double _analysisProgress = 0;
  String _analysisStep = '';
  SampleAnalysisResult? _analysisResult;

  // Settings
  late AnalysisSettings _settings;
  bool _showAdvancedSettings = false;

  @override
  void initState() {
    super.initState();
    _initializeSample();
    _settings = ref.read(settingsNotifierProvider).analysisSettings;
  }

  void _initializeSample() {
    // Start with the middle of the video
    final middle = widget.videoDuration ~/ 2;
    _sampleStart = middle;
    _sampleEnd = _clampEnd(middle + _defaultSampleDuration);
  }

  Duration _clampEnd(Duration end) {
    if (end > widget.videoDuration) return widget.videoDuration;
    return end;
  }

  Duration get _sampleDuration => _sampleEnd - _sampleStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Analysis'),
        centerTitle: true,
        actions: [
          if (_analysisResult != null && widget.onApplyToFullVideo != null)
            TextButton.icon(
              onPressed: () => widget.onApplyToFullVideo!(_settings),
              icon: const Icon(Icons.check),
              label: const Text('Apply to Full Video'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Video preview placeholder
                _VideoPreviewCard(
                  videoPath: widget.videoPath,
                  sampleStart: _sampleStart,
                  sampleEnd: _sampleEnd,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 24),

                // Sample segment selection
                _SampleSegmentCard(
                  videoDuration: widget.videoDuration,
                  sampleStart: _sampleStart,
                  sampleEnd: _sampleEnd,
                  sampleDuration: _sampleDuration,
                  onStartChanged: (value) =>
                      setState(() => _sampleStart = value),
                  onEndChanged: (value) =>
                      setState(() => _sampleEnd = _clampEnd(value)),
                  onPresetSelected: _selectPreset,
                ),
                const SizedBox(height: 24),

                // Analysis settings
                _AnalysisSettingsCard(
                  settings: _settings,
                  showAdvanced: _showAdvancedSettings,
                  onSettingsChanged: (settings) =>
                      setState(() => _settings = settings),
                  onToggleAdvanced: () => setState(
                      () => _showAdvancedSettings = !_showAdvancedSettings,),
                ),
                const SizedBox(height: 24),

                // Analysis controls
                _AnalysisControlsCard(
                  isAnalyzing: _isAnalyzing,
                  progress: _analysisProgress,
                  currentStep: _analysisStep,
                  onStartAnalysis: _startAnalysis,
                  onCancelAnalysis: _cancelAnalysis,
                ),
                const SizedBox(height: 24),

                // Results
                if (_analysisResult != null)
                  _AnalysisResultsCard(result: _analysisResult!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectPreset(_SamplePreset preset) {
    setState(() {
      switch (preset) {
        case _SamplePreset.beginning:
          _sampleStart = Duration.zero;
          _sampleEnd = _clampEnd(_defaultSampleDuration);
        case _SamplePreset.middle:
          final middle = widget.videoDuration ~/ 2;
          _sampleStart = middle - (_defaultSampleDuration ~/ 2);
          if (_sampleStart < Duration.zero) _sampleStart = Duration.zero;
          _sampleEnd = _clampEnd(_sampleStart + _defaultSampleDuration);
        case _SamplePreset.end:
          _sampleEnd = widget.videoDuration;
          _sampleStart = _sampleEnd - _defaultSampleDuration;
          if (_sampleStart < Duration.zero) _sampleStart = Duration.zero;
      }
    });
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0;
      _analysisStep = 'Initializing...';
      _analysisResult = null;
    });

    try {
      // Simulate analysis steps
      await _simulateAnalysisStep('Extracting sample segment...', 0.1);
      await _simulateAnalysisStep('Transcribing audio...', 0.3);
      await _simulateAnalysisStep('Detecting profanity...', 0.5);
      await _simulateAnalysisStep('Analyzing visual content...', 0.7);
      await _simulateAnalysisStep('Processing results...', 0.9);

      // Generate mock results
      setState(() {
        _analysisProgress = 1.0;
        _analysisStep = 'Complete';
        _analysisResult = SampleAnalysisResult(
          sampleStart: _sampleStart,
          sampleEnd: _sampleEnd,
          profanityCount: _generateMockCount(),
          nsfwCount: _generateMockCount(),
          violenceCount: _generateMockCount(),
          processingTimeMs: 2500 + (_sampleDuration.inSeconds * 100),
          averageConfidence:
              0.85 + (0.1 * (DateTime.now().millisecond % 10) / 10),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analysis failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  Future<void> _simulateAnalysisStep(String step, double progress) async {
    if (!_isAnalyzing) return;
    setState(() {
      _analysisStep = step;
      _analysisProgress = progress;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  int _generateMockCount() => DateTime.now().millisecond % 5;

  void _cancelAnalysis() {
    setState(() {
      _isAnalyzing = false;
      _analysisProgress = 0;
      _analysisStep = '';
    });
  }
}

enum _SamplePreset { beginning, middle, end }

class _VideoPreviewCard extends StatelessWidget {
  const _VideoPreviewCard({
    required this.videoPath,
    required this.sampleStart,
    required this.sampleEnd,
    required this.colorScheme,
  });

  final String videoPath;
  final Duration sampleStart;
  final Duration sampleEnd;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video preview placeholder
          Container(
            height: 300,
            color: Colors.black87,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.movie_rounded,
                  size: 64,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preview Sample',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sample indicator overlay
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.content_cut_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sample: ${_formatDuration(sampleStart)} - ${_formatDuration(sampleEnd)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Video path
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.video_file_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    videoPath,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _SampleSegmentCard extends StatelessWidget {
  const _SampleSegmentCard({
    required this.videoDuration,
    required this.sampleStart,
    required this.sampleEnd,
    required this.sampleDuration,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onPresetSelected,
  });

  final Duration videoDuration;
  final Duration sampleStart;
  final Duration sampleEnd;
  final Duration sampleDuration;
  final ValueChanged<Duration> onStartChanged;
  final ValueChanged<Duration> onEndChanged;
  final ValueChanged<_SamplePreset> onPresetSelected;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.content_cut_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Select Sample Segment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Duration: ${_formatDuration(sampleDuration)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Quick presets
            Row(
              children: [
                Text(
                  'Quick Select:',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 12),
                _PresetChip(
                  label: 'Beginning',
                  icon: Icons.first_page,
                  onTap: () => onPresetSelected(_SamplePreset.beginning),
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: 'Middle',
                  icon: Icons.center_focus_strong,
                  onTap: () => onPresetSelected(_SamplePreset.middle),
                ),
                const SizedBox(width: 8),
                _PresetChip(
                  label: 'End',
                  icon: Icons.last_page,
                  onTap: () => onPresetSelected(_SamplePreset.end),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Start time slider
            _TimeSlider(
              label: 'Start Time',
              value: sampleStart,
              max: sampleEnd - const Duration(seconds: 1),
              videoDuration: videoDuration,
              onChanged: onStartChanged,
            ),
            const SizedBox(height: 16),

            // End time slider
            _TimeSlider(
              label: 'End Time',
              value: sampleEnd,
              min: sampleStart + const Duration(seconds: 1),
              videoDuration: videoDuration,
              onChanged: onEndChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
}

class _TimeSlider extends StatelessWidget {
  const _TimeSlider({
    required this.label,
    required this.value,
    required this.videoDuration,
    required this.onChanged,
    this.min,
    this.max,
  });

  final String label;
  final Duration value;
  final Duration videoDuration;
  final ValueChanged<Duration> onChanged;
  final Duration? min;
  final Duration? max;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveMin = min ?? Duration.zero;
    final effectiveMax = max ?? videoDuration;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDuration(value),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.inMilliseconds.toDouble(),
          min: effectiveMin.inMilliseconds.toDouble(),
          max: effectiveMax.inMilliseconds.toDouble(),
          onChanged: (v) => onChanged(Duration(milliseconds: v.round())),
        ),
      ],
    );
  }
}

class _AnalysisSettingsCard extends StatelessWidget {
  const _AnalysisSettingsCard({
    required this.settings,
    required this.showAdvanced,
    required this.onSettingsChanged,
    required this.onToggleAdvanced,
  });

  final AnalysisSettings settings;
  final bool showAdvanced;
  final ValueChanged<AnalysisSettings> onSettingsChanged;
  final VoidCallback onToggleAdvanced;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_rounded, color: colorScheme.secondary),
                const SizedBox(width: 12),
                Text(
                  'Analysis Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onToggleAdvanced,
                  icon: Icon(
                    showAdvanced ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(showAdvanced ? 'Less' : 'More'),
                ),
              ],
            ),
            const Divider(height: 24),

            // Basic settings
            SwitchListTile(
              title: const Text('Enable Profanity Detection'),
              subtitle: const Text('Detect and flag profane language'),
              value: settings.enableProfanity,
              onChanged: (value) => onSettingsChanged(
                settings.copyWith(enableProfanity: value),
              ),
            ),
            SwitchListTile(
              title: const Text('Enable Visual Analysis'),
              subtitle: const Text('Detect NSFW and violent content'),
              value: settings.hasVisualDetection,
              onChanged: (value) => onSettingsChanged(
                settings.copyWith(
                  enableNsfw: value,
                  enableViolence: value,
                  enableBlood: value,
                  enableWeapons: value,
                ),
              ),
            ),

            // Advanced settings
            if (showAdvanced) ...[
              const Divider(height: 24),
              Text(
                'Advanced Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Detection Sensitivity'),
                subtitle: Slider(
                  value: settings.nsfwThreshold,
                  min: 0.5,
                  max: 0.99,
                  divisions: 49,
                  label: '${(settings.nsfwThreshold * 100).round()}%',
                  onChanged: (value) => onSettingsChanged(
                    settings.copyWith(
                      nsfwThreshold: value,
                      violenceThreshold: value,
                      bloodThreshold: value,
                      weaponsThreshold: value,
                    ),
                  ),
                ),
                trailing: Text(
                  '${(settings.nsfwThreshold * 100).round()}%',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              ListTile(
                title: const Text('Frame Sample Rate'),
                subtitle: Text(
                  'Analyze every ${settings.frameSamplingRate} frames',
                ),
                trailing: DropdownButton<int>(
                  value: settings.frameSamplingRate,
                  underline: const SizedBox.shrink(),
                  onChanged: (value) {
                    if (value != null) {
                      onSettingsChanged(
                        settings.copyWith(
                          frameSamplingRate: value,
                        ),
                      );
                    }
                  },
                  items: [1, 2, 3, 5, 10].map((rate) => DropdownMenuItem(
                      value: rate,
                      child: Text('Every $rate frames'),
                    ),).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisControlsCard extends StatelessWidget {
  const _AnalysisControlsCard({
    required this.isAnalyzing,
    required this.progress,
    required this.currentStep,
    required this.onStartAnalysis,
    required this.onCancelAnalysis,
  });

  final bool isAnalyzing;
  final double progress;
  final String currentStep;
  final VoidCallback onStartAnalysis;
  final VoidCallback onCancelAnalysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isAnalyzing) ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      currentStep,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onCancelAnalysis,
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
              ),
            ] else ...[
              Icon(
                Icons.science_rounded,
                size: 48,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Run a quick analysis on the selected sample to test your settings.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onStartAnalysis,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run Sample Analysis'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisResultsCard extends StatelessWidget {
  const _AnalysisResultsCard({required this.result});

  final SampleAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_rounded, color: colorScheme.tertiary),
                const SizedBox(width: 12),
                Text(
                  'Sample Analysis Results',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Complete',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Detection counts
            Row(
              children: [
                Expanded(
                  child: _ResultStat(
                    icon: Icons.record_voice_over_rounded,
                    label: 'Profanity',
                    count: result.profanityCount,
                    color: const Color(0xFFFFB300),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ResultStat(
                    icon: Icons.visibility_off_rounded,
                    label: 'NSFW',
                    count: result.nsfwCount,
                    color: const Color(0xFFEC407A),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ResultStat(
                    icon: Icons.warning_rounded,
                    label: 'Violence',
                    count: result.violenceCount,
                    color: const Color(0xFFFF8A65),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Additional stats
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                    label: 'Processing Time',
                    value: '${result.processingTimeMs}ms',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: colorScheme.outlineVariant,
                  ),
                  _MiniStat(
                    label: 'Avg Confidence',
                    value: '${(result.averageConfidence * 100).round()}%',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: colorScheme.outlineVariant,
                  ),
                  _MiniStat(
                    label: 'Total Detections',
                    value: '${result.totalDetections}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recommendation
            if (result.totalDetections > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Content issues detected in sample. Consider running full analysis to identify all problematic content.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No issues detected in this sample. The content appears to be family-friendly.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: count > 0 ? color : colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Result model for sample analysis
class SampleAnalysisResult {
  const SampleAnalysisResult({
    required this.sampleStart,
    required this.sampleEnd,
    required this.profanityCount,
    required this.nsfwCount,
    required this.violenceCount,
    required this.processingTimeMs,
    required this.averageConfidence,
  });

  final Duration sampleStart;
  final Duration sampleEnd;
  final int profanityCount;
  final int nsfwCount;
  final int violenceCount;
  final int processingTimeMs;
  final double averageConfidence;

  int get totalDetections => profanityCount + nsfwCount + violenceCount;
}
