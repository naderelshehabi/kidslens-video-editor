import 'package:kidslens_video_editor/data/models/models.dart';

class EvidenceReplayOptions {
  const EvidenceReplayOptions({
    this.nsfwThreshold = 0.5,
    this.profanityThreshold = 0.5,
    this.mediaDuration,
    this.language = 'en',
  });

  final double nsfwThreshold;
  final double profanityThreshold;
  final Duration? mediaDuration;
  final String language;
}

class EvidenceReplayService {
  AnalysisResult replayAnalysis({
    required String analysisId,
    required String mediaId,
    required Iterable<EvidenceRecord> records,
    EvidenceReplayOptions options = const EvidenceReplayOptions(),
    Map<String, dynamic>? settings,
  }) {
    final scopedRecords = records
        .where((record) => record.mediaId == mediaId)
        .toList(growable: false)
      ..sort(_compareReplayRecords);

    final frameResults = _replayFrameResults(scopedRecords);
    final transcript = _replayTranscript(scopedRecords, options.language);
    final profanityMatches = _replayProfanityMatches(scopedRecords);
    final detections = <Detection>[
      ..._buildProfanityDetections(
        mediaId: mediaId,
        matches: profanityMatches,
        threshold: options.profanityThreshold,
      ),
      ..._buildNsfwScoreDetections(
        mediaId: mediaId,
        records: scopedRecords,
        frameResults: frameResults,
        threshold: options.nsfwThreshold,
      ),
      ..._buildRegionDetections(
        mediaId: mediaId,
        records: scopedRecords,
      ),
    ];

    final mediaDuration = options.mediaDuration ??
        _inferMediaDuration(scopedRecords, frameResults, profanityMatches);
    final timeline = UnifiedTimeline.fromDetections(
      id: 'timeline_$analysisId',
      mediaDuration: mediaDuration,
      detections: detections,
    );

    return AnalysisResult(
      id: analysisId,
      status: AnalysisStatus.completed,
      mediaFileId: mediaId,
      transcript: transcript,
      profanityMatches: profanityMatches,
      frameResults: frameResults,
      timeline: timeline,
      completedAt: DateTime.now().toUtc(),
      settings: settings,
    );
  }

  List<FrameAnalysisResult> _replayFrameResults(List<EvidenceRecord> records) {
    final framesByTimestamp = <int, FrameAnalysisResult>{};

    for (final record in records) {
      switch (record.type) {
        case EvidenceType.legacyNsfwScore:
          final timestamp = _timestampFromPayload(record);
          final frame = _frameAt(framesByTimestamp, record, timestamp);
          framesByTimestamp[timestamp.inMilliseconds] = frame.copyWith(
            nsfw: NsfwResult.fromJson(
              Map<String, dynamic>.from(record.payload['nsfw'] as Map),
            ),
            isSceneChange:
                record.payload['isSceneChange'] as bool? ?? frame.isSceneChange,
          );
        case EvidenceType.legacyNudenetRegion:
        case EvidenceType.modestyParserSignal:
        case EvidenceType.groundedRegion:
          final timestamp = _timestampFromPayload(record);
          final frame = _frameAt(framesByTimestamp, record, timestamp);
          final region = DetectedRegion.fromJson(
            Map<String, dynamic>.from(record.payload['region'] as Map),
          );
          final existingVisual =
              frame.visualContent ?? VisualContentResult.safe();
          framesByTimestamp[timestamp.inMilliseconds] = frame.copyWith(
            visualContent: existingVisual.copyWith(
              detectedRegions: [
                ...existingVisual.detectedRegions,
                region,
              ],
            ),
          );
        case EvidenceType.vlmCaption:
        case EvidenceType.vlmPolicyJson:
        case EvidenceType.transcriptSpan:
        case EvidenceType.profanityMatch:
        case EvidenceType.embeddingRecord:
          break;
      }
    }

    return framesByTimestamp.values.toList(growable: false)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  FrameAnalysisResult _frameAt(
    Map<int, FrameAnalysisResult> framesByTimestamp,
    EvidenceRecord record,
    Duration timestamp,
  ) {
    final timestampMs = timestamp.inMilliseconds;
    return framesByTimestamp[timestampMs] ??
        FrameAnalysisResult.safe(
          frameNumber:
              record.payload['frameNumber'] as int? ?? framesByTimestamp.length,
          timestamp: timestamp,
          isSceneChange: record.payload['isSceneChange'] as bool? ?? false,
        );
  }

  Transcript? _replayTranscript(
    List<EvidenceRecord> records,
    String language,
  ) {
    final segments = records
        .where((record) => record.type == EvidenceType.transcriptSpan)
        .map(
          (record) => TranscriptSegment.fromJson(
            Map<String, dynamic>.from(record.payload['segment'] as Map),
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (segments.isEmpty) {
      return null;
    }
    return Transcript(segments: segments, language: language);
  }

  List<ProfanityMatch> _replayProfanityMatches(List<EvidenceRecord> records) =>
      records
          .where((record) => record.type == EvidenceType.profanityMatch)
          .map(
            (record) => ProfanityMatch.fromJson(
              Map<String, dynamic>.from(record.payload['match'] as Map),
            ),
          )
          .toList(growable: false)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

  List<Detection> _buildProfanityDetections({
    required String mediaId,
    required List<ProfanityMatch> matches,
    required double threshold,
  }) =>
      matches
          .where((match) => !match.isFalsePositive)
          .where((match) => match.confidence >= threshold)
          .map(
            (match) => Detection.profanity(
              id: 'replay_${match.id}',
              mediaId: mediaId,
              startTime: match.startTime,
              endTime: match.endTime,
              confidence: match.confidence,
              word: match.originalWord,
            ),
          )
          .toList(growable: false);

  List<Detection> _buildNsfwScoreDetections({
    required String mediaId,
    required List<EvidenceRecord> records,
    required List<FrameAnalysisResult> frameResults,
    required double threshold,
  }) {
    final nsfwRecords = records
        .where((record) => record.type == EvidenceType.legacyNsfwScore)
        .toList(growable: false)
      ..sort(_compareReplayRecords);
    if (nsfwRecords.isEmpty) {
      return const <Detection>[];
    }

    final frameByTimestamp = {
      for (final frame in frameResults) frame.timestamp.inMilliseconds: frame,
    };
    final detections = <Detection>[];
    EvidenceRecord? openRecord;
    var maxScore = 0.0;
    var index = 0;

    for (final record in nsfwRecords) {
      final timestamp = _timestampFromPayload(record);
      final frame = frameByTimestamp[timestamp.inMilliseconds];
      final score = frame?.nsfw.maxNsfwScore ?? 0;
      final flagged = score >= threshold;

      if (flagged && openRecord == null) {
        openRecord = record;
        maxScore = score;
      } else if (flagged) {
        maxScore = score > maxScore ? score : maxScore;
      } else if (openRecord != null) {
        detections.add(
          _nsfwReplayDetection(
            id: 'replay_nsfw_${index++}',
            mediaId: mediaId,
            start: openRecord.provenance.startTime,
            end: record.provenance.startTime,
            confidence: maxScore,
          ),
        );
        openRecord = null;
        maxScore = 0;
      }
    }

    if (openRecord != null) {
      detections.add(
        _nsfwReplayDetection(
          id: 'replay_nsfw_${index++}',
          mediaId: mediaId,
          start: openRecord.provenance.startTime,
          end: openRecord.provenance.endTime > openRecord.provenance.startTime
              ? openRecord.provenance.endTime
              : openRecord.provenance.startTime,
          confidence: maxScore,
        ),
      );
    }

    return detections;
  }

  List<Detection> _buildRegionDetections({
    required String mediaId,
    required List<EvidenceRecord> records,
  }) {
    final result = <Detection>[];
    for (final record in records) {
      if (record.type != EvidenceType.legacyNudenetRegion &&
          record.type != EvidenceType.modestyParserSignal &&
          record.type != EvidenceType.groundedRegion) {
        continue;
      }
      final region = DetectedRegion.fromJson(
        Map<String, dynamic>.from(record.payload['region'] as Map),
      );
      result.add(
        Detection.visual(
          id: 'replay_${record.id}',
          mediaId: mediaId,
          type: ContentType.nsfw,
          startTime: record.provenance.startTime,
          endTime: record.provenance.endTime,
          confidence: region.confidence,
          description: '${region.label} detected',
        ).copyWith(
          source: record.provenance.providerId,
          metadata: {
            Detection.visualContentCategoryKey:
                record.payload['categoryId'] as String? ?? region.label,
            Detection.boundingBoxKey: {
              'x': region.x,
              'y': region.y,
              'width': region.width,
              'height': region.height,
            },
            'supportingEvidenceIds': [record.id],
          },
        ),
      );
    }
    return result;
  }

  Detection _nsfwReplayDetection({
    required String id,
    required String mediaId,
    required Duration start,
    required Duration end,
    required double confidence,
  }) =>
      Detection.visual(
        id: id,
        mediaId: mediaId,
        type: ContentType.nsfw,
        startTime: start,
        endTime: end,
        confidence: confidence,
        description: 'NSFW content detected',
      ).copyWith(
        source: 'evidence_replay',
      );

  Duration _timestampFromPayload(EvidenceRecord record) {
    final timestampMs = record.payload['timestampMs'] as int?;
    if (timestampMs != null) {
      return Duration(milliseconds: timestampMs);
    }
    return record.provenance.startTime;
  }

  Duration _inferMediaDuration(
    List<EvidenceRecord> records,
    List<FrameAnalysisResult> frameResults,
    List<ProfanityMatch> profanityMatches,
  ) {
    final candidateDurations = <Duration>[
      for (final record in records) record.provenance.endTime,
      for (final frame in frameResults) frame.timestamp,
      for (final match in profanityMatches) match.endTime,
    ]..sort();
    if (candidateDurations.isEmpty) {
      return Duration.zero;
    }
    return candidateDurations.last;
  }
}

int _compareReplayRecords(EvidenceRecord a, EvidenceRecord b) {
  final startCompare = a.provenance.startTime.compareTo(b.provenance.startTime);
  if (startCompare != 0) {
    return startCompare;
  }
  final typeCompare = a.type.jsonValue.compareTo(b.type.jsonValue);
  if (typeCompare != 0) {
    return typeCompare;
  }
  return a.id.compareTo(b.id);
}
