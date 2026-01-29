import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/presentation/screens/export_screen.dart';
import 'package:kidslens_video_editor/presentation/screens/timeline_editor_screen.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/state/providers/analysis_provider.dart';
import 'package:kidslens_video_editor/state/providers/timeline_provider.dart';

/// Screen for reviewing detected content
class DetectionReviewScreen extends ConsumerStatefulWidget {
  const DetectionReviewScreen({super.key});

  @override
  ConsumerState<DetectionReviewScreen> createState() =>
      _DetectionReviewScreenState();
}

class _DetectionReviewScreenState extends ConsumerState<DetectionReviewScreen> {
  String? _selectedType;
  bool _showDismissed = false;

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisNotifierProvider);
    final detections = analysisState.result?.timeline?.detections ?? [];

    // Filter detections, sorted by start time
    final filteredDetections = detections.where((d) {
      if (!_showDismissed && d.isRejected) return false;
      if (_selectedType != null && d.type.name != _selectedType) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Detections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _openTimeline(context),
            tooltip: 'Timeline Editor',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _openExport(context),
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, detections),
          _buildSummaryBar(context, detections),
          Expanded(
            child: filteredDetections.isEmpty
                ? _buildEmptyState(context)
                : _buildDetectionList(context, filteredDetections),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildFilterBar(BuildContext context, List<Detection> allDetections) {
    // Get unique types
    final types = allDetections.map((d) => d.type).toSet().toList();

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: 8),
                  ...types.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_formatType(type.name)),
                        selected: _selectedType == type.name,
                        selectedColor: AppTheme.getDetectionColor(type.name).withValues(alpha: 0.3),
                        onSelected: (_) => setState(() {
                          _selectedType = _selectedType == type.name ? null : type.name;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Show Dismissed'),
            selected: _showDismissed,
            onSelected: (value) => setState(() => _showDismissed = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(BuildContext context, List<Detection> detections) {
    final active = detections.where((d) => !d.isRejected).length;
    final dismissed = detections.where((d) => d.isRejected).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          _SummaryChip(
            label: 'Total',
            count: detections.length,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          _SummaryChip(
            label: 'Active',
            count: active,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: 16),
          _SummaryChip(
            label: 'Dismissed',
            count: dismissed,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Detections Found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedType != null
                ? 'No ${_formatType(_selectedType!)} detections'
                : 'The content appears to be safe',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );

  Widget _buildDetectionList(
    BuildContext context,
    List<Detection> detections,
  ) => ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: detections.length,
      itemBuilder: (context, index) {
        final detection = detections[index];
        return _DetectionCard(
          detection: detection,
          onDismiss: () => _dismissDetection(detection),
          onRestore: () => _restoreDetection(detection),
          onJumpTo: () => _jumpToDetection(detection),
        );
      },
    );

  Widget _buildBottomBar(BuildContext context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openTimeline(context),
                icon: const Icon(Icons.timeline),
                label: const Text('Edit Timeline'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _openExport(context),
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
            ),
          ],
        ),
      ),
    );

  String _formatType(String type) => type[0].toUpperCase() + type.substring(1);

  void _dismissDetection(Detection detection) {
    ref.read(timelineNotifierProvider.notifier).rejectDetection(detection.id);
  }

  void _restoreDetection(Detection detection) {
    ref.read(timelineNotifierProvider.notifier).confirmDetection(detection.id);
  }

  void _jumpToDetection(Detection detection) {
    ref.read(timelineNotifierProvider.notifier).setPlayheadPosition(detection.startTime);
  }

  void _openTimeline(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const TimelineEditorScreen(),
      ),
    );
  }

  void _openExport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ExportScreen(),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$label: $count'),
      ],
    );
}

class _DetectionCard extends StatelessWidget {
  const _DetectionCard({
    required this.detection,
    required this.onDismiss,
    required this.onRestore,
    required this.onJumpTo,
  });

  final Detection detection;
  final VoidCallback onDismiss;
  final VoidCallback onRestore;
  final VoidCallback onJumpTo;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getDetectionColor(detection.type.name);

    return Card(
      child: InkWell(
        onTap: onJumpTo,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: detection.isRejected ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              detection.type.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(detection.confidence * 100).round()}% confidence',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        detection.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatTime(detection.startTime)} - ${_formatTime(detection.endTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        detection.isRejected
                            ? Icons.restore
                            : Icons.visibility_off,
                      ),
                      onPressed: detection.isRejected ? onRestore : onDismiss,
                      tooltip: detection.isRejected ? 'Restore' : 'Dismiss',
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: onJumpTo,
                      tooltip: 'Jump to',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$milliseconds';
  }
}
