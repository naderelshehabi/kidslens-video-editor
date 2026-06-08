import 'package:crypto/crypto.dart';
import 'package:kidslens_video_editor/data/models/converters.dart';

/// A deterministic time window used by chunked video analysis.
class VideoChunk {
  const VideoChunk({
    required this.id,
    required this.mediaId,
    required this.index,
    required this.startTime,
    required this.endTime,
    this.overlapBefore = Duration.zero,
    this.overlapAfter = Duration.zero,
    this.sceneChangeTimestamps = const [],
  });

  factory VideoChunk.fromJson(Map<String, dynamic> json) => VideoChunk(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        index: (json['index'] as num).toInt(),
        startTime: const DurationConverter().fromJson(
          (json['startTimeMs'] as num).toInt(),
        ),
        endTime: const DurationConverter().fromJson(
          (json['endTimeMs'] as num).toInt(),
        ),
        overlapBefore: const DurationConverter().fromJson(
          (json['overlapBeforeMs'] as num?)?.toInt() ?? 0,
        ),
        overlapAfter: const DurationConverter().fromJson(
          (json['overlapAfterMs'] as num?)?.toInt() ?? 0,
        ),
        sceneChangeTimestamps:
            (json['sceneChangeTimestampsMs'] as List<dynamic>? ?? const [])
                .map(
                  (value) => const DurationConverter().fromJson(
                    (value as num).toInt(),
                  ),
                )
                .toList(growable: false),
      );

  final String id;
  final String mediaId;
  final int index;
  final Duration startTime;
  final Duration endTime;
  final Duration overlapBefore;
  final Duration overlapAfter;
  final List<Duration> sceneChangeTimestamps;

  Duration get duration => endTime - startTime;

  bool contains(Duration timestamp) =>
      timestamp >= startTime && timestamp < endTime;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'index': index,
        'startTimeMs': const DurationConverter().toJson(startTime),
        'endTimeMs': const DurationConverter().toJson(endTime),
        'overlapBeforeMs': const DurationConverter().toJson(overlapBefore),
        'overlapAfterMs': const DurationConverter().toJson(overlapAfter),
        'sceneChangeTimestampsMs': sceneChangeTimestamps
            .map(const DurationConverter().toJson)
            .toList(growable: false),
      };

  static String deterministicId({
    required String mediaId,
    required int index,
    required Duration startTime,
    required Duration endTime,
  }) {
    final input =
        '$mediaId|$index|${startTime.inMilliseconds}|${endTime.inMilliseconds}';
    return 'chunk_${sha256.convert(input.codeUnits).toString().substring(0, 16)}';
  }
}
