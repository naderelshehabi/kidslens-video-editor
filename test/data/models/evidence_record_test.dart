import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

void main() {
  group('EvidenceRecord', () {
    test('round-trips all provenance fields through JSON', () {
      const provenance = EvidenceProvenance(
        providerId: 'legacy_nsfw',
        providerVersion: '8',
        modelBundleId: 'bundle-a',
        modelChecksum: 'sha256-a',
        runtime: 'onnx_directml',
        gpuProvider: 'directml',
        inputIds: ['frame-a'],
        startTime: Duration(seconds: 1),
        endTime: Duration(seconds: 2),
        schemaVersion: 3,
      );
      final record = EvidenceRecord(
        id: 'ev-a',
        mediaId: 'media-a',
        type: EvidenceType.vlmPolicyJson,
        provenance: provenance,
        payload: const {
          'category': 'violence',
          'confidence': 0.91,
        },
        createdAt: DateTime.utc(2026, 6, 7),
        chunkId: 'chunk-a',
        frameRefId: 'frame-ref-a',
      );

      final restored = EvidenceRecord.fromJson(record.toJson());

      expect(restored.id, record.id);
      expect(restored.type, EvidenceType.vlmPolicyJson);
      expect(restored.provenance.providerId, 'legacy_nsfw');
      expect(restored.provenance.modelBundleId, 'bundle-a');
      expect(restored.provenance.modelChecksum, 'sha256-a');
      expect(restored.provenance.runtime, 'onnx_directml');
      expect(restored.provenance.gpuProvider, 'directml');
      expect(restored.provenance.inputIds, ['frame-a']);
      expect(restored.provenance.startTime, const Duration(seconds: 1));
      expect(restored.provenance.endTime, const Duration(seconds: 2));
      expect(restored.provenance.schemaVersion, 3);
      expect(restored.payload['category'], 'violence');
      expect(restored.chunkId, 'chunk-a');
      expect(restored.frameRefId, 'frame-ref-a');
    });

    test('creates deterministic legacy NSFW score ids', () {
      const provenance = EvidenceProvenance(
        providerId: 'legacy_nsfw',
        providerVersion: '8',
        runtime: 'onnx_cpu',
        inputIds: ['frame-0'],
        startTime: Duration.zero,
        endTime: Duration(seconds: 1),
      );
      final frame = FrameAnalysisResult.safe(
        frameNumber: 0,
        timestamp: Duration.zero,
      ).copyWith(
        nsfw: const NsfwResult(
          porn: 0.8,
          sexy: 0.1,
          hentai: 0,
          drawings: 0,
          neutral: 0.1,
        ),
      );

      final first = EvidenceRecord.legacyNsfwScore(
        mediaId: 'media-a',
        frame: frame,
        provenance: provenance,
      );
      final second = EvidenceRecord.legacyNsfwScore(
        mediaId: 'media-a',
        frame: frame,
        provenance: provenance,
      );

      expect(first.id, second.id);
      expect(first.type, EvidenceType.legacyNsfwScore);
      expect(first.payload['nsfw'], frame.nsfw.toJson());
    });
  });
}
