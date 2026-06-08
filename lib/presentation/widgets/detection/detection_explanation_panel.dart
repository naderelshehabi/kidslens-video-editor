import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/presentation/widgets/detection_region_overlay.dart';

/// User-facing explanation for a family-safety detection.
///
/// This widget intentionally renders only sanitized detection metadata. Raw
/// provider payloads and debug traces belong in the debug-only overlay.
class DetectionExplanationPanel extends StatelessWidget {
  const DetectionExplanationPanel({
    required this.detection,
    super.key,
    this.compact = false,
    this.showFramePreview = true,
  });

  final Detection detection;
  final bool compact;
  final bool showFramePreview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = AppTheme.getDetectionColor(
      detection.policyCategoryId ??
          detection.visualContentCategoryId ??
          detection.type.name,
    );
    final rationale = detection.rationale ?? detection.description;

    final details = <Widget>[
      _InfoPill(
        icon: Icons.category_outlined,
        label: detection.explainableCategoryLabel,
        color: categoryColor,
      ),
      if (detection.policySeverityLabel != null)
        _InfoPill(
          icon: Icons.priority_high_rounded,
          label: detection.policySeverityLabel!,
          color: _severityColor(detection.policySeverity),
        ),
      _InfoPill(
        icon: Icons.percent_rounded,
        label: '${(detection.confidence * 100).round()}% confidence',
        color: colorScheme.primary,
      ),
      _InfoPill(
        icon: detection.hasBoundary
            ? Icons.crop_free_rounded
            : detection.isAudioDetection
                ? Icons.graphic_eq_rounded
                : Icons.fullscreen_rounded,
        label: detection.localizationLabel,
        color: detection.hasBoundary ? Colors.teal : colorScheme.secondary,
      ),
      _InfoPill(
        icon: _reviewIcon(detection.userStatus),
        label: detection.reviewStatusLabel,
        color: _reviewColor(detection.userStatus),
      ),
      _InfoPill(
        icon: Icons.auto_fix_high_rounded,
        label: detection.suggestedActionLabel,
        color: colorScheme.tertiary,
      ),
    ];

    return Semantics(
      container: true,
      label: 'Detection explanation. Rationale: $rationale',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFramePreview) ...[
            _SupportingFramePreview(detection: detection),
            SizedBox(height: compact ? 6 : 10),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: details,
          ),
          SizedBox(height: compact ? 6 : 10),
          Text(
            'Rationale',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            rationale,
            maxLines: compact ? 2 : 4,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          if (detection.sourceModels.isNotEmpty) ...[
            SizedBox(height: compact ? 6 : 8),
            _KeyValueText(
              label: 'Sources',
              value: detection.sourceModels.join(', '),
            ),
          ],
          if (!showFramePreview && detection.supportingFrameLabel != null) ...[
            SizedBox(height: compact ? 6 : 8),
            _KeyValueText(
              label: 'Frame',
              value: detection.supportingFrameLabel!,
            ),
          ],
          if (!compact && detection.supportingEvidenceIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            _KeyValueText(
              label: 'Evidence',
              value: detection.supportingEvidenceIds.join(', '),
            ),
          ],
          if (!compact && detection.regionIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            _KeyValueText(
              label: 'Regions',
              value: detection.regionIds.join(', '),
            ),
          ],
        ],
      ),
    );
  }

  Color _severityColor(String? severity) => switch (severity) {
        'critical' => Colors.red.shade800,
        'high' => Colors.red,
        'medium' => Colors.orange,
        'low' => Colors.blueGrey,
        _ => Colors.blueGrey,
      };

  IconData _reviewIcon(DetectionUserStatus status) => switch (status) {
        DetectionUserStatus.pending => Icons.rate_review_outlined,
        DetectionUserStatus.confirmed => Icons.check_circle_outline,
        DetectionUserStatus.rejected => Icons.cancel_outlined,
        DetectionUserStatus.adjusted => Icons.tune_rounded,
      };

  Color _reviewColor(DetectionUserStatus status) => switch (status) {
        DetectionUserStatus.pending => Colors.orange,
        DetectionUserStatus.confirmed => Colors.green,
        DetectionUserStatus.rejected => Colors.red,
        DetectionUserStatus.adjusted => Colors.blue,
      };
}

class _SupportingFramePreview extends StatelessWidget {
  const _SupportingFramePreview({required this.detection});

  final Detection detection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final frameLabel = detection.supportingFrameLabel ?? 'Supporting frame';
    final thumbnailPath = detection.supportingThumbnailPath;
    final regions = detection.boundingBoxes
        .map(
          (box) => DetectionRegion(
            x: box['x'] ?? 0,
            y: box['y'] ?? 0,
            width: box['width'] ?? 0,
            height: box['height'] ?? 0,
            categoryId: detection.policyCategoryId ??
                detection.visualContentCategoryId ??
                detection.type.name,
            label: detection.explainableCategoryLabel,
            confidence: detection.confidence,
          ),
        )
        .toList();

    final fallbackFrame = DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          detection.isAudioDetection
              ? Icons.graphic_eq_rounded
              : Icons.image_rounded,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
    Widget frame = fallbackFrame;

    if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
      frame = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(thumbnailPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallbackFrame,
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DetectionRegionOverlay(
            regions: regions,
            showLabels: true,
            showConfidence: true,
            child: frame,
          ),
          Positioned(
            left: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                frameLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.32)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _KeyValueText extends StatelessWidget {
  const _KeyValueText({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
