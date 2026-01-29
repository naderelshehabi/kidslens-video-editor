import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/converters.dart';

part 'transcript.freezed.dart';
part 'transcript.g.dart';

/// Represents a word within a transcript segment with timing information
@freezed
class TranscriptWord with _$TranscriptWord {
  const factory TranscriptWord({
    /// The actual word text
    required String word,

    /// Start time of the word relative to media start
    @DurationConverter() required Duration startTime,

    /// End time of the word relative to media start
    @DurationConverter() required Duration endTime,

    /// Confidence score from ASR (0.0 to 1.0)
    required double confidence,
  }) = _TranscriptWord;

  const TranscriptWord._();

  factory TranscriptWord.fromJson(Map<String, dynamic> json) =>
      _$TranscriptWordFromJson(json);

  /// Duration of the word
  Duration get duration => endTime - startTime;

  /// Whether this word has high confidence (>= 0.9)
  bool get isHighConfidence => confidence >= 0.9;

  /// Whether this word has low confidence (< 0.7)
  bool get isLowConfidence => confidence < 0.7;
}

/// Represents a segment of transcript (typically a sentence or phrase)
@freezed
class TranscriptSegment with _$TranscriptSegment {
  const factory TranscriptSegment({
    /// Unique identifier for the segment
    required String id,

    /// Start time of the segment relative to media start
    @DurationConverter() required Duration startTime,

    /// End time of the segment relative to media start
    @DurationConverter() required Duration endTime,

    /// Full text of the segment
    required String text,

    /// Individual words with timing information
    required List<TranscriptWord> words,
  }) = _TranscriptSegment;

  const TranscriptSegment._();

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) =>
      _$TranscriptSegmentFromJson(json);

  /// Duration of the segment
  Duration get duration => endTime - startTime;

  /// Average confidence across all words
  double get averageConfidence => words.isEmpty
      ? 0.0
      : words.map((w) => w.confidence).reduce((a, b) => a + b) / words.length;

  /// Number of words in the segment
  int get wordCount => words.length;

  /// Gets words within a time range
  List<TranscriptWord> getWordsInRange(Duration start, Duration end) =>
      words
          .where((word) => word.startTime < end && word.endTime > start)
          .toList();

  /// Checks if this segment overlaps with a time range
  bool overlapsWithRange(Duration start, Duration end) =>
      startTime < end && endTime > start;
}

/// Represents a complete transcript for a media file
@freezed
class Transcript with _$Transcript {
  const factory Transcript({
    /// List of transcript segments
    required List<TranscriptSegment> segments,

    /// Language code (e.g., 'en', 'es', 'fr')
    required String language,

    /// Optional display name for the language
    String? languageDisplayName,

    /// Timestamp when the transcript was generated
    DateTime? generatedAt,

    /// Model ID used to generate the transcript
    String? modelId,
  }) = _Transcript;

  const Transcript._();

  factory Transcript.fromJson(Map<String, dynamic> json) =>
      _$TranscriptFromJson(json);

  /// Creates an empty transcript
  factory Transcript.empty({String language = 'en'}) => Transcript(
        segments: const [],
        language: language,
      );

  /// Total duration covered by the transcript
  Duration get totalDuration {
    if (segments.isEmpty) return Duration.zero;
    return segments.last.endTime;
  }

  /// Total word count across all segments
  int get totalWordCount =>
      segments.fold(0, (sum, segment) => sum + segment.wordCount);

  /// Overall average confidence
  double get overallConfidence {
    if (segments.isEmpty) return 0;
    final allWords = segments.expand((s) => s.words).toList();
    if (allWords.isEmpty) return 0;
    return allWords.map((w) => w.confidence).reduce((a, b) => a + b) /
        allWords.length;
  }

  /// Full transcript text
  String get fullText => segments.map((s) => s.text).join(' ');

  /// Gets the segment at a specific time
  TranscriptSegment? getSegmentAt(Duration time) {
    for (final segment in segments) {
      if (time >= segment.startTime && time < segment.endTime) {
        return segment;
      }
    }
    return null;
  }

  /// Gets the word at a specific time
  TranscriptWord? getWordAt(Duration time) {
    final segment = getSegmentAt(time);
    if (segment == null) return null;

    for (final word in segment.words) {
      if (time >= word.startTime && time < word.endTime) {
        return word;
      }
    }
    return null;
  }

  /// Gets all segments within a time range
  List<TranscriptSegment> getSegmentsInRange(Duration start, Duration end) =>
      segments.where((segment) => segment.overlapsWithRange(start, end)).toList();

  /// Gets all words within a time range
  List<TranscriptWord> getWordsInRange(Duration start, Duration end) => segments
      .where((s) => s.overlapsWithRange(start, end))
      .expand((s) => s.getWordsInRange(start, end))
      .toList();
}
