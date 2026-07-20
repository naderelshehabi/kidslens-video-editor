import 'package:freezed_annotation/freezed_annotation.dart';

part 'modification.freezed.dart';
part 'modification.g.dart';

/// Normalized bounding box for region-based modifications
@freezed
class RegionBounds with _$RegionBounds {
  const factory RegionBounds({
    /// X coordinate of top-left corner (normalized 0-1)
    required double x,

    /// Y coordinate of top-left corner (normalized 0-1)
    required double y,

    /// Width of region (normalized 0-1)
    required double width,

    /// Height of region (normalized 0-1)
    required double height,
  }) = _RegionBounds;

  factory RegionBounds.fromJson(Map<String, dynamic> json) =>
      _$RegionBoundsFromJson(json);
}

/// Sealed class hierarchy representing modifications that can be applied to media
@freezed
sealed class Modification with _$Modification {
  const Modification._();

  // ============ Audio Modifications ============

  /// Mutes the audio track in the specified region
  const factory Modification.audioMute() = AudioMute;

  /// Replaces audio with a beep tone
  const factory Modification.audioBeep({
    /// Frequency of the beep in Hz (default: 1000)
    @Default(1000) int frequency,

    /// Volume level (0.0 to 1.0, default: 0.5)
    @Default(0.5) double volume,
  }) = AudioBeep;

  /// Replaces audio with a custom audio file
  const factory Modification.audioReplace({
    /// Path to the replacement audio file
    required String audioPath,

    /// Volume level (0.0 to 1.0, default: 1.0)
    @Default(1.0) double volume,

    /// Whether to loop the audio if it's shorter than the region
    @Default(false) bool loop,
  }) = AudioReplace;

  // ============ Video Modifications ============

  /// Applies Gaussian blur to the video region
  const factory Modification.videoBlur({
    /// Blur intensity (1-100, default: 20)
    @Default(20) int intensity,
  }) = VideoBlur;

  /// Applies pixelation/mosaic effect to the video region
  const factory Modification.videoPixelate({
    /// Size of pixelation blocks in pixels (default: 16)
    @Default(16) int blockSize,
  }) = VideoPixelate;

  /// Covers the video region with a solid black box
  const factory Modification.videoBlackBox({
    /// Optional color in hex format (default: black)
    @Default('#000000') String color,

    /// Opacity level (0.0 to 1.0, default: 1.0)
    @Default(1.0) double opacity,
  }) = VideoBlackBox;

  /// Skips the video region entirely (cuts it from the output)
  const factory Modification.videoSkip() = VideoSkip;

  // ============ Region-Based Video Modifications ============

  /// Applies Gaussian blur to a specific bounding box region
  const factory Modification.videoRegionBlur({
    /// Normalized bounding box for the region
    required RegionBounds region,

    /// Blur intensity (1-100, default: 50)
    @Default(50) int intensity,
  }) = VideoRegionBlur;

  /// Applies pixelation/mosaic effect to a specific bounding box region
  const factory Modification.videoRegionPixelate({
    /// Normalized bounding box for the region
    required RegionBounds region,

    /// Size of pixelation blocks in pixels (default: 10)
    @Default(10) int blockSize,
  }) = VideoRegionPixelate;

  /// Covers a specific bounding box region with a solid color
  const factory Modification.videoRegionBlackBox({
    /// Normalized bounding box for the region
    required RegionBounds region,

    /// Color in hex format (default: black)
    @Default('#000000') String color,

    /// Opacity level (0.0 to 1.0, default: 1.0)
    @Default(1.0) double opacity,
  }) = VideoRegionBlackBox;

  factory Modification.fromJson(Map<String, dynamic> json) =>
      _$ModificationFromJson(json);

  /// Whether this modification affects audio
  bool get isAudioModification => switch (this) {
        AudioMute() => true,
        AudioBeep() => true,
        AudioReplace() => true,
        VideoBlur() => false,
        VideoPixelate() => false,
        VideoBlackBox() => false,
        VideoSkip() => false,
        VideoRegionBlur() => false,
        VideoRegionPixelate() => false,
        VideoRegionBlackBox() => false,
      };

  /// Whether this modification affects video
  bool get isVideoModification => switch (this) {
        AudioMute() => false,
        AudioBeep() => false,
        AudioReplace() => false,
        VideoBlur() => true,
        VideoPixelate() => true,
        VideoBlackBox() => true,
        VideoSkip() => true,
        VideoRegionBlur() => true,
        VideoRegionPixelate() => true,
        VideoRegionBlackBox() => true,
      };

  /// Whether this modification removes content (vs replacing/obscuring)
  bool get isDestructive => switch (this) {
        AudioMute() => true,
        AudioBeep() => false,
        AudioReplace() => false,
        VideoBlur() => false,
        VideoPixelate() => false,
        VideoBlackBox() => false,
        VideoSkip() => true,
        VideoRegionBlur() => false,
        VideoRegionPixelate() => false,
        VideoRegionBlackBox() => false,
      };

  /// Whether this modification targets a specific region (vs full-frame)
  bool get isRegionModification => switch (this) {
        VideoRegionBlur() => true,
        VideoRegionPixelate() => true,
        VideoRegionBlackBox() => true,
        _ => false,
      };

  /// Human-readable display name for the modification
  String get displayName => switch (this) {
        AudioMute() => 'Mute Audio',
        AudioBeep(:final frequency) => 'Beep (${frequency}Hz)',
        AudioReplace() => 'Replace Audio',
        VideoBlur(:final intensity) => 'Blur ($intensity%)',
        VideoPixelate(:final blockSize) => 'Pixelate (${blockSize}px)',
        VideoBlackBox() => 'Black Box',
        VideoSkip() => 'Skip/Cut',
        VideoRegionBlur(:final intensity) => 'Region Blur ($intensity%)',
        VideoRegionPixelate(:final blockSize) =>
          'Region Pixelate (${blockSize}px)',
        VideoRegionBlackBox() => 'Region Black Box',
      };

  /// Short code for the modification type
  String get shortCode => switch (this) {
        AudioMute() => 'MUTE',
        AudioBeep() => 'BEEP',
        AudioReplace() => 'REPLACE',
        VideoBlur() => 'BLUR',
        VideoPixelate() => 'PIXEL',
        VideoBlackBox() => 'BBOX',
        VideoSkip() => 'SKIP',
        VideoRegionBlur() => 'RBLUR',
        VideoRegionPixelate() => 'RPIXEL',
        VideoRegionBlackBox() => 'RBBOX',
      };

  /// Icon name for the modification type
  String get iconName => switch (this) {
        AudioMute() => 'volume_off',
        AudioBeep() => 'music_note',
        AudioReplace() => 'swap_horiz',
        VideoBlur() => 'blur_on',
        VideoPixelate() => 'grid_on',
        VideoBlackBox() => 'crop_square',
        VideoSkip() => 'content_cut',
        VideoRegionBlur() => 'blur_on',
        VideoRegionPixelate() => 'grid_on',
        VideoRegionBlackBox() => 'crop_square',
      };

  /// FFmpeg filter string for this modification
  ///
  /// Note: Region-based modifications return empty strings here because they
  /// use a separate split→crop→effect→overlay filter chain built in
  /// [ExportService]. They are partitioned out before reaching the linear
  /// filter chain.
  String toFFmpegFilter() => switch (this) {
        AudioMute() => 'volume=0',
        AudioBeep(:final frequency, :final volume) =>
          'sine=frequency=$frequency:sample_rate=44100,volume=$volume',
        AudioReplace(:final audioPath, :final volume) =>
          'amovie=$audioPath,volume=$volume',
        VideoBlur(:final intensity) =>
          'boxblur=${intensity ~/ 5}:${intensity ~/ 5}',
        VideoPixelate(:final blockSize) =>
          'scale=iw/$blockSize:ih/$blockSize,scale=iw*$blockSize:ih*$blockSize:flags=neighbor',
        VideoBlackBox(:final color, :final opacity) =>
          'drawbox=color=${color.replaceFirst('#', '')}@$opacity:t=fill',
        VideoSkip() => 'select=0',
        VideoRegionBlur() => '',
        VideoRegionPixelate() => '',
        VideoRegionBlackBox() => '',
      };
}

/// Extension methods for working with lists of modifications
extension ModificationListExtensions on List<Modification> {
  /// Gets all audio modifications
  List<Modification> get audioModifications =>
      where((m) => m.isAudioModification).toList();

  /// Gets all video modifications
  List<Modification> get videoModifications =>
      where((m) => m.isVideoModification).toList();

  /// Gets all destructive modifications
  List<Modification> get destructiveModifications =>
      where((m) => m.isDestructive).toList();
}
