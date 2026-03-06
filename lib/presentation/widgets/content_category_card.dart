import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// Expandable card widget for a content detection category.
///
/// Shows a collapsed summary (name, type badge, threshold, enable toggle)
/// and expands to reveal model contributions, threshold slider, and
/// remediation action selector.
class ContentCategoryCard extends StatefulWidget {
  const ContentCategoryCard({
    required this.category,
    required this.onToggleEnabled,
    required this.onThresholdChanged,
    required this.onActionChanged,
    required this.onToggleModel,
    super.key,
    this.downloadedModelIds = const {},
  });

  final ContentCategory category;
  final ValueChanged<bool> onToggleEnabled;
  final ValueChanged<double> onThresholdChanged;
  final ValueChanged<RemediationAction> onActionChanged;
  final void Function(String modelId, {required bool enabled}) onToggleModel;
  final Set<String> downloadedModelIds;

  @override
  State<ContentCategoryCard> createState() => _ContentCategoryCardState();
}

class _ContentCategoryCardState extends State<ContentCategoryCard> {
  bool _expanded = false;

  ContentCategory get _cat => widget.category;

  Color get _categoryColor => AppTheme.getDetectionColor(_cat.id);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: _cat.enabled ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _cat.enabled
            ? BorderSide(color: _categoryColor.withValues(alpha: 0.5))
            : BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Color accent bar
          Container(
            height: 4,
            color: _cat.enabled ? _categoryColor : colorScheme.outlineVariant,
          ),
          // Collapsed header
          _buildHeader(context),
          // Expanded content
          if (_expanded) _buildExpandedContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon
            Icon(
              _iconForCategory(_cat.id),
              color: _cat.enabled ? _categoryColor : colorScheme.outline,
              size: 24,
            ),
            const SizedBox(width: 12),
            // Name + type badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cat.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _cat.enabled
                          ? colorScheme.onSurface
                          : colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      _TypeBadge(
                        label: _cat.isVisual ? 'Visual' : 'Audio',
                        color: _cat.isVisual
                            ? AppTheme.infoColor
                            : AppTheme.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Threshold: ${(_cat.threshold * 100).round()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _cat.action.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Enable switch
            Switch(
              value: _cat.enabled,
              onChanged: widget.onToggleEnabled,
              activeThumbColor: _categoryColor,
            ),
            // Expand/collapse icon
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Text(
              _cat.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_cat.modelContributions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Model Contributions',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ..._cat.modelContributions.map((contribution) {
                final downloaded = widget.downloadedModelIds.contains(
                  contribution.modelId,
                );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    downloaded ? Icons.check_circle : Icons.download,
                    color: downloaded
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  title: Text(
                    contribution.displayName,
                    style: theme.textTheme.bodySmall,
                  ),
                  subtitle: Text(
                    downloaded ? 'Downloaded' : 'Not downloaded',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Switch(
                    value: contribution.enabled,
                    onChanged: (enabled) => widget
                        .onToggleModel(contribution.modelId, enabled: enabled),
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),

            // Threshold slider
            Text(
              'Detection Threshold',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                const Text('Sensitive'),
                Expanded(
                  child: Slider(
                    value: _cat.threshold,
                    min: 0.1,
                    max: 0.95,
                    divisions: 17,
                    label: '${(_cat.threshold * 100).round()}%',
                    activeColor: _categoryColor,
                    onChanged: widget.onThresholdChanged,
                  ),
                ),
                const Text('Strict'),
              ],
            ),
            const SizedBox(height: 16),

            // Remediation action selector
            Text(
              'Action When Detected',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _availableActions.map((action) {
                final selected = _cat.action == action;
                return ChoiceChip(
                  label: Text(action.displayName),
                  avatar: Icon(
                    _iconForAction(action),
                    size: 18,
                    color: selected ? colorScheme.onPrimary : null,
                  ),
                  selected: selected,
                  selectedColor: _categoryColor,
                  onSelected: (_) => widget.onActionChanged(action),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Actions available based on category type.
  List<RemediationAction> get _availableActions {
    if (_cat.isVisual) {
      if (_cat.supportsRegions) {
        return [
          RemediationAction.blurRegion,
          RemediationAction.pixelateRegion,
          RemediationAction.blackBoxRegion,
          RemediationAction.blurFullFrame,
          RemediationAction.cutScene,
        ];
      }
      return [
        RemediationAction.blurFullFrame,
        RemediationAction.cutScene,
      ];
    } else {
      return [
        RemediationAction.mute,
        RemediationAction.beep,
      ];
    }
  }

  static IconData _iconForCategory(String categoryId) {
    switch (categoryId) {
      case 'nsfw':
        return Icons.no_adult_content;
      case 'nudity':
        return Icons.visibility_off;
      case 'female_chest_exposure':
        return Icons.female;
      case 'female_abdomen_exposure':
        return Icons.self_improvement;
      case 'female_arms_exposure':
        return Icons.front_hand;
      case 'female_legs_exposure':
        return Icons.directions_walk;
      case 'male_buttocks_exposure':
      case 'male_genitals_exposure':
        return Icons.man;
      case 'profanity':
        return Icons.volume_off;
      default:
        return Icons.category;
    }
  }

  static IconData _iconForAction(RemediationAction action) {
    switch (action) {
      case RemediationAction.blurRegion:
      case RemediationAction.blurFullFrame:
        return Icons.blur_on;
      case RemediationAction.pixelateRegion:
        return Icons.grid_on;
      case RemediationAction.blackBoxRegion:
        return Icons.crop_square;
      case RemediationAction.cutScene:
        return Icons.content_cut;
      case RemediationAction.mute:
        return Icons.volume_off;
      case RemediationAction.beep:
        return Icons.music_note;
    }
  }
}

/// Small colored badge for category type (Visual / Audio).
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}
