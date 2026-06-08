import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

/// Debug-only local diagnostics bundle for detection troubleshooting.
///
/// The exporter never includes unrelated files and recursively redacts common
/// secret-bearing keys before JSON serialization.
class DebugDetectionBundleExporter {
  const DebugDetectionBundleExporter({this.debugBuildEnabled = kDebugMode});

  /// Test seam for simulating release builds. Defaults to [kDebugMode].
  final bool debugBuildEnabled;

  DebugDetectionBundle buildBundle({
    required String mediaId,
    AnalysisRunManifest? analysisManifest,
    Iterable<ModelBundleManifest> modelManifests =
        const <ModelBundleManifest>[],
    Iterable<VideoChunk> chunks = const <VideoChunk>[],
    Iterable<EvidenceRecord> evidenceRecords = const <EvidenceRecord>[],
    Iterable<Detection> detections = const <Detection>[],
    Map<String, dynamic>? parsedVlmJson,
    Map<String, dynamic>? timingMetrics,
    Iterable<String> redactedPrompts = const <String>[],
    LocalRuntimeStatus? runtimeStatus,
  }) {
    _assertDebugBuild();

    return DebugDetectionBundle(
      mediaId: mediaId,
      createdAt: DateTime.now().toUtc(),
      analysisManifest: _redactedMap(analysisManifest?.toJson()),
      modelManifests: modelManifests
          .map((manifest) => _redact(_modelManifestJson(manifest)))
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      chunkPlan: chunks
          .map((chunk) => _redact(chunk.toJson()))
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      evidenceRecords: evidenceRecords
          .map((record) => _redact(record.toJson()))
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      parsedVlmJson: _redactedMap(parsedVlmJson),
      timingMetrics: _redactedMap(timingMetrics),
      redactedPrompts:
          redactedPrompts.map(_redactPrompt).toList(growable: false),
      detections: detections
          .map((detection) => _redact(detection.toJson()))
          .whereType<Map<String, dynamic>>()
          .toList(growable: false),
      runtimeStatus: _redactedMap(runtimeStatus?.toJson()),
    );
  }

  Future<File> writeBundle({
    required Directory directory,
    required DebugDetectionBundle bundle,
  }) async {
    _assertDebugBuild();
    await directory.create(recursive: true);
    final timestamp =
        bundle.createdAt.toIso8601String().replaceAll(RegExp('[:.]'), '-');
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      'kidslens_debug_bundle_$timestamp.json',
    );
    return file.writeAsString(bundle.toPrettyJson());
  }

  void _assertDebugBuild() {
    if (!kDebugMode || !debugBuildEnabled) {
      throw StateError('debug detection bundle export is debug-build only');
    }
  }
}

class DebugDetectionBundle {
  const DebugDetectionBundle({
    required this.mediaId,
    required this.createdAt,
    this.analysisManifest,
    this.modelManifests = const <Map<String, dynamic>>[],
    this.chunkPlan = const <Map<String, dynamic>>[],
    this.evidenceRecords = const <Map<String, dynamic>>[],
    this.parsedVlmJson,
    this.timingMetrics,
    this.redactedPrompts = const <String>[],
    this.detections = const <Map<String, dynamic>>[],
    this.runtimeStatus,
  });

  final String mediaId;
  final DateTime createdAt;
  final Map<String, dynamic>? analysisManifest;
  final List<Map<String, dynamic>> modelManifests;
  final List<Map<String, dynamic>> chunkPlan;
  final List<Map<String, dynamic>> evidenceRecords;
  final Map<String, dynamic>? parsedVlmJson;
  final Map<String, dynamic>? timingMetrics;
  final List<String> redactedPrompts;
  final List<Map<String, dynamic>> detections;
  final Map<String, dynamic>? runtimeStatus;

  Map<String, dynamic> toJson() => {
        'mediaId': mediaId,
        'createdAt': createdAt.toUtc().toIso8601String(),
        if (analysisManifest != null) 'analysisManifest': analysisManifest,
        'modelManifests': modelManifests,
        'chunkPlan': chunkPlan,
        'evidenceRecords': evidenceRecords,
        if (parsedVlmJson != null) 'parsedVlmJson': parsedVlmJson,
        if (timingMetrics != null) 'timingMetrics': timingMetrics,
        'redactedPrompts': redactedPrompts,
        'detections': detections,
        if (runtimeStatus != null) 'runtimeStatus': runtimeStatus,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

Object? _redact(Object? value) {
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (_isSecretKey(key) || _isBulkyMediaKey(key)) {
        result[key] = '<redacted>';
      } else if (_isPromptKey(key) && entry.value is String) {
        result[key] = _redactPrompt(entry.value as String);
      } else if (_isUrlKey(key) && entry.value is String) {
        result[key] = _redactUrl(entry.value as String);
      } else {
        result[key] = _redact(entry.value);
      }
    }
    return result;
  }

  if (value is Iterable) {
    return value.map(_redact).toList(growable: false);
  }

  if (value is String && _looksLikeSecret(value)) {
    return '<redacted>';
  }

  return value;
}

String _redactPrompt(String prompt) {
  var redacted = prompt.replaceAll(
    RegExp(
      '(api[_-]?key|token|password|secret|authorization)'
      r'\s*[:=]\s*(?:bearer\s+)?\S+',
      caseSensitive: false,
    ),
    r'$1=<redacted>',
  );
  if (redacted.length > 1200) {
    redacted = '${redacted.substring(0, 1200)}...<truncated>';
  }
  return redacted;
}

String _redactUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasQuery) return value;
  return uri.replace(query: '<redacted>').toString();
}

bool _isSecretKey(String key) => RegExp(
      '(api[_-]?key|token|password|secret|authorization|cookie|credential)',
      caseSensitive: false,
    ).hasMatch(key);

bool _isBulkyMediaKey(String key) => RegExp(
      '(base64|imageBytes|frameBytes|rawImage|maskPng|audioBytes)',
      caseSensitive: false,
    ).hasMatch(key);

bool _isPromptKey(String key) =>
    RegExp('prompt', caseSensitive: false).hasMatch(key);

bool _isUrlKey(String key) =>
    RegExp('(url|endpoint|uri)', caseSensitive: false).hasMatch(key);

bool _looksLikeSecret(String value) =>
    RegExp(
      'bearer\\s+[a-z0-9._-]{8,}',
      caseSensitive: false,
    ).hasMatch(value) ||
    RegExp(
      '(hf_|sk-)[a-z0-9_-]{8,}',
      caseSensitive: false,
    ).hasMatch(value);

Map<String, dynamic>? _redactedMap(Object? value) {
  final redacted = _redact(value);
  if (redacted is! Map) return null;
  return Map<String, dynamic>.from(redacted);
}

Map<String, dynamic> _modelManifestJson(ModelBundleManifest manifest) => {
      'modelId': manifest.modelId,
      'displayName': manifest.displayName,
      'vendor': manifest.vendor,
      'officialSourceRepo': manifest.officialSourceRepo,
      'officialRevision': manifest.officialRevision,
      'license': manifest.license.name,
      'commercialUse': manifest.commercialUse.name,
      'acceptedTermsRequired': manifest.acceptedTermsRequired,
      'artifactType': manifest.artifactType.name,
      'artifactUri': manifest.artifactUri,
      'sha256': manifest.sha256,
      'conversionRecipeId': manifest.conversionRecipeId,
      'runtime': manifest.runtime.name,
      'minVramGb': manifest.minVramGb,
      'recommendedVramGb': manifest.recommendedVramGb,
      'targetGpuClass': manifest.targetGpuClass,
      'maxValidatedVramGb': manifest.maxValidatedVramGb,
      'quantization': manifest.quantization.name,
      'fitsRtx5070Validated': manifest.fitsRtx5070Validated,
      'supportsVideoInput': manifest.supportsVideoInput,
      'supportsImageInput': manifest.supportsImageInput,
      'supportsBoundingBoxes': manifest.supportsBoundingBoxes,
      'supportsMasks': manifest.supportsMasks,
      'supportsPointLocalization': manifest.supportsPointLocalization,
      'maxFramesPerChunk': manifest.maxFramesPerChunk,
      'maxContextTokens': manifest.maxContextTokens,
      'recommendedChunkSeconds': manifest.recommendedChunkSeconds,
      'knownFailureModes': manifest.knownFailureModes,
      'roles': manifest.roles.map((role) => role.name).toList(growable: false),
      'approvalStatus': manifest.approvalStatus.name,
      'reviewNotes': manifest.reviewNotes,
      'leaderboardSourcesReviewed': manifest.leaderboardSourcesReviewed,
    };
