import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/converters.dart';

part 'frame_data.freezed.dart';
part 'frame_data.g.dart';

/// Format of frame pixel data
@JsonEnum()
enum FrameFormat {
  /// RGB 24-bit (8 bits per channel)
  @JsonValue('rgb24')
  rgb24,

  /// RGBA 32-bit (8 bits per channel with alpha)
  @JsonValue('rgba32')
  rgba32,

  /// BGR 24-bit (OpenCV default format)
  @JsonValue('bgr24')
  bgr24,

  /// BGRA 32-bit
  @JsonValue('bgra32')
  bgra32,

  /// Grayscale 8-bit
  @JsonValue('gray8')
  gray8,

  /// YUV 4:2:0 planar
  @JsonValue('yuv420p')
  yuv420p,

  /// NV12 semi-planar (common hardware decoder output)
  @JsonValue('nv12')
  nv12,
}

/// Converter for Uint8List to/from JSON (stored as base64)
class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(String json) => Uint8List.fromList(
        List<int>.from(json.codeUnits),
      );

  @override
  String toJson(Uint8List object) => String.fromCharCodes(object);
}

/// Represents a single video frame with its pixel data
@freezed
class FrameData with _$FrameData {
  const factory FrameData({
    /// Timestamp of the frame relative to video start
    @DurationConverter() required Duration timestamp,

    /// Frame width in pixels
    required int width,

    /// Frame height in pixels
    required int height,

    /// Raw pixel data
    @Uint8ListConverter() required Uint8List data,

    /// Pixel format of the data
    @Default(FrameFormat.rgb24) FrameFormat format,

    /// Frame number in the video sequence
    int? frameNumber,

    /// Whether this is a keyframe
    @Default(false) bool isKeyframe,

    /// Presentation timestamp (PTS) from decoder
    int? pts,

    /// Scene change score (0.0 to 1.0, higher = more likely scene change)
    double? sceneChangeScore,

    /// Average luminance of the frame (for exposure detection)
    double? averageLuminance,

    /// Motion score compared to previous frame (0.0 = static, 1.0 = max motion)
    double? motionScore,
  }) = _FrameData;

  const FrameData._();

  factory FrameData.fromJson(Map<String, dynamic> json) =>
      _$FrameDataFromJson(json);

  /// Number of bytes per pixel based on format
  int get bytesPerPixel {
    switch (format) {
      case FrameFormat.rgb24:
      case FrameFormat.bgr24:
        return 3;
      case FrameFormat.rgba32:
      case FrameFormat.bgra32:
        return 4;
      case FrameFormat.gray8:
        return 1;
      case FrameFormat.yuv420p:
      case FrameFormat.nv12:
        return 1; // Per Y plane, UV is subsampled
    }
  }

  /// Expected size of the data buffer in bytes
  int get expectedDataSize {
    switch (format) {
      case FrameFormat.rgb24:
      case FrameFormat.bgr24:
        return width * height * 3;
      case FrameFormat.rgba32:
      case FrameFormat.bgra32:
        return width * height * 4;
      case FrameFormat.gray8:
        return width * height;
      case FrameFormat.yuv420p:
      case FrameFormat.nv12:
        return (width * height * 3) ~/ 2; // Y + UV subsampled
    }
  }

  /// Validates that data size matches expected size
  bool get isValid => data.length == expectedDataSize;

  /// Aspect ratio of the frame
  double get aspectRatio => width / height;

  /// Total number of pixels
  int get pixelCount => width * height;

  /// Whether this frame likely represents a scene change
  bool get isSceneChange => (sceneChangeScore ?? 0) > 0.5;

  /// Whether this frame is very dark (potential issue)
  bool get isVeryDark => (averageLuminance ?? 0.5) < 0.1;

  /// Whether this frame is very bright (potential issue)
  bool get isVeryBright => (averageLuminance ?? 0.5) > 0.9;

  /// Creates a resized copy descriptor (doesn't actually resize)
  FrameData resizedDescriptor(int newWidth, int newHeight) => copyWith(
        width: newWidth,
        height: newHeight,
        data:
            Uint8List(0), // Placeholder - actual resize needs image processing
      );
}

/// Batch of frames for efficient processing
@freezed
class FrameBatch with _$FrameBatch {
  const factory FrameBatch({
    /// List of frames in this batch
    required List<FrameData> frames,

    /// Batch index for tracking progress
    @Default(0) int batchIndex,

    /// Total number of batches (if known)
    int? totalBatches,
  }) = _FrameBatch;

  const FrameBatch._();

  factory FrameBatch.fromJson(Map<String, dynamic> json) =>
      _$FrameBatchFromJson(json);

  /// Number of frames in this batch
  int get count => frames.length;

  /// Whether this batch is empty
  bool get isEmpty => frames.isEmpty;

  /// First timestamp in the batch
  Duration? get startTime => frames.isEmpty ? null : frames.first.timestamp;

  /// Last timestamp in the batch
  Duration? get endTime => frames.isEmpty ? null : frames.last.timestamp;

  /// Duration covered by this batch
  Duration? get duration {
    if (startTime == null || endTime == null) return null;
    return endTime! - startTime!;
  }
}
