import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/evidence_replay_service.dart';
import 'package:kidslens_video_editor/services/detection/evidence_store.dart';

void main() {
  group('JsonEvidenceStore', () {
    test('persists, filters, deduplicates, and clears evidence records',
        () async {
      final directory = await Directory.systemTemp.createTemp('kidslens_ev_');
      addTearDown(() => directory.delete(recursive: true));
      final store = JsonEvidenceStore(File('${directory.path}/evidence.json'));

      final first = _nsfwEvidence(
        mediaId: 'media-a',
        frameNumber: 0,
        timestamp: Duration.zero,
        score: 0.9,
      );
      final second = _nsfwEvidence(
        mediaId: 'media-b',
        frameNumber: 0,
        timestamp: Duration.zero,
        score: 0.1,
      );

      await store.appendAll([first, second, first]);

      expect(await store.readAll(), hasLength(2));
      expect(
        (await store.readAll(mediaId: 'media-a')).map((record) => record.id),
        [first.id],
      );
      expect(
        await store.readAll(type: EvidenceType.legacyNsfwScore),
        hasLength(2),
      );

      await store.clear(mediaId: 'media-a');
      expect((await store.readAll()).map((record) => record.id), [second.id]);

      await store.clear();
      expect(await store.readAll(), isEmpty);
    });
  });

  group('EvidenceReplayService', () {
    test('replays legacy visual and audio evidence without model inference',
        () {
      const transcriptSegment = TranscriptSegment(
        id: 'seg-a',
        startTime: Duration(seconds: 3),
        endTime: Duration(seconds: 4),
        text: 'bad word',
        words: [
          TranscriptWord(
            word: 'bad',
            startTime: Duration(seconds: 3),
            endTime: Duration(milliseconds: 3500),
            confidence: 0.97,
          ),
        ],
      );
      final profanityMatch = ProfanityMatch.exact(
        id: 'match-a',
        word: transcriptSegment.words.first,
        matchedProfanity: 'bad',
      );
      const region = DetectedRegion(
        label: 'FEMALE_LEG_EXPOSED',
        confidence: 0.88,
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
      );
      final records = [
        _nsfwEvidence(
          mediaId: 'media-a',
          frameNumber: 0,
          timestamp: Duration.zero,
          score: 0.1,
        ),
        _nsfwEvidence(
          mediaId: 'media-a',
          frameNumber: 1,
          timestamp: const Duration(seconds: 1),
          score: 0.92,
        ),
        _nsfwEvidence(
          mediaId: 'media-a',
          frameNumber: 2,
          timestamp: const Duration(seconds: 2),
          score: 0.2,
        ),
        EvidenceRecord.legacyNudenetRegion(
          mediaId: 'media-a',
          timestamp: const Duration(seconds: 1),
          frameNumber: 1,
          region: region,
          provenance: _provenance(
            providerId: 'legacy_nudenet',
            inputId: 'frame-1',
            start: const Duration(seconds: 1),
            end: const Duration(milliseconds: 1500),
          ),
        ),
        EvidenceRecord.modestyParserSignal(
          mediaId: 'media-a',
          timestamp: const Duration(seconds: 1),
          frameNumber: 1,
          region: region.copyWith(label: 'MODESTY_FEMALE_LEGS_EXPOSED'),
          categoryId: 'female_legs_exposure',
          provenance: _provenance(
            providerId: 'modesty_parser',
            inputId: 'frame-1',
            start: const Duration(seconds: 1),
            end: const Duration(milliseconds: 1500),
          ),
        ),
        EvidenceRecord.transcriptSpan(
          mediaId: 'media-a',
          segment: transcriptSegment,
          provenance: _provenance(
            providerId: 'asr',
            inputId: 'audio-0',
            start: transcriptSegment.startTime,
            end: transcriptSegment.endTime,
          ),
        ),
        EvidenceRecord.profanityMatch(
          mediaId: 'media-a',
          match: profanityMatch,
          provenance: _provenance(
            providerId: 'profanity',
            inputId: 'seg-a',
            start: profanityMatch.startTime,
            end: profanityMatch.endTime,
          ),
        ),
      ];

      final replayed = EvidenceReplayService().replayAnalysis(
        analysisId: 'analysis-a',
        mediaId: 'media-a',
        records: records,
        options: const EvidenceReplayOptions(
          mediaDuration: Duration(seconds: 5),
        ),
      );

      expect(replayed.status, AnalysisStatus.completed);
      expect(replayed.frameResults, hasLength(3));
      expect(replayed.frameResults[1].nsfw.maxNsfwScore, 0.92);
      expect(
        replayed.frameResults[1].visualContent?.detectedRegions,
        hasLength(2),
      );
      expect(replayed.transcript?.segments.single.text, 'bad word');
      expect(replayed.profanityMatches.single.id, 'match-a');

      final videoSegments = replayed.timeline!.videoTrack!.segments;
      final audioSegments = replayed.timeline!.audioTrack!.segments;
      expect(audioSegments, hasLength(1));
      expect(
        videoSegments.where((segment) => segment.confidence == 0.92),
        hasLength(1),
      );
      expect(
        videoSegments
            .where((segment) => segment.detectionId!.startsWith('replay_ev_')),
        hasLength(2),
      );
    });
  });
}

EvidenceRecord _nsfwEvidence({
  required String mediaId,
  required int frameNumber,
  required Duration timestamp,
  required double score,
}) {
  final frame = FrameAnalysisResult.safe(
    frameNumber: frameNumber,
    timestamp: timestamp,
  ).copyWith(
    nsfw: NsfwResult(
      porn: score,
      sexy: 0,
      hentai: 0,
      drawings: 0,
      neutral: 1 - score,
    ),
  );
  return EvidenceRecord.legacyNsfwScore(
    mediaId: mediaId,
    frame: frame,
    provenance: _provenance(
      providerId: 'legacy_nsfw',
      inputId: 'frame-$frameNumber',
      start: timestamp,
      end: timestamp + const Duration(seconds: 1),
    ),
  );
}

EvidenceProvenance _provenance({
  required String providerId,
  required String inputId,
  required Duration start,
  required Duration end,
}) =>
    EvidenceProvenance(
      providerId: providerId,
      providerVersion: '1',
      modelBundleId: '$providerId-bundle',
      modelChecksum: 'sha256-$providerId',
      runtime: 'local_test',
      gpuProvider: 'cpu',
      inputIds: [inputId],
      startTime: start,
      endTime: end,
    );
