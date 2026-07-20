import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Widget displaying audio waveform
class WaveformDisplay extends StatelessWidget {
  const WaveformDisplay({
    required this.duration,
    required this.currentPosition,
    required this.zoom,
    super.key,
    this.waveformData,
    this.color,
    this.playedColor,
  });

  final Float32List? waveformData;
  final Duration duration;
  final Duration currentPosition;
  final double zoom;
  final Color? color;
  final Color? playedColor;

  @override
  Widget build(BuildContext context) {
    if (waveformData == null || waveformData!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return CustomPaint(
      painter: _WaveformPainter(
        waveformData: waveformData!,
        duration: duration,
        currentPosition: currentPosition,
        zoom: zoom,
        color: color ?? Theme.of(context).colorScheme.outline,
        playedColor: playedColor ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) => CustomPaint(
        painter: _PlaceholderWaveformPainter(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      );
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.waveformData,
    required this.duration,
    required this.currentPosition,
    required this.zoom,
    required this.color,
    required this.playedColor,
  });

  final Float32List waveformData;
  final Duration duration;
  final Duration currentPosition;
  final double zoom;
  final Color color;
  final Color playedColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final samplesPerPixel = waveformData.length / size.width;
    final centerY = size.height / 2;
    final progress = duration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / duration.inMilliseconds
        : 0.0;
    final playedWidth = size.width * progress;

    for (var x = 0.0; x < size.width; x += 1) {
      final startSample = (x * samplesPerPixel).round();
      final endSample =
          ((x + 1) * samplesPerPixel).round().clamp(0, waveformData.length);

      var maxAmplitude = 0.0;
      for (var i = startSample; i < endSample; i++) {
        maxAmplitude = math.max(maxAmplitude, waveformData[i].abs());
      }

      final amplitude = maxAmplitude * (size.height / 2) * 0.9;
      paint.color = x < playedWidth ? playedColor : color;

      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.currentPosition != currentPosition ||
      oldDelegate.zoom != zoom;
}

class _PlaceholderWaveformPainter extends CustomPainter {
  _PlaceholderWaveformPainter({required this.color});

  final Color color;
  final math.Random _random = math.Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;

    for (var x = 0.0; x < size.width; x += 2) {
      final amplitude = _random.nextDouble() * (size.height / 4);
      canvas.drawLine(
        Offset(x, centerY - amplitude),
        Offset(x, centerY + amplitude),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
