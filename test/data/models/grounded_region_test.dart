import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

void main() {
  group('NormalizedGroundingBox', () {
    test('clamps boxes and preserves frame aspect metadata', () {
      final box = NormalizedGroundingBox.clamped(
        x: 0.8,
        y: -0.1,
        width: 0.5,
        height: 0.5,
        frameWidth: 1920,
        frameHeight: 1080,
      );

      expect(box.x, 0.8);
      expect(box.y, 0);
      expect(box.width, closeTo(0.2, 0.0001));
      expect(box.height, 0.5);
      expect(box.frameAspectRatio, closeTo(16 / 9, 0.0001));
      expect(box.toJson()['frameAspectRatio'], closeTo(16 / 9, 0.0001));
    });

    test('rejects zero-area boxes after clamping', () {
      expect(
        () => NormalizedGroundingBox.clamped(
          x: 1,
          y: 0.5,
          width: 0.2,
          height: 0.2,
        ),
        throwsA(isA<GroundedRegionValidationException>()),
      );
    });
  });

  group('GroundedRegion', () {
    test('round-trips through JSON and converts to evidence', () {
      final provenance = _provenance();
      final box = NormalizedGroundingBox.clamped(
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
      );
      final region = GroundedRegion(
        id: GroundedRegion.deterministicId(
          mediaId: 'media-a',
          categoryId: 'blood',
          frameId: 'frame-a',
          chunkId: 'chunk-a',
          label: 'blood',
          box: box,
          provenance: provenance,
        ),
        mediaId: 'media-a',
        categoryId: 'blood',
        label: 'blood',
        frameId: 'frame-a',
        chunkId: 'chunk-a',
        box: box,
        confidence: 1.2,
        rationale: 'Visible red fluid.',
        provenance: provenance,
        status: GroundingStatus.grounded,
        metadata: const {'sourceKind': 'test'},
      );

      final restored = GroundedRegion.fromJson(region.toJson());
      final evidence = restored.toEvidenceRecord(
        timestamp: const Duration(milliseconds: 500),
      );

      expect(restored.id, region.id);
      expect(restored.confidence, 1);
      expect(restored.status, GroundingStatus.grounded);
      expect(restored.toDetectedRegion()?.label, 'blood');
      expect(evidence.type, EvidenceType.groundedRegion);
      expect(evidence.payload['timestampMs'], 500);
      expect(evidence.payload['groundingStatus'], 'grounded');
      expect(evidence.payload['region'], isA<Map<String, dynamic>>());
    });

    test('does not allow grounded status without a boundary', () {
      expect(
        () => GroundedRegion(
          id: 'region-a',
          mediaId: 'media-a',
          categoryId: 'weapon',
          label: 'knife',
          frameId: 'frame-a',
          chunkId: 'chunk-a',
          confidence: 0.5,
          rationale: 'Visible object.',
          provenance: _provenance(),
          status: GroundingStatus.grounded,
        ),
        throwsA(isA<GroundedRegionValidationException>()),
      );
    });
  });
}

EvidenceProvenance _provenance() => const EvidenceProvenance(
      providerId: 'provider-a',
      providerVersion: '1',
      modelBundleId: 'model-a',
      runtime: 'cpu',
      inputIds: ['frame-a'],
      startTime: Duration.zero,
      endTime: Duration(seconds: 1),
    );
