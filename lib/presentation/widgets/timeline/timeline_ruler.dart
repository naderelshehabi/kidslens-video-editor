import 'package:flutter/material.dart';

/// Timeline ruler showing time markers
class TimelineRuler extends StatelessWidget {
  const TimelineRuler({
    required this.duration,
    required this.zoom,
    required this.scrollController,
    super.key,
  });

  final Duration duration;
  final double zoom;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final width = duration.inMilliseconds * zoom / 10;

    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: CustomPaint(
            painter: _TimelineRulerPainter(
              duration: duration,
              zoom: zoom,
              textColor: Theme.of(context).colorScheme.onSurface,
              lineColor: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineRulerPainter extends CustomPainter {
  _TimelineRulerPainter({
    required this.duration,
    required this.zoom,
    required this.textColor,
    required this.lineColor,
  });

  final Duration duration;
  final double zoom;
  final Color textColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Determine interval based on zoom
    final intervalSeconds = _getInterval();
    final totalSeconds = duration.inSeconds;

    for (var seconds = 0; seconds <= totalSeconds; seconds += intervalSeconds) {
      final x = seconds * 1000 * zoom / 10;

      // Draw major tick
      canvas.drawLine(
        Offset(x, size.height - 16),
        Offset(x, size.height),
        paint,
      );

      // Draw time label
      final label = _formatTime(seconds);
      textPainter
        ..text = TextSpan(
          text: label,
          style: TextStyle(color: textColor, fontSize: 10),
        )
        ..layout()
        ..paint(
          canvas,
          Offset(x - textPainter.width / 2, 4),
        );

      // Draw minor ticks
      if (intervalSeconds >= 5) {
        for (var minor = 1; minor < intervalSeconds; minor++) {
          final minorX = (seconds + minor) * 1000 * zoom / 10;
          if (minorX <= size.width) {
            canvas.drawLine(
              Offset(minorX, size.height - 8),
              Offset(minorX, size.height),
              paint..color = lineColor.withValues(alpha: 0.5),
            );
          }
        }
        paint.color = lineColor;
      }
    }
  }

  int _getInterval() {
    if (zoom >= 2) return 1;
    if (zoom >= 1) return 5;
    if (zoom >= 0.5) return 10;
    if (zoom >= 0.25) return 30;
    return 60;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _TimelineRulerPainter oldDelegate) => oldDelegate.duration != duration ||
        oldDelegate.zoom != zoom ||
        oldDelegate.textColor != textColor;
}
