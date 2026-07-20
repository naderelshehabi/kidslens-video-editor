import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/converters.dart';

part 'frame_analysis_result.freezed.dart';
part 'frame_analysis_result.g.dart';

/// Result of NSFW classification for a frame
@freezed
class NsfwResult with _$NsfwResult {
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

  const NsfwResult._();

  factory NsfwResult.fromJson(Map<String, dynamic> json) =>
      _$NsfwResultFromJson(json);

  /// Creates a safe/neutral result
  factory NsfwResult.safe() => const NsfwResult(
        porn: 0,
        sexy: 0,
        hentai: 0,
        drawings: 0,
        neutral: 1,
      );

  /// Maximum NSFW score (highest of porn, sexy, hentai)
  double get maxNsfwScore =>
      [porn, sexy, hentai].reduce((a, b) => a > b ? a : b);

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
  const factory ViolenceResult({
    /// Probability of violent content
    required double violent,

    /// Probability of non-violent content
    required double nonViolent,
  }) = _ViolenceResult;

  const ViolenceResult._();

  factory ViolenceResult.fromJson(Map<String, dynamic> json) =>
      _$ViolenceResultFromJson(json);

  /// Creates a non-violent result
  factory ViolenceResult.safe() => const ViolenceResult(
        violent: 0,
        nonViolent: 1,
      );

  /// Whether this frame is considered violent at a given threshold
  bool isViolentAtThreshold(double threshold) => violent >= threshold;

  /// Whether this frame is safe (nonViolent > 0.9)
  bool get isSafe => nonViolent > 0.9;
}

/// Result of blood/gore detection for a frame
@freezed
class BloodResult with _$BloodResult {
  const factory BloodResult({
    /// Probability of blood/gore presence
    required double score,

    /// Detected regions (optional, for bounding boxes)
    List<BloodRegion>? regions,
  }) = _BloodResult;

  const BloodResult._();

  factory BloodResult.fromJson(Map<String, dynamic> json) =>
      _$BloodResultFromJson(json);

  /// Creates a safe result with no blood detected
  factory BloodResult.safe() => const BloodResult(score: 0);

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
  const factory WeaponsResult({
    /// Probability of weapon presence
    required double score,

    /// List of detected weapons
    List<DetectedWeapon>? weapons,
  }) = _WeaponsResult;

  const WeaponsResult._();

  factory WeaponsResult.fromJson(Map<String, dynamic> json) =>
      _$WeaponsResultFromJson(json);

  /// Creates a safe result with no weapons detected
  factory WeaponsResult.safe() => const WeaponsResult(score: 0);

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

/// Represents a detected region from NudeNet (raw model output)
@freezed
class DetectedRegion with _$DetectedRegion {
  const factory DetectedRegion({
    /// Raw model label (e.g. 'FEMALE_BREAST_EXPOSED')
    required String label,

    /// Detection confidence score (0-1)
    required double confidence,

    /// X coordinate of top-left corner (normalized 0-1)
    required double x,

    /// Y coordinate of top-left corner (normalized 0-1)
    required double y,

    /// Width of region (normalized 0-1)
    required double width,

    /// Height of region (normalized 0-1)
    required double height,
  }) = _DetectedRegion;

  factory DetectedRegion.fromJson(Map<String, dynamic> json) =>
      _$DetectedRegionFromJson(json);
}

/// Visual content detection result combining NudeNet regions and CLIP scores
@freezed
class VisualContentResult with _$VisualContentResult {
  const factory VisualContentResult({
    /// Detected regions from NudeNet (bounding boxes)
    @Default([]) List<DetectedRegion> detectedRegions,

    /// CLIP temperature-scaled discriminative scores per category ID
    @Default({}) Map<String, double> clipScores,
  }) = _VisualContentResult;

  const VisualContentResult._();

  factory VisualContentResult.fromJson(Map<String, dynamic> json) =>
      _$VisualContentResultFromJson(json);

  /// Creates a safe result with no detections
  factory VisualContentResult.safe() => const VisualContentResult();

  /// Whether any NudeNet regions were detected
  bool get hasRegions => detectedRegions.isNotEmpty;

  /// Whether any CLIP categories triggered
  bool get hasClipDetections => clipScores.isNotEmpty;

  /// Whether any visual content was detected
  bool get hasAnyDetections => hasRegions || hasClipDetections;

  /// Get regions matching a specific label
  List<DetectedRegion> regionsForLabel(String label) =>
      detectedRegions.where((r) => r.label == label).toList();

  /// Get regions above a confidence threshold
  List<DetectedRegion> regionsAboveThreshold(double threshold) =>
      detectedRegions.where((r) => r.confidence >= threshold).toList();

  /// Get CLIP score for a category, or null if not present
  double? clipScoreForCategory(String categoryId) => clipScores[categoryId];

  /// Whether a CLIP category exceeds its threshold
  bool clipCategoryExceedsThreshold(String categoryId, double threshold) =>
      (clipScores[categoryId] ?? double.negativeInfinity) >= threshold;
}

/// Complete analysis result for a single video frame
@freezed
class FrameAnalysisResult with _$FrameAnalysisResult {
  const factory FrameAnalysisResult({
    /// Frame number in the video
    required int frameNumber,

    /// Timestamp of the frame in the video
    @DurationConverter() required Duration timestamp,

    /// NSFW classification result
    required NsfwResult nsfw,

    /// Violence classification result
    required ViolenceResult violence,

    /// Whether this frame is a scene change
    @Default(false) bool isSceneChange,

    /// Blood/gore detection result (optional)
    BloodResult? blood,

    /// Weapons detection result (optional)
    WeaponsResult? weapons,

    /// Visual content detection result (NudeNet + CLIP)
    VisualContentResult? visualContent,

    /// Processing time for this frame in milliseconds
    int? processingTimeMs,

    /// Optional frame hash for deduplication
    String? frameHash,
  }) = _FrameAnalysisResult;

  const FrameAnalysisResult._();

  factory FrameAnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$FrameAnalysisResultFromJson(json);

  /// Creates a safe result with no detections
  factory FrameAnalysisResult.safe({
    required int frameNumber,
    required Duration timestamp,
    bool isSceneChange = false,
  }) =>
      FrameAnalysisResult(
        frameNumber: frameNumber,
        timestamp: timestamp,
        isSceneChange: isSceneChange,
        nsfw: NsfwResult.safe(),
        violence: ViolenceResult.safe(),
        blood: BloodResult.safe(),
        weapons: WeaponsResult.safe(),
        visualContent: VisualContentResult.safe(),
      );

  /// Whether this frame has any NSFW content at threshold
  bool hasNsfwAt(double threshold) => nsfw.isNsfwAtThreshold(threshold);

  /// Whether this frame has violence at threshold
  bool hasViolenceAt(double threshold) =>
      violence.isViolentAtThreshold(threshold);

  /// Whether this frame has blood at threshold
  bool hasBloodAt(double threshold) =>
      blood?.isDetectedAtThreshold(threshold) ?? false;

  /// Whether this frame has weapons at threshold
  bool hasWeaponsAt(double threshold) =>
      weapons?.isDetectedAtThreshold(threshold) ?? false;

  /// Whether this frame has visual content detections
  bool get hasVisualContentDetections =>
      visualContent?.hasAnyDetections ?? false;

  /// Whether this frame is completely safe at given thresholds
  bool isSafeAt({
    double nsfwThreshold = 0.5,
    double violenceThreshold = 0.5,
    double bloodThreshold = 0.5,
    double weaponsThreshold = 0.5,
  }) =>
      !hasNsfwAt(nsfwThreshold) &&
      !hasViolenceAt(violenceThreshold) &&
      !hasBloodAt(bloodThreshold) &&
      !hasWeaponsAt(weaponsThreshold);

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
  List<FrameAnalysisResult> withNsfwAt(double threshold) =>
      where((f) => f.hasNsfwAt(threshold)).toList();

  /// Gets all frames with violence at threshold
  List<FrameAnalysisResult> withViolenceAt(double threshold) =>
      where((f) => f.hasViolenceAt(threshold)).toList();

  /// Gets all frames with blood at threshold
  List<FrameAnalysisResult> withBloodAt(double threshold) =>
      where((f) => f.hasBloodAt(threshold)).toList();

  /// Gets all frames with weapons at threshold
  List<FrameAnalysisResult> withWeaponsAt(double threshold) =>
      where((f) => f.hasWeaponsAt(threshold)).toList();

  /// Gets all scene change frames
  List<FrameAnalysisResult> get sceneChanges =>
      where((f) => f.isSceneChange).toList();

  /// Gets frames in a time range
  List<FrameAnalysisResult> inTimeRange(Duration start, Duration end) =>
      where((f) => f.timestamp >= start && f.timestamp < end).toList();
}
