import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/converters.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';

part 'timeline.freezed.dart';
part 'timeline.g.dart';

/// Types of timeline tracks
@JsonEnum()
enum TrackType {
  /// Main audio track
  @JsonValue('audio')
  audio,

  /// Main video track
  @JsonValue('video')
  video,

  /// Detection markers track
  @JsonValue('detection')
  detection,

  /// Custom user-defined track
  @JsonValue('custom')
  custom,
}

/// Represents a segment on a timeline track
@freezed
class TimelineSegment with _$TimelineSegment {
  const factory TimelineSegment({
    /// Unique identifier for the segment
    required String id,

    /// Start time of the segment
    @DurationConverter() required Duration start,

    /// End time of the segment
    @DurationConverter() required Duration end,

    /// Type of content in this segment
    required ContentType type,

    /// Confidence score (0.0 to 1.0)
    required double confidence,

    /// Optional modification to apply to this segment
    Modification? modification,

    /// Whether this segment is selected in the UI
    @Default(false) bool isSelected,

    /// Whether this segment is locked from editing
    @Default(false) bool isLocked,

    /// Reference to the original detection ID if applicable
    String? detectionId,
  }) = _TimelineSegment;

  const TimelineSegment._();

  factory TimelineSegment.fromJson(Map<String, dynamic> json) =>
      _$TimelineSegmentFromJson(json);

  /// Creates a TimelineSegment from a Detection
  factory TimelineSegment.fromDetection(Detection detection, {Modification? modification}) =>
      TimelineSegment(
        id: 'seg_${detection.id}',
        start: detection.startTime,
        end: detection.endTime,
        type: detection.type,
        confidence: detection.confidence,
        modification: modification,
        detectionId: detection.id,
      );

  /// Duration of the segment
  Duration get duration => end - start;

  /// Whether this segment has a modification applied
  bool get hasModification => modification != null;

  /// Checks if this segment overlaps with a time range
  bool overlapsWithRange(Duration startTime, Duration endTime) =>
      start < endTime && end > startTime;

  /// Checks if this segment overlaps with another segment
  bool overlapsWith(TimelineSegment other) =>
      overlapsWithRange(other.start, other.end);

  /// Checks if a timestamp falls within this segment
  bool containsTime(Duration time) => time >= start && time < end;
}

/// Represents a track in the timeline
@freezed
class TimelineTrack with _$TimelineTrack {
  const factory TimelineTrack({
    /// Unique identifier for the track
    required String id,

    /// Type of track
    required TrackType type,

    /// Display name of the track
    required String name,

    /// Segments on this track
    required List<TimelineSegment> segments,

    /// Whether this track is visible
    @Default(true) bool isVisible,

    /// Whether this track is muted (for audio/video tracks)
    @Default(false) bool isMuted,

    /// Whether this track is locked from editing
    @Default(false) bool isLocked,

    /// Track height in pixels (for UI)
    @Default(40) int height,

    /// Track color in hex format
    String? color,
  }) = _TimelineTrack;

  const TimelineTrack._();

  factory TimelineTrack.fromJson(Map<String, dynamic> json) =>
      _$TimelineTrackFromJson(json);

  /// Creates an empty audio track
  factory TimelineTrack.audio({String? name}) => TimelineTrack(
        id: 'track_audio',
        type: TrackType.audio,
        name: name ?? 'Audio',
        segments: const [],
        color: '#4CAF50',
      );

  /// Creates an empty video track
  factory TimelineTrack.video({String? name}) => TimelineTrack(
        id: 'track_video',
        type: TrackType.video,
        name: name ?? 'Video',
        segments: const [],
        color: '#2196F3',
      );

  /// Creates an empty detection track
  factory TimelineTrack.detection({String? name}) => TimelineTrack(
        id: 'track_detection',
        type: TrackType.detection,
        name: name ?? 'Detections',
        segments: const [],
        color: '#FF5722',
      );

  /// Total number of segments
  int get segmentCount => segments.length;

  /// Whether this track has any segments
  bool get hasSegments => segments.isNotEmpty;

  /// Gets segments overlapping with a time range
  List<TimelineSegment> getSegmentsInRange(Duration start, Duration end) =>
      segments.where((s) => s.overlapsWithRange(start, end)).toList();

  /// Gets the segment at a specific time
  TimelineSegment? getSegmentAt(Duration time) {
    for (final segment in segments) {
      if (segment.containsTime(time)) {
        return segment;
      }
    }
    return null;
  }

  /// Gets all segments with modifications
  List<TimelineSegment> get modifiedSegments =>
      segments.where((s) => s.hasModification).toList();
}

/// Represents a conflict between overlapping segments or modifications
@freezed
class TimelineConflict with _$TimelineConflict {
  const factory TimelineConflict({
    /// First conflicting segment
    required TimelineSegment segment1,

    /// Second conflicting segment
    required TimelineSegment segment2,

    /// Type of conflict
    required ConflictType conflictType,

    /// Description of the conflict
    required String description,
  }) = _TimelineConflict;

  factory TimelineConflict.fromJson(Map<String, dynamic> json) =>
      _$TimelineConflictFromJson(json);
}

/// Types of timeline conflicts
@JsonEnum()
enum ConflictType {
  /// Segments overlap in time
  @JsonValue('overlap')
  overlap,

  /// Multiple modifications on same content
  @JsonValue('multipleModifications')
  multipleModifications,

  /// Conflicting modification types
  @JsonValue('incompatibleModifications')
  incompatibleModifications,
}

/// Unified timeline combining all tracks and detections
@freezed
class UnifiedTimeline with _$UnifiedTimeline {
  const factory UnifiedTimeline({
    /// Unique identifier for the timeline
    required String id,

    /// Total duration of the media
    @DurationConverter() required Duration mediaDuration,

    /// All tracks in the timeline
    required List<TimelineTrack> tracks,

    /// Timestamp when timeline was created
    DateTime? createdAt,

    /// Timestamp when timeline was last modified
    DateTime? modifiedAt,
  }) = _UnifiedTimeline;

  const UnifiedTimeline._();

  factory UnifiedTimeline.fromJson(Map<String, dynamic> json) =>
      _$UnifiedTimelineFromJson(json);

  /// Creates an empty timeline with default tracks
  factory UnifiedTimeline.empty({
    required Duration mediaDuration,
    String? id,
  }) =>
      UnifiedTimeline(
        id: id ?? 'timeline_${DateTime.now().millisecondsSinceEpoch}',
        mediaDuration: mediaDuration,
        tracks: [
          TimelineTrack.video(),
          TimelineTrack.audio(),
          TimelineTrack.detection(),
        ],
        createdAt: DateTime.now(),
      );

  /// Creates a timeline from a list of detections
  factory UnifiedTimeline.fromDetections({
    required Duration mediaDuration,
    required List<Detection> detections,
    String? id,
  }) {
    final audioSegments = <TimelineSegment>[];
    final videoSegments = <TimelineSegment>[];

    for (final detection in detections) {
      final segment = TimelineSegment.fromDetection(detection);
      if (detection.isAudioDetection) {
        audioSegments.add(segment);
      } else {
        videoSegments.add(segment);
      }
    }

    return UnifiedTimeline(
      id: id ?? 'timeline_${DateTime.now().millisecondsSinceEpoch}',
      mediaDuration: mediaDuration,
      tracks: [
        TimelineTrack.video().copyWith(segments: videoSegments),
        TimelineTrack.audio().copyWith(segments: audioSegments),
        TimelineTrack.detection(),
      ],
      createdAt: DateTime.now(),
    );
  }

  /// All detections derived from segments across all tracks
  List<Detection> get detections {
    final result = <Detection>[];
    for (final track in tracks) {
      for (final segment in track.segments) {
        if (segment.detectionId != null) {
          result.add(Detection(
            id: segment.detectionId!,
            mediaId: '', // mediaId not available in timeline context
            type: segment.type,
            startTime: segment.start,
            endTime: segment.end,
            confidence: segment.confidence,
            description: '${segment.type.name} detection',
          ),);
        }
      }
    }
    return result;
  }

  /// Gets the audio track
  TimelineTrack? get audioTrack =>
      tracks.where((t) => t.type == TrackType.audio).firstOrNull;

  /// Gets the video track
  TimelineTrack? get videoTrack =>
      tracks.where((t) => t.type == TrackType.video).firstOrNull;

  /// Gets the detection track
  TimelineTrack? get detectionTrack =>
      tracks.where((t) => t.type == TrackType.detection).firstOrNull;

  /// Gets all segments at a specific time across all tracks
  List<TimelineSegment> getSegmentsAt(Duration time) {
    final result = <TimelineSegment>[];
    for (final track in tracks) {
      final segment = track.getSegmentAt(time);
      if (segment != null) {
        result.add(segment);
      }
    }
    return result;
  }

  /// Gets all modifications at a specific time
  List<Modification> getModificationsAt(Duration time) => getSegmentsAt(time)
      .where((s) => s.modification != null)
      .map((s) => s.modification!)
      .toList();

  /// Gets all segments in a time range across all tracks
  List<TimelineSegment> getSegmentsInRange(Duration start, Duration end) =>
      tracks.expand((t) => t.getSegmentsInRange(start, end)).toList();

  /// Updates a detection by its ID
  UnifiedTimeline updateDetection(
    String detectionId, {
    Duration? newStart,
    Duration? newEnd,
    Modification? modification,
    bool? isSelected,
    bool? isLocked,
  }) {
    final newTracks = tracks.map((track) {
      final newSegments = track.segments.map((segment) {
        if (segment.detectionId == detectionId) {
          return segment.copyWith(
            start: newStart ?? segment.start,
            end: newEnd ?? segment.end,
            modification: modification ?? segment.modification,
            isSelected: isSelected ?? segment.isSelected,
            isLocked: isLocked ?? segment.isLocked,
          );
        }
        return segment;
      }).toList();
      return track.copyWith(segments: newSegments);
    }).toList();

    return copyWith(
      tracks: newTracks,
      modifiedAt: DateTime.now(),
    );
  }

  /// Adds a modification to a segment by ID
  UnifiedTimeline addModification(String segmentId, Modification modification) {
    final newTracks = tracks.map((track) {
      final newSegments = track.segments.map((segment) {
        if (segment.id == segmentId) {
          return segment.copyWith(modification: modification);
        }
        return segment;
      }).toList();
      return track.copyWith(segments: newSegments);
    }).toList();

    return copyWith(
      tracks: newTracks,
      modifiedAt: DateTime.now(),
    );
  }

  /// Removes a modification from a segment by ID
  UnifiedTimeline removeModification(String segmentId) {
    final newTracks = tracks.map((track) {
      final newSegments = track.segments.map((segment) {
        if (segment.id == segmentId) {
          return TimelineSegment(
            id: segment.id,
            start: segment.start,
            end: segment.end,
            type: segment.type,
            confidence: segment.confidence,
            isSelected: segment.isSelected,
            isLocked: segment.isLocked,
            detectionId: segment.detectionId,
          );
        }
        return segment;
      }).toList();
      return track.copyWith(segments: newSegments);
    }).toList();

    return copyWith(
      tracks: newTracks,
      modifiedAt: DateTime.now(),
    );
  }

  /// Finds conflicts between segments
  List<TimelineConflict> findConflicts() {
    final conflicts = <TimelineConflict>[];

    for (final track in tracks) {
      final segments = track.segments;
      for (var i = 0; i < segments.length; i++) {
        for (var j = i + 1; j < segments.length; j++) {
          final seg1 = segments[i];
          final seg2 = segments[j];

          if (seg1.overlapsWith(seg2)) {
            // Check for time overlap
            conflicts.add(TimelineConflict(
              segment1: seg1,
              segment2: seg2,
              conflictType: ConflictType.overlap,
              description: 'Segments overlap between ${_formatDuration(seg1.start)} and ${_formatDuration(seg2.end)}',
            ),);

            // Check for multiple modifications
            if (seg1.hasModification && seg2.hasModification) {
              conflicts.add(TimelineConflict(
                segment1: seg1,
                segment2: seg2,
                conflictType: ConflictType.multipleModifications,
                description: 'Multiple modifications applied to overlapping segments',
              ),);

              // Check for incompatible modifications
              final mod1 = seg1.modification!;
              final mod2 = seg2.modification!;
              if (mod1.isAudioModification != mod2.isAudioModification) {
                // This is actually allowed, no conflict
              } else if (mod1.isDestructive || mod2.isDestructive) {
                conflicts.add(TimelineConflict(
                  segment1: seg1,
                  segment2: seg2,
                  conflictType: ConflictType.incompatibleModifications,
                  description: 'Destructive modification conflicts with another modification',
                ),);
              }
            }
          }
        }
      }
    }

    return conflicts;
  }

  /// Total number of segments across all tracks
  int get totalSegmentCount =>
      tracks.fold(0, (sum, track) => sum + track.segmentCount);

  /// Total number of modifications applied
  int get totalModificationCount => tracks.fold(
        0,
        (sum, track) =>
            sum + track.segments.where((s) => s.hasModification).length,
      );

  /// Whether timeline has any conflicts
  bool get hasConflicts => findConflicts().isNotEmpty;

  /// Helper to format duration for display
  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final millis = d.inMilliseconds % 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }
}
