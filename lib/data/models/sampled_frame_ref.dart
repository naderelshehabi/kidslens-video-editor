import 'package:crypto/crypto.dart';
import 'package:kidslens_video_editor/data/models/converters.dart';

/// Metadata reference for a frame selected for analysis.
class SampledFrameRef {
  const SampledFrameRef({
    required this.id,
    required this.mediaId,
    required this.chunkId,
    required this.frameIndex,
    required this.timestamp,
    this.selectionReasons = const [],
    this.sourceFrameNumber,
    this.cachePath,
  });

  factory SampledFrameRef.fromJson(Map<String, dynamic> json) =>
      SampledFrameRef(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        chunkId: json['chunkId'] as String,
        frameIndex: (json['frameIndex'] as num).toInt(),
        timestamp: const DurationConverter().fromJson(
          (json['timestampMs'] as num).toInt(),
        ),
        selectionReasons:
            (json['selectionReasons'] as List<dynamic>? ?? const [])
                .map((value) => value as String)
                .toList(growable: false),
        sourceFrameNumber: (json['sourceFrameNumber'] as num?)?.toInt(),
        cachePath: json['cachePath'] as String?,
      );

  final String id;
  final String mediaId;
  final String chunkId;
  final int frameIndex;
  final Duration timestamp;
  final List<String> selectionReasons;
  final int? sourceFrameNumber;
  final String? cachePath;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'chunkId': chunkId,
        'frameIndex': frameIndex,
        'timestampMs': const DurationConverter().toJson(timestamp),
        'selectionReasons': selectionReasons,
        'sourceFrameNumber': sourceFrameNumber,
        'cachePath': cachePath,
      };

  static String deterministicId({
    required String mediaId,
    required String chunkId,
    required int frameIndex,
    required Duration timestamp,
  }) {
    final input = '$mediaId|$chunkId|$frameIndex|${timestamp.inMilliseconds}';
    return 'frame_${sha256.convert(input.codeUnits).toString().substring(0, 16)}';
  }
}
