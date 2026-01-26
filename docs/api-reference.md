# KidsLens Video Editor - API Reference

This document provides comprehensive API documentation for all public classes, providers, services, and models in the KidsLens Video Editor.

## Table of Contents

- [Provider API](#provider-api)
- [Service API](#service-api)
- [Model Schemas](#model-schemas)
- [Native Bindings API](#native-bindings-api)
- [Exception Types](#exception-types)

---

## Provider API

All providers are defined in `lib/state/providers/` and use Riverpod with code generation.

### MediaNotifier

Manages the current media file and recent files list.

**Provider:** `mediaNotifierProvider`

**State Class:**
```dart
class MediaState {
  final MediaFile? currentMedia;    // Currently loaded media
  final bool isLoading;              // Loading indicator
  final String? errorMessage;        // Error message if any
  final List<MediaFile> recentFiles; // Recently opened files
}
```

**Methods:**

| Method | Parameters | Description |
|--------|------------|-------------|
| `importMedia` | `String path` | Import media file from path |
| `setCurrentMedia` | `MediaFile media` | Set the current media file |
| `clearMedia` | - | Clear current media |
| `clearError` | - | Dismiss error message |

**Example:**
```dart
// Import a video file
await ref.read(mediaNotifierProvider.notifier).importMedia('/path/to/video.mp4');

// Get current media
final media = ref.watch(mediaNotifierProvider).currentMedia;
```

---

### AnalysisNotifier

Manages content analysis state and progress.

**Provider:** `analysisNotifierProvider`

**State Class:**
```dart
class AnalysisState {
  final AnalysisStatus status;           // Current analysis status
  final double progress;                  // Progress 0.0 - 1.0
  final String? currentStep;              // Current step name
  final int? estimatedSecondsRemaining;   // ETA in seconds
  final AnalysisResult? result;           // Analysis result
  final String? errorMessage;             // Error if failed
  final bool isPaused;                    // Whether paused
}
```

**Analysis Status Enum:**
```dart
enum AnalysisStatus {
  pending,    // Not started
  running,    // In progress
  paused,     // Paused by user
  completed,  // Successfully completed
  failed,     // Failed with error
  cancelled,  // Cancelled by user
}
```

**Methods:**

| Method | Parameters | Description |
|--------|------------|-------------|
| `startAnalysis` | `String mediaPath, AnalysisSettings settings` | Start content analysis |
| `updateProgress` | `AnalysisProgress progress` | Update progress state |
| `pause` | - | Pause running analysis |
| `resume` | - | Resume paused analysis |
| `cancel` | - | Cancel running analysis |
| `reset` | - | Reset to initial state |

**Example:**
```dart
// Start analysis with default settings
await ref.read(analysisNotifierProvider.notifier).startAnalysis(
  mediaPath: '/path/to/video.mp4',
  settings: AnalysisSettings.defaults(),
);

// Watch progress
final state = ref.watch(analysisNotifierProvider);
print('Progress: ${(state.progress * 100).toInt()}%');
```

---

### TimelineNotifier

Manages the unified timeline state for detection visualization and editing.

**Provider:** `timelineNotifierProvider`

**State Class:**
```dart
class TimelineState {
  final UnifiedTimeline? timeline;           // The timeline data
  final Set<String> selectedDetectionIds;    // Selected detection IDs
  final Duration playheadPosition;           // Current playhead position
  final double zoomLevel;                    // Timeline zoom level
  final bool isPlaying;                      // Playback state
}
```

**Methods:**

| Method | Parameters | Description |
|--------|------------|-------------|
| `setTimeline` | `UnifiedTimeline timeline` | Set the timeline |
| `selectDetection` | `String detectionId` | Select a detection |
| `deselectDetection` | `String detectionId` | Deselect a detection |
| `clearSelection` | - | Clear all selections |
| `confirmDetection` | `String detectionId` | Confirm detection as valid |
| `rejectDetection` | `String detectionId` | Reject detection as false positive |
| `setModification` | `String segmentId, Modification mod` | Apply modification |
| `updatePlayhead` | `Duration position` | Update playhead position |
| `setZoom` | `double level` | Set zoom level |
| `setPlaying` | `bool isPlaying` | Set playback state |

---

### SettingsNotifier

Manages application and analysis settings.

**Provider:** `settingsNotifierProvider`

**State Class:**
```dart
class SettingsState {
  final AnalysisSettings analysisSettings;  // Detection settings
  final String? selectedLanguage;            // UI language
  final bool useDarkTheme;                   // Theme preference
  final bool showOnboarding;                 // Show onboarding
  final String? modelCachePath;              // Model storage path
  final String? exportPath;                  // Default export path
}
```

**Methods:**

| Method | Parameters | Description |
|--------|------------|-------------|
| `updateAnalysisSettings` | `AnalysisSettings settings` | Update analysis config |
| `setLanguage` | `String language` | Set UI language |
| `setDarkTheme` | `bool useDark` | Set theme mode |
| `setOnboardingComplete` | - | Mark onboarding complete |
| `setModelCachePath` | `String path` | Set model cache location |
| `setExportPath` | `String path` | Set default export location |
| `resetToDefaults` | - | Reset all settings |

---

### ModelNotifier

Manages AI model downloads and selection.

**Provider:** `modelNotifierProvider`

**State Class:**
```dart
class ModelState {
  final List<ModelInfo> availableModels;    // All available models
  final Set<String> downloadedModels;       // Downloaded model IDs
  final Map<String, double> downloadProgress; // Download progress by ID
  final String? selectedAsrModel;            // Selected ASR model
  final String? selectedVisualModel;         // Selected visual model
  final String? errorMessage;                // Error message
}
```

**Methods:**

| Method | Parameters | Description |
|--------|------------|-------------|
| `loadAvailableModels` | - | Fetch available models list |
| `downloadModel` | `String modelId` | Download a model |
| `cancelDownload` | `String modelId` | Cancel ongoing download |
| `deleteModel` | `String modelId` | Delete downloaded model |
| `selectAsrModel` | `String modelId` | Select ASR model |
| `selectVisualModel` | `String modelId` | Select visual model |

---

### Derived Providers

Computed providers that derive state from notifiers.

**Location:** `lib/state/providers/derived_providers.dart`

| Provider | Return Type | Description |
|----------|-------------|-------------|
| `pendingDetectionsProvider` | `List<Detection>` | Detections awaiting review |
| `detectionCountsProvider` | `Map<ContentType, int>` | Count by detection type |
| `canStartAnalysisProvider` | `bool` | Whether analysis can start |
| `canStartExportProvider` | `bool` | Whether export can start |
| `totalModelDiskUsageProvider` | `int` | Total model disk usage in bytes |
| `detectionSummaryProvider` | `DetectionSummary` | Aggregated detection stats |

---

## Service API

Services are located in `lib/services/` and contain business logic.

### MediaService

Handles media file operations.

**Constructor:**
```dart
MediaService(FFmpegBindings ffmpeg)
```

**Methods:**

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `importMedia` | `String path` | `Future<MediaFile>` | Import media and extract metadata |
| `extractAudio` | `String videoPath, String outputPath` | `Future<String>` | Extract audio track |
| `extractFrames` | `String videoPath, {double fps, int? startFrame, int? endFrame}` | `Stream<FrameData>` | Stream video frames |
| `generateThumbnail` | `String videoPath, String outputPath` | `Future<String>` | Generate video thumbnail |
| `getDuration` | `String path` | `Future<Duration>` | Get media duration |

**FrameData Class:**
```dart
class FrameData {
  final int frameNumber;
  final Duration timestamp;
  final List<int> rgbData;
  final int width;
  final int height;
}
```

---

### AnalysisService

Orchestrates content analysis pipeline.

**Constructor:**
```dart
AnalysisService({
  required FFmpegBindings ffmpeg,
  required WhisperBindings whisper,
  required MMSBindings mms,
  required ONNXBindings onnx,
  required ModelManagerService modelManager,
  required ProfanityService profanity,
})
```

**Methods:**

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `analyze` | `String mediaPath, AnalysisSettings settings, {AnalysisCheckpoint? checkpoint}` | `Stream<AnalysisProgress>` | Run complete analysis |

**AnalysisProgress Class:**
```dart
class AnalysisProgress {
  final String stepName;              // Current step name
  final int currentStep;              // Current step number (1-based)
  final int totalSteps;               // Total number of steps
  final double stepProgress;          // Progress within current step (0-1)
  final int? itemsProcessed;          // Items processed in step
  final int? totalItems;              // Total items in step
  final int? estimatedSecondsRemaining;

  double get overallProgress => 
      (currentStep - 1 + stepProgress) / totalSteps;
}
```

**AnalysisCheckpoint Class:**
```dart
class AnalysisCheckpoint {
  final Transcript? transcript;
  final List<ProfanityMatch>? profanityMatches;
  final int lastAnalyzedFrame;
  final DateTime timestamp;
}
```

---

### ExportService

Applies modifications and exports media.

**Constructor:**
```dart
ExportService({
  required FFmpegBindings ffmpeg,
  required MediaService mediaService,
})
```

**Methods:**

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `export` | `{String inputPath, String outputPath, UnifiedTimeline timeline, ExportSettings settings}` | `Stream<ExportProgress>` | Export with modifications |

**ExportProgress Class:**
```dart
class ExportProgress {
  final double progress;       // Overall progress 0-1
  final String phase;          // Current phase name
  final int? encodedFrames;    // Frames encoded so far
}
```

**ExportSettings Class:**
```dart
class ExportSettings {
  final String? videoCodec;    // Output video codec
  final String? audioCodec;    // Output audio codec
  final int? videoBitrate;     // Video bitrate in kbps
  final int? audioBitrate;     // Audio bitrate in kbps
  final String? container;     // Output container format
}
```

---

### ProfanityService

Detects profanity in transcripts.

**Methods:**

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `loadWordList` | `String language` | `Future<void>` | Load profanity word list |
| `addCustomWords` | `List<String> words` | `void` | Add custom bad words |
| `excludeWords` | `List<String> words` | `void` | Exclude words from detection |
| `detect` | `Transcript transcript` | `List<ProfanityMatch>` | Detect profanity in transcript |

**Detection Capabilities:**
- Exact word matching
- Leetspeak variations (e.g., "h4te" → "hate")
- Phonetic matching
- Custom word lists
- Exclusion lists

---

### ModelManagerService

Manages AI model downloads and storage.

**Methods:**

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `modelsDirectory` | - | `Future<String>` | Get models cache directory |
| `getAvailableModels` | - | `Future<List<ModelInfo>>` | Get available models list |
| `getDownloadedModels` | - | `Future<Set<String>>` | Get downloaded model IDs |
| `downloadModel` | `String modelId` | `Stream<ModelDownloadProgress>` | Download a model |
| `getModelPath` | `String modelId` | `Future<String?>` | Get path to downloaded model |
| `deleteModel` | `String modelId` | `Future<void>` | Delete a downloaded model |
| `validateModel` | `String modelPath` | `Future<bool>` | Validate model integrity |

**ModelDownloadProgress Class:**
```dart
class ModelDownloadProgress {
  final String modelId;
  final double percentage;     // 0.0 - 1.0
  final int downloadedBytes;
  final int totalBytes;
  
  bool get isComplete => percentage >= 1.0;
}
```

---

### SampleAnalysisService

Provides quick 5-second sample analysis.

**Constructor:**
```dart
SampleAnalysisService({
  required AnalysisService analysisService,
  required MediaService mediaService,
})
```

**Methods:**

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `analyzeSample` | `String mediaPath, Duration startPosition, AnalysisSettings settings` | `Stream<SampleAnalysisProgress>` | Analyze 5-second sample |

---

## Model Schemas

Data models are located in `lib/data/models/` and use Freezed.

### MediaFile

```dart
@freezed
class MediaFile with _$MediaFile {
  const factory MediaFile({
    required String id,           // Unique identifier
    required String path,         // Absolute file path
    required String name,         // Display name
    @DurationConverter() required Duration duration,
    required int width,           // Video width (0 for audio)
    required int height,          // Video height (0 for audio)
    required int fileSize,        // File size in bytes
    String? codec,                // Encoding codec
    String? container,            // Container format
    required MediaType mediaType, // video or audio
  }) = _MediaFile;
  
  // Computed properties
  bool get isVideo;
  bool get isAudio;
  double get aspectRatio;
  String get fileSizeFormatted;
  Future<String> computeHash();
}

enum MediaType { video, audio }
```

---

### Transcript

```dart
@freezed
class Transcript with _$Transcript {
  const factory Transcript({
    required List<TranscriptSegment> segments,
    required String language,     // ISO language code
    String? modelId,              // ASR model used
  }) = _Transcript;
}

@freezed
class TranscriptSegment with _$TranscriptSegment {
  const factory TranscriptSegment({
    required String id,
    @DurationConverter() required Duration startTime,
    @DurationConverter() required Duration endTime,
    required String text,
    required List<TranscriptWord> words,
  }) = _TranscriptSegment;
  
  Duration get duration;
  double get averageConfidence;
  int get wordCount;
}

@freezed
class TranscriptWord with _$TranscriptWord {
  const factory TranscriptWord({
    required String word,
    @DurationConverter() required Duration startTime,
    @DurationConverter() required Duration endTime,
    required double confidence,   // 0.0 - 1.0
  }) = _TranscriptWord;
}
```

---

### Detection

```dart
@freezed
class Detection with _$Detection {
  const factory Detection({
    required String id,
    required ContentType type,
    @DurationConverter() required Duration startTime,
    @DurationConverter() required Duration endTime,
    required double confidence,
    required String description,
    @Default(DetectionUserStatus.pending) DetectionUserStatus userStatus,
    String? userNote,
    @DurationConverter() Duration? originalStartTime,
    @DurationConverter() Duration? originalEndTime,
    String? source,               // 'asr', 'visual', 'manual'
    Map<String, dynamic>? metadata,
  }) = _Detection;
  
  // Factory constructors
  factory Detection.profanity({...});
  factory Detection.visual({...});
  
  // Computed properties
  Duration get duration;
  bool get isReviewed;
  bool get isConfirmed;
  bool get isRejected;
  bool get isAdjusted;
}

enum ContentType { nsfw, violence, blood, profanity, weapons }

enum DetectionUserStatus { pending, confirmed, rejected, adjusted }
```

---

### Modification

```dart
@freezed
sealed class Modification with _$Modification {
  // Audio modifications
  const factory Modification.audioMute() = AudioMute;
  
  const factory Modification.audioBeep({
    @Default(1000) int frequency,
    @Default(0.5) double volume,
  }) = AudioBeep;
  
  const factory Modification.audioReplace({
    required String audioPath,
    @Default(1.0) double volume,
    @Default(false) bool loop,
  }) = AudioReplace;
  
  // Video modifications
  const factory Modification.videoBlur({
    @Default(20) int intensity,
  }) = VideoBlur;
  
  const factory Modification.videoPixelate({
    @Default(16) int blockSize,
  }) = VideoPixelate;
  
  const factory Modification.videoBlackBox({
    @Default('#000000') String color,
    @Default(1.0) double opacity,
  }) = VideoBlackBox;
  
  const factory Modification.videoSkip() = VideoSkip;
  
  // Computed properties
  bool get isAudioModification;
  bool get isVideoModification;
  bool get isDestructive;
  String get displayName;
  String get shortCode;
  String get iconName;
  String toFFmpegFilter();
}
```

---

### Timeline

```dart
@freezed
class UnifiedTimeline with _$UnifiedTimeline {
  const factory UnifiedTimeline({
    required String id,
    required String mediaId,
    required List<TimelineTrack> tracks,
    required List<Detection> detections,
    @DurationConverter() required Duration duration,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) = _UnifiedTimeline;
}

@freezed
class TimelineTrack with _$TimelineTrack {
  const factory TimelineTrack({
    required String id,
    required TrackType type,
    required String name,
    required List<TimelineSegment> segments,
    @Default(true) bool isVisible,
    @Default(false) bool isMuted,
    @Default(false) bool isLocked,
    @Default(40) int height,
    String? color,
  }) = _TimelineTrack;
}

@freezed
class TimelineSegment with _$TimelineSegment {
  const factory TimelineSegment({
    required String id,
    @DurationConverter() required Duration start,
    @DurationConverter() required Duration end,
    required ContentType type,
    required double confidence,
    Modification? modification,
    @Default(false) bool isSelected,
    @Default(false) bool isLocked,
    String? detectionId,
  }) = _TimelineSegment;
}

enum TrackType { audio, video, detection, custom }
```

---

### AnalysisSettings

```dart
@freezed
class AnalysisSettings with _$AnalysisSettings {
  const factory AnalysisSettings({
    required ModelConfig modelConfig,
    @Default(0.6) double nsfwThreshold,
    @Default(0.6) double violenceThreshold,
    @Default(0.6) double bloodThreshold,
    @Default(0.6) double weaponsThreshold,
    required ProfanityConfig profanityConfig,
    @Default(true) bool enableNsfw,
    @Default(true) bool enableViolence,
    @Default(true) bool enableBlood,
    @Default(true) bool enableWeapons,
    @Default(true) bool enableProfanity,
    @Default(5) int frameSamplingRate,
    @Default(true) bool useSceneDetection,
    @Default(500) int minSegmentDurationMs,
    @Default(true) bool mergeAdjacentDetections,
    @Default(100) int detectionBufferMs,
    @Default(4) int maxConcurrentAnalyses,
  }) = _AnalysisSettings;
  
  factory AnalysisSettings.defaults();
  factory AnalysisSettings.strict();
  factory AnalysisSettings.permissive();
}

@freezed
class ModelConfig with _$ModelConfig {
  const factory ModelConfig({
    required String asrModelId,
    required String visualModelId,
    @Default('en') String asrLanguage,
    @Default(true) bool useGpu,
    @Default(4) int cpuThreads,
    @Default(8) int batchSize,
    @Default(false) bool useFp16,
  }) = _ModelConfig;
}

@freezed
class ProfanityConfig with _$ProfanityConfig {
  const factory ProfanityConfig({
    @Default(['english-profanity']) List<String> wordlistIds,
    @Default(true) bool detectLeetspeak,
    @Default(true) bool detectPhonetic,
    @Default(true) bool detectFuzzy,
    @Default(true) bool detectObfuscated,
    @Default(0.8) double fuzzyThreshold,
    @Default([]) List<String> customWords,
    @Default([]) List<String> excludedWords,
    @Default(2) int minWordLength,
    @Default(true) bool useContextAnalysis,
  }) = _ProfanityConfig;
}
```

---

### ModelInfo

```dart
@freezed
class ModelInfo with _$ModelInfo {
  const factory ModelInfo({
    required String id,
    required String name,
    required String description,
    required ModelType type,
    required int sizeBytes,
    String? downloadUrl,
    String? checksum,
    @Default([]) List<String> supportedLanguages,
    Map<String, dynamic>? metadata,
  }) = _ModelInfo;
}

enum ModelType { asr, visual, profanity }
```

---

## Native Bindings API

Native bindings are located in `lib/native/bindings/`.

### FFmpegBindings

```dart
class FFmpegBindings extends NativeResource {
  Future<void> initialize();
  Future<MediaMetadata> probeMedia(String path);
  Future<String> extractAudio(String videoPath, String outputPath);
  Stream<FrameData> extractFrames(String videoPath, {double fps, int? startFrame, int? endFrame});
  Future<String> generateThumbnail(String videoPath, String outputPath, {Duration? position});
  Stream<double> runFilterComplex({required String inputPath, required String outputPath, required String filterComplex, Map<String, String>? outputSettings});
  Future<List<SceneChange>> detectSceneChanges(String videoPath, {double threshold});
  void releaseNative();
}
```

### WhisperBindings

```dart
class WhisperBindings extends NativeResource {
  Future<void> initialize();
  Future<Transcript> transcribe(String audioPath, String modelPath, {String? language, bool translateToEnglish});
  Future<List<String>> getSupportedLanguages(String modelPath);
  void releaseNative();
}
```

### ONNXBindings

```dart
class ONNXBindings extends NativeResource {
  Future<void> initialize({List<String>? executionProviders});
  Future<void> loadModel(String modelPath);
  void unloadModel(String modelPath);
  Future<Map<String, double>> runInference(String modelPath, List<int> rgbData, int width, int height);
  Future<List<Map<String, double>>> runBatchInference(String modelPath, List<List<int>> rgbDataList, int width, int height);
  Future<ONNXModelMetadata> getModelMetadata(String modelPath);
  void releaseNative();
}
```

---

## Exception Types

All exceptions are defined in `lib/core/errors/app_exceptions.dart`.

### Base Exception

```dart
sealed class KidsLensException implements Exception {
  final String message;
  final String? technicalDetails;
  final bool isRetryable;
  
  String get userMessage;
  String get remediation;
}
```

### Exception Hierarchy

| Exception | Use Case | Retryable |
|-----------|----------|-----------|
| `ModelDownloadException` | Model download failures | Yes |
| `GPUInitializationException` | GPU init failures | Yes |
| `UnsupportedMediaException` | Unsupported format | No |
| `CorruptedMediaException` | Corrupt media file | No |
| `OutOfMemoryException` | Memory exhausted | Yes |
| `AnalysisException` | Analysis failures | Depends |
| `ExportException` | Export failures | Depends |

Each exception provides:
- `userMessage` - Human-readable error description
- `remediation` - Suggested fix for the user
- `technicalDetails` - Debug information for developers
