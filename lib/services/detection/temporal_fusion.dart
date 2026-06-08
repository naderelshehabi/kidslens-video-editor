import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:kidslens_video_editor/data/models/models.dart';

class TemporalFusionOptions {
  const TemporalFusionOptions({
    this.mergeGap = const Duration(milliseconds: 750),
    this.chunkOverlapTolerance = const Duration(seconds: 2),
  });

  final Duration mergeGap;
  final Duration chunkOverlapTolerance;
}

class PolicyDetectionBuildResult {
  const PolicyDetectionBuildResult({
    required this.fusedSegments,
    required this.detections,
    required this.timeline,
  });

  final List<FusedPolicySegment> fusedSegments;
  final List<Detection> detections;
  final UnifiedTimeline timeline;
}

class FusedPolicySegment {
  FusedPolicySegment({
    required this.id,
    required this.mediaId,
    required this.category,
    required this.severity,
    required double confidence,
    required this.startTime,
    required this.endTime,
    required this.recommendedAction,
    required this.needsReview,
    required List<String> rationales,
    required List<String> supportingEvidenceIds,
    required List<String> sourceModels,
    required List<PolicyFindingOrigin> origins,
    required List<PolicyAgreementState> agreementStates,
    required List<String> regionIds,
    required List<Map<String, double>> boundingBoxes,
    required List<String> policyFindingIds,
    this.groundingStatus = 'scene_level_only',
  })  : confidence = _clampConfidence(confidence),
        rationales = List.unmodifiable(_dedupeStrings(rationales)),
        supportingEvidenceIds =
            List.unmodifiable(_dedupeStrings(supportingEvidenceIds)),
        sourceModels = List.unmodifiable(_dedupeStrings(sourceModels)),
        origins = List.unmodifiable(origins.toSet()),
        agreementStates = List.unmodifiable(agreementStates.toSet()),
        regionIds = List.unmodifiable(_dedupeStrings(regionIds)),
        boundingBoxes = List.unmodifiable(_dedupeBoxes(boundingBoxes)),
        policyFindingIds = List.unmodifiable(_dedupeStrings(policyFindingIds));

  final String id;
  final String mediaId;
  final FamilySafetyPolicyCategory category;
  final FamilySafetySeverity severity;
  final double confidence;
  final Duration startTime;
  final Duration endTime;
  final RemediationAction recommendedAction;
  final bool needsReview;
  final List<String> rationales;
  final List<String> supportingEvidenceIds;
  final List<String> sourceModels;
  final List<PolicyFindingOrigin> origins;
  final List<PolicyAgreementState> agreementStates;
  final List<String> regionIds;
  final List<Map<String, double>> boundingBoxes;
  final List<String> policyFindingIds;
  final String groundingStatus;

  String get categoryId => category.id;

  Duration get duration => endTime - startTime;

  bool get hasBoundary => boundingBoxes.isNotEmpty || regionIds.isNotEmpty;

  String get primaryRationale => rationales.isEmpty
      ? '${category.displayName} detected by local policy engine.'
      : rationales.first;

  Map<String, dynamic> toDetectionMetadata() {
    final metadata = <String, dynamic>{
      'policyFindingIds': policyFindingIds,
      'policyCategoryId': category.id,
      'policyCategoryDisplayName': category.displayName,
      'policySeverity': severity.name,
      'policyContentType': category.id,
      'migrationContentType': category.id,
      'needsReview': needsReview,
      'sourceModels': sourceModels,
      'supportingEvidenceIds': supportingEvidenceIds,
      'rationale': primaryRationale,
      'rationales': rationales,
      'groundingStatus': groundingStatus,
      'regionIds': regionIds,
      'agreementStates':
          agreementStates.map((state) => state.jsonValue).toList(),
      'origins': origins.map((origin) => origin.jsonValue).toList(),
      'action': recommendedAction.name,
      'boundingBoxes': boundingBoxes,
    };
    if (category != FamilySafetyPolicyCategory.profanity) {
      metadata[Detection.visualContentCategoryKey] = category.id;
    }
    if (boundingBoxes.isNotEmpty) {
      metadata[Detection.boundingBoxKey] = boundingBoxes.first;
    }
    return metadata;
  }

  static String deterministicId({
    required String mediaId,
    required FamilySafetyPolicyCategory category,
    required Duration startTime,
    required Duration endTime,
    required Iterable<String> policyFindingIds,
  }) {
    final canonical = jsonEncode({
      'mediaId': mediaId,
      'categoryId': category.id,
      'startTimeMs': startTime.inMilliseconds,
      'endTimeMs': endTime.inMilliseconds,
      'policyFindingIds': policyFindingIds.toList()..sort(),
    });
    return 'fus_${sha256.convert(utf8.encode(canonical)).toString().substring(0, 24)}';
  }
}

class TemporalFusion {
  const TemporalFusion({
    this.options = const TemporalFusionOptions(),
  });

  final TemporalFusionOptions options;

  List<FusedPolicySegment> fuse(Iterable<PolicyFinding> findings) {
    final sorted = findings.toList(growable: false)
      ..sort((a, b) {
        final category = a.categoryId.compareTo(b.categoryId);
        if (category != 0) return category;
        final start = a.startTime.compareTo(b.startTime);
        if (start != 0) return start;
        return a.id.compareTo(b.id);
      });
    if (sorted.isEmpty) return const <FusedPolicySegment>[];

    final fused = <FusedPolicySegment>[];
    var builder = _FusedPolicySegmentBuilder.fromFinding(sorted.first);
    for (final finding in sorted.skip(1)) {
      if (builder.canMerge(finding, options)) {
        builder.add(finding);
      } else {
        fused.add(builder.build());
        builder = _FusedPolicySegmentBuilder.fromFinding(finding);
      }
    }
    fused
      ..add(builder.build())
      ..sort((a, b) {
        final start = a.startTime.compareTo(b.startTime);
        if (start != 0) return start;
        return a.categoryId.compareTo(b.categoryId);
      });
    return fused;
  }
}

class PolicyDetectionBuilder {
  const PolicyDetectionBuilder({
    this.fusion = const TemporalFusion(),
  });

  final TemporalFusion fusion;

  PolicyDetectionBuildResult build({
    required String mediaId,
    required Iterable<PolicyFinding> findings,
    required Duration mediaDuration,
    String? timelineId,
  }) {
    final fusedSegments = fusion.fuse(findings);
    final detections = fusedSegments
        .map((segment) => _toDetection(mediaId: mediaId, segment: segment))
        .toList(growable: false);
    final timeline = UnifiedTimeline.fromDetections(
      id: timelineId,
      mediaDuration: mediaDuration,
      detections: detections,
    );
    return PolicyDetectionBuildResult(
      fusedSegments: fusedSegments,
      detections: detections,
      timeline: timeline,
    );
  }

  Detection _toDetection({
    required String mediaId,
    required FusedPolicySegment segment,
  }) {
    final type = segment.category == FamilySafetyPolicyCategory.profanity
        ? ContentType.profanity
        : ContentType.nsfw;
    final description =
        '${segment.category.displayName} detected: ${segment.primaryRationale}';
    final detection = Detection(
      id: 'det_${segment.id}',
      mediaId: mediaId,
      type: type,
      startTime: segment.startTime,
      endTime: segment.endTime,
      confidence: segment.confidence,
      description: description,
      source: 'policy_engine',
      metadata: segment.toDetectionMetadata(),
    );
    if (type == ContentType.profanity) {
      return detection.copyWith(source: 'policy_engine_audio');
    }
    return detection;
  }
}

class _FusedPolicySegmentBuilder {
  _FusedPolicySegmentBuilder._({
    required this.mediaId,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.recommendedAction,
    required this.severity,
    required this.confidences,
    required this.needsReview,
    required this.rationales,
    required this.supportingEvidenceIds,
    required this.sourceModels,
    required this.origins,
    required this.agreementStates,
    required this.regionIds,
    required this.boundingBoxes,
    required this.policyFindingIds,
    required this.groundingStatuses,
  });

  factory _FusedPolicySegmentBuilder.fromFinding(PolicyFinding finding) =>
      _FusedPolicySegmentBuilder._(
        mediaId: finding.mediaId,
        category: finding.category,
        startTime: finding.startTime,
        endTime: _normalizedEnd(finding.startTime, finding.endTime),
        recommendedAction: finding.recommendedAction,
        severity: finding.severity,
        confidences: [finding.confidence],
        needsReview: finding.needsReview,
        rationales: [finding.rationale],
        supportingEvidenceIds: [...finding.supportingEvidenceIds],
        sourceModels: [...finding.sourceModels],
        origins: [...finding.origins],
        agreementStates: [finding.agreementState],
        regionIds: [...finding.regionIds],
        boundingBoxes: _extractBoundingBoxes(finding),
        policyFindingIds: [finding.id],
        groundingStatuses: [finding.groundingStatus],
      );

  final String mediaId;
  final FamilySafetyPolicyCategory category;
  Duration startTime;
  Duration endTime;
  final RemediationAction recommendedAction;
  FamilySafetySeverity severity;
  final List<double> confidences;
  bool needsReview;
  final List<String> rationales;
  final List<String> supportingEvidenceIds;
  final List<String> sourceModels;
  final List<PolicyFindingOrigin> origins;
  final List<PolicyAgreementState> agreementStates;
  final List<String> regionIds;
  final List<Map<String, double>> boundingBoxes;
  final List<String> policyFindingIds;
  final List<String> groundingStatuses;

  bool canMerge(PolicyFinding finding, TemporalFusionOptions options) {
    if (finding.mediaId != mediaId || finding.category != category) {
      return false;
    }
    final normalizedEnd = _normalizedEnd(finding.startTime, finding.endTime);
    final gap = finding.startTime - endTime;
    final overlaps = finding.startTime <= endTime && normalizedEnd >= startTime;
    final adjacent = !gap.isNegative && gap <= options.mergeGap;
    final chunkOverlap =
        finding.startTime <= endTime + options.chunkOverlapTolerance &&
            normalizedEnd >= startTime;
    return overlaps || adjacent || chunkOverlap;
  }

  void add(PolicyFinding finding) {
    final normalizedEnd = _normalizedEnd(finding.startTime, finding.endTime);
    if (finding.startTime < startTime) startTime = finding.startTime;
    if (normalizedEnd > endTime) endTime = normalizedEnd;
    if (finding.severity.index > severity.index) {
      severity = finding.severity;
    }
    confidences.add(finding.confidence);
    needsReview = needsReview || finding.needsReview;
    rationales.add(finding.rationale);
    supportingEvidenceIds.addAll(finding.supportingEvidenceIds);
    sourceModels.addAll(finding.sourceModels);
    origins.addAll(finding.origins);
    agreementStates.add(finding.agreementState);
    regionIds.addAll(finding.regionIds);
    boundingBoxes.addAll(_extractBoundingBoxes(finding));
    policyFindingIds.add(finding.id);
    groundingStatuses.add(finding.groundingStatus);
  }

  FusedPolicySegment build() => FusedPolicySegment(
        id: FusedPolicySegment.deterministicId(
          mediaId: mediaId,
          category: category,
          startTime: startTime,
          endTime: endTime,
          policyFindingIds: policyFindingIds,
        ),
        mediaId: mediaId,
        category: category,
        severity: severity,
        confidence: _aggregateConfidence(confidences),
        startTime: startTime,
        endTime: endTime,
        recommendedAction: recommendedAction,
        needsReview: needsReview,
        rationales: rationales,
        supportingEvidenceIds: supportingEvidenceIds,
        sourceModels: sourceModels,
        origins: origins,
        agreementStates: agreementStates,
        regionIds: regionIds,
        boundingBoxes: boundingBoxes,
        policyFindingIds: policyFindingIds,
        groundingStatus: _aggregateGroundingStatus(groundingStatuses),
      );
}

Duration _normalizedEnd(Duration start, Duration end) {
  if (end > start) return end;
  return start + const Duration(milliseconds: 1);
}

double _aggregateConfidence(List<double> confidences) {
  var safeProduct = 1.0;
  for (final confidence in confidences) {
    safeProduct *= 1 - _clampConfidence(confidence);
  }
  return (1 - safeProduct).clamp(0.0, 1.0);
}

String _aggregateGroundingStatus(List<String> statuses) {
  if (statuses.contains('grounded')) return 'grounded';
  if (statuses.contains('ambiguous')) return 'ambiguous';
  if (statuses.contains('failed')) return 'failed';
  if (statuses.contains('unsupported_by_model')) return 'unsupported_by_model';
  return 'scene_level_only';
}

List<Map<String, double>> _extractBoundingBoxes(PolicyFinding finding) {
  final boxes = <Map<String, double>>[];
  void collect(Object? value) {
    final box = _boxFromObject(value);
    if (box != null) boxes.add(box);
  }

  final trace = finding.developerTracePayload;
  collect(trace['boundingBox']);
  collect(trace['region']);
  collect(trace['legacyRegion']);
  final groundedRegion = trace['groundedRegion'];
  if (groundedRegion is Map) {
    collect(groundedRegion['box']);
    collect(groundedRegion['region']);
  }
  final boundingBoxes = trace['boundingBoxes'];
  if (boundingBoxes is List) {
    boundingBoxes.forEach(collect);
  }
  return _dedupeBoxes(boxes);
}

Map<String, double>? _boxFromObject(Object? value) {
  if (value is! Map) return null;
  final x = _numAsDouble(value['x'] ?? value['left']);
  final y = _numAsDouble(value['y'] ?? value['top']);
  final width = _numAsDouble(value['width']);
  final height = _numAsDouble(value['height']);
  if (x == null || y == null || width == null || height == null) {
    return null;
  }
  if (width <= 0 || height <= 0) return null;
  return {
    'x': x.clamp(0.0, 1.0),
    'y': y.clamp(0.0, 1.0),
    'width': width.clamp(0.0, 1.0),
    'height': height.clamp(0.0, 1.0),
  };
}

double? _numAsDouble(Object? value) {
  if (value is! num) return null;
  final result = value.toDouble();
  return result.isFinite ? result : null;
}

List<String> _dedupeStrings(Iterable<String> values) => values
    .where((value) => value.trim().isNotEmpty)
    .toSet()
    .toList(growable: false);

List<Map<String, double>> _dedupeBoxes(Iterable<Map<String, double>> boxes) {
  final seen = <String>{};
  final result = <Map<String, double>>[];
  for (final box in boxes) {
    final key = jsonEncode(box);
    if (seen.add(key)) {
      result.add(Map.unmodifiable(box));
    }
  }
  return result;
}

double _clampConfidence(double value) {
  if (!value.isFinite) return 0;
  return value.clamp(0.0, 1.0);
}
