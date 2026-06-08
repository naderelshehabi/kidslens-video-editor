import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/evidence_record.dart';
import 'package:kidslens_video_editor/data/models/local_runtime_profile.dart';
import 'package:kidslens_video_editor/data/models/video_chunk.dart';
import 'package:kidslens_video_editor/presentation/widgets/detection/debug_detection_overlay.dart';

void main() {
  group('DebugDetectionOverlay', () {
    testWidgets('is absent when simulating a release build', (tester) async {
      await tester.pumpWidget(
        _Host(
          child: DebugDetectionOverlay(
            enabled: true,
            debugBuildEnabled: false,
            detections: [_detection()],
            currentPosition: const Duration(seconds: 2),
            mediaDuration: const Duration(seconds: 10),
          ),
        ),
      );

      expect(find.text('Family Safety Debug'), findsNothing);
      expect(
        find.byKey(const Key('debug_detection_overlay_paint')),
        findsNothing,
      );
    });

    testWidgets(
      'renders active detection diagnostics in debug mode',
      (tester) async {
        await tester.pumpWidget(
          _Host(
            child: DebugDetectionOverlay(
              enabled: true,
              detections: [_detection()],
              currentPosition: const Duration(seconds: 2),
              mediaDuration: const Duration(seconds: 10),
              evidenceRecords: [_evidence()],
              runtimeStatus: _runtimeStatus(),
            ),
          ),
        );

        expect(find.text('Family Safety Debug'), findsOneWidget);
        expect(find.textContaining('Female Legs Exposure'), findsOneWidget);
        expect(find.textContaining('High'), findsOneWidget);
        expect(find.textContaining('Region-level'), findsOneWidget);
        expect(find.textContaining('Exposed legs localized'), findsOneWidget);
        expect(find.textContaining('provider_failed'), findsOneWidget);
        expect(find.textContaining('removed trailing comma'), findsOneWidget);
        expect(find.textContaining('raw unsafe json'), findsOneWidget);
        expect(find.textContaining('CUDA vLLM'), findsOneWidget);
        expect(
          find.byKey(const Key('debug_detection_overlay_paint')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows no active detection message at empty playhead',
      (tester) async {
        await tester.pumpWidget(
          _Host(
            child: DebugDetectionOverlay(
              enabled: true,
              detections: [_detection()],
              currentPosition: const Duration(seconds: 8),
              mediaDuration: const Duration(seconds: 10),
            ),
          ),
        );

        expect(find.text('Family Safety Debug'), findsOneWidget);
        expect(find.text('No active detection at playhead.'), findsOneWidget);
      },
    );
  });

  group('DebugDetectionTimelineOverlay', () {
    testWidgets('draws only in debug-enabled mode', (tester) async {
      await tester.pumpWidget(
        _Host(
          child: SizedBox(
            width: 400,
            height: 40,
            child: DebugDetectionTimelineOverlay(
              enabled: true,
              duration: const Duration(seconds: 10),
              timelineWidth: 400,
              height: 40,
              detections: [_detection()],
              chunks: [_chunk()],
              sampledFrameTimestamps: const [
                Duration(seconds: 2),
                Duration(seconds: 6),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('debug_detection_timeline_paint')),
        findsOneWidget,
      );
    });

    testWidgets('is absent when disabled', (tester) async {
      await tester.pumpWidget(
        const _Host(
          child: DebugDetectionTimelineOverlay(
            enabled: false,
            duration: Duration(seconds: 10),
            timelineWidth: 400,
            height: 40,
          ),
        ),
      );

      expect(
        find.byKey(const Key('debug_detection_timeline_paint')),
        findsNothing,
      );
    });
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );
}

Detection _detection() => const Detection(
      id: 'det_1',
      mediaId: 'media_1',
      type: ContentType.nsfw,
      startTime: Duration(seconds: 1),
      endTime: Duration(seconds: 4),
      confidence: 0.93,
      description: 'debug detection',
      metadata: {
        'policyCategoryId': 'female_legs_exposure',
        'policySeverity': 'high',
        'rationale': 'Exposed legs localized in sampled frame.',
        'supportingEvidenceIds': ['ev_1'],
        'groundingStatus': 'grounded',
        'regionIds': ['region_1'],
        'providerAgreement': 'provider_failed',
        'schemaRepairWarnings': ['removed trailing comma'],
        'secondPassChanges': 'severity raised from medium to high',
        'rawProviderJson': {'note': 'raw unsafe json'},
        'boundingBoxes': [
          {'x': 0.2, 'y': 0.3, 'width': 0.4, 'height': 0.5},
        ],
        'masks': [
          {'x': 0.22, 'y': 0.32, 'width': 0.3, 'height': 0.4},
        ],
        'points': [
          {'x': 0.3, 'y': 0.4},
        ],
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
        endTime: Duration(seconds: 4),
        modelBundleId: 'qwen',
        modelChecksum: 'sha256',
        gpuProvider: 'cuda',
      ),
      payload: const {
        'parsedProviderJson': {'finding': 'raw unsafe json'},
      },
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
