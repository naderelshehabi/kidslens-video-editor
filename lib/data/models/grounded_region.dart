import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:kidslens_video_editor/data/models/evidence_record.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';

enum GroundingStatus {
  grounded('grounded'),
  sceneLevelOnly('scene_level_only'),
  unsupportedByModel('unsupported_by_model'),
  failed('failed'),
  ambiguous('ambiguous');

  const GroundingStatus(this.jsonValue);

  final String jsonValue;

  static GroundingStatus fromJson(String value) =>
      GroundingStatus.values.firstWhere(
        (status) => status.jsonValue == value,
        orElse: () => throw ArgumentError('Unknown grounding status: $value'),
      );
}

class GroundedRegionValidationException implements Exception {
  const GroundedRegionValidationException(this.message);

  final String message;

  @override
  String toString() => 'GroundedRegionValidationException: $message';
}

class NormalizedGroundingBox {
  NormalizedGroundingBox._({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.frameWidth,
    this.frameHeight,
  });

  factory NormalizedGroundingBox.clamped({
    required double x,
    required double y,
    required double width,
    required double height,
    int? frameWidth,
    int? frameHeight,
  }) {
    _requireFinite('x', x);
    _requireFinite('y', y);
    _requireFinite('width', width);
    _requireFinite('height', height);
    final clampedX = _clampUnit(x);
    final clampedY = _clampUnit(y);
    final clampedWidth = _clampUnit(width).clamp(0.0, 1.0 - clampedX);
    final clampedHeight = _clampUnit(height).clamp(0.0, 1.0 - clampedY);
    if (clampedWidth <= 0 || clampedHeight <= 0) {
      throw const GroundedRegionValidationException(
        'grounding box must have non-zero area after clamping',
      );
    }
    if ((frameWidth != null && frameWidth <= 0) ||
        (frameHeight != null && frameHeight <= 0)) {
      throw const GroundedRegionValidationException(
        'frame dimensions must be positive when provided',
      );
    }
    return NormalizedGroundingBox._(
      x: clampedX,
      y: clampedY,
      width: clampedWidth,
      height: clampedHeight,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
  }

  factory NormalizedGroundingBox.fromCorners({
    required double left,
    required double top,
    required double right,
    required double bottom,
    int? frameWidth,
    int? frameHeight,
  }) =>
      NormalizedGroundingBox.clamped(
        x: min(left, right),
        y: min(top, bottom),
        width: (right - left).abs(),
        height: (bottom - top).abs(),
        frameWidth: frameWidth,
        frameHeight: frameHeight,
      );

  factory NormalizedGroundingBox.fromJson(Map<String, dynamic> json) =>
      NormalizedGroundingBox.clamped(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        frameWidth: (json['frameWidth'] as num?)?.toInt(),
        frameHeight: (json['frameHeight'] as num?)?.toInt(),
      );

  final double x;
  final double y;
  final double width;
  final double height;
  final int? frameWidth;
  final int? frameHeight;

  double? get frameAspectRatio => frameWidth == null || frameHeight == null
      ? null
      : frameWidth! / frameHeight!;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        if (frameWidth != null) 'frameWidth': frameWidth,
        if (frameHeight != null) 'frameHeight': frameHeight,
        if (frameAspectRatio != null) 'frameAspectRatio': frameAspectRatio,
      };

  Map<String, dynamic> toRegionJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };

  static void _requireFinite(String name, double value) {
    if (!value.isFinite) {
      throw GroundedRegionValidationException('$name must be finite');
    }
  }

  static double _clampUnit(double value) => value.clamp(0.0, 1.0);
}

class GroundedRegion {
  GroundedRegion({
    required this.id,
    required this.mediaId,
    required this.categoryId,
    required this.label,
    required this.frameId,
    required this.chunkId,
    required double confidence,
    required this.rationale,
    required this.provenance,
    required this.status,
    this.box,
    this.maskRef,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  })  : confidence = _clampConfidence(confidence),
        metadata = Map.unmodifiable(_normalizeJsonMap(metadata)) {
    if (id.trim().isEmpty) {
      throw const GroundedRegionValidationException('region id is required');
    }
    if (mediaId.trim().isEmpty ||
        frameId.trim().isEmpty ||
        chunkId.trim().isEmpty) {
      throw const GroundedRegionValidationException(
        'media, frame, and chunk ids are required',
      );
    }
    if (categoryId.trim().isEmpty || label.trim().isEmpty) {
      throw const GroundedRegionValidationException(
        'category and label are required',
      );
    }
    if (rationale.trim().isEmpty) {
      throw const GroundedRegionValidationException('rationale is required');
    }
    if (status == GroundingStatus.grounded && box == null && maskRef == null) {
      throw const GroundedRegionValidationException(
        'grounded regions require a box or mask reference',
      );
    }
  }

  factory GroundedRegion.fromJson(Map<String, dynamic> json) => GroundedRegion(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        categoryId: json['categoryId'] as String,
        label: json['label'] as String,
        frameId: json['frameId'] as String,
        chunkId: json['chunkId'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        rationale: json['rationale'] as String,
        provenance: EvidenceProvenance.fromJson(
          Map<String, dynamic>.from(json['provenance'] as Map),
        ),
        status: GroundingStatus.fromJson(json['status'] as String),
        box: json['box'] == null
            ? null
            : NormalizedGroundingBox.fromJson(
                Map<String, dynamic>.from(json['box'] as Map),
              ),
        maskRef: json['maskRef'] as String?,
        metadata: Map<String, dynamic>.from(
          json['metadata'] as Map<dynamic, dynamic>? ?? const {},
        ),
      );

  factory GroundedRegion.fromDetectedRegion({
    required String mediaId,
    required String categoryId,
    required String frameId,
    required String chunkId,
    required DetectedRegion region,
    required EvidenceProvenance provenance,
    required String rationale,
    int? frameWidth,
    int? frameHeight,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final box = NormalizedGroundingBox.clamped(
      x: region.x,
      y: region.y,
      width: region.width,
      height: region.height,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
    return GroundedRegion(
      id: deterministicId(
        mediaId: mediaId,
        categoryId: categoryId,
        frameId: frameId,
        chunkId: chunkId,
        label: region.label,
        box: box,
        provenance: provenance,
      ),
      mediaId: mediaId,
      categoryId: categoryId,
      label: region.label,
      frameId: frameId,
      chunkId: chunkId,
      box: box,
      confidence: region.confidence,
      rationale: rationale,
      provenance: provenance,
      status: GroundingStatus.grounded,
      metadata: metadata,
    );
  }

  final String id;
  final String mediaId;
  final String categoryId;
  final String label;
  final String frameId;
  final String chunkId;
  final NormalizedGroundingBox? box;
  final String? maskRef;
  final double confidence;
  final String rationale;
  final EvidenceProvenance provenance;
  final GroundingStatus status;
  final Map<String, dynamic> metadata;

  bool get hasBoundary => box != null || maskRef != null;

  DetectedRegion? toDetectedRegion() {
    final box = this.box;
    if (box == null) {
      return null;
    }
    return DetectedRegion(
      label: label,
      confidence: confidence,
      x: box.x,
      y: box.y,
      width: box.width,
      height: box.height,
    );
  }

  EvidenceRecord toEvidenceRecord({
    required Duration timestamp,
  }) {
    final detectedRegion = toDetectedRegion();
    if (detectedRegion == null) {
      throw const GroundedRegionValidationException(
        'scene-level grounding cannot be persisted as region evidence',
      );
    }
    final payload = {
      'timestampMs': timestamp.inMilliseconds,
      'categoryId': categoryId,
      'groundingStatus': status.jsonValue,
      'rationale': rationale,
      'region': detectedRegion.toJson(),
      'groundedRegion': toJson(),
    };
    return EvidenceRecord(
      id: EvidenceRecord.deterministicId(
        mediaId: mediaId,
        type: EvidenceType.groundedRegion,
        provenance: provenance,
        payload: payload,
      ),
      mediaId: mediaId,
      type: EvidenceType.groundedRegion,
      provenance: provenance,
      payload: payload,
      chunkId: chunkId,
      frameRefId: frameId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'categoryId': categoryId,
        'label': label,
        'frameId': frameId,
        'chunkId': chunkId,
        if (box != null) 'box': box!.toJson(),
        if (maskRef != null) 'maskRef': maskRef,
        'confidence': confidence,
        'rationale': rationale,
        'provenance': provenance.toJson(),
        'status': status.jsonValue,
        'metadata': metadata,
      };

  static String deterministicId({
    required String mediaId,
    required String categoryId,
    required String frameId,
    required String chunkId,
    required String label,
    required NormalizedGroundingBox? box,
    required EvidenceProvenance provenance,
  }) {
    final canonical = jsonEncode({
      'mediaId': mediaId,
      'categoryId': categoryId,
      'frameId': frameId,
      'chunkId': chunkId,
      'label': label,
      'box': box?.toRegionJson(),
      'providerId': provenance.providerId,
      'providerVersion': provenance.providerVersion,
      'modelBundleId': provenance.modelBundleId,
      'inputIds': provenance.inputIds,
      'startTimeMs': provenance.startTime.inMilliseconds,
      'endTimeMs': provenance.endTime.inMilliseconds,
    });
    return 'gr_${sha256.convert(utf8.encode(canonical)).toString().substring(0, 24)}';
  }

  static double _clampConfidence(double value) {
    if (!value.isFinite) {
      throw const GroundedRegionValidationException(
        'confidence must be finite',
      );
    }
    return value.clamp(0.0, 1.0);
  }
}

Map<String, dynamic> _normalizeJsonMap(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
