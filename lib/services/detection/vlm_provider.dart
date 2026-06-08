import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/services/detection/evidence_store.dart';
import 'package:kidslens_video_editor/services/detection/family_safety_prompt_templates.dart';
import 'package:kidslens_video_editor/services/detection/local_runtime_manager.dart';

enum VlmInputMode {
  imageFrames,
  videoSegment,
}

class VlmProviderException implements Exception {
  const VlmProviderException(this.message);

  final String message;

  @override
  String toString() => 'VlmProviderException: $message';
}

class VlmSchemaException extends VlmProviderException {
  const VlmSchemaException(super.message);
}

class VideoSegmentRequest {
  const VideoSegmentRequest({
    required this.mediaId,
    required this.chunk,
    required this.frames,
    required this.modelBundle,
    required this.runtimeProfile,
    required this.prompt,
    this.inputMode = VlmInputMode.imageFrames,
    this.maxOutputTokens = 2048,
    this.frameWidth,
    this.frameHeight,
    this.timeout = const Duration(seconds: 60),
    this.cancellationToken,
    this.evidenceStore,
  });

  final String mediaId;
  final VideoChunk chunk;
  final List<SampledFrameRef> frames;
  final ModelBundleManifest modelBundle;
  final LocalRuntimeProfile runtimeProfile;
  final String prompt;
  final VlmInputMode inputMode;
  final int maxOutputTokens;
  final int? frameWidth;
  final int? frameHeight;
  final Duration timeout;
  final CancellationToken? cancellationToken;
  final EvidenceStore? evidenceStore;

  List<String> validateAgainstManifest() {
    final issues = <String>[];
    if (frames.length > modelBundle.maxFramesPerChunk) {
      issues.add(
        'request has ${frames.length} frames but model allows ${modelBundle.maxFramesPerChunk}',
      );
    }
    if (maxOutputTokens > modelBundle.maxContextTokens) {
      issues.add(
        'request max output tokens exceed model context limit',
      );
    }
    if (inputMode == VlmInputMode.imageFrames &&
        !modelBundle.supportsImageInput) {
      issues.add('model does not support image-frame input');
    }
    if (inputMode == VlmInputMode.videoSegment &&
        !modelBundle.supportsVideoInput) {
      issues.add('model does not support video-segment input');
    }
    if ((frameWidth ?? 1) < 1 || (frameHeight ?? 1) < 1) {
      issues.add('frame resolution must be positive when provided');
    }
    if (prompt.trim().isEmpty) {
      issues.add('prompt is required');
    }
    if (timeout <= Duration.zero) {
      issues.add('timeout must be positive');
    }
    return issues.toSet().toList(growable: false);
  }

  Map<String, dynamic> toProviderJson() => {
        'mediaId': mediaId,
        'chunk': chunk.toJson(),
        'frames': frames.map((frame) => frame.toJson()).toList(),
        'inputMode': inputMode.name,
        'prompt': prompt,
        'maxOutputTokens': maxOutputTokens,
        if (frameWidth != null) 'frameWidth': frameWidth,
        if (frameHeight != null) 'frameHeight': frameHeight,
      };
}

class VlmSegmentResponse {
  const VlmSegmentResponse({
    required this.providerId,
    required this.providerVersion,
    required this.rawResponse,
    required this.parsedJson,
    required this.evidenceRecords,
    this.schemaRepairWarnings = const <String>[],
  });

  final String providerId;
  final String providerVersion;
  final String rawResponse;
  final Map<String, dynamic> parsedJson;
  final List<EvidenceRecord> evidenceRecords;
  final List<String> schemaRepairWarnings;

  String get caption => parsedJson['caption'] as String;

  List<dynamic> get findings => parsedJson['findings'] as List<dynamic>;

  bool get hasFindings => findings.isNotEmpty;
}

abstract interface class VlmProvider {
  String get providerId;

  String get providerVersion;

  LocalRuntimeProfile get runtimeProfile;

  Future<VlmSegmentResponse> analyzeSegment(VideoSegmentRequest request);
}

class VlmJsonParser {
  const VlmJsonParser();

  VlmParsedJson parse(String rawResponse) {
    final repair = _repair(rawResponse);
    final decoded = jsonDecode(repair.jsonText);
    if (decoded is! Map<String, dynamic>) {
      throw const VlmSchemaException('VLM response must be a JSON object');
    }
    _validate(decoded);
    return VlmParsedJson(
      json: decoded,
      repairWarnings: repair.warnings,
    );
  }

  VlmJsonRepairResult _repair(String rawResponse) {
    var text = rawResponse.trim();
    final warnings = <String>[];
    if (text.startsWith('```')) {
      final lines = text.split('\n');
      if (lines.length >= 3 && lines.last.trim() == '```') {
        text = lines.sublist(1, lines.length - 1).join('\n').trim();
        if (text.startsWith('json')) {
          text = text.substring(4).trim();
        }
        warnings.add('removed markdown code fence');
      }
    }

    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    if ((firstBrace > 0 || lastBrace < text.length - 1) &&
        firstBrace >= 0 &&
        lastBrace > firstBrace) {
      text = text.substring(firstBrace, lastBrace + 1);
      warnings.add('extracted JSON object from surrounding text');
    }

    final trailingCommaPattern = RegExp(r',\s*([}\]])');
    if (trailingCommaPattern.hasMatch(text)) {
      text = text.replaceAllMapped(
        trailingCommaPattern,
        (match) => match.group(1)!,
      );
      warnings.add('removed trailing commas');
    }

    return VlmJsonRepairResult(jsonText: text, warnings: warnings);
  }

  void _validate(Map<String, dynamic> json) {
    final issues = FamilySafetyVlmOutputSchema.validate(json);
    if (issues.isNotEmpty) {
      throw VlmSchemaException(issues.first);
    }
  }
}

class VlmParsedJson {
  const VlmParsedJson({
    required this.json,
    required this.repairWarnings,
  });

  final Map<String, dynamic> json;
  final List<String> repairWarnings;
}

class VlmJsonRepairResult {
  const VlmJsonRepairResult({
    required this.jsonText,
    required this.warnings,
  });

  final String jsonText;
  final List<String> warnings;
}

class MockVlmProvider implements VlmProvider {
  const MockVlmProvider({
    this.rawResponse,
    this.delay = Duration.zero,
    this.parser = const VlmJsonParser(),
  });

  final String? rawResponse;
  final Duration delay;
  final VlmJsonParser parser;

  @override
  String get providerId => 'mock_vlm';

  @override
  String get providerVersion => '1';

  @override
  LocalRuntimeProfile get runtimeProfile =>
      LocalRuntimeProfile.byId(LocalRuntimeId.cpuLightweight);

  @override
  Future<VlmSegmentResponse> analyzeSegment(VideoSegmentRequest request) async {
    await _validateAndCheck(request);
    if (delay > Duration.zero) {
      await _withCancellation<void>(
        Future<void>.delayed(delay),
        request.cancellationToken,
        request.timeout,
      );
    }
    final raw = rawResponse ?? _defaultRawResponse(request);
    final parsed = parser.parse(raw);
    return _buildResponse(
      request: request,
      providerId: providerId,
      providerVersion: providerVersion,
      runtimeProfile: runtimeProfile,
      rawResponse: raw,
      parsed: parsed,
    );
  }

  String _defaultRawResponse(VideoSegmentRequest request) => jsonEncode({
        'schemaVersion': FamilySafetyPromptTemplates.schemaVersion,
        'caption': 'Chunk ${request.chunk.index} contains routine content.',
        'findings': <Map<String, dynamic>>[],
        'groundedRegions': <Map<String, dynamic>>[],
        'searchTerms': <String>[],
        'uncertainty': <String>[],
      });
}

abstract class LocalHttpVlmProvider implements VlmProvider {
  LocalHttpVlmProvider({
    required this.endpoint,
    required this.runtimeProfile,
    required this.providerId,
    required this.providerVersion,
    http.Client? client,
    this.parser = const VlmJsonParser(),
  }) : client = client ?? http.Client() {
    final issues = const LocalRuntimeEndpointPolicy().validate(
      LocalRuntimeConfig(endpointUri: endpoint.toString()),
    );
    if (issues.isNotEmpty) {
      throw VlmProviderException(issues.join('; '));
    }
  }

  final Uri endpoint;
  final http.Client client;
  final VlmJsonParser parser;

  @override
  final LocalRuntimeProfile runtimeProfile;

  @override
  final String providerId;

  @override
  final String providerVersion;

  @override
  Future<VlmSegmentResponse> analyzeSegment(VideoSegmentRequest request) async {
    await _validateAndCheck(request);
    final response = await _withCancellation<http.Response>(
      client.post(
        endpoint,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(request.toProviderJson()),
      ),
      request.cancellationToken,
      request.timeout,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VlmProviderException(
        'local VLM provider returned HTTP ${response.statusCode}',
      );
    }
    final parsed = parser.parse(response.body);
    return _buildResponse(
      request: request,
      providerId: providerId,
      providerVersion: providerVersion,
      runtimeProfile: runtimeProfile,
      rawResponse: response.body,
      parsed: parsed,
    );
  }
}

class TransformersHelperVlmProvider extends LocalHttpVlmProvider {
  TransformersHelperVlmProvider({
    required super.endpoint,
    super.client,
  }) : super(
          runtimeProfile:
              LocalRuntimeProfile.byId(LocalRuntimeId.cudaTransformersHelper),
          providerId: 'local_transformers_helper',
          providerVersion: '1',
        );
}

class VllmVlmProvider extends LocalHttpVlmProvider {
  VllmVlmProvider({
    required super.endpoint,
    super.client,
  }) : super(
          runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cudaVllm),
          providerId: 'local_vllm',
          providerVersion: '1',
        );
}

class NvidiaLocalVlmProvider extends LocalHttpVlmProvider {
  NvidiaLocalVlmProvider({
    required super.endpoint,
    super.client,
  }) : super(
          runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cudaTensorRt),
          providerId: 'local_nvidia_runtime',
          providerVersion: '1',
        );
}

Future<void> _validateAndCheck(VideoSegmentRequest request) async {
  final token = request.cancellationToken;
  token?.throwIfCancelled();
  final issues = request.validateAgainstManifest();
  if (issues.isNotEmpty) {
    throw VlmProviderException(issues.join('; '));
  }
  await token?.checkState();
}

Future<T> _withCancellation<T>(
  Future<T> future,
  CancellationToken? token,
  Duration timeout,
) async {
  token?.throwIfCancelled();
  final futures = <Future<T>>[
    future.timeout(timeout),
    if (token != null)
      token.cancelled.then<T>(
        (_) => throw CancelledException(),
      ),
  ];
  return Future.any(futures);
}

Future<VlmSegmentResponse> _buildResponse({
  required VideoSegmentRequest request,
  required String providerId,
  required String providerVersion,
  required LocalRuntimeProfile runtimeProfile,
  required String rawResponse,
  required VlmParsedJson parsed,
}) async {
  final provenance = _provenance(
    request: request,
    providerId: providerId,
    providerVersion: providerVersion,
    runtimeProfile: runtimeProfile,
  );
  final rawPayload = {
    'kind': 'raw_response',
    'rawResponse': rawResponse,
  };
  final parsedPayload = {
    'kind': 'parsed_response',
    'caption': parsed.json['caption'],
    'findings': parsed.json['findings'],
    'uncertainty': parsed.json['uncertainty'] ?? const <dynamic>[],
    'schemaRepairWarnings': parsed.repairWarnings,
  };
  final rawRecord = EvidenceRecord(
    id: EvidenceRecord.deterministicId(
      mediaId: request.mediaId,
      type: EvidenceType.vlmPolicyJson,
      provenance: provenance,
      payload: rawPayload,
    ),
    mediaId: request.mediaId,
    type: EvidenceType.vlmPolicyJson,
    provenance: provenance,
    payload: rawPayload,
    chunkId: request.chunk.id,
  );
  final parsedRecord = EvidenceRecord(
    id: EvidenceRecord.deterministicId(
      mediaId: request.mediaId,
      type: EvidenceType.vlmCaption,
      provenance: provenance,
      payload: parsedPayload,
    ),
    mediaId: request.mediaId,
    type: EvidenceType.vlmCaption,
    provenance: provenance,
    payload: parsedPayload,
    chunkId: request.chunk.id,
  );
  final records = [rawRecord, parsedRecord];
  await request.evidenceStore?.appendAll(records);

  return VlmSegmentResponse(
    providerId: providerId,
    providerVersion: providerVersion,
    rawResponse: rawResponse,
    parsedJson: parsed.json,
    schemaRepairWarnings: parsed.repairWarnings,
    evidenceRecords: records,
  );
}

EvidenceProvenance _provenance({
  required VideoSegmentRequest request,
  required String providerId,
  required String providerVersion,
  required LocalRuntimeProfile runtimeProfile,
}) =>
    EvidenceProvenance(
      providerId: providerId,
      providerVersion: providerVersion,
      modelBundleId: request.modelBundle.modelId,
      modelChecksum: request.modelBundle.sha256,
      runtime: runtimeProfile.id.jsonValue,
      inputIds: [
        request.chunk.id,
        ...request.frames.map((frame) => frame.id),
      ],
      startTime: request.chunk.startTime,
      endTime: request.chunk.endTime,
    );
