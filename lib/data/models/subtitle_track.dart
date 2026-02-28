import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kidslens_video_editor/data/models/converters.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';

part 'subtitle_track.freezed.dart';
part 'subtitle_track.g.dart';

/// A subtitle track for a media file in the project
@freezed
class SubtitleTrack with _$SubtitleTrack {
  const factory SubtitleTrack({
    /// Unique identifier for the subtitle track
    required String id,

    /// ID of the media file this subtitle belongs to
    required String mediaId,

    /// Language code (e.g., 'en', 'es')
    required String language,

    /// When the subtitles were generated
    @DateTimeConverter() required DateTime createdAt,

    /// Subtitle segments with timing
    required List<SubtitleSegment> segments, /// The ASR model used to generate the subtitles
    String? modelId,
  }) = _SubtitleTrack;

  const SubtitleTrack._();

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) =>
      _$SubtitleTrackFromJson(json);

  /// Create from a Transcript
  factory SubtitleTrack.fromTranscript({
    required String id,
    required String mediaId,
    required Transcript transcript,
    String? modelId,
  }) =>
      SubtitleTrack(
        id: id,
        mediaId: mediaId,
        language: transcript.language,
        createdAt: transcript.generatedAt ?? DateTime.now(),
        modelId: modelId ?? transcript.modelId,
        segments: transcript.segments
            .map(
              (s) => SubtitleSegment(
                id: s.id,
                startTime: s.startTime,
                endTime: s.endTime,
                text: s.text,
              ),
            )
            .toList(),
      );

  /// Total duration of the subtitle track
  Duration get totalDuration {
    if (segments.isEmpty) return Duration.zero;
    return segments.last.endTime;
  }

  /// Get segment at a specific time
  SubtitleSegment? getSegmentAt(Duration time) {
    for (final segment in segments) {
      if (time >= segment.startTime && time < segment.endTime) {
        return segment;
      }
    }
    return null;
  }

  /// Full text of all segments
  String get fullText => segments.map((s) => s.text).join(' ');

  /// Total number of segments
  int get segmentCount => segments.length;

  /// Convert to Transcript for export services
  Transcript toTranscript() => Transcript(
        language: language,
        generatedAt: createdAt,
        modelId: modelId ?? '',
        segments: segments
            .map(
              (s) {
                final normalizedText = s.text.trim();
                final tokens = normalizedText.isEmpty
                    ? const <String>[]
                    : normalizedText
                        .split(RegExp(r'\s+'))
                        .where((word) => word.isNotEmpty)
                        .toList(growable: false);

                final segmentDurationUs =
                    (s.endTime - s.startTime).inMicroseconds;
                final perWordDurationUs = tokens.isEmpty
                    ? 0
                    : (segmentDurationUs / tokens.length).floor();

                final words = <TranscriptWord>[];
                for (var i = 0; i < tokens.length; i++) {
                  final startOffsetUs = perWordDurationUs * i;
                  final endOffsetUs = i == tokens.length - 1
                      ? segmentDurationUs
                      : perWordDurationUs * (i + 1);

                  final startTime =
                      s.startTime + Duration(microseconds: startOffsetUs);
                  final endTime = s.startTime + Duration(
                    microseconds: endOffsetUs <= startOffsetUs
                        ? startOffsetUs + 1
                        : endOffsetUs,
                  );

                  words.add(
                    TranscriptWord(
                      word: tokens[i],
                      startTime: startTime,
                      endTime: endTime,
                      confidence: 1.0,
                    ),
                  );
                }

                return TranscriptSegment(
                  id: s.id,
                  startTime: s.startTime,
                  endTime: s.endTime,
                  text: s.text,
                  words: words,
                );
              },
            )
            .toList(),
      );
}

/// A single subtitle segment with timing
@freezed
class SubtitleSegment with _$SubtitleSegment {
  const factory SubtitleSegment({
    /// Unique identifier
    required String id,

    /// Start time relative to media start
    @DurationConverter() required Duration startTime,

    /// End time relative to media start
    @DurationConverter() required Duration endTime,

    /// The subtitle text to display
    required String text,
  }) = _SubtitleSegment;

  const SubtitleSegment._();

  factory SubtitleSegment.fromJson(Map<String, dynamic> json) =>
      _$SubtitleSegmentFromJson(json);

  /// Duration of the segment
  Duration get duration => endTime - startTime;
}
