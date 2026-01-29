import 'package:flutter/material.dart';

import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';

/// Filter mode for detection list
enum DetectionFilterMode {
  active, // Show only non-rejected
  all,    // Show all
  rejected, // Show only rejected
}

/// Right panel showing detections and allowing actions
class DetectionPanel extends StatefulWidget {
  const DetectionPanel({
    required this.detections,
    required this.editActions,
    required this.onSeekToDetection,
    required this.onApplyAction,
    required this.onRejectDetection,
    required this.onAcceptDetection,
    required this.onToggleEditAction,
    required this.onRemoveEditAction,
    super.key,
  });

  final List<Detection> detections;
  final List<EditAction> editActions;
  final void Function(Detection) onSeekToDetection;
  final void Function(Detection, EditActionType) onApplyAction;
  final void Function(Detection) onRejectDetection;
  final void Function(Detection) onAcceptDetection;
  final void Function(EditAction) onToggleEditAction;
  final void Function(EditAction) onRemoveEditAction;

  @override
  State<DetectionPanel> createState() => _DetectionPanelState();
}

class _DetectionPanelState extends State<DetectionPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ContentType? _filterType;
  DetectionFilterMode _filterMode = DetectionFilterMode.active;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _contentTypeName(ContentType type) {
    switch (type) {
      case ContentType.nsfw:
        return 'NSFW';
      case ContentType.violence:
        return 'Violence';
      case ContentType.blood:
        return 'Blood/Gore';
      case ContentType.profanity:
        return 'Profanity';
      case ContentType.weapons:
        return 'Weapons';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Panel header with tabs
          _buildHeader(context),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetectionsTab(context),
                _buildEditsTab(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Calculate statistics
    final total = widget.detections.length;
    final active = widget.detections.where((d) => !d.isRejected).length;
    final rejected = widget.detections.where((d) => d.isRejected).length;
    final handled = widget.detections.where((d) => d.hasAction || d.isRejected).length;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Title row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Detections & Edits',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Summary statistics bar
          if (total > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatChip(context, 'Total', total, colorScheme.primary),
                  _buildStatChip(context, 'Active', active, Colors.orange),
                  _buildStatChip(context, 'Rejected', rejected, Colors.grey),
                  _buildStatChip(context, 'Handled', handled, Colors.green),
                ],
              ),
            ),
          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber, size: 14),
                    const SizedBox(width: 4),
                    Text('Detections (${_getFilteredDetections().length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit, size: 14),
                    const SizedBox(width: 4),
                    Text('Edits (${widget.editActions.length})'),
                  ],
                ),
              ),
            ],
            labelStyle: const TextStyle(fontSize: 11),
            indicatorSize: TabBarIndicatorSize.tab,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, int count, Color color) => Row(
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
        const SizedBox(width: 4),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );

  Widget _buildDetectionsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredDetections = _getFilteredDetections();

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filter mode segmented button
              SegmentedButton<DetectionFilterMode>(
                segments: const [
                  ButtonSegment(
                    value: DetectionFilterMode.active,
                    label: Text('Active', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.check_circle_outline, size: 14),
                  ),
                  ButtonSegment(
                    value: DetectionFilterMode.all,
                    label: Text('All', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.list, size: 14),
                  ),
                  ButtonSegment(
                    value: DetectionFilterMode.rejected,
                    label: Text('Rejected', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.cancel_outlined, size: 14),
                  ),
                ],
                selected: {_filterMode},
                onSelectionChanged: (value) => setState(() => _filterMode = value.first),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 8),
              // Type filter dropdown
              DropdownButtonFormField<ContentType?>(
                initialValue: _filterType,
                decoration: const InputDecoration(
                  labelText: 'Filter by type',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    child: Text('All types', style: TextStyle(fontSize: 12)),
                  ),
                  ...ContentType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      _contentTypeName(type),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),),
                ],
                onChanged: (value) => setState(() => _filterType = value),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        
        // Detection list
        Expanded(
          child: filteredDetections.isEmpty
              ? _buildEmptyDetections(context)
              : ListView.builder(
                  itemCount: filteredDetections.length,
                  itemBuilder: (context, index) => _DetectionTile(
                      detection: filteredDetections[index],
                      onSeek: () => widget.onSeekToDetection(
                        filteredDetections[index],
                      ),
                      onApplyAction: (type) => widget.onApplyAction(
                        filteredDetections[index],
                        type,
                      ),
                      onReject: () => widget.onRejectDetection(
                        filteredDetections[index],
                      ),
                      onAccept: () => widget.onAcceptDetection(
                        filteredDetections[index],
                      ),
                    ),
                ),
        ),
        
        // Bulk actions
        _buildBulkActions(context),
      ],
    );
  }

  Widget _buildEditsTab(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.editActions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_off,
              size: 48,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No edits applied',
              style: TextStyle(color: colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Text(
              'Apply actions to detections\nor use timeline tools',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.editActions.length,
      itemBuilder: (context, index) {
        final action = widget.editActions[index];
        return _EditActionTile(
          action: action,
          onToggle: () => widget.onToggleEditAction(action),
          onRemove: () => widget.onRemoveEditAction(action),
        );
      },
    );
  }

  Widget _buildEmptyDetections(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No detections found',
            style: TextStyle(color: colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            'Run analysis on imported media\nto detect content',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unhandledCount = widget.detections
        .where((d) => !d.isRejected && !d.hasAction)
        .length;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$unhandledCount unhandled',
            style: TextStyle(fontSize: 11, color: colorScheme.outline),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: unhandledCount > 0 ? _applyAllSuggested : null,
            icon: const Icon(Icons.auto_fix_high, size: 14),
            label: const Text('Apply All Suggested'),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 11),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  List<Detection> _getFilteredDetections() => widget.detections.where((d) {
      // Apply filter mode
      switch (_filterMode) {
        case DetectionFilterMode.active:
          if (d.isRejected) return false;
        case DetectionFilterMode.rejected:
          if (!d.isRejected) return false;
        case DetectionFilterMode.all:
          break;
      }
      if (_filterType != null && d.type != _filterType) return false;
      return true;
    }).toList();

  void _applyAllSuggested() {
    for (final detection in widget.detections) {
      if (!detection.isRejected && !detection.hasAction) {
        widget.onApplyAction(detection, detection.suggestedAction);
      }
    }
  }
}

class _DetectionTile extends StatelessWidget {
  const _DetectionTile({
    required this.detection,
    required this.onSeek,
    required this.onApplyAction,
    required this.onReject,
    required this.onAccept,
  });

  final Detection detection;
  final VoidCallback onSeek;
  final void Function(EditActionType) onApplyAction;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRejected = detection.isRejected;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isRejected ? colorScheme.surfaceContainerLow : null,
      child: InkWell(
        onTap: onSeek,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: isRejected ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(detection.type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(detection.type),
                            size: 12,
                            color: _getTypeColor(detection.type),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            detection.typeDisplayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getTypeColor(detection.type),
                              decoration: isRejected ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rejected indicator
                    if (isRejected) ...[
                      Icon(Icons.cancel, size: 14, color: Colors.red.shade300),
                      const SizedBox(width: 4),
                    ],
                    // Confidence
                    Text(
                      '${(detection.confidence * 100).round()}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.outline,
                        decoration: isRejected ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const Spacer(),
                    // Time
                    Text(
                      _formatTimeRange(detection.startTime, detection.endTime),
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
                
                // Content (if any)
                if (detection.content != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detection.content!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                      decoration: isRejected ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              
              const SizedBox(height: 8),
              
              // Action buttons
              if (detection.isRejected)
                Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: 14,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Rejected',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.outline,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onAccept,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Restore', style: TextStyle(fontSize: 10)),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _ActionChip(
                      icon: Icons.volume_off,
                      label: 'Mute',
                      color: Colors.purple,
                      onTap: () => onApplyAction(EditActionType.mute),
                    ),
                    _ActionChip(
                      icon: Icons.notifications,
                      label: 'Beep',
                      color: Colors.indigo,
                      onTap: () => onApplyAction(EditActionType.beep),
                    ),
                    if (detection.isVisualDetection)
                      _ActionChip(
                        icon: Icons.blur_on,
                        label: 'Blur',
                        color: Colors.blue,
                        onTap: () => onApplyAction(EditActionType.blur),
                      ),
                    _ActionChip(
                      icon: Icons.content_cut,
                      label: 'Cut',
                      color: Colors.red,
                      onTap: () => onApplyAction(EditActionType.cut),
                    ),
                    _ActionChip(
                      icon: Icons.block,
                      label: 'Reject',
                      color: colorScheme.outline,
                      onTap: onReject,
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

  Color _getTypeColor(ContentType type) {
    switch (type) {
      case ContentType.profanity:
        return Colors.orange;
      case ContentType.nsfw:
        return Colors.red;
      case ContentType.violence:
        return Colors.deepOrange;
      case ContentType.blood:
        return Colors.red.shade900;
      case ContentType.weapons:
        return Colors.amber;
    }
  }

  IconData _getTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.profanity:
        return Icons.volume_off;
      case ContentType.nsfw:
        return Icons.visibility_off;
      case ContentType.violence:
        return Icons.sports_mma;
      case ContentType.blood:
        return Icons.water_drop;
      case ContentType.weapons:
        return Icons.warning;
    }
  }

  String _formatTimeRange(Duration start, Duration end) => '${_formatDuration(start)} - ${_formatDuration(end)}';

  String _formatDuration(Duration d) {
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: color),
            ),
          ],
        ),
      ),
    );
}

class _EditActionTile extends StatelessWidget {
  const _EditActionTile({
    required this.action,
    required this.onToggle,
    required this.onRemove,
  });

  final EditAction action;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: action.enabled ? null : colorScheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Enable/disable toggle
            Switch(
              value: action.enabled,
              onChanged: (_) => onToggle(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            
            const SizedBox(width: 8),
            
            // Action type icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _getActionColor(action.type).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getActionIcon(action.type),
                size: 14,
                color: _getActionColor(action.type),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.typeLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: action.enabled
                          ? colorScheme.onSurface
                          : colorScheme.outline,
                    ),
                  ),
                  Text(
                    _formatTimeRange(action.startTime, action.endTime),
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            
            // Remove button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              color: colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(EditActionType type) {
    switch (type) {
      case EditActionType.mute:
        return Colors.purple;
      case EditActionType.beep:
        return Colors.indigo;
      case EditActionType.blur:
        return Colors.blue;
      case EditActionType.cut:
        return Colors.red;
      case EditActionType.skip:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(EditActionType type) {
    switch (type) {
      case EditActionType.mute:
        return Icons.volume_off;
      case EditActionType.beep:
        return Icons.notifications;
      case EditActionType.blur:
        return Icons.blur_on;
      case EditActionType.cut:
        return Icons.content_cut;
      case EditActionType.skip:
        return Icons.skip_next;
    }
  }

  String _formatTimeRange(Duration start, Duration end) => '${_formatDuration(start)} - ${_formatDuration(end)}';

  String _formatDuration(Duration d) {
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
