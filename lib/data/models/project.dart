import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kidslens_video_editor/data/models/converters.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/data/models/subtitle_track.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// Represents a KidsLens Editor project (.kle file)
@freezed
class Project with _$Project {
  const factory Project({
    /// Unique identifier for the project
    required String id,

    /// Project name (displayed in UI)
    required String name,

    /// Absolute path to the .kle project file
    required String projectPath,

    /// When the project was created
    @DateTimeConverter() required DateTime createdAt,

    /// When the project was last modified
    @DateTimeConverter() required DateTime modifiedAt,

    /// Media files imported into the project
    @Default([]) List<MediaFile> mediaFiles,

    /// Currently selected media file ID for editing
    String? selectedMediaId,

    /// All detections found during analysis
    @Default([]) List<Detection> detections,

    /// Edit actions applied to the project (cuts, blurs, mutes)
    @Default([]) List<EditAction> editActions,

    /// Subtitle tracks generated for media files
    @Default([]) List<SubtitleTrack> subtitleTracks,

    /// Project settings
    @Default(ProjectSettings()) ProjectSettings settings,

    /// Analysis progress (0.0 to 1.0, null if not started)
    double? analysisProgress,

    /// Whether analysis is complete
    @Default(false) bool analysisComplete,
    
    /// Track if project has unsaved changes
    @Default(false) @JsonKey(includeFromJson: false, includeToJson: false) bool isDirty,
  }) = _Project;

  const Project._();

  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  /// Create a new empty project
  factory Project.create({
    required String id,
    required String name,
    required String projectPath,
  }) {
    final now = DateTime.now();
    return Project(
      id: id,
      name: name,
      projectPath: projectPath,
      createdAt: now,
      modifiedAt: now,
    );
  }

  /// Get the currently selected media file
  MediaFile? get selectedMedia {
    if (selectedMediaId == null) return null;
    return mediaFiles.where((m) => m.id == selectedMediaId).firstOrNull;
  }

  /// Get detections for a specific media file
  List<Detection> detectionsForMedia(String mediaId) =>
      detections.where((d) => d.mediaId == mediaId).toList();

  /// Get edit actions for a specific media file
  List<EditAction> editActionsForMedia(String mediaId) =>
      editActions.where((e) => e.mediaId == mediaId).toList();

  /// Get subtitle track for a specific media file
  SubtitleTrack? subtitleTrackForMedia(String mediaId) =>
      subtitleTracks.where((s) => s.mediaId == mediaId).firstOrNull;

  /// Check if project has any subtitle tracks
  bool get hasSubtitles => subtitleTracks.isNotEmpty;

  /// Check if project has unsaved changes
  bool get hasUnsavedChanges => isDirty;
}

/// Project-level settings
@freezed
class ProjectSettings with _$ProjectSettings {
  const factory ProjectSettings({
    /// Output quality preset
    @Default(OutputQuality.high) OutputQuality outputQuality,

    /// Whether to include original audio in export
    @Default(true) bool includeOriginalAudio,

    /// Whether to auto-save project changes
    @Default(true) bool autoSave,

    /// Auto-save interval in seconds
    @Default(60) int autoSaveIntervalSeconds,

    /// Detection sensitivity (0.0 to 1.0)
    @Default(0.7) double detectionSensitivity,

    /// Categories to detect
    @Default(DetectionCategories()) DetectionCategories detectionCategories,
  }) = _ProjectSettings;

  factory ProjectSettings.fromJson(Map<String, dynamic> json) =>
      _$ProjectSettingsFromJson(json);
}

/// Categories of content to detect
@freezed
class DetectionCategories with _$DetectionCategories {
  const factory DetectionCategories({
    @Default(true) bool profanity,
    @Default(true) bool nudity,
    @Default(true) bool violence,
    @Default(true) bool drugs,
    @Default(true) bool alcohol,
    @Default(false) bool customWords,
    @Default([]) List<String> customWordList,
  }) = _DetectionCategories;

  factory DetectionCategories.fromJson(Map<String, dynamic> json) =>
      _$DetectionCategoriesFromJson(json);
}

/// Output quality presets
@JsonEnum()
enum OutputQuality {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high,
  @JsonValue('original')
  original,
}
