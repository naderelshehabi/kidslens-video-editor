import 'dart:async';
import 'dart:math';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/services/detection/evidence_store.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider.dart';

class GroundingProviderException implements Exception {
  const GroundingProviderException(this.message);

  final String message;

  @override
  String toString() => 'GroundingProviderException: $message';
}

enum GroundingSourceKind {
  vlmNative('vlm_native'),
  locateAnything('locate_anything'),
  legacyNudenet('legacy_nudenet'),
  modestyParser('modesty_parser'),
  officialGroundingModel('official_grounding_model');

  const GroundingSourceKind(this.jsonValue);

  final String jsonValue;
}

enum LocateAnythingDecodingMode {
  fast,
  slow,
  hybrid,
}

class GroundingRequest {
  const GroundingRequest({
    required this.mediaId,
    required this.chunk,
    required this.frames,
    required this.modelBundle,
    required this.runtimeProfile,
    this.vlmResponse,
    this.rawGroundingResponse,
    this.groundingPrompts = const <String>[],
    this.legacyNudenetRegionsByFrame = const <List<DetectedRegion>>[],
    this.modestyParserRegionsByFrame = const <List<DetectedRegion>>[],
    this.frameWidth,
    this.frameHeight,
    this.allowEvaluationOnlyModels = false,
    this.evidenceStore,
    this.cancellationToken,
  });

  final String mediaId;
  final VideoChunk chunk;
  final List<SampledFrameRef> frames;
  final ModelBundleManifest modelBundle;
  final LocalRuntimeProfile runtimeProfile;
  final VlmSegmentResponse? vlmResponse;
  final String? rawGroundingResponse;
  final List<String> groundingPrompts;
  final List<List<DetectedRegion>> legacyNudenetRegionsByFrame;
  final List<List<DetectedRegion>> modestyParserRegionsByFrame;
  final int? frameWidth;
  final int? frameHeight;
  final bool allowEvaluationOnlyModels;
  final EvidenceStore? evidenceStore;
  final CancellationToken? cancellationToken;

  SampledFrameRef? frameById(String id) {
    for (final frame in frames) {
      if (frame.id == id) {
        return frame;
      }
    }
    return null;
  }
}

class GroundingResult {
  const GroundingResult({
    required this.providerId,
    required this.providerVersion,
    required this.status,
    this.regions = const <GroundedRegion>[],
    this.evidenceRecords = const <EvidenceRecord>[],
    this.warnings = const <String>[],
  });

  final String providerId;
  final String providerVersion;
  final GroundingStatus status;
  final List<GroundedRegion> regions;
  final List<EvidenceRecord> evidenceRecords;
  final List<String> warnings;

  bool get hasGroundedRegions => regions.any(
        (region) =>
            region.status == GroundingStatus.grounded && region.hasBoundary,
      );
}

abstract interface class GroundingProvider {
  String get providerId;

  String get providerVersion;

  GroundingSourceKind get sourceKind;

  Future<GroundingResult> ground(GroundingRequest request);
}

class VlmNativeGroundingProvider implements GroundingProvider {
  const VlmNativeGroundingProvider({
    this.providerId = 'vlm_native_grounding',
    this.providerVersion = '1',
  });

  @override
  final String providerId;

  @override
  final String providerVersion;

  @override
  GroundingSourceKind get sourceKind => GroundingSourceKind.vlmNative;

  @override
  Future<GroundingResult> ground(GroundingRequest request) async {
    await _checkCancellation(request);
    if (!request.modelBundle.supportsBoundingBoxes &&
        !request.modelBundle.supportsPointLocalization) {
      return GroundingResult(
        providerId: providerId,
        providerVersion: providerVersion,
        status: GroundingStatus.unsupportedByModel,
        warnings: const <String>[
          'model manifest does not advertise box or point localization',
        ],
      );
    }
    final response = request.vlmResponse;
    if (response == null) {
      return GroundingResult(
        providerId: providerId,
        providerVersion: providerVersion,
        status: GroundingStatus.sceneLevelOnly,
        warnings: const <String>['no VLM response was provided for grounding'],
      );
    }

    final rawRegions = response.parsedJson['groundedRegions'];
    if (rawRegions == null) {
      return GroundingResult(
        providerId: providerId,
        providerVersion: providerVersion,
        status: GroundingStatus.sceneLevelOnly,
        warnings: const <String>[
          'VLM response did not include groundedRegions',
        ],
      );
    }
    if (rawRegions is! List) {
      throw const GroundingProviderException(
        'groundedRegions must be a JSON list',
      );
    }

    final warnings = <String>[];
    final regions = <GroundedRegion>[];
    for (final raw in rawRegions) {
      if (raw is! Map) {
        warnings.add('skipped non-object grounded region');
        continue;
      }
      try {
        final region = _groundedRegionFromMap(
          request: request,
          raw: Map<String, dynamic>.from(raw),
          providerId: providerId,
          providerVersion: providerVersion,
          inputIds: [
            request.chunk.id,
            ...request.frames.map((frame) => frame.id),
            ...response.evidenceRecords.map((record) => record.id),
          ],
          sourceKind: sourceKind,
        );
        regions.add(region);
      } on Object catch (error) {
        warnings.add('skipped invalid grounded region: $error');
      }
    }

    return _persistResult(
      request: request,
      providerId: providerId,
      providerVersion: providerVersion,
      status: regions.isEmpty
          ? GroundingStatus.ambiguous
          : GroundingStatus.grounded,
      regions: regions,
      warnings: warnings,
    );
  }
}

class ApprovedOfficialGroundingProvider extends VlmNativeGroundingProvider {
  const ApprovedOfficialGroundingProvider()
      : super(
          providerId: 'official_grounding_model',
          providerVersion: '1',
        );

  @override
  GroundingSourceKind get sourceKind =>
      GroundingSourceKind.officialGroundingModel;

  @override
  Future<GroundingResult> ground(GroundingRequest request) {
    if (!request.modelBundle.roles.contains(ModelBundleRole.grounding)) {
      throw const GroundingProviderException(
        'official grounding provider requires a grounding model bundle',
      );
    }
    if (request.modelBundle.approvalStatus !=
        ModelBundleApprovalStatus.productionApproved) {
      throw const GroundingProviderException(
        'official grounding provider requires a production-approved model',
      );
    }
    return super.ground(request);
  }
}

class LegacyNudenetGroundingProvider extends _LegacyRegionGroundingProvider {
  const LegacyNudenetGroundingProvider()
      : super(
          providerId: 'legacy_nudenet_grounding',
          providerVersion: '1',
          sourceKind: GroundingSourceKind.legacyNudenet,
        );

  @override
  List<List<DetectedRegion>> regionsByFrame(GroundingRequest request) =>
      request.legacyNudenetRegionsByFrame;

  @override
  String categoryIdFor(DetectedRegion region) =>
      'legacy_nudenet_${_normalizeCategoryId(region.label)}';
}

class ModestyParserGroundingProvider extends _LegacyRegionGroundingProvider {
  const ModestyParserGroundingProvider()
      : super(
          providerId: 'modesty_parser_grounding',
          providerVersion: '1',
          sourceKind: GroundingSourceKind.modestyParser,
        );

  @override
  List<List<DetectedRegion>> regionsByFrame(GroundingRequest request) =>
      request.modestyParserRegionsByFrame;

  @override
  String categoryIdFor(DetectedRegion region) =>
      _normalizeCategoryId(region.label);
}

abstract class _LegacyRegionGroundingProvider implements GroundingProvider {
  const _LegacyRegionGroundingProvider({
    required this.providerId,
    required this.providerVersion,
    required this.sourceKind,
  });

  @override
  final String providerId;

  @override
  final String providerVersion;

  @override
  final GroundingSourceKind sourceKind;

  List<List<DetectedRegion>> regionsByFrame(GroundingRequest request);

  String categoryIdFor(DetectedRegion region);

  @override
  Future<GroundingResult> ground(GroundingRequest request) async {
    await _checkCancellation(request);
    final regions = <GroundedRegion>[];
    final source = regionsByFrame(request);
    for (var frameIndex = 0; frameIndex < source.length; frameIndex++) {
      if (frameIndex >= request.frames.length) {
        break;
      }
      final frame = request.frames[frameIndex];
      final provenance = _provenance(
        request: request,
        providerId: providerId,
        providerVersion: providerVersion,
        inputIds: [request.chunk.id, frame.id],
      );
      for (final region in source[frameIndex]) {
        try {
          regions.add(
            GroundedRegion.fromDetectedRegion(
              mediaId: request.mediaId,
              categoryId: categoryIdFor(region),
              frameId: frame.id,
              chunkId: request.chunk.id,
              region: region,
              provenance: provenance,
              rationale:
                  'Legacy ${sourceKind.jsonValue} region ${region.label}.',
              frameWidth: request.frameWidth,
              frameHeight: request.frameHeight,
              metadata: {
                'sourceKind': sourceKind.jsonValue,
              },
            ),
          );
        } on Object {
          continue;
        }
      }
    }
    return _persistResult(
      request: request,
      providerId: providerId,
      providerVersion: providerVersion,
      status: regions.isEmpty
          ? GroundingStatus.sceneLevelOnly
          : GroundingStatus.grounded,
      regions: regions,
    );
  }
}

class LocateAnythingGroundingProvider implements GroundingProvider {
  const LocateAnythingGroundingProvider({
    this.coordinateScale = 1000,
    this.pointBoxSize = 0.02,
  });

  final double coordinateScale;
  final double pointBoxSize;

  @override
  String get providerId => 'locateanything_eval_grounding';

  @override
  String get providerVersion => '1';

  @override
  GroundingSourceKind get sourceKind => GroundingSourceKind.locateAnything;

  @override
  Future<GroundingResult> ground(GroundingRequest request) async {
    await _checkCancellation(request);
    _validateLocateAnythingGate(request);
    final raw = request.rawGroundingResponse?.trim();
    if (raw == null || raw.isEmpty) {
      return GroundingResult(
        providerId: providerId,
        providerVersion: providerVersion,
        status: GroundingStatus.failed,
        warnings: const <String>['no LocateAnything response was provided'],
      );
    }
    final frame = request.frames.isEmpty ? null : request.frames.first;
    if (frame == null) {
      return GroundingResult(
        providerId: providerId,
        providerVersion: providerVersion,
        status: GroundingStatus.failed,
        warnings: const <String>['LocateAnything grounding requires a frame'],
      );
    }

    final boxes = parseBoxTokens(raw);
    final pointBoxes = parsePointTokens(raw);
    final allBoxes = [...boxes, ...pointBoxes];
    final prompts = request.groundingPrompts.isEmpty
        ? const <String>['locateanything_object']
        : request.groundingPrompts;
    final provenance = _provenance(
      request: request,
      providerId: providerId,
      providerVersion: providerVersion,
      inputIds: [request.chunk.id, frame.id],
    );
    final regions = <GroundedRegion>[];
    for (var index = 0; index < allBoxes.length; index++) {
      final label = prompts[min(index, prompts.length - 1)];
      final box = allBoxes[index];
      regions.add(
        GroundedRegion(
          id: GroundedRegion.deterministicId(
            mediaId: request.mediaId,
            categoryId: _normalizeCategoryId(label),
            frameId: frame.id,
            chunkId: request.chunk.id,
            label: label,
            box: box,
            provenance: provenance,
          ),
          mediaId: request.mediaId,
          categoryId: _normalizeCategoryId(label),
          label: label,
          frameId: frame.id,
          chunkId: request.chunk.id,
          box: box,
          confidence: 1,
          rationale: 'LocateAnything token localization for "$label".',
          provenance: provenance,
          status: GroundingStatus.grounded,
          metadata: {
            'sourceKind': sourceKind.jsonValue,
            'evaluationOnly': true,
            'commercialProductionAllowed': false,
          },
        ),
      );
    }
    return _persistResult(
      request: request,
      providerId: providerId,
      providerVersion: providerVersion,
      status: regions.isEmpty
          ? GroundingStatus.ambiguous
          : GroundingStatus.grounded,
      regions: regions,
      warnings: regions.isEmpty
          ? const <String>[
              'LocateAnything response did not include boxes or points',
            ]
          : const <String>[],
    );
  }

  List<NormalizedGroundingBox> parseBoxTokens(String raw) {
    final regex = RegExp(
      r'<box>\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*,\s*([0-9.]+)\s*</box>',
      caseSensitive: false,
    );
    return regex.allMatches(raw).map((match) {
      final left = _normalizeCoordinate(double.parse(match.group(1)!));
      final top = _normalizeCoordinate(double.parse(match.group(2)!));
      final right = _normalizeCoordinate(double.parse(match.group(3)!));
      final bottom = _normalizeCoordinate(double.parse(match.group(4)!));
      return NormalizedGroundingBox.fromCorners(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      );
    }).toList(growable: false);
  }

  List<NormalizedGroundingBox> parsePointTokens(String raw) {
    final regex = RegExp(
      r'<point>\s*([0-9.]+)\s*,\s*([0-9.]+)\s*</point>',
      caseSensitive: false,
    );
    final half = pointBoxSize / 2;
    return regex.allMatches(raw).map((match) {
      final x = _normalizeCoordinate(double.parse(match.group(1)!));
      final y = _normalizeCoordinate(double.parse(match.group(2)!));
      return NormalizedGroundingBox.clamped(
        x: x - half,
        y: y - half,
        width: pointBoxSize,
        height: pointBoxSize,
      );
    }).toList(growable: false);
  }

  double _normalizeCoordinate(double value) =>
      value <= 1 ? value : value / coordinateScale;

  void _validateLocateAnythingGate(GroundingRequest request) {
    if (request.modelBundle.modelId != 'nvidia_locateanything_3b') {
      throw const GroundingProviderException(
        'LocateAnything provider requires nvidia_locateanything_3b bundle',
      );
    }
    if (!request.allowEvaluationOnlyModels) {
      throw const GroundingProviderException(
        'LocateAnything is evaluation-only and production-blocked',
      );
    }
    if (request.modelBundle.commercialUse != CommercialUseStatus.blocked ||
        request.modelBundle.approvalStatus !=
            ModelBundleApprovalStatus.blocked) {
      throw const GroundingProviderException(
        'LocateAnything gate expects the current blocked non-commercial manifest',
      );
    }
  }
}

class LocateAnythingEvaluationRecord {
  const LocateAnythingEvaluationRecord({
    required this.licenseVerified,
    required this.localRuntimeValidated,
    required this.promptsTested,
    required this.decodingModesBenchmarked,
    required this.meanBoxIouByPrompt,
    required this.failureModes,
  });

  final bool licenseVerified;
  final bool localRuntimeValidated;
  final List<String> promptsTested;
  final List<LocateAnythingDecodingMode> decodingModesBenchmarked;
  final Map<String, double> meanBoxIouByPrompt;
  final List<String> failureModes;

  bool get productionEligible =>
      licenseVerified &&
      localRuntimeValidated &&
      promptsTested.isNotEmpty &&
      LocateAnythingDecodingMode.values
          .every(decodingModesBenchmarked.contains) &&
      meanBoxIouByPrompt.isNotEmpty &&
      failureModes.isNotEmpty;

  List<String> validate() {
    final issues = <String>[];
    if (!licenseVerified) {
      issues.add('official LocateAnything license and terms must be verified');
    }
    if (!localRuntimeValidated) {
      issues.add('local Windows/NVIDIA runtime must be validated');
    }
    const requiredPrompts = {
      'exposed female legs',
      'blood',
      'knife',
      'gun',
      'exposed chest',
      'bare abdomen',
    };
    final missingPrompts = requiredPrompts.difference(promptsTested.toSet());
    if (missingPrompts.isNotEmpty) {
      issues.add('missing prompt tests: ${missingPrompts.join(', ')}');
    }
    final missingModes = LocateAnythingDecodingMode.values
        .where((mode) => !decodingModesBenchmarked.contains(mode))
        .map((mode) => mode.name)
        .toList(growable: false);
    if (missingModes.isNotEmpty) {
      issues.add('missing decoding benchmarks: ${missingModes.join(', ')}');
    }
    for (final entry in meanBoxIouByPrompt.entries) {
      if (entry.value < 0 || entry.value > 1) {
        issues.add('IoU for ${entry.key} must be between 0 and 1');
      }
    }
    const documentedFailureModes = {
      'ambiguous clothing',
      'multiple people',
      'occlusion',
      'blur',
      'low light',
    };
    final missingFailureModes =
        documentedFailureModes.difference(failureModes.toSet());
    if (missingFailureModes.isNotEmpty) {
      issues.add(
        'missing failure modes: ${missingFailureModes.join(', ')}',
      );
    }
    return issues;
  }
}

GroundedRegion _groundedRegionFromMap({
  required GroundingRequest request,
  required Map<String, dynamic> raw,
  required String providerId,
  required String providerVersion,
  required List<String> inputIds,
  required GroundingSourceKind sourceKind,
}) {
  final frameId = _stringValue(raw, 'frameId');
  final frame = frameId == null ? null : request.frameById(frameId);
  if (frame == null) {
    throw GroundingProviderException('unknown frameId: ${frameId ?? '<null>'}');
  }
  final box = _readBox(raw, request.frameWidth, request.frameHeight);
  final categoryId = _stringValue(raw, 'category') ??
      _stringValue(raw, 'categoryId') ??
      'other';
  final label = _stringValue(raw, 'label') ?? categoryId;
  final provenance = _provenance(
    request: request,
    providerId: providerId,
    providerVersion: providerVersion,
    inputIds: inputIds,
  );
  return GroundedRegion(
    id: _stringValue(raw, 'regionId') ??
        _stringValue(raw, 'id') ??
        GroundedRegion.deterministicId(
          mediaId: request.mediaId,
          categoryId: categoryId,
          frameId: frame.id,
          chunkId: request.chunk.id,
          label: label,
          box: box,
          provenance: provenance,
        ),
    mediaId: request.mediaId,
    categoryId: categoryId,
    label: label,
    frameId: frame.id,
    chunkId: request.chunk.id,
    box: box,
    maskRef: _stringValue(raw, 'maskRef'),
    confidence: (raw['confidence'] as num?)?.toDouble() ?? 0,
    rationale: _stringValue(raw, 'rationale') ?? 'VLM-native grounded region.',
    provenance: provenance,
    status: GroundingStatus.grounded,
    metadata: {
      'sourceKind': sourceKind.jsonValue,
    },
  );
}

NormalizedGroundingBox _readBox(
  Map<String, dynamic> raw,
  int? frameWidth,
  int? frameHeight,
) {
  final box = raw['box'] ?? raw['bbox'];
  if (box is Map) {
    return NormalizedGroundingBox.clamped(
      x: (box['x'] as num).toDouble(),
      y: (box['y'] as num).toDouble(),
      width: (box['width'] as num).toDouble(),
      height: (box['height'] as num).toDouble(),
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
  }
  if (box is List && box.length == 4) {
    return NormalizedGroundingBox.fromCorners(
      left: (box[0] as num).toDouble(),
      top: (box[1] as num).toDouble(),
      right: (box[2] as num).toDouble(),
      bottom: (box[3] as num).toDouble(),
      frameWidth: frameWidth,
      frameHeight: frameHeight,
    );
  }
  throw const GroundingProviderException('grounded region missing box');
}

Future<GroundingResult> _persistResult({
  required GroundingRequest request,
  required String providerId,
  required String providerVersion,
  required GroundingStatus status,
  required List<GroundedRegion> regions,
  List<String> warnings = const <String>[],
}) async {
  final records = <EvidenceRecord>[];
  for (final region in regions) {
    final frame = request.frameById(region.frameId);
    if (frame == null || !region.hasBoundary) {
      continue;
    }
    records.add(region.toEvidenceRecord(timestamp: frame.timestamp));
  }
  await request.evidenceStore?.appendAll(records);
  return GroundingResult(
    providerId: providerId,
    providerVersion: providerVersion,
    status: status,
    regions: regions,
    evidenceRecords: records,
    warnings: warnings,
  );
}

EvidenceProvenance _provenance({
  required GroundingRequest request,
  required String providerId,
  required String providerVersion,
  required List<String> inputIds,
}) =>
    EvidenceProvenance(
      providerId: providerId,
      providerVersion: providerVersion,
      modelBundleId: request.modelBundle.modelId,
      modelChecksum: request.modelBundle.sha256,
      runtime: request.runtimeProfile.id.jsonValue,
      inputIds: inputIds,
      startTime: request.chunk.startTime,
      endTime: request.chunk.endTime,
    );

Future<void> _checkCancellation(GroundingRequest request) async {
  final token = request.cancellationToken;
  token?.throwIfCancelled();
  await token?.checkState();
}

String? _stringValue(Map<String, dynamic> raw, String key) {
  final value = raw[key];
  return value is String && value.trim().isNotEmpty ? value : null;
}

String _normalizeCategoryId(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp('^_|_\$'), '');
  return normalized.isEmpty ? 'other' : normalized;
}
