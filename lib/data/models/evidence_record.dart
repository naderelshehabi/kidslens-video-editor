import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:kidslens_video_editor/data/models/converters.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/profanity_match.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';

enum EvidenceType {
  vlmCaption('vlm_caption'),
  vlmPolicyJson('vlm_policy_json'),
  groundedRegion('grounded_region'),
  legacyNsfwScore('legacy_nsfw_score'),
  legacyNudenetRegion('legacy_nudenet_region'),
  modestyParserSignal('modesty_parser_signal'),
  transcriptSpan('transcript_span'),
  profanityMatch('profanity_match'),
  embeddingRecord('embedding_record');

  const EvidenceType(this.jsonValue);

  final String jsonValue;

  static EvidenceType fromJson(String value) => EvidenceType.values.firstWhere(
        (type) => type.jsonValue == value,
        orElse: () => throw ArgumentError('Unknown evidence type: $value'),
      );
}

class EvidenceProvenance {
  const EvidenceProvenance({
    required this.providerId,
    required this.providerVersion,
    required this.runtime,
    required this.inputIds,
    required this.startTime,
    required this.endTime,
    this.modelBundleId,
    this.modelChecksum,
    this.gpuProvider,
    this.schemaVersion = 1,
  });

  factory EvidenceProvenance.fromJson(Map<String, dynamic> json) =>
      EvidenceProvenance(
        providerId: json['providerId'] as String,
        providerVersion: json['providerVersion'] as String,
        modelBundleId: json['modelBundleId'] as String?,
        modelChecksum: json['modelChecksum'] as String?,
        runtime: json['runtime'] as String,
        gpuProvider: json['gpuProvider'] as String?,
        inputIds: (json['inputIds'] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => value as String)
            .toList(growable: false),
        startTime: const DurationConverter().fromJson(
          json['startTimeMs'] as int? ?? 0,
        ),
        endTime: const DurationConverter().fromJson(
          json['endTimeMs'] as int? ?? 0,
        ),
        schemaVersion: json['schemaVersion'] as int? ?? 1,
      );

  final String providerId;
  final String providerVersion;
  final String? modelBundleId;
  final String? modelChecksum;
  final String runtime;
  final String? gpuProvider;
  final List<String> inputIds;
  final Duration startTime;
  final Duration endTime;
  final int schemaVersion;

  Map<String, dynamic> toJson() => {
        'providerId': providerId,
        'providerVersion': providerVersion,
        if (modelBundleId != null) 'modelBundleId': modelBundleId,
        if (modelChecksum != null) 'modelChecksum': modelChecksum,
        'runtime': runtime,
        if (gpuProvider != null) 'gpuProvider': gpuProvider,
        'inputIds': inputIds,
        'startTimeMs': const DurationConverter().toJson(startTime),
        'endTimeMs': const DurationConverter().toJson(endTime),
        'schemaVersion': schemaVersion,
      };
}

class EvidenceRecord {
  EvidenceRecord({
    required this.id,
    required this.mediaId,
    required this.type,
    required this.provenance,
    required Map<String, dynamic> payload,
    DateTime? createdAt,
    this.chunkId,
    this.frameRefId,
  })  : payload = Map.unmodifiable(_normalizeJsonMap(payload)),
        createdAt = createdAt ?? DateTime.now().toUtc();

  factory EvidenceRecord.fromJson(Map<String, dynamic> json) => EvidenceRecord(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        type: EvidenceType.fromJson(json['type'] as String),
        provenance: EvidenceProvenance.fromJson(
          json['provenance'] as Map<String, dynamic>,
        ),
        payload: _normalizeJsonMap(
          Map<String, dynamic>.from(
            json['payload'] as Map<dynamic, dynamic>? ?? const {},
          ),
        ),
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
        chunkId: json['chunkId'] as String?,
        frameRefId: json['frameRefId'] as String?,
      );

  factory EvidenceRecord.legacyNsfwScore({
    required String mediaId,
    required FrameAnalysisResult frame,
    required EvidenceProvenance provenance,
    String? chunkId,
    String? frameRefId,
  }) =>
      EvidenceRecord(
        id: deterministicId(
          mediaId: mediaId,
          type: EvidenceType.legacyNsfwScore,
          provenance: provenance,
          payload: {
            'frameNumber': frame.frameNumber,
            'timestampMs': frame.timestamp.inMilliseconds,
            'isSceneChange': frame.isSceneChange,
            'nsfw': frame.nsfw.toJson(),
          },
        ),
        mediaId: mediaId,
        type: EvidenceType.legacyNsfwScore,
        provenance: provenance,
        payload: {
          'frameNumber': frame.frameNumber,
          'timestampMs': frame.timestamp.inMilliseconds,
          'isSceneChange': frame.isSceneChange,
          'nsfw': frame.nsfw.toJson(),
        },
        chunkId: chunkId,
        frameRefId: frameRefId,
      );

  factory EvidenceRecord.legacyNudenetRegion({
    required String mediaId,
    required Duration timestamp,
    required int frameNumber,
    required DetectedRegion region,
    required EvidenceProvenance provenance,
    String? chunkId,
    String? frameRefId,
  }) =>
      _regionEvidence(
        mediaId: mediaId,
        type: EvidenceType.legacyNudenetRegion,
        timestamp: timestamp,
        frameNumber: frameNumber,
        region: region,
        provenance: provenance,
        chunkId: chunkId,
        frameRefId: frameRefId,
      );

  factory EvidenceRecord.modestyParserSignal({
    required String mediaId,
    required Duration timestamp,
    required int frameNumber,
    required DetectedRegion region,
    required EvidenceProvenance provenance,
    String? categoryId,
    String? chunkId,
    String? frameRefId,
  }) {
    final payload = {
      'frameNumber': frameNumber,
      'timestampMs': timestamp.inMilliseconds,
      if (categoryId != null) 'categoryId': categoryId,
      'region': region.toJson(),
    };
    return EvidenceRecord(
      id: deterministicId(
        mediaId: mediaId,
        type: EvidenceType.modestyParserSignal,
        provenance: provenance,
        payload: payload,
      ),
      mediaId: mediaId,
      type: EvidenceType.modestyParserSignal,
      provenance: provenance,
      payload: payload,
      chunkId: chunkId,
      frameRefId: frameRefId,
    );
  }

  factory EvidenceRecord.transcriptSpan({
    required String mediaId,
    required TranscriptSegment segment,
    required EvidenceProvenance provenance,
    String? chunkId,
  }) {
    final payload = {'segment': segment.toJson()};
    return EvidenceRecord(
      id: deterministicId(
        mediaId: mediaId,
        type: EvidenceType.transcriptSpan,
        provenance: provenance,
        payload: payload,
      ),
      mediaId: mediaId,
      type: EvidenceType.transcriptSpan,
      provenance: provenance,
      payload: payload,
      chunkId: chunkId,
    );
  }

  factory EvidenceRecord.profanityMatch({
    required String mediaId,
    required ProfanityMatch match,
    required EvidenceProvenance provenance,
    String? chunkId,
  }) {
    final payload = {'match': match.toJson()};
    return EvidenceRecord(
      id: deterministicId(
        mediaId: mediaId,
        type: EvidenceType.profanityMatch,
        provenance: provenance,
        payload: payload,
      ),
      mediaId: mediaId,
      type: EvidenceType.profanityMatch,
      provenance: provenance,
      payload: payload,
      chunkId: chunkId,
    );
  }

  static String deterministicId({
    required String mediaId,
    required EvidenceType type,
    required EvidenceProvenance provenance,
    required Map<String, dynamic> payload,
  }) {
    final canonical = jsonEncode({
      'mediaId': mediaId,
      'type': type.jsonValue,
      'providerId': provenance.providerId,
      'providerVersion': provenance.providerVersion,
      'modelBundleId': provenance.modelBundleId,
      'modelChecksum': provenance.modelChecksum,
      'inputIds': provenance.inputIds,
      'startTimeMs': provenance.startTime.inMilliseconds,
      'endTimeMs': provenance.endTime.inMilliseconds,
      'payload': _normalizeJsonMap(payload),
    });
    return 'ev_${sha256.convert(utf8.encode(canonical))}';
  }

  final String id;
  final String mediaId;
  final EvidenceType type;
  final EvidenceProvenance provenance;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final String? chunkId;
  final String? frameRefId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'type': type.jsonValue,
        'provenance': provenance.toJson(),
        'payload': payload,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (chunkId != null) 'chunkId': chunkId,
        if (frameRefId != null) 'frameRefId': frameRefId,
      };
}

EvidenceRecord _regionEvidence({
  required String mediaId,
  required EvidenceType type,
  required Duration timestamp,
  required int frameNumber,
  required DetectedRegion region,
  required EvidenceProvenance provenance,
  String? chunkId,
  String? frameRefId,
}) {
  final payload = {
    'frameNumber': frameNumber,
    'timestampMs': timestamp.inMilliseconds,
    'region': region.toJson(),
  };
  return EvidenceRecord(
    id: EvidenceRecord.deterministicId(
      mediaId: mediaId,
      type: type,
      provenance: provenance,
      payload: payload,
    ),
    mediaId: mediaId,
    type: type,
    provenance: provenance,
    payload: payload,
    chunkId: chunkId,
    frameRefId: frameRefId,
  );
}

Map<String, dynamic> _normalizeJsonMap(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
