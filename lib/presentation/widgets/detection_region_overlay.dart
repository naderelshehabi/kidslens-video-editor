import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// A single bounding box region to draw on the overlay.
class DetectionRegion {
  const DetectionRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.categoryId,
    this.label,
    this.confidence,
  });

  /// Normalized coordinates (0.0 - 1.0)
  final double x;
  final double y;
  final double width;
  final double height;

  /// Optional category ID for color coding
  final String? categoryId;

  /// Optional label to display
  final String? label;

  /// Optional confidence score
  final double? confidence;
}

/// Overlay widget that draws detection bounding boxes on top of a child widget.
///
/// Supports two display modes:
/// - **Thumbnail mode** (`showLabels: false`): 1px stroke, no labels, count badge
/// - **Full-frame mode** (`showLabels: true`): 2px stroke, category labels
class DetectionRegionOverlay extends StatelessWidget {
  const DetectionRegionOverlay({
    required this.regions, super.key,
    this.showLabels = false,
    this.showConfidence = false,
    this.child,
  });

  /// Bounding box regions to draw
  final List<DetectionRegion> regions;

  /// Whether to show labels on each box (full-frame mode)
  final bool showLabels;

  /// Whether to show confidence on labels
  final bool showConfidence;

  /// Optional child widget (e.g., an image) to draw on top of
  final Widget? child;

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        if (child != null) child!,
        Positioned.fill(
          child: CustomPaint(
            painter: _RegionPainter(
              regions: regions,
              showLabels: showLabels,
              showConfidence: showConfidence,
            ),
          ),
        ),
        // Count badge for thumbnail mode
        if (!showLabels && regions.length > 1)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${regions.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
}

class _RegionPainter extends CustomPainter {
  _RegionPainter({
    required this.regions,
    required this.showLabels,
    required this.showConfidence,
  });

  final List<DetectionRegion> regions;
  final bool showLabels;
  final bool showConfidence;

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      final color = _getRegionColor(region.categoryId);
      final strokeWidth = showLabels ? 2.0 : 1.0;

      final rect = Rect.fromLTWH(
        region.x * size.width,
        region.y * size.height,
        region.width * size.width,
        region.height * size.height,
      );

      // Draw box outline
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawRect(rect, paint);

      // Draw semi-transparent fill
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, fillPaint);

      // Draw label in full-frame mode
      if (showLabels && region.label != null) {
        _drawLabel(canvas, rect, region, color);
      }
    }
  }

  void _drawLabel(
    Canvas canvas,
    Rect rect,
    DetectionRegion region,
    Color color,
  ) {
    var text = region.label ?? '';
    if (showConfidence && region.confidence != null) {
      text += ' ${(region.confidence! * 100).round()}%';
    }

    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final bgWidth = textPainter.width + 6;
    final bgHeight = textPainter.height + 4;

    // Position label above the box, or inside if no room
    final labelY =
        rect.top > bgHeight ? rect.top - bgHeight : rect.top;

    // Background
    final bgRect = Rect.fromLTWH(rect.left, labelY, bgWidth, bgHeight);
    canvas.drawRect(bgRect, Paint()..color = color.withValues(alpha: 0.8));

    // Text
    textPainter.paint(canvas, Offset(rect.left + 3, labelY + 2));
  }

  Color _getRegionColor(String? categoryId) {
    if (categoryId == null) return Colors.red;
    return AppTheme.getDetectionColor(categoryId);
  }

  @override
  bool shouldRepaint(covariant _RegionPainter oldDelegate) =>
      regions != oldDelegate.regions ||
      showLabels != oldDelegate.showLabels ||
      showConfidence != oldDelegate.showConfidence;
}
