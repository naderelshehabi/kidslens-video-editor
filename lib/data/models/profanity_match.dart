import 'package:freezed_annotation/freezed_annotation.dart';

import 'transcript.dart';

part 'profanity_match.freezed.dart';
part 'profanity_match.g.dart';

/// Types of profanity matching methods
@JsonEnum()
enum MatchType {
  /// Exact word match
  @JsonValue('exact')
  exact,

  /// Leetspeak substitution (e.g., '@ss' for 'ass')
  @JsonValue('leetspeak')
  leetspeak,

  /// Phonetic/sound-alike match (e.g., 'fuk' for 'fuck')
  @JsonValue('phonetic')
  phonetic,

  /// Fuzzy/approximate match
  @JsonValue('fuzzy')
  fuzzy,

  /// Obfuscated with special characters (e.g., 'f***')
  @JsonValue('obfuscated')
  obfuscated,
}

/// Represents a detected profanity match in the transcript
@freezed
class ProfanityMatch with _$ProfanityMatch {
  const ProfanityMatch._();

  const factory ProfanityMatch({
    /// Unique identifier for the match
    required String id,

    /// The transcript word that matched
    required TranscriptWord word,

    /// The profanity word/pattern that was matched against
    required String matchedProfanity,

    /// Confidence score (0.0 to 1.0)
    required double confidence,

    /// Type of match
    required MatchType type,

    /// Severity level (1-5, where 5 is most severe)
    @Default(3) int severity,

    /// Category of profanity (e.g., 'sexual', 'slur', 'general')
    String? category,

    /// Whether this match has been reviewed by user
    @Default(false) bool isReviewed,

    /// Whether this is a false positive (user marked)
    @Default(false) bool isFalsePositive,

    /// User note about this match
    String? userNote,
  }) = _ProfanityMatch;

  factory ProfanityMatch.fromJson(Map<String, dynamic> json) =>
      _$ProfanityMatchFromJson(json);

  /// Creates an exact match
  factory ProfanityMatch.exact({
    required String id,
    required TranscriptWord word,
    required String matchedProfanity,
    int severity = 3,
    String? category,
  }) {
    return ProfanityMatch(
      id: id,
      word: word,
      matchedProfanity: matchedProfanity,
      confidence: 1.0,
      type: MatchType.exact,
      severity: severity,
      category: category,
    );
  }

  /// Creates a leetspeak match
  factory ProfanityMatch.leetspeak({
    required String id,
    required TranscriptWord word,
    required String matchedProfanity,
    required double confidence,
    int severity = 3,
    String? category,
  }) {
    return ProfanityMatch(
      id: id,
      word: word,
      matchedProfanity: matchedProfanity,
      confidence: confidence,
      type: MatchType.leetspeak,
      severity: severity,
      category: category,
    );
  }

  /// Creates a phonetic match
  factory ProfanityMatch.phonetic({
    required String id,
    required TranscriptWord word,
    required String matchedProfanity,
    required double confidence,
    int severity = 3,
    String? category,
  }) {
    return ProfanityMatch(
      id: id,
      word: word,
      matchedProfanity: matchedProfanity,
      confidence: confidence,
      type: MatchType.phonetic,
      severity: severity,
      category: category,
    );
  }

  /// Creates a fuzzy match
  factory ProfanityMatch.fuzzy({
    required String id,
    required TranscriptWord word,
    required String matchedProfanity,
    required double confidence,
    int severity = 3,
    String? category,
  }) {
    return ProfanityMatch(
      id: id,
      word: word,
      matchedProfanity: matchedProfanity,
      confidence: confidence,
      type: MatchType.fuzzy,
      severity: severity,
      category: category,
    );
  }

  /// Creates an obfuscated match
  factory ProfanityMatch.obfuscated({
    required String id,
    required TranscriptWord word,
    required String matchedProfanity,
    required double confidence,
    int severity = 3,
    String? category,
  }) {
    return ProfanityMatch(
      id: id,
      word: word,
      matchedProfanity: matchedProfanity,
      confidence: confidence,
      type: MatchType.obfuscated,
      severity: severity,
      category: category,
    );
  }

  /// Start time of the matched word
  Duration get startTime => word.startTime;

  /// End time of the matched word
  Duration get endTime => word.endTime;

  /// Duration of the matched word
  Duration get duration => word.duration;

  /// The original word text from transcript
  String get originalWord => word.word;

  /// Whether this is a high confidence match (>= 0.9)
  bool get isHighConfidence => confidence >= 0.9;

  /// Whether this is a low confidence match (< 0.7)
  bool get isLowConfidence => confidence < 0.7;

  /// Whether this is a high severity profanity (4-5)
  bool get isHighSeverity => severity >= 4;

  /// Whether this is a low severity profanity (1-2)
  bool get isLowSeverity => severity <= 2;

  /// Whether this match should be filtered (not false positive, reviewed or high confidence)
  bool get shouldFilter => !isFalsePositive && (isReviewed || isHighConfidence);

  /// Display name for the match type
  String get typeDisplayName {
    switch (type) {
      case MatchType.exact:
        return 'Exact Match';
      case MatchType.leetspeak:
        return 'Leetspeak';
      case MatchType.phonetic:
        return 'Phonetic';
      case MatchType.fuzzy:
        return 'Fuzzy';
      case MatchType.obfuscated:
        return 'Obfuscated';
    }
  }

  /// Short description of the match
  String get shortDescription {
    return '"${word.word}" → "$matchedProfanity" (${type.name})';
  }

  /// Mark as false positive
  ProfanityMatch markAsFalsePositive({String? note}) {
    return copyWith(
      isFalsePositive: true,
      isReviewed: true,
      userNote: note ?? userNote,
    );
  }

  /// Mark as reviewed (confirmed)
  ProfanityMatch markAsReviewed({String? note}) {
    return copyWith(
      isReviewed: true,
      userNote: note ?? userNote,
    );
  }

  /// Checks if this match overlaps with a time range
  bool overlapsWithRange(Duration start, Duration end) {
    return startTime < end && endTime > start;
  }
}

/// Extension for working with lists of profanity matches
extension ProfanityMatchListExtensions on List<ProfanityMatch> {
  /// Gets matches by type
  List<ProfanityMatch> byType(MatchType type) {
    return where((m) => m.type == type).toList();
  }

  /// Gets exact matches only
  List<ProfanityMatch> get exactMatches => byType(MatchType.exact);

  /// Gets all matches that are not false positives
  List<ProfanityMatch> get validMatches {
    return where((m) => !m.isFalsePositive).toList();
  }

  /// Gets matches within a time range
  List<ProfanityMatch> inTimeRange(Duration start, Duration end) {
    return where((m) => m.overlapsWithRange(start, end)).toList();
  }

  /// Gets unreviewed matches
  List<ProfanityMatch> get unreviewedMatches {
    return where((m) => !m.isReviewed).toList();
  }

  /// Gets high severity matches
  List<ProfanityMatch> get highSeverityMatches {
    return where((m) => m.isHighSeverity).toList();
  }

  /// Sorts by time
  List<ProfanityMatch> sortedByTime() {
    return [...this]..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Sorts by confidence (descending)
  List<ProfanityMatch> sortedByConfidence() {
    return [...this]..sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// Sorts by severity (descending)
  List<ProfanityMatch> sortedBySeverity() {
    return [...this]..sort((a, b) => b.severity.compareTo(a.severity));
  }
}
