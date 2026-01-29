import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/state/providers/media_provider.dart';

/// Screen for sample/preview analysis results
class SampleAnalysisScreen extends ConsumerWidget {
  const SampleAnalysisScreen({
    required this.detections,
    required this.sampleDuration,
    super.key,
  });

  final List<Detection> detections;
  final Duration sampleDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Analysis'),
      ),
      body: Column(
        children: [
          // Sample info
          _buildSampleInfo(context, mediaState),
          const Divider(),
          // Results
          Expanded(
            child: detections.isEmpty
                ? _buildNoDetections(context)
                : _buildDetectionsList(context),
          ),
          // Actions
          _buildActions(context, ref),
        ],
      ),
    );
  }

  Widget _buildSampleInfo(BuildContext context, MediaState mediaState) => Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.preview),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'First ${sampleDuration.inSeconds} seconds analyzed',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: detections.isEmpty
                  ? AppTheme.successColor.withValues(alpha: 0.2)
                  : AppTheme.warningColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${detections.length} ${detections.length == 1 ? 'detection' : 'detections'}',
              style: TextStyle(
                color: detections.isEmpty
                    ? AppTheme.successColor
                    : AppTheme.warningColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

  Widget _buildNoDetections(BuildContext context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 64,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No Issues Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'The sample appears to be safe for all audiences',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );

  Widget _buildDetectionsList(BuildContext context) {
    // Group by type
    final grouped = <String, List<Detection>>{};
    for (final detection in detections) {
      grouped.putIfAbsent(detection.type.name, () => []).add(detection);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final entry in grouped.entries) ...[
          _buildTypeHeader(context, entry.key, entry.value.length),
          const SizedBox(height: 8),
          ...entry.value.map((d) => _buildDetectionItem(context, d)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildTypeHeader(BuildContext context, String type, int count) {
    final color = AppTheme.getDetectionColor(type);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          type.toUpperCase(),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionItem(BuildContext context, Detection detection) => Card(
      child: ListTile(
        leading: Icon(
          _getDetectionIcon(detection.type.name),
          color: AppTheme.getDetectionColor(detection.type.name),
        ),
        title: Text(detection.description),
        subtitle: Text(
          '${_formatTime(detection.startTime)} - ${_formatTime(detection.endTime)}',
        ),
        trailing: Text(
          '${(detection.confidence * 100).round()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );

  Widget _buildActions(BuildContext context, WidgetRef ref) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Full Analysis'),
              ),
            ),
          ],
        ),
      ),
    );

  IconData _getDetectionIcon(String type) => switch (type) {
      'profanity' => Icons.mic_off,
      'nudity' => Icons.visibility_off,
      'violence' => Icons.warning,
      'blood' => Icons.water_drop,
      'weapons' => Icons.gpp_bad,
      _ => Icons.error,
    };

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
