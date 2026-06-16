import 'dart:convert';

import 'package:kidslens_video_editor/data/models/models.dart';

enum EvaluationClipKind {
  safeControl,
  categoryPositive,
  ambiguousBoundary,
  lowLightMotionBlur,
  shortUnsafeFlash,
  longTemporalContext,
  immodestClothing,
}

enum EvaluationProfileId {
  legacyOnly('legacy_only', 'Legacy only'),
  vlmOnly('vlm_only', 'VLM only'),
  vlmPlusLegacyEvidence('vlm_plus_legacy_evidence', 'VLM + legacy evidence'),
  vlmPlusGrounding('vlm_plus_grounding', 'VLM + grounding');

  const EvaluationProfileId(this.id, this.displayName);

  final String id;
  final String displayName;

  static EvaluationProfileId? tryParse(String value) {
    for (final profile in EvaluationProfileId.values) {
      if (profile.id == value) return profile;
    }
    return null;
  }
}

class EvaluationDataset {
  const EvaluationDataset({
    required this.id,
    required this.version,
    required this.clips,
  });

  factory EvaluationDataset.fromJson(Map<String, dynamic> json) =>
      EvaluationDataset(
        id: _readString(json, 'id'),
        version: _readString(json, 'version'),
        clips: _readList(json, 'clips')
            .map(
              (value) => EvaluationClip.fromJson(
                _readMap(value, 'clips[]'),
              ),
            )
            .toList(growable: false),
      );

  final String id;
  final String version;
  final List<EvaluationClip> clips;

  List<String> validate() {
    final issues = <String>[];
    if (id.trim().isEmpty) issues.add('dataset id is required');
    if (version.trim().isEmpty) issues.add('dataset version is required');
    if (clips.isEmpty) issues.add('dataset must contain clips');

    final clipIds = <String>{};
    final kinds = <EvaluationClipKind>{};
    for (final clip in clips) {
      if (!clipIds.add(clip.id)) {
        issues.add('duplicate clip id: ${clip.id}');
      }
      kinds.addAll(clip.kinds);
      issues.addAll(clip.validate().map((issue) => '${clip.id}: $issue'));
    }

    const requiredKinds = <EvaluationClipKind>{
      EvaluationClipKind.safeControl,
      EvaluationClipKind.categoryPositive,
      EvaluationClipKind.ambiguousBoundary,
      EvaluationClipKind.lowLightMotionBlur,
      EvaluationClipKind.shortUnsafeFlash,
      EvaluationClipKind.longTemporalContext,
      EvaluationClipKind.immodestClothing,
    };
    for (final kind in requiredKinds) {
      if (!kinds.contains(kind)) {
        issues.add('dataset missing ${kind.name} clip coverage');
      }
    }

    final hasBoundingBoxGroundTruth = clips.any(
      (clip) => clip.groundTruth.any((truth) => truth.box != null),
    );
    if (!hasBoundingBoxGroundTruth) {
      issues.add('dataset must include bounding-box ground truth');
    }

    return issues.toSet().toList(growable: false);
  }

  bool get isValid => validate().isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'version': version,
        'clips': clips.map((clip) => clip.toJson()).toList(),
      };

  static const familySafetyV1Smoke = EvaluationDataset(
    id: 'kidslens_family_safety_v1_smoke',
    version: '2026-06-08',
    clips: [
      EvaluationClip(
        id: 'safe_kitchen_001',
        mediaId: 'safe_kitchen_001',
        relativePath: 'fixtures/evaluation/safe_kitchen_001.mp4',
        duration: Duration(seconds: 24),
        kinds: {EvaluationClipKind.safeControl},
        notes: 'Safe cooking scene with adults and children fully clothed.',
        groundTruth: [],
      ),
      EvaluationClip(
        id: 'nudity_beach_legs_001',
        mediaId: 'nudity_beach_legs_001',
        relativePath: 'fixtures/evaluation/nudity_beach_legs_001.mp4',
        duration: Duration(seconds: 18),
        kinds: {
          EvaluationClipKind.categoryPositive,
          EvaluationClipKind.immodestClothing,
        },
        notes: 'Female exposed legs; review-first immodest clothing example.',
        groundTruth: [
          EvaluationAnnotation(
            id: 'gt_legs_001',
            categoryId: 'female_legs_exposure',
            startTime: Duration(seconds: 4),
            endTime: Duration(seconds: 10),
            severity: 'medium',
            requiresReview: true,
            rationale: 'Female legs are exposed and should be reviewed.',
            box: EvaluationBox(x: 0.22, y: 0.48, width: 0.34, height: 0.42),
          ),
        ],
      ),
      EvaluationClip(
        id: 'explicit_nudity_scene_001',
        mediaId: 'explicit_nudity_scene_001',
        relativePath: 'fixtures/evaluation/explicit_nudity_scene_001.mp4',
        duration: Duration(seconds: 14),
        kinds: {EvaluationClipKind.categoryPositive},
        notes: 'Explicit nudity positive with region-level boundary.',
        groundTruth: [
          EvaluationAnnotation(
            id: 'gt_explicit_nudity_001',
            categoryId: 'explicit_nudity',
            startTime: Duration(seconds: 2),
            endTime: Duration(seconds: 7),
            severity: 'critical',
            rationale: 'Explicit nudity is visible in the scene.',
            box: EvaluationBox(x: 0.34, y: 0.24, width: 0.22, height: 0.36),
          ),
        ],
      ),
      EvaluationClip(
        id: 'violence_shadow_001',
        mediaId: 'violence_shadow_001',
        relativePath: 'fixtures/evaluation/violence_shadow_001.mp4',
        duration: Duration(seconds: 16),
        kinds: {
          EvaluationClipKind.categoryPositive,
          EvaluationClipKind.lowLightMotionBlur,
        },
        notes: 'Low-light fight with motion blur.',
        groundTruth: [
          EvaluationAnnotation(
            id: 'gt_violence_001',
            categoryId: 'violence',
            startTime: Duration(seconds: 3),
            endTime: Duration(seconds: 9),
            severity: 'high',
            rationale: 'Two people are fighting in a low-light scene.',
          ),
        ],
      ),
      EvaluationClip(
        id: 'blood_flash_001',
        mediaId: 'blood_flash_001',
        relativePath: 'fixtures/evaluation/blood_flash_001.mp4',
        duration: Duration(seconds: 12),
        kinds: {
          EvaluationClipKind.categoryPositive,
          EvaluationClipKind.shortUnsafeFlash,
        },
        notes: 'Very short blood flash for temporal recall.',
        groundTruth: [
          EvaluationAnnotation(
            id: 'gt_blood_001',
            categoryId: 'blood',
            startTime: Duration(milliseconds: 5200),
            endTime: Duration(milliseconds: 5900),
            severity: 'high',
            rationale: 'A brief visible blood flash appears.',
            box: EvaluationBox(x: 0.58, y: 0.38, width: 0.14, height: 0.12),
          ),
        ],
      ),
      EvaluationClip(
        id: 'weapon_context_001',
        mediaId: 'weapon_context_001',
        relativePath: 'fixtures/evaluation/weapon_context_001.mp4',
        duration: Duration(seconds: 75),
        kinds: {
          EvaluationClipKind.categoryPositive,
          EvaluationClipKind.longTemporalContext,
        },
        notes: 'Toy-like object later revealed as a weapon.',
        groundTruth: [
          EvaluationAnnotation(
            id: 'gt_weapon_001',
            categoryId: 'weapons',
            startTime: Duration(seconds: 42),
            endTime: Duration(seconds: 58),
            severity: 'high',
            rationale: 'A weapon is shown and handled after context resolves.',
            box: EvaluationBox(x: 0.62, y: 0.30, width: 0.18, height: 0.22),
          ),
        ],
      ),
      EvaluationClip(
        id: 'ambiguous_sports_contact_001',
        mediaId: 'ambiguous_sports_contact_001',
        relativePath: 'fixtures/evaluation/ambiguous_sports_contact_001.mp4',
        duration: Duration(seconds: 20),
        kinds: {
          EvaluationClipKind.safeControl,
          EvaluationClipKind.ambiguousBoundary,
        },
        notes: 'Sports contact that should not be labeled as violence.',
        groundTruth: [],
      ),
      EvaluationClip(
        id: 'gore_scene_001',
        mediaId: 'gore_scene_001',
        relativePath: 'fixtures/evaluation/gore_scene_001.mp4',
        duration: Duration(seconds: 22),
        kinds: {EvaluationClipKind.categoryPositive},
        notes: 'Gore-positive scene-level unsafe example.',
        groundTruth: [
          EvaluationAnnotation(
            id: 'gt_gore_001',
            categoryId: 'gore',
            startTime: Duration(seconds: 8),
            endTime: Duration(seconds: 14),
            severity: 'critical',
            rationale: 'Graphic gore is visible in the scene.',
          ),
        ],
      ),
    ],
  );
}

class EvaluationClip {
  const EvaluationClip({
    required this.id,
    required this.mediaId,
    required this.relativePath,
    required this.duration,
    required this.kinds,
    required this.notes,
    required this.groundTruth,
  });

  factory EvaluationClip.fromJson(Map<String, dynamic> json) => EvaluationClip(
        id: _readString(json, 'id'),
        mediaId: _readString(json, 'mediaId'),
        relativePath: _readString(json, 'relativePath'),
        duration: Duration(milliseconds: _readInt(json, 'durationMs')),
        kinds: _readList(json, 'kinds')
            .map((value) => _readClipKind('$value'))
            .toSet(),
        notes: _readString(json, 'notes'),
        groundTruth: _readList(json, 'groundTruth')
            .map(
              (value) => EvaluationAnnotation.fromJson(
                _readMap(value, 'groundTruth[]'),
              ),
            )
            .toList(growable: false),
      );

  final String id;
  final String mediaId;
  final String relativePath;
  final Duration duration;
  final Set<EvaluationClipKind> kinds;
  final String notes;
  final List<EvaluationAnnotation> groundTruth;

  bool get isSafeControl =>
      kinds.contains(EvaluationClipKind.safeControl) && groundTruth.isEmpty;

  List<String> validate() {
    final issues = <String>[];
    if (id.trim().isEmpty) issues.add('clip id is required');
    if (mediaId.trim().isEmpty) issues.add('media id is required');
    if (relativePath.trim().isEmpty) issues.add('relative path is required');
    if (duration <= Duration.zero) issues.add('duration must be positive');
    if (kinds.isEmpty) issues.add('at least one clip kind is required');
    if (notes.trim().isEmpty) issues.add('notes are required');

    for (final annotation in groundTruth) {
      issues.addAll(
        annotation
            .validate(duration)
            .map((issue) => '${annotation.id}: $issue'),
      );
    }
    return issues;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'relativePath': relativePath,
        'durationMs': duration.inMilliseconds,
        'kinds': kinds.map((kind) => kind.name).toList()..sort(),
        'notes': notes,
        'groundTruth': groundTruth.map((truth) => truth.toJson()).toList(),
      };
}

class EvaluationAnnotation {
  const EvaluationAnnotation({
    required this.id,
    required this.categoryId,
    required this.startTime,
    required this.endTime,
    required this.severity,
    required this.rationale,
    this.confidence = 1,
    this.requiresReview = false,
    this.box,
    this.maskId,
    this.maskIouHint,
    this.sourceProfileId,
    this.runtimeId,
    this.metadata = const <String, dynamic>{},
  });

  factory EvaluationAnnotation.fromDetection(
    Detection detection, {
    String? sourceProfileId,
    String? runtimeId,
  }) {
    final metadata = detection.metadata ?? const <String, dynamic>{};
    return EvaluationAnnotation(
      id: detection.id,
      categoryId: detection.policyCategoryId ??
          detection.visualContentCategoryId ??
          detection.type.name,
      startTime: detection.startTime,
      endTime: detection.endTime,
      severity: detection.policySeverityLabel?.toLowerCase() ?? 'unknown',
      confidence: detection.confidence,
      requiresReview: metadata['needsReview'] == true ||
          detection.userStatus == DetectionUserStatus.pending,
      rationale: detection.rationale ?? detection.description,
      box: _boxFromMetadata(metadata),
      sourceProfileId: sourceProfileId,
      runtimeId: runtimeId,
      metadata: metadata,
    );
  }

  factory EvaluationAnnotation.fromPolicyFinding(
    PolicyFinding finding, {
    EvaluationBox? box,
    String? sourceProfileId,
    String? runtimeId,
  }) =>
      EvaluationAnnotation(
        id: finding.id,
        categoryId: finding.categoryId,
        startTime: finding.startTime,
        endTime: finding.endTime,
        severity: finding.severity.name,
        confidence: finding.confidence,
        requiresReview: finding.needsReview,
        rationale: finding.rationale,
        box: box,
        sourceProfileId: sourceProfileId,
        runtimeId: runtimeId,
        metadata: finding.toJson(),
      );

  factory EvaluationAnnotation.fromJson(Map<String, dynamic> json) =>
      EvaluationAnnotation(
        id: _readString(json, 'id'),
        categoryId: _readString(json, 'categoryId'),
        startTime: Duration(milliseconds: _readInt(json, 'startTimeMs')),
        endTime: Duration(milliseconds: _readInt(json, 'endTimeMs')),
        severity: _readString(json, 'severity'),
        confidence: _readDouble(json, 'confidence', defaultValue: 1),
        requiresReview: _readBool(
          json,
          'requiresReview',
          defaultValue: false,
        ),
        rationale: _readString(json, 'rationale'),
        box: json['box'] == null
            ? null
            : EvaluationBox.fromJson(_readMap(json['box'], 'box')),
        maskId: json['maskId'] as String?,
        maskIouHint: json['maskIouHint'] == null
            ? null
            : _readDouble(json, 'maskIouHint'),
        sourceProfileId: json['sourceProfileId'] as String?,
        runtimeId: json['runtimeId'] as String?,
        metadata: json['metadata'] is Map
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : const <String, dynamic>{},
      );

  final String id;
  final String categoryId;
  final Duration startTime;
  final Duration endTime;
  final String severity;
  final double confidence;
  final bool requiresReview;
  final String rationale;
  final EvaluationBox? box;
  final String? maskId;
  final double? maskIouHint;
  final String? sourceProfileId;
  final String? runtimeId;
  final Map<String, dynamic> metadata;

  List<String> validate(Duration clipDuration) {
    final issues = <String>[];
    if (id.trim().isEmpty) issues.add('annotation id is required');
    if (categoryId.trim().isEmpty) issues.add('category id is required');
    if (startTime < Duration.zero) issues.add('start time cannot be negative');
    if (endTime <= startTime) issues.add('end time must be after start time');
    if (endTime > clipDuration) issues.add('end time exceeds clip duration');
    if (severity.trim().isEmpty) issues.add('severity is required');
    if (confidence < 0 || confidence > 1 || !confidence.isFinite) {
      issues.add('confidence must be between 0 and 1');
    }
    if (rationale.trim().isEmpty) issues.add('rationale is required');
    if (box != null) issues.addAll(box!.validate());
    if (maskIouHint != null &&
        (maskIouHint! < 0 || maskIouHint! > 1 || !maskIouHint!.isFinite)) {
      issues.add('mask IoU hint must be between 0 and 1');
    }
    return issues;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'startTimeMs': startTime.inMilliseconds,
        'endTimeMs': endTime.inMilliseconds,
        'severity': severity,
        'confidence': confidence,
        'requiresReview': requiresReview,
        'rationale': rationale,
        if (box != null) 'box': box!.toJson(),
        if (maskId != null) 'maskId': maskId,
        if (maskIouHint != null) 'maskIouHint': maskIouHint,
        if (sourceProfileId != null) 'sourceProfileId': sourceProfileId,
        if (runtimeId != null) 'runtimeId': runtimeId,
        if (metadata.isNotEmpty)
          'metadata': jsonDecode(jsonEncode(metadata)) as Map<String, dynamic>,
      };
}

class EvaluationBox {
  const EvaluationBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory EvaluationBox.fromJson(Map<String, dynamic> json) => EvaluationBox(
        x: _readDouble(json, 'x'),
        y: _readDouble(json, 'y'),
        width: _readDouble(json, 'width'),
        height: _readDouble(json, 'height'),
      );

  final double x;
  final double y;
  final double width;
  final double height;

  double get right => x + width;

  double get bottom => y + height;

  double get area => width <= 0 || height <= 0 ? 0 : width * height;

  List<String> validate() {
    final issues = <String>[];
    for (final entry
        in {'x': x, 'y': y, 'width': width, 'height': height}.entries) {
      if (!entry.value.isFinite) issues.add('${entry.key} must be finite');
    }
    if (x < 0 || y < 0 || x > 1 || y > 1) {
      issues.add('box origin must be normalized');
    }
    if (width <= 0 || height <= 0) {
      issues.add('box dimensions must be positive');
    }
    if (right > 1 || bottom > 1) {
      issues.add('box must remain within normalized frame');
    }
    return issues;
  }

  double iou(EvaluationBox other) {
    final left = x > other.x ? x : other.x;
    final top = y > other.y ? y : other.y;
    final intersectRight = right < other.right ? right : other.right;
    final intersectBottom = bottom < other.bottom ? bottom : other.bottom;
    final intersectWidth = intersectRight - left;
    final intersectHeight = intersectBottom - top;
    if (intersectWidth <= 0 || intersectHeight <= 0) return 0;
    final intersection = intersectWidth * intersectHeight;
    final union = area + other.area - intersection;
    return union <= 0 ? 0 : intersection / union;
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

class EvaluationProfilePredictions {
  const EvaluationProfilePredictions({
    required this.profileId,
    required this.displayName,
    required this.detectionsByClipId,
    this.runtimeId,
    this.chunkLatencyMs = const <int>[],
    this.memoryUsageMb = const <int>[],
    this.vramUsageMb = const <int>[],
  });

  factory EvaluationProfilePredictions.forBuiltInProfile({
    required EvaluationProfileId profile,
    required Map<String, List<EvaluationAnnotation>> detectionsByClipId,
    String? runtimeId,
    List<int> chunkLatencyMs = const <int>[],
    List<int> memoryUsageMb = const <int>[],
    List<int> vramUsageMb = const <int>[],
  }) =>
      EvaluationProfilePredictions(
        profileId: profile.id,
        displayName: profile.displayName,
        detectionsByClipId: detectionsByClipId,
        runtimeId: runtimeId,
        chunkLatencyMs: chunkLatencyMs,
        memoryUsageMb: memoryUsageMb,
        vramUsageMb: vramUsageMb,
      );

  factory EvaluationProfilePredictions.fromJson(Map<String, dynamic> json) {
    final detectionsJson =
        _readMap(json['detectionsByClipId'], 'detectionsByClipId');
    return EvaluationProfilePredictions(
      profileId: _readString(json, 'profileId'),
      displayName: json['displayName'] as String? ??
          EvaluationProfileId.tryParse(_readString(json, 'profileId'))
              ?.displayName ??
          _readString(json, 'profileId'),
      runtimeId: json['runtimeId'] as String?,
      detectionsByClipId: {
        for (final entry in detectionsJson.entries)
          entry.key: _readList(detectionsJson, entry.key)
              .map(
                (value) => EvaluationAnnotation.fromJson(
                  _readMap(value, '${entry.key}[]'),
                ),
              )
              .toList(growable: false),
      },
      chunkLatencyMs: _readOptionalIntList(json, 'chunkLatencyMs'),
      memoryUsageMb: _readOptionalIntList(json, 'memoryUsageMb'),
      vramUsageMb: _readOptionalIntList(json, 'vramUsageMb'),
    );
  }

  final String profileId;
  final String displayName;
  final Map<String, List<EvaluationAnnotation>> detectionsByClipId;
  final String? runtimeId;
  final List<int> chunkLatencyMs;
  final List<int> memoryUsageMb;
  final List<int> vramUsageMb;

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'displayName': displayName,
        if (runtimeId != null) 'runtimeId': runtimeId,
        'detectionsByClipId': {
          for (final entry in detectionsByClipId.entries)
            entry.key:
                entry.value.map((detection) => detection.toJson()).toList(),
        },
        'chunkLatencyMs': chunkLatencyMs,
        'memoryUsageMb': memoryUsageMb,
        'vramUsageMb': vramUsageMb,
      };

  static List<EvaluationProfilePredictions> requiredComparisonProfiles({
    required Map<EvaluationProfileId, Map<String, List<EvaluationAnnotation>>>
        detectionsByProfile,
    Map<String, Map<String, List<EvaluationAnnotation>>> detectionsByRuntime =
        const <String, Map<String, List<EvaluationAnnotation>>>{},
  }) =>
      <EvaluationProfilePredictions>[
        for (final profile in EvaluationProfileId.values)
          EvaluationProfilePredictions.forBuiltInProfile(
            profile: profile,
            detectionsByClipId: detectionsByProfile[profile] ??
                const <String, List<EvaluationAnnotation>>{},
          ),
        ...detectionsByRuntime.entries.map(
          (entry) => EvaluationProfilePredictions(
            profileId: 'runtime_${entry.key}',
            displayName: 'Runtime ${entry.key}',
            runtimeId: entry.key,
            detectionsByClipId: entry.value,
          ),
        ),
      ];
}

EvaluationBox? _boxFromMetadata(Map<String, dynamic> metadata) {
  final raw = metadata[Detection.boundingBoxKey];
  if (raw is! Map) return null;
  final x = raw['x'];
  final y = raw['y'];
  final width = raw['width'];
  final height = raw['height'];
  if (x is! num || y is! num || width is! num || height is! num) {
    return null;
  }
  return EvaluationBox(
    x: x.toDouble(),
    y: y.toDouble(),
    width: width.toDouble(),
    height: height.toDouble(),
  );
}

EvaluationClipKind _readClipKind(String value) {
  for (final kind in EvaluationClipKind.values) {
    if (kind.name == value) return kind;
  }
  throw FormatException('Unknown evaluation clip kind: $value');
}

Map<String, dynamic> _readMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('$field must be an object');
}

List<dynamic> _readList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is List) return value;
  throw FormatException('$field must be a list');
}

String _readString(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw FormatException('$field must be a string');
}

int _readInt(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is int) return value;
  if (value is num) return value.round();
  throw FormatException('$field must be an integer');
}

double _readDouble(
  Map<String, dynamic> json,
  String field, {
  double? defaultValue,
}) {
  final value = json[field];
  if (value == null && defaultValue != null) return defaultValue;
  if (value is num) return value.toDouble();
  throw FormatException('$field must be a number');
}

bool _readBool(
  Map<String, dynamic> json,
  String field, {
  required bool defaultValue,
}) {
  final value = json[field];
  if (value == null) return defaultValue;
  if (value is bool) return value;
  throw FormatException('$field must be a boolean');
}

List<int> _readOptionalIntList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return const <int>[];
  if (value is! List) throw FormatException('$field must be a list');
  return value.map((entry) {
    if (entry is int) return entry;
    if (entry is num) return entry.round();
    throw FormatException('$field entries must be integers');
  }).toList(growable: false);
}
