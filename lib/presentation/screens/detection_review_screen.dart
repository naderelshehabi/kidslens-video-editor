import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/presentation/widgets/detection/detection_explanation_panel.dart';
import 'package:kidslens_video_editor/presentation/widgets/detection_region_overlay.dart';
import 'package:kidslens_video_editor/state/providers/project_provider.dart';

/// Sort options for detections
enum DetectionSortOption {
  timeAsc('Time (Earliest First)'),
  timeDesc('Time (Latest First)'),
  confidenceHigh('Confidence (High to Low)'),
  confidenceLow('Confidence (Low to High)'),
  type('Type');

  const DetectionSortOption(this.label);
  final String label;
}

/// Detection review screen for reviewing and managing AI detections
class DetectionReviewScreen extends ConsumerStatefulWidget {
  const DetectionReviewScreen({
    required this.mediaId,
    required this.detections,
    super.key,
    this.onSeekToDetection,
  });

  final String mediaId;
  final List<Detection> detections;
  final void Function(Duration time)? onSeekToDetection;

  @override
  ConsumerState<DetectionReviewScreen> createState() =>
      _DetectionReviewScreenState();
}

class _DetectionReviewScreenState extends ConsumerState<DetectionReviewScreen> {
  // Filter state
  Set<ContentType> _selectedTypes = ContentType.values.toSet();
  Set<DetectionUserStatus> _selectedStatuses =
      DetectionUserStatus.values.toSet();
  DetectionSortOption _sortOption = DetectionSortOption.timeAsc;
  double _minConfidence = 0;

  // Selection state for batch operations
  final Set<String> _selectedDetectionIds = {};
  bool _isSelectionMode = false;

  List<Detection> get _filteredDetections {
    final filtered = widget.detections.where((d) {
      // Filter by type
      if (!_selectedTypes.contains(d.type)) return false;
      // Filter by status
      if (!_selectedStatuses.contains(d.userStatus)) return false;
      // Filter by confidence
      if (d.confidence < _minConfidence) return false;
      return true;
    }).toList()
      // Sort
      ..sort((a, b) {
        switch (_sortOption) {
          case DetectionSortOption.timeAsc:
            return a.startTime.compareTo(b.startTime);
          case DetectionSortOption.timeDesc:
            return b.startTime.compareTo(a.startTime);
          case DetectionSortOption.confidenceHigh:
            return b.confidence.compareTo(a.confidence);
          case DetectionSortOption.confidenceLow:
            return a.confidence.compareTo(b.confidence);
          case DetectionSortOption.type:
            return a.type.name.compareTo(b.type.name);
        }
      });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredDetections = _filteredDetections;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? '${_selectedDetectionIds.length} Selected'
              : 'Review Detections (${widget.detections.length})',
        ),
        centerTitle: true,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Select All',
              onPressed: _selectAll,
            ),
            IconButton(
              icon: const Icon(Icons.deselect),
              tooltip: 'Deselect All',
              onPressed: _deselectAll,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Exit Selection',
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedDetectionIds.clear();
              }),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist_rounded),
              tooltip: 'Selection Mode',
              onPressed: () => setState(() => _isSelectionMode = true),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Filter',
              onPressed: _showFilterDialog,
            ),
            PopupMenuButton<DetectionSortOption>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort',
              onSelected: (option) => setState(() => _sortOption = option),
              itemBuilder: (context) => DetectionSortOption.values
                  .map(
                    (option) => PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (_sortOption == option)
                            Icon(
                              Icons.check,
                              size: 18,
                              color: colorScheme.primary,
                            )
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(option.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          _StatsBar(
            total: widget.detections.length,
            filtered: filteredDetections.length,
            confirmed: widget.detections
                .where((d) => d.userStatus == DetectionUserStatus.confirmed)
                .length,
            rejected: widget.detections
                .where((d) => d.userStatus == DetectionUserStatus.rejected)
                .length,
            pending: widget.detections
                .where((d) => d.userStatus == DetectionUserStatus.pending)
                .length,
          ),

          // Detection list
          Expanded(
            child: filteredDetections.isEmpty
                ? _EmptyState(onClearFilters: _clearFilters)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDetections.length,
                    itemBuilder: (context, index) {
                      final detection = filteredDetections[index];
                      return _DetectionCard(
                        detection: detection,
                        isSelected:
                            _selectedDetectionIds.contains(detection.id),
                        isSelectionMode: _isSelectionMode,
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(detection.id);
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() => _isSelectionMode = true);
                          }
                          _toggleSelection(detection.id);
                        },
                        onAccept: () => _acceptDetection(detection),
                        onReject: () => _rejectDetection(detection),
                        onAdjust: () => _showAdjustDialog(detection),
                        onJumpTo: widget.onSeekToDetection != null
                            ? () =>
                                widget.onSeekToDetection!(detection.startTime)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode && _selectedDetectionIds.isNotEmpty
          ? _BatchActionsBar(
              selectedCount: _selectedDetectionIds.length,
              onAcceptAll: _acceptSelected,
              onRejectAll: _rejectSelected,
            )
          : null,
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedDetectionIds.contains(id)) {
        _selectedDetectionIds.remove(id);
      } else {
        _selectedDetectionIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedDetectionIds.addAll(
        _filteredDetections.map((d) => d.id),
      );
    });
  }

  void _deselectAll() {
    setState(_selectedDetectionIds.clear);
  }

  void _clearFilters() {
    setState(() {
      _selectedTypes = ContentType.values.toSet();
      _selectedStatuses = DetectionUserStatus.values.toSet();
      _minConfidence = 0.0;
    });
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _FilterDialog(
        selectedTypes: _selectedTypes,
        selectedStatuses: _selectedStatuses,
        minConfidence: _minConfidence,
        onApply: (types, statuses, confidence) {
          setState(() {
            _selectedTypes = types;
            _selectedStatuses = statuses;
            _minConfidence = confidence;
          });
        },
      ),
    );
  }

  void _acceptDetection(Detection detection) {
    final updated =
        detection.copyWith(userStatus: DetectionUserStatus.confirmed);
    ref.read(projectNotifierProvider.notifier).updateDetection(updated);
  }

  void _rejectDetection(Detection detection) {
    final updated =
        detection.copyWith(userStatus: DetectionUserStatus.rejected);
    ref.read(projectNotifierProvider.notifier).updateDetection(updated);
  }

  void _acceptSelected() {
    for (final id in _selectedDetectionIds) {
      final detection = widget.detections.firstWhere((d) => d.id == id);
      final updated =
          detection.copyWith(userStatus: DetectionUserStatus.confirmed);
      ref.read(projectNotifierProvider.notifier).updateDetection(updated);
    }
    setState(() {
      _isSelectionMode = false;
      _selectedDetectionIds.clear();
    });
  }

  void _rejectSelected() {
    for (final id in _selectedDetectionIds) {
      final detection = widget.detections.firstWhere((d) => d.id == id);
      final updated =
          detection.copyWith(userStatus: DetectionUserStatus.rejected);
      ref.read(projectNotifierProvider.notifier).updateDetection(updated);
    }
    setState(() {
      _isSelectionMode = false;
      _selectedDetectionIds.clear();
    });
  }

  void _showAdjustDialog(Detection detection) {
    showDialog<void>(
      context: context,
      builder: (context) => _AdjustDetectionDialog(
        detection: detection,
        onSave: (newStart, newEnd) {
          final updated = detection.copyWith(
            startTime: newStart,
            endTime: newEnd,
            originalStartTime:
                detection.originalStartTime ?? detection.startTime,
            originalEndTime: detection.originalEndTime ?? detection.endTime,
            userStatus: DetectionUserStatus.adjusted,
          );
          ref.read(projectNotifierProvider.notifier).updateDetection(updated);
        },
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.total,
    required this.filtered,
    required this.confirmed,
    required this.rejected,
    required this.pending,
  });

  final int total;
  final int filtered;
  final int confirmed;
  final int rejected;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _StatChip(
            label: 'Showing',
            value: '$filtered/$total',
            color: colorScheme.primary,
          ),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Pending',
            value: '$pending',
            color: Colors.orange,
          ),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Confirmed',
            value: '$confirmed',
            color: Colors.green,
          ),
          const SizedBox(width: 16),
          _StatChip(
            label: 'Rejected',
            value: '$rejected',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onClearFilters});

  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_list_off_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No detections match your filters',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
}

class _DetectionCard extends StatelessWidget {
  const _DetectionCard({
    required this.detection,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onAccept,
    required this.onReject,
    required this.onAdjust,
    this.onJumpTo,
  });

  final Detection detection;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onAdjust;
  final VoidCallback? onJumpTo;

  Color _getTypeColor(Detection detection) {
    // Use visual content category color if available
    final categoryId = detection.visualContentCategoryId;
    if (categoryId != null) {
      return AppTheme.getDetectionColor(categoryId);
    }

    switch (detection.type) {
      case ContentType.profanity:
        return const Color(0xFFFFB300);
      case ContentType.nsfw:
        return const Color(0xFFEC407A);
    }
  }

  IconData _getTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.profanity:
        return Icons.record_voice_over_rounded;
      case ContentType.nsfw:
        return Icons.visibility_off_rounded;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${milliseconds.toString().padLeft(2, '0')}';
  }

  String _getTypeLabel(Detection detection) {
    final categoryId = detection.visualContentCategoryId;
    if (categoryId != null && categoryId.trim().isNotEmpty) {
      return categoryId
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '',
          )
          .join(' ');
    }

    switch (detection.type) {
      case ContentType.profanity:
        return 'Profanity';
      case ContentType.nsfw:
        return 'NSFW';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typeColor = _getTypeColor(detection);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Thumbnail placeholder with optional bounding box overlay
              Container(
                width: 120,
                height: 80,
                color: colorScheme.surfaceContainerHighest,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.image_rounded,
                      size: 32,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    // Bounding box overlay for visual content detections
                    if (detection.hasBoundingBox)
                      Positioned.fill(
                        child: DetectionRegionOverlay(
                          regions: [
                            DetectionRegion(
                              x: detection.boundingBox!['x'] ?? 0,
                              y: detection.boundingBox!['y'] ?? 0,
                              width: detection.boundingBox!['width'] ?? 0,
                              height: detection.boundingBox!['height'] ?? 0,
                              categoryId: detection.visualContentCategoryId,
                            ),
                          ],
                        ),
                      ),
                    if (isSelectionMode)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: colorScheme.onPrimary,
                                )
                              : null,
                        ),
                      ),
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _formatDuration(detection.startTime),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTypeIcon(detection.type),
                                  size: 14,
                                  color: typeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getTypeLabel(detection),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: typeColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ConfidenceBadge(confidence: detection.confidence),
                          const Spacer(),
                          _StatusBadge(status: detection.userStatus),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detection.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDuration(detection.startTime)} - ${_formatDuration(detection.endTime)} '
                        '(${detection.duration.inMilliseconds}ms)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (detection.hasExplainabilityMetadata) ...[
                        const SizedBox(height: 10),
                        DetectionExplanationPanel(
                          detection: detection,
                          showFramePreview: false,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions
              if (!isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (onJumpTo != null)
                        IconButton(
                          icon: const Icon(Icons.play_circle_outline),
                          tooltip: 'Jump to',
                          onPressed: onJumpTo,
                          iconSize: 20,
                        ),
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        tooltip: 'Accept',
                        onPressed: onAccept,
                        iconSize: 20,
                        color: Colors.green,
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        tooltip: 'Reject',
                        onPressed: onReject,
                        iconSize: 20,
                        color: Colors.red,
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        tooltip: 'Adjust',
                        onPressed: onAdjust,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (confidence * 100).round();

    Color color;
    if (confidence >= 0.9) {
      color = Colors.green;
    } else if (confidence >= 0.7) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$percentage%',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DetectionUserStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;
    String label;

    switch (status) {
      case DetectionUserStatus.pending:
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        label = 'Pending';
      case DetectionUserStatus.confirmed:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Confirmed';
      case DetectionUserStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red;
        label = 'Rejected';
      case DetectionUserStatus.adjusted:
        icon = Icons.tune;
        color = Colors.blue;
        label = 'Adjusted';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _BatchActionsBar extends StatelessWidget {
  const _BatchActionsBar({
    required this.selectedCount,
    required this.onAcceptAll,
    required this.onRejectAll,
  });

  final int selectedCount;
  final VoidCallback onAcceptAll;
  final VoidCallback onRejectAll;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Text('$selectedCount selected'),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: onRejectAll,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Reject All'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: onAcceptAll,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Accept All'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.selectedTypes,
    required this.selectedStatuses,
    required this.minConfidence,
    required this.onApply,
  });

  final Set<ContentType> selectedTypes;
  final Set<DetectionUserStatus> selectedStatuses;
  final double minConfidence;
  final void Function(
    Set<ContentType> types,
    Set<DetectionUserStatus> statuses,
    double confidence,
  ) onApply;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late Set<ContentType> _types;
  late Set<DetectionUserStatus> _statuses;
  late double _confidence;

  @override
  void initState() {
    super.initState();
    _types = Set.from(widget.selectedTypes);
    _statuses = Set.from(widget.selectedStatuses);
    _confidence = widget.minConfidence;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Filter Detections'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Detection Type',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ContentType.values
                    .map(
                      (type) => FilterChip(
                        label: Text(_typeFilterLabel(type)),
                        selected: _types.contains(type),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _types.add(type);
                            } else {
                              _types.remove(type);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Review Status',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DetectionUserStatus.values
                    .map(
                      (status) => FilterChip(
                        label: Text(status.name),
                        selected: _statuses.contains(status),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _statuses.add(status);
                            } else {
                              _statuses.remove(status);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Minimum Confidence: ${(_confidence * 100).round()}%',
                style: theme.textTheme.titleSmall,
              ),
              Slider(
                value: _confidence,
                divisions: 10,
                label: '${(_confidence * 100).round()}%',
                onChanged: (value) => setState(() => _confidence = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _types = ContentType.values.toSet();
              _statuses = DetectionUserStatus.values.toSet();
              _confidence = 0;
            });
          },
          child: const Text('Reset'),
        ),
        FilledButton(
          onPressed: () {
            widget.onApply(_types, _statuses, _confidence);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String _typeFilterLabel(ContentType type) {
    switch (type) {
      case ContentType.nsfw:
        return 'Visual (NSFW/Nudity)';
      case ContentType.profanity:
        return 'Profanity';
    }
  }
}

class _AdjustDetectionDialog extends StatefulWidget {
  const _AdjustDetectionDialog({
    required this.detection,
    required this.onSave,
  });

  final Detection detection;
  final void Function(Duration newStart, Duration newEnd) onSave;

  @override
  State<_AdjustDetectionDialog> createState() => _AdjustDetectionDialogState();
}

class _AdjustDetectionDialogState extends State<_AdjustDetectionDialog> {
  late Duration _startTime;
  late Duration _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.detection.startTime;
    _endTime = widget.detection.endTime;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final milliseconds = duration.inMilliseconds % 1000;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${milliseconds.toString().padLeft(3, '0')}';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Adjust Detection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text(_formatDuration(_startTime)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      final newStart =
                          _startTime - const Duration(milliseconds: 100);
                      if (newStart >= Duration.zero) {
                        setState(() => _startTime = newStart);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final newStart =
                          _startTime + const Duration(milliseconds: 100);
                      if (newStart < _endTime) {
                        setState(() => _startTime = newStart);
                      }
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('End Time'),
              subtitle: Text(_formatDuration(_endTime)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      final newEnd =
                          _endTime - const Duration(milliseconds: 100);
                      if (newEnd > _startTime) {
                        setState(() => _endTime = newEnd);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(
                        () => _endTime =
                            _endTime + const Duration(milliseconds: 100),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Duration: ${(_endTime - _startTime).inMilliseconds}ms',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.onSave(_startTime, _endTime);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      );
}
