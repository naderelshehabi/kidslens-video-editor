import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'frame_analysis_result.freezed.dart';
part 'frame_analysis_result.g.dart';

/// Result of NSFW classification for a frame
@freezed
class NsfwResult with _$NsfwResult {
  const NsfwResult._();

  const factory NsfwResult({
    /// Probability of pornographic content
    required double porn,

    /// Probability of sexy/suggestive content
    required double sexy,

    /// Probability of hentai/animated adult content
    required double hentai,

    /// Probability of drawings/illustrations (non-adult)
    required double drawings,

    /// Probability of neutral/safe content
    required double neutral,
  }) = _NsfwResult;

  factory NsfwResult.fromJson(Map<String, dynamic> json) =>
      _$NsfwResultFromJson(json);

  /// Creates a safe/neutral result
  factory NsfwResult.safe() {
    return const NsfwResult(
      porn: 0.0,
      sexy: 0.0,
      hentai: 0.0,
      drawings: 0.0,
      neutral: 1.0,
    );
  }

  /// Maximum NSFW score (highest of porn, sexy, hentai)
  double get maxNsfwScore => [porn, sexy, hentai].reduce((a, b) => a > b ? a : b);

  /// Whether this frame is considered NSFW at a given threshold
  bool isNsfwAtThreshold(double threshold) => maxNsfwScore >= threshold;

  /// Whether this frame is safe (neutral > 0.8 and maxNsfwScore < 0.2)
  bool get isSafe => neutral > 0.8 && maxNsfwScore < 0.2;

  /// Dominant category (the one with highest probability)
  String get dominantCategory {
    final scores = {
      'porn': porn,
      'sexy': sexy,
      'hentai': hentai,
      'drawings': drawings,
      'neutral': neutral,
    };
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// All non-neutral scores above threshold
  Map<String, double> getScoresAboveThreshold(double threshold) {
    final result = <String, double>{};
    if (porn >= threshold) result['porn'] = porn;
    if (sexy >= threshold) result['sexy'] = sexy;
    if (hentai >= threshold) result['hentai'] = hentai;
    return result;
  }
}

/// Result of violence classification for a frame
@freezed
class ViolenceResult with _$ViolenceResult {
  const ViolenceResult._();

  const factory ViolenceResult({
    /// Probability of violent content
    required double violent,

    /// Probability of non-violent content
    required double nonViolent,
  }) = _ViolenceResult;

  factory ViolenceResult.fromJson(Map<String, dynamic> json) =>
      _$ViolenceResultFromJson(json);

  /// Creates a non-violent result
  factory ViolenceResult.safe() {
    return const ViolenceResult(
      violent: 0.0,
      nonViolent: 1.0,
    );
  }

  /// Whether this frame is considered violent at a given threshold
  bool isViolentAtThreshold(double threshold) => violent >= threshold;

  /// Whether this frame is safe (nonViolent > 0.9)
  bool get isSafe => nonViolent > 0.9;
}

/// Result of blood/gore detection for a frame
@freezed
class BloodResult with _$BloodResult {
  const BloodResult._();

  const factory BloodResult({
    /// Probability of blood/gore presence
    required double score,

    /// Detected regions (optional, for bounding boxes)
    List<BloodRegion>? regions,
  }) = _BloodResult;

  factory BloodResult.fromJson(Map<String, dynamic> json) =>
      _$BloodResultFromJson(json);

  /// Creates a safe result with no blood detected
  factory BloodResult.safe() {
    return const BloodResult(score: 0.0);
  }

  /// Whether blood is detected at a given threshold
  bool isDetectedAtThreshold(double threshold) => score >= threshold;

  /// Whether this frame is safe (score < 0.1)
  bool get isSafe => score < 0.1;
}

/// Represents a detected blood region in a frame
@freezed
class BloodRegion with _$BloodRegion {
  const factory BloodRegion({
    /// X coordinate of top-left corner (normalized 0-1)
    required double x,

    /// Y coordinate of top-left corner (normalized 0-1)
    required double y,

    /// Width of region (normalized 0-1)
    required double width,

    /// Height of region (normalized 0-1)
    required double height,

    /// Confidence score for this region
    required double confidence,
  }) = _BloodRegion;

  factory BloodRegion.fromJson(Map<String, dynamic> json) =>
      _$BloodRegionFromJson(json);
}

/// Result of weapons detection for a frame
@freezed
class WeaponsResult with _$WeaponsResult {
  const WeaponsResult._();

  const factory WeaponsResult({
    /// Probability of weapon presence
    required double score,

    /// List of detected weapons
    List<DetectedWeapon>? weapons,
  }) = _WeaponsResult;

  factory WeaponsResult.fromJson(Map<String, dynamic> json) =>
      _$WeaponsResultFromJson(json);

  /// Creates a safe result with no weapons detected
  factory WeaponsResult.safe() {
    return const WeaponsResult(score: 0.0);
  }

  /// Whether weapons are detected at a given threshold
  bool isDetectedAtThreshold(double threshold) => score >= threshold;

  /// Whether this frame is safe (score < 0.1)
  bool get isSafe => score < 0.1;

  /// Number of weapons detected
  int get weaponCount => weapons?.length ?? 0;
}

/// Represents a detected weapon in a frame
@freezed
class DetectedWeapon with _$DetectedWeapon {
  const factory DetectedWeapon({
    /// Type of weapon (e.g., 'gun', 'knife', 'rifle')
    required String type,

    /// Confidence score
    required double confidence,

    /// Bounding box X (normalized 0-1)
    required double x,

    /// Bounding box Y (normalized 0-1)
    required double y,

    /// Bounding box width (normalized 0-1)
    required double width,

    /// Bounding box height (normalized 0-1)
    required double height,
  }) = _DetectedWeapon;

  factory DetectedWeapon.fromJson(Map<String, dynamic> json) =>
      _$DetectedWeaponFromJson(json);
}

/// Complete analysis result for a single video frame
@freezed
class FrameAnalysisResult with _$FrameAnalysisResult {
  const FrameAnalysisResult._();

  const factory FrameAnalysisResult({
    /// Frame number in the video
    required int frameNumber,

    /// Timestamp of the frame in the video
    @DurationConverter() required Duration timestamp,

    /// Whether this frame is a scene change
    @Default(false) bool isSceneChange,

    /// NSFW classification result
    required NsfwResult nsfw,

    /// Violence classification result
    required ViolenceResult violence,

    /// Blood/gore detection result (optional)
    BloodResult? blood,

    /// Weapons detection result (optional)
    WeaponsResult? weapons,

    /// Processing time for this frame in milliseconds
    int? processingTimeMs,

    /// Optional frame hash for deduplication
    String? frameHash,
  }) = _FrameAnalysisResult;

  factory FrameAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$FrameAnalysisResultFromJson(json);

  /// Creates a safe result with no detections
  factory FrameAnalysisResult.safe({
    required int frameNumber,
    required Duration timestamp,
    bool isSceneChange = false,
  }) {
    return FrameAnalysisResult(
      frameNumber: frameNumber,
      timestamp: timestamp,
      isSceneChange: isSceneChange,
      nsfw: NsfwResult.safe(),
      violence: ViolenceResult.safe(),
      blood: BloodResult.safe(),
      weapons: WeaponsResult.safe(),
    );
  }

  /// Whether this frame has any NSFW content at threshold
  bool hasNsfwAt(double threshold) => nsfw.isNsfwAtThreshold(threshold);

  /// Whether this frame has violence at threshold
  bool hasViolenceAt(double threshold) => violence.isViolentAtThreshold(threshold);

  /// Whether this frame has blood at threshold
  bool hasBloodAt(double threshold) =>
      blood?.isDetectedAtThreshold(threshold) ?? false;

  /// Whether this frame has weapons at threshold
  bool hasWeaponsAt(double threshold) =>
      weapons?.isDetectedAtThreshold(threshold) ?? false;

  /// Whether this frame is completely safe at given thresholds
  bool isSafeAt({
    double nsfwThreshold = 0.5,
    double violenceThreshold = 0.5,
    double bloodThreshold = 0.5,
    double weaponsThreshold = 0.5,
  }) {
    return !hasNsfwAt(nsfwThreshold) &&
        !hasViolenceAt(violenceThreshold) &&
        !hasBloodAt(bloodThreshold) &&
        !hasWeaponsAt(weaponsThreshold);
  }

  /// Gets all detection scores above threshold
  Map<String, double> getDetectionsAboveThreshold({
    double nsfwThreshold = 0.5,
    double violenceThreshold = 0.5,
    double bloodThreshold = 0.5,
    double weaponsThreshold = 0.5,
  }) {
    final result = <String, double>{};

    if (nsfw.maxNsfwScore >= nsfwThreshold) {
      result['nsfw'] = nsfw.maxNsfwScore;
    }
    if (violence.violent >= violenceThreshold) {
      result['violence'] = violence.violent;
    }
    if (blood != null && blood!.score >= bloodThreshold) {
      result['blood'] = blood!.score;
    }
    if (weapons != null && weapons!.score >= weaponsThreshold) {
      result['weapons'] = weapons!.score;
    }

    return result;
  }

  /// Maximum severity score across all detection types
  double get maxSeverityScore {
    final scores = [
      nsfw.maxNsfwScore,
      violence.violent,
      if (blood != null) blood!.score,
      if (weapons != null) weapons!.score,
    ];
    return scores.reduce((a, b) => a > b ? a : b);
  }
}

/// Extension for working with lists of frame analysis results
extension FrameAnalysisResultListExtensions on List<FrameAnalysisResult> {
  /// Gets all frames with NSFW content at threshold
  List<FrameAnalysisResult> withNsfwAt(double threshold) {
    return where((f) => f.hasNsfwAt(threshold)).toList();
  }

  /// Gets all frames with violence at threshold
  List<FrameAnalysisResult> withViolenceAt(double threshold) {
    return where((f) => f.hasViolenceAt(threshold)).toList();
  }

  /// Gets all frames with blood at threshold
  List<FrameAnalysisResult> withBloodAt(double threshold) {
    return where((f) => f.hasBloodAt(threshold)).toList();
  }

  /// Gets all frames with weapons at threshold
  List<FrameAnalysisResult> withWeaponsAt(double threshold) {
    return where((f) => f.hasWeaponsAt(threshold)).toList();
  }

  /// Gets all scene change frames
  List<FrameAnalysisResult> get sceneChanges {
    return where((f) => f.isSceneChange).toList();
  }

  /// Gets frames in a time range
  List<FrameAnalysisResult> inTimeRange(Duration start, Duration end) {
    return where((f) => f.timestamp >= start && f.timestamp < end).toList();
  }
}
