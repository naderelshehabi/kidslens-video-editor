import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_run_manifest.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/evidence_record.dart';
import 'package:kidslens_video_editor/data/models/local_runtime_profile.dart';
import 'package:kidslens_video_editor/data/models/video_chunk.dart';
import 'package:kidslens_video_editor/services/detection/debug_detection_bundle.dart';

void main() {
  group('DebugDetectionBundleExporter', () {
    test('blocks export when simulating release build', () {
      const exporter = DebugDetectionBundleExporter(debugBuildEnabled: false);

      expect(
        () => exporter.buildBundle(mediaId: 'media_1'),
        throwsA(isA<StateError>()),
      );
    });

    test('builds bundle with required local diagnostics and redaction', () {
      const exporter = DebugDetectionBundleExporter();

      final bundle = exporter.buildBundle(
        mediaId: 'media_1',
        analysisManifest: _manifest(),
        chunks: [_chunk()],
        evidenceRecords: [_evidence()],
        detections: [_detection()],
        parsedVlmJson: const {
          'caption': 'sample caption',
          'apiKey': 'sk-secret-value',
          'endpoint': 'http://127.0.0.1:8000/infer?token=secret',
          'rawImageBase64': 'abc123',
        },
        timingMetrics: const {'chunkLatencyMsP95': 456},
        redactedPrompts: const [
          'token=secret prompt about family-safety categories',
        ],
        runtimeStatus: _runtimeStatus(),
      );

      final json = bundle.toJson();
      expect(json['analysisManifest'], isA<Map<String, dynamic>>());
      expect(json['chunkPlan'], isA<List<dynamic>>());
      expect(json['evidenceRecords'], isA<List<dynamic>>());
      expect(json['detections'], isA<List<dynamic>>());
      expect(json['parsedVlmJson'], isA<Map<String, dynamic>>());
      expect(json['timingMetrics'], {'chunkLatencyMsP95': 456});
      expect(json['runtimeStatus'], isA<Map<String, dynamic>>());

      final text = bundle.toPrettyJson();
      expect(text, contains('sample caption'));
      expect(text, contains('chunkLatencyMsP95'));
      expect(text, contains('<redacted>'));
      expect(text, isNot(contains('sk-secret-value')));
      expect(text, isNot(contains('token=secret')));
      expect(text, isNot(contains('abc123')));
    });

    test('writes local bundle file', () async {
      const exporter = DebugDetectionBundleExporter();
      final temp = await Directory.systemTemp.createTemp(
        'kidslens_debug_bundle_test_',
      );
      addTearDown(() => temp.delete(recursive: true));

      final bundle = exporter.buildBundle(mediaId: 'media_1');
      final file = await exporter.writeBundle(
        directory: temp,
        bundle: bundle,
      );

      expect(file.existsSync(), isTrue);
      expect(file.path, contains('kidslens_debug_bundle_'));
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(decoded['mediaId'], 'media_1');
    });
  });
}

AnalysisRunManifest _manifest() => AnalysisRunManifest(
      runId: 'run_1',
      mediaId: 'media_1',
      pipelineId: 'vss_family_safety_v1',
      pipelineVersion: 1,
      createdAt: DateTime.utc(2026, 6, 8),
      chunkPlannerHash: 'chunk_hash',
      samplingHash: 'sampling_hash',
      policyProfileHash: 'policy_hash',
      chunks: [_chunk()],
    );

VideoChunk _chunk() => VideoChunk(
      id: VideoChunk.deterministicId(
        mediaId: 'media_1',
        index: 0,
        startTime: Duration.zero,
        endTime: const Duration(seconds: 5),
      ),
      mediaId: 'media_1',
      index: 0,
      startTime: Duration.zero,
      endTime: const Duration(seconds: 5),
    );

Detection _detection() => const Detection(
      id: 'det_1',
      mediaId: 'media_1',
      type: ContentType.nsfw,
      startTime: Duration(seconds: 1),
      endTime: Duration(seconds: 3),
      confidence: 0.91,
      description: 'debug detection',
      metadata: {
        'policyCategoryId': 'violence',
        'rationale': 'A fight was detected.',
        'rawImageBase64': 'abc123',
        'apiKey': 'sk-secret-value',
      },
    );

EvidenceRecord _evidence() => EvidenceRecord(
      id: 'ev_1',
      mediaId: 'media_1',
      type: EvidenceType.vlmPolicyJson,
      provenance: const EvidenceProvenance(
        providerId: 'local_vlm',
        providerVersion: '1',
        runtime: 'cuda_vllm',
        inputIds: ['frame_1'],
        startTime: Duration(seconds: 1),
        endTime: Duration(seconds: 3),
      ),
      payload: const {
        'prompt': 'authorization: Bearer secret-token',
        'parsedProviderJson': {'finding': 'violence'},
      },
    );

LocalRuntimeStatus _runtimeStatus() => const LocalRuntimeStatus(
      runtimeName: 'CUDA vLLM',
      modelName: 'Qwen local',
      gpuDevice: 'RTX 5070',
      vramEstimate: LocalRuntimeVramEstimate(
        requiredGb: 8,
        availableGb: 12,
        hasSufficientVram: true,
        workload: LocalRuntimeWorkload(
          chunkSeconds: 10,
          frameCount: 8,
          frameWidth: 768,
          frameHeight: 432,
          maxOutputTokens: 1024,
        ),
        components: {'weights': 6},
      ),
    );
