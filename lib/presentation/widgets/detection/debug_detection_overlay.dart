import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// Debug-only overlay for troubleshooting family-safety detection output.
///
/// The overlay is intentionally guarded by [kDebugMode]. In release builds this
/// widget always returns an empty box, even if [enabled] is true.
class DebugDetectionOverlay extends StatelessWidget {
  const DebugDetectionOverlay({
    required this.enabled,
    required this.detections,
    required this.currentPosition,
    required this.mediaDuration,
    super.key,
    this.evidenceRecords = const <EvidenceRecord>[],
    this.runtimeStatus,
    this.debugBuildEnabled = kDebugMode,
  });

  final bool enabled;
  final List<Detection> detections;
  final Duration currentPosition;
  final Duration mediaDuration;
  final List<EvidenceRecord> evidenceRecords;
  final LocalRuntimeStatus? runtimeStatus;

  /// Test seam for simulating release builds. Defaults to [kDebugMode].
  final bool debugBuildEnabled;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !debugBuildEnabled || !enabled) {
      return const SizedBox.shrink();
    }

    final activeDetections = detections
        .where((detection) => detection.containsTime(currentPosition))
        .toList(growable: false);
    final selectedDetection =
        activeDetections.isNotEmpty ? activeDetections.first : null;
    final evidenceById = {
      for (final record in evidenceRecords) record.id: record,
    };
    final selectedEvidence = selectedDetection == null
        ? const <EvidenceRecord>[]
        : selectedDetection.supportingEvidenceIds
            .map(evidenceById.lookup)
            .whereType<EvidenceRecord>()
            .toList(growable: false);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            key: const Key('debug_detection_overlay_paint'),
            painter: _DebugDetectionPainter(
              detections: activeDetections,
              currentPosition: currentPosition,
              mediaDuration: mediaDuration,
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: _DebugPanel(
              selectedDetection: selectedDetection,
              activeCount: activeDetections.length,
              evidenceRecords: selectedEvidence,
              runtimeStatus: runtimeStatus,
            ),
          ),
        ],
      ),
    );
  }
}

/// Timeline-layer debug overlay. It draws chunk boundaries, sampled-frame
/// markers, and detection bands when debug mode is enabled.
class DebugDetectionTimelineOverlay extends StatelessWidget {
  const DebugDetectionTimelineOverlay({
    required this.enabled,
    required this.duration,
    required this.timelineWidth,
    required this.height,
    super.key,
    this.detections = const <Detection>[],
    this.chunks = const <VideoChunk>[],
    this.sampledFrames = const <SampledFrameRef>[],
    this.sampledFrameTimestamps = const <Duration>[],
    this.debugBuildEnabled = kDebugMode,
  });

  final bool enabled;
  final Duration duration;
  final double timelineWidth;
  final double height;
  final List<Detection> detections;
  final List<VideoChunk> chunks;
  final List<SampledFrameRef> sampledFrames;
  final List<Duration> sampledFrameTimestamps;
  final bool debugBuildEnabled;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode ||
        !debugBuildEnabled ||
        !enabled ||
        duration.inMilliseconds <= 0) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        key: const Key('debug_detection_timeline_paint'),
        size: Size(timelineWidth, height),
        painter: _DebugTimelinePainter(
          duration: duration,
          detections: detections,
          chunks: chunks,
          sampledFrames: sampledFrames,
          sampledFrameTimestamps: sampledFrameTimestamps,
        ),
      ),
    );
  }
}

class _DebugPanel extends StatelessWidget {
  const _DebugPanel({
    required this.selectedDetection,
    required this.activeCount,
    required this.evidenceRecords,
    required this.runtimeStatus,
  });

  final Detection? selectedDetection;
  final int activeCount;
  final List<EvidenceRecord> evidenceRecords;
  final LocalRuntimeStatus? runtimeStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final detection = selectedDetection;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.94),
          border: Border.all(color: colorScheme.primary),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black26,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: DefaultTextStyle(
            style: theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Family Safety Debug',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                _line('Active detections', '$activeCount'),
                if (detection == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'No active detection at playhead.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  _line('Category', detection.explainableCategoryLabel),
                  _line(
                    'Severity',
                    detection.policySeverityLabel ?? 'unspecified',
                  ),
                  _line('Localization', detection.localizationLabel),
                  _line(
                    'Rationale',
                    detection.rationale ?? detection.description,
                  ),
                  _line(
                    'Evidence IDs',
                    detection.supportingEvidenceIds.isEmpty
                        ? 'none'
                        : detection.supportingEvidenceIds.join(', '),
                  ),
                  _line(
                    'Provider disagreement',
                    _stringMetadata(detection, 'providerAgreement') ??
                        _stringMetadata(detection, 'agreementState') ??
                        'none',
                  ),
                  _line(
                    'Schema repairs',
                    _listMetadata(detection, 'schemaRepairWarnings').isEmpty
                        ? 'none'
                        : _listMetadata(detection, 'schemaRepairWarnings')
                            .join(', '),
                  ),
                  _line(
                    'First vs second pass',
                    _passChangeSummary(detection),
                  ),
                  if (_rawProviderJson(detection, evidenceRecords) != null)
                    _line(
                      'Raw parsed provider JSON',
                      _rawProviderJson(detection, evidenceRecords)!,
                    ),
                ],
                const SizedBox(height: 4),
                _line(
                  'Runtime/GPU/fallback',
                  runtimeStatus == null
                      ? 'runtime status unavailable'
                      : _runtimeSummary(runtimeStatus!),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '$label: $value',
          maxLines: label == 'Raw parsed provider JSON' ? 6 : 2,
          overflow: TextOverflow.ellipsis,
        ),
      );

  String _runtimeSummary(LocalRuntimeStatus status) {
    final vramSummary =
        '${status.vramEstimate.requiredGb.toStringAsFixed(1)}GB/'
        '${status.vramEstimate.availableGb.toStringAsFixed(1)}GB VRAM';
    final parts = <String>[
      status.runtimeName,
      status.modelName,
      status.gpuDevice,
      vramSummary,
    ];
    if (status.fallbackReason != null) parts.add(status.fallbackReason!);
    return parts.join(' | ');
  }

  String _passChangeSummary(Detection detection) {
    final direct = _stringMetadata(detection, 'secondPassChanges') ??
        _stringMetadata(detection, 'passChanges');
    if (direct != null) return direct;

    final firstPass = detection.metadata?['firstPass'];
    final secondPass = detection.metadata?['secondPass'];
    if (firstPass != null || secondPass != null) {
      return 'first=${_compactJson(firstPass)} second=${_compactJson(secondPass)}';
    }
    return 'none recorded';
  }

  String? _rawProviderJson(
    Detection detection,
    List<EvidenceRecord> evidenceRecords,
  ) {
    final raw = detection.metadata?['rawProviderJson'] ??
        detection.metadata?['parsedProviderJson'] ??
        detection.metadata?['providerJson'];
    if (raw != null) return _compactJson(raw);

    for (final record in evidenceRecords) {
      final payload = record.payload;
      final evidenceRaw =
          payload['rawProviderJson'] ?? payload['parsedProviderJson'];
      if (evidenceRaw != null) return _compactJson(evidenceRaw);
      if (record.type == EvidenceType.vlmPolicyJson) {
        return _compactJson(payload);
      }
    }
    return null;
  }

  String? _stringMetadata(Detection detection, String key) {
    final value = detection.metadata?[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  List<String> _listMetadata(Detection detection, String key) {
    final value = detection.metadata?[key];
    if (value is! Iterable) return const <String>[];
    return value.whereType<String>().where((item) => item.isNotEmpty).toList();
  }

  String _compactJson(Object? value) {
    if (value == null) return 'null';
    if (value is String) return value;
    return jsonEncode(value);
  }
}

class _DebugDetectionPainter extends CustomPainter {
  const _DebugDetectionPainter({
    required this.detections,
    required this.currentPosition,
    required this.mediaDuration,
  });

  final List<Detection> detections;
  final Duration currentPosition;
  final Duration mediaDuration;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < detections.length; index++) {
      final detection = detections[index];
      final color = AppTheme.getDetectionColor(
        detection.policyCategoryId ??
            detection.visualContentCategoryId ??
            detection.type.name,
      );

      if (detection.boundingBoxes.isNotEmpty) {
        for (final box in detection.boundingBoxes) {
          _drawBox(canvas, size, box, color);
        }
      } else if (detection.isVisualDetection) {
        _drawSceneBand(canvas, size, index, color);
      }

      for (final mask in _boxList(detection.metadata?['masks'])) {
        _drawMask(canvas, size, mask, color);
      }
      for (final point in _pointList(detection.metadata?['points'])) {
        _drawPoint(canvas, size, point, color);
      }
      for (final point
          in _pointList(detection.metadata?['localizationPoints'])) {
        _drawPoint(canvas, size, point, color);
      }
    }
  }

  void _drawBox(
    Canvas canvas,
    Size size,
    Map<String, double> box,
    Color color,
  ) {
    final rect = Rect.fromLTWH(
      (box['x'] ?? 0).clamp(0.0, 1.0) * size.width,
      (box['y'] ?? 0).clamp(0.0, 1.0) * size.height,
      (box['width'] ?? 0).clamp(0.0, 1.0) * size.width,
      (box['height'] ?? 0).clamp(0.0, 1.0) * size.height,
    );
    canvas
      ..drawRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      )
      ..drawRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  void _drawMask(
    Canvas canvas,
    Size size,
    Map<String, double> box,
    Color color,
  ) {
    final rect = Rect.fromLTWH(
      (box['x'] ?? 0).clamp(0.0, 1.0) * size.width,
      (box['y'] ?? 0).clamp(0.0, 1.0) * size.height,
      (box['width'] ?? 0).clamp(0.0, 1.0) * size.width,
      (box['height'] ?? 0).clamp(0.0, 1.0) * size.height,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill,
    );
  }

  void _drawPoint(
    Canvas canvas,
    Size size,
    Map<String, double> point,
    Color color,
  ) {
    final center = Offset(
      (point['x'] ?? 0).clamp(0.0, 1.0) * size.width,
      (point['y'] ?? 0).clamp(0.0, 1.0) * size.height,
    );
    canvas
      ..drawCircle(center, 6, Paint()..color = color)
      ..drawCircle(
        center,
        10,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
  }

  void _drawSceneBand(Canvas canvas, Size size, int index, Color color) {
    final top = 6.0 + index * 10.0;
    final rect = Rect.fromLTWH(0, top, size.width, 6);
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.55));
  }

  List<Map<String, double>> _boxList(Object? value) {
    if (value is! Iterable) return const <Map<String, double>>[];
    return value
        .whereType<Map<dynamic, dynamic>>()
        .map(_normalizeBox)
        .whereType<Map<String, double>>()
        .toList(growable: false);
  }

  List<Map<String, double>> _pointList(Object? value) => _boxList(value);

  Map<String, double>? _normalizeBox(Map<dynamic, dynamic> value) {
    final x = value['x'];
    final y = value['y'];
    final width = value['width'] ?? value['w'] ?? 0;
    final height = value['height'] ?? value['h'] ?? 0;
    if (x is! num || y is! num || width is! num || height is! num) {
      return null;
    }
    return {
      'x': x.toDouble(),
      'y': y.toDouble(),
      'width': width.toDouble(),
      'height': height.toDouble(),
    };
  }

  @override
  bool shouldRepaint(covariant _DebugDetectionPainter oldDelegate) =>
      oldDelegate.detections != detections ||
      oldDelegate.currentPosition != currentPosition ||
      oldDelegate.mediaDuration != mediaDuration;
}

class _DebugTimelinePainter extends CustomPainter {
  const _DebugTimelinePainter({
    required this.duration,
    required this.detections,
    required this.chunks,
    required this.sampledFrames,
    required this.sampledFrameTimestamps,
  });

  final Duration duration;
  final List<Detection> detections;
  final List<VideoChunk> chunks;
  final List<SampledFrameRef> sampledFrames;
  final List<Duration> sampledFrameTimestamps;

  @override
  void paint(Canvas canvas, Size size) {
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) return;

    for (final detection
        in detections.where((detection) => !detection.isRejected)) {
      final color = AppTheme.getDetectionColor(
        detection.policyCategoryId ??
            detection.visualContentCategoryId ??
            detection.type.name,
      );
      final left = detection.startTime.inMilliseconds / totalMs * size.width;
      final right = detection.endTime.inMilliseconds / totalMs * size.width;
      canvas.drawRect(
        Rect.fromLTRB(left, 0, right.clamp(left + 2, size.width), size.height),
        Paint()..color = color.withValues(alpha: 0.18),
      );
    }

    for (final chunk in chunks) {
      _line(canvas, size, chunk.startTime, Colors.cyanAccent, strokeWidth: 2);
      _line(canvas, size, chunk.endTime, Colors.cyanAccent, strokeWidth: 1);
    }

    final timestamps = [
      ...sampledFrames.map((frame) => frame.timestamp),
      ...sampledFrameTimestamps,
    ];
    for (final timestamp in timestamps) {
      _line(canvas, size, timestamp, Colors.white, strokeWidth: 1);
    }
  }

  void _line(
    Canvas canvas,
    Size size,
    Duration timestamp,
    Color color, {
    required double strokeWidth,
  }) {
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0) return;
    final x = (timestamp.inMilliseconds / totalMs * size.width)
        .clamp(0.0, size.width);
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = color.withValues(alpha: 0.75)
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _DebugTimelinePainter oldDelegate) =>
      oldDelegate.duration != duration ||
      oldDelegate.detections != detections ||
      oldDelegate.chunks != chunks ||
      oldDelegate.sampledFrames != sampledFrames ||
      oldDelegate.sampledFrameTimestamps != sampledFrameTimestamps;
}

extension<K, V> on Map<K, V> {
  V? lookup(K key) => this[key];
}
