# KidsLens Video Editor - Implementation Plan v2.0

## Project Overview

**KidsLens** is an enterprise-grade, multiplatform desktop application designed to automatically detect and remove unsafe content (profanity, nudity, violence, blood, and other inappropriate content) from videos and audio files, making them safe for children. The app prioritizes local AI processing for privacy and supports configurable content filtering with user-selectable model accuracy/size tradeoffs.

### Target Platforms (v1.0)

| Platform | Status | Notes |
|----------|--------|-------|
| Windows 10/11 | ✓ Primary | x64, ARM64 |
| macOS 12+ | ✓ Primary | Intel, Apple Silicon |
| Linux (Ubuntu 22+) | ✓ Primary | x64, ARM64 |
| Android | Future | See `mobile-future-plan.md` |
| iOS | Future | See `mobile-future-plan.md` |

### Key Features

1. **Multi-format Media Processing** - All common audio/video formats (input and output)
2. **Automated Speech Recognition (ASR)** - User-selectable models (Whisper, Meta MMS)
3. **Audio Profanity Detection** - AI-powered + dictionary-based with phonetic matching
4. **Visual Content Moderation** - Nudity, violence, blood, weapons detection
5. **Multiple Modification Options** - Mute, beep, blur, pixelate, black box, skip
6. **Configurable Detection Sensitivity** - User-adjustable thresholds per category
7. **Sample Analysis Mode** - Test detection on 5-second sample before full analysis
8. **Model Selection UI** - Choose model size/accuracy based on hardware
9. **Multilingual Support** - English primary, extensible architecture
10. **Fully Localized UI** - All text localizable
11. **Detection Review UI** - Manual review, override, and correction
12. **Checkpoint/Resume** - Long operations can be paused and resumed

---

## Technology Stack

### Core Framework

| Component | Implementation | Notes |
|-----------|----------------|-------|
| **UI Framework** | Flutter | Custom widget implementations |
| **Language** | Dart 3.x | Null-safe, pattern matching |
| **State Management** | flutter_riverpod + riverpod_annotation | Official Riverpod with code generation |
| **Localization** | Custom ARB parser | Based on intl package patterns |

### Media Processing

| Component | Implementation | Notes |
|-----------|----------------|-------|
| **FFmpeg** | Native via dart:ffi | Custom bindings, no FFmpegKit |
| **Video Playback** | Custom player | FFmpeg decode + Flutter texture |
| **Frame Extraction** | Native FFmpeg | Streaming with backpressure |

### AI/ML Components

| Component | Implementation | Notes |
|-----------|----------------|-------|
| **ML Runtime** | ONNX Runtime via FFI | Custom Dart bindings |
| **ASR Engine** | whisper.cpp + Meta MMS | Native FFI integration |
| **Model Hub** | Custom downloader | HuggingFace API integration |

### Native Bindings (All Custom FFI)

| Library | Purpose | Platforms |
|---------|---------|-----------|
| FFmpeg 6.x | Media processing | All desktop |
| whisper.cpp | Whisper ASR | All desktop |
| fairseq2 (MMS) | Meta MMS ASR | All desktop |
| ONNX Runtime | ML inference | All desktop |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           KidsLens Application                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                              UI Layer (Flutter)                             │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐  ┌──────────────────┐   │
│  │   Import    │  │   Preview    │  │  Timeline   │  │    Settings      │   │
│  │   Screen    │  │   Screen     │  │   Editor    │  │    + Models      │   │
│  └─────────────┘  └──────────────┘  └─────────────┘  └──────────────────┘   │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐  ┌──────────────────┐   │
│  │  Detection  │  │    Export    │  │  Onboarding │  │  About/Attrib    │   │
│  │   Review    │  │   Screen     │  │    Flow     │  │     Screen       │   │
│  └─────────────┘  └──────────────┘  └─────────────┘  └──────────────────┘   │
├─────────────────────────────────────────────────────────────────────────────┤
│                     State Management (Riverpod)                             │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐  ┌──────────────────┐   │
│  │   Media     │  │   Analysis   │  │  Timeline   │  │     Model        │   │
│  │  Notifier   │  │  Notifier    │  │  Notifier   │  │    Notifier      │   │
│  └─────────────┘  └──────────────┘  └─────────────┘  └──────────────────┘   │
├─────────────────────────────────────────────────────────────────────────────┤
│                              Job System                                     │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  AnalysisJob: queued → running → paused → resumed → completed/failed │   │
│  │  ExportJob:   queued → running → paused → resumed → completed/failed │   │
│  │  - CancellationToken support                                          │   │
│  │  - Checkpoint/resume with artifact caching                            │   │
│  │  - Progress reporting with ETA                                        │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────────┤
│                           Service Layer                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │  Media Service  │  │ Analysis Service│  │  Model Manager Service      │  │
│  │  - Import       │  │  - ASR Pipeline │  │  - Download with resume     │  │
│  │  - Export       │  │  - Visual       │  │  - Validation               │  │
│  │  - Transcode    │  │  - Profanity    │  │  - GPU detection            │  │
│  │  - Streaming    │  │  - Timeline     │  │  - Fallback handling        │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────────────┤
│                     Content Analysis Pipeline                               │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  Audio Track → ASR (Whisper/MMS) → Profanity Detection → Timeline    │   │
│  │                     ↓                                                 │   │
│  │  Video Frames → Scene Detection → Sampling → Visual Models → Timeline│   │
│  │       (keyframe + 1-2fps)           (NSFW, Violence, Blood)          │   │
│  │                     ↓                                                 │   │
│  │  Temporal Aggregator → Hysteresis → Unified Timeline with Confidence │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────────┤
│                    Native Resource Manager                                  │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │  - Finalizer-based cleanup for FFI resources                          │   │
│  │  - Frame buffer pool with backpressure (max 30 frames, ~750MB 4K)     │   │
│  │  - Memory pressure monitoring and adaptive quality                    │   │
│  │  - GPU memory management with overflow prevention                     │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────────────────────┤
│                          Native FFI Layer                                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │     FFmpeg      │  │   whisper.cpp   │  │      ONNX Runtime           │  │
│  │  Custom Wrapper │  │  Custom Wrapper │  │     Custom Wrapper          │  │
│  └─────────────────┘  └─────────────────┘  └─────────────────────────────┘  │
│  ┌─────────────────┐  ┌─────────────────┐                                   │
│  │   Meta MMS/     │  │  GPU Backend    │                                   │
│  │   fairseq2      │  │ CUDA/Metal/Vulkan│                                  │
│  └─────────────────┘  └─────────────────┘                                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## AI Models - User Selectable

### ASR Models

The user can select ASR model based on their hardware capabilities and accuracy requirements.

#### OpenAI Whisper (via whisper.cpp)

| Model | Parameters | Disk | RAM | Speed | Accuracy | Use Case |
|-------|------------|------|-----|-------|----------|----------|
| tiny | 39M | 75MB | ~1GB | ~10x | Good | Quick preview, low-end |
| tiny.en | 39M | 75MB | ~1GB | ~10x | Better (EN) | English only, fast |
| base | 74M | 142MB | ~1GB | ~7x | Better | Balanced low-end |
| base.en | 74M | 142MB | ~1GB | ~7x | Good (EN) | English only |
| small | 244M | 466MB | ~2GB | ~4x | Great | Recommended default |
| small.en | 244M | 466MB | ~2GB | ~4x | Great (EN) | English only |
| medium | 769M | 1.5GB | ~5GB | ~2x | Excellent | High accuracy |
| medium.en | 769M | 1.5GB | ~5GB | ~2x | Excellent (EN) | English only |
| large-v3 | 1550M | 2.9GB | ~10GB | 1x | Best | Maximum accuracy |
| large-v3-turbo | 809M | 1.6GB | ~6GB | ~4x | Excellent | Best speed/accuracy |

#### Meta MMS (Massively Multilingual Speech)

| Model | Languages | Disk | RAM | Notes |
|-------|-----------|------|-----|-------|
| MMS-1B-all | 1,100+ | 4GB | ~8GB | Best multilingual coverage |
| MMS-1B-fl102 | 102 | 4GB | ~8GB | Common languages |
| MMS-300M | 1,100+ | 1.2GB | ~3GB | Lighter weight |

**MMS Advantages:**
- 1,100+ language support (vs Whisper's 99)
- Better performance on low-resource languages
- Open source (MIT license from Meta)

### Visual Content Models

#### NSFW/Nudity Detection

| Model | Architecture | Accuracy | Disk | Speed | License |
|-------|--------------|----------|------|-------|---------|
| NSFW-MobileNetV2 | MobileNet V2 | 91% | 20MB | Fast | MIT |
| NSFW-InceptionV3 | Inception V3 | 93% | 95MB | Medium | MIT |
| NSFW-EfficientNet | EfficientNet-B4 | 95% | 75MB | Medium | Apache 2.0 |

**Categories:** drawings, hentai, neutral, porn, sexy

#### Violence Detection

| Model | Architecture | Accuracy | Disk | Speed | License |
|-------|--------------|----------|------|-------|---------|
| Violence-ViT-Base | ViT-base-patch16 | 98.8% | 330MB | Medium | Apache 2.0 |
| Violence-MobileNet | MobileNetV3 | 94% | 15MB | Fast | MIT |
| Violence-ConvNeXt | ConvNeXt-Tiny | 97% | 110MB | Medium | Apache 2.0 |

**Categories:** violent, non-violent

#### Blood/Gore Detection

| Model | Architecture | Accuracy | Disk | License |
|-------|--------------|----------|------|---------|
| Gore-EfficientNet | EfficientNet-B2 | 96% | 35MB | MIT |
| Blood-YOLO | YOLOv8-nano | 92% | 12MB | AGPL-3.0 |

#### Weapons Detection (Object Detection)

| Model | Architecture | mAP | Disk | License |
|-------|--------------|-----|------|---------|
| Weapons-YOLOv8 | YOLOv8-small | 78% | 22MB | AGPL-3.0 |
| Weapons-DETR | DETR-ResNet50 | 82% | 160MB | Apache 2.0 |

### Model Selection UI

```dart
class ModelSelectionScreen extends ConsumerWidget {
  const ModelSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelState = ref.watch(modelNotifierProvider);
    final hardwareInfo = ref.watch(hardwareInfoProvider);
    
    return modelState.when(
      data: (state) => Scaffold(
        appBar: AppBar(title: Text(l10n.modelSelection)),
        body: Column(
          children: [
            // Hardware info display
            HardwareInfoCard(
              cpuCores: hardwareInfo.cpuCores,
              ramGB: hardwareInfo.ramGB,
              gpu: hardwareInfo.gpu,
              recommendation: hardwareInfo.recommendedTier,
            ),
            
            // ASR Model Selection
            ModelCategorySection(
              title: l10n.asrModels,
              models: state.availableModels
                  .where((m) => m.type == ModelType.asr)
                  .map((m) => ModelOption(
                    id: m.id,
                    name: m.displayName,
                    accuracy: m.accuracy,
                    size: m.formattedSize,
                    speed: m.speedRating,
                    isDownloaded: state.downloadedModels.contains(m.id),
                    downloadProgress: state.downloadProgress[m.id],
                    recommended: m.meetsRequirements(hardwareInfo),
                    description: m.description,
                    badge: m.badge,
                    onDownload: () => ref
                        .read(modelNotifierProvider.notifier)
                        .downloadModel(m.id),
                    onDelete: () => ref
                        .read(modelNotifierProvider.notifier)
                        .deleteModel(m.id),
                    onSelect: () => ref
                        .read(modelNotifierProvider.notifier)
                        .setSelectedConfig(
                          state.selectedConfig?.copyWith(asrModel: m.id) ??
                              ModelConfig(asrModel: m.id),
                        ),
                  ))
                  .toList(),
            ),
            
            // Visual Models Selection
            ModelCategorySection(
              title: l10n.visualModels,
              models: state.availableModels
                  .where((m) => m.type == ModelType.visual)
                  .map((m) => /* similar mapping */)
                  .toList(),
            ),
            
            // Disk space indicator
            Consumer(
              builder: (context, ref, _) {
                final diskUsage = ref.watch(totalModelDiskUsageProvider);
                return diskUsage.when(
                  data: (bytes) => DiskSpaceIndicator(
                    used: bytes,
                    available: hardwareInfo.availableDiskSpace,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                );
              },
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading models: $e')),
    );
  }
}
```

---

## Sample Analysis Mode

Users can test detection settings on a 5-second sample before running full analysis.

```dart
class SampleAnalysisService {
  static const Duration sampleDuration = Duration(seconds: 5);
  
  /// Extract a representative sample from the media
  Future<MediaSample> extractSample(
    MediaFile media, {
    Duration? startOffset,
    SampleStrategy strategy = SampleStrategy.detectInteresting,
  }) async {
    switch (strategy) {
      case SampleStrategy.beginning:
        return _extractFromOffset(media, Duration.zero);
      
      case SampleStrategy.middle:
        final middle = media.duration ~/ 2;
        return _extractFromOffset(media, middle);
      
      case SampleStrategy.detectInteresting:
        // Use scene detection to find a segment with activity
        final scenes = await _detectSceneChanges(media);
        final interestingOffset = _findMostDynamicSegment(scenes);
        return _extractFromOffset(media, interestingOffset);
      
      case SampleStrategy.custom:
        return _extractFromOffset(media, startOffset!);
    }
  }
  
  /// Run full analysis pipeline on sample
  Future<SampleAnalysisResult> analyzeSample(
    MediaSample sample,
    AnalysisSettings settings,
  ) async {
    final result = await _analysisService.analyzeMedia(
      sample.mediaFile,
      settings: settings,
      isSample: true,
    );
    
    return SampleAnalysisResult(
      transcript: result.transcript,
      profanityMatches: result.profanityMatches,
      visualDetections: result.frameResults,
      estimatedFullDuration: _estimateFullAnalysisDuration(
        sample.duration,
        result.processingTime,
        sample.originalMedia.duration,
      ),
      sampleTimeline: result.timeline,
    );
  }
}

/// Sample selection UI using Riverpod
class SampleSelectionWidget extends ConsumerStatefulWidget {
  final MediaFile media;
  
  const SampleSelectionWidget({super.key, required this.media});
  
  @override
  ConsumerState<SampleSelectionWidget> createState() => 
      _SampleSelectionWidgetState();
}

class _SampleSelectionWidgetState extends ConsumerState<SampleSelectionWidget> {
  Duration _selectedOffset = Duration.zero;
  
  @override
  Widget build(BuildContext context) {
    final sampleState = ref.watch(sampleAnalysisProvider);
    
    return Column(
      children: [
        // Thumbnail strip for visual selection
        ThumbnailStrip(
          media: widget.media,
          onTap: (offset) => setState(() => _selectedOffset = offset),
        ),
        
        // Quick selection buttons
        Row(
          children: [
            QuickSelectButton(
              icon: Icons.first_page,
              label: l10n.beginning,
              onPressed: () => setState(() => _selectedOffset = Duration.zero),
            ),
            QuickSelectButton(
              icon: Icons.center_focus_strong,
              label: l10n.middle,
              onPressed: () => setState(
                () => _selectedOffset = widget.media.duration ~/ 2,
              ),
            ),
            QuickSelectButton(
              icon: Icons.auto_awesome,
              label: l10n.autoDetect,
              onPressed: () => _detectAndSelect(),
            ),
          ],
        ),
        
        // Sample preview player
        SamplePreviewPlayer(
          media: widget.media,
          sampleStart: _selectedOffset,
          sampleDuration: const Duration(seconds: 5),
        ),
        
        // Sample analysis status
        if (sampleState.isLoading)
          const LinearProgressIndicator()
        else if (sampleState.hasError)
          Text('Error: ${sampleState.error}', 
               style: TextStyle(color: Theme.of(context).colorScheme.error)),
        
        // Run sample analysis button
        ElevatedButton.icon(
          icon: const Icon(Icons.science),
          label: Text(l10n.runSampleAnalysis),
          onPressed: sampleState.isLoading
              ? null
              : () => ref.read(sampleAnalysisProvider.notifier).runSample(
                    widget.media,
                    _selectedOffset,
                  ),
        ),
        
        // Show sample results
        if (sampleState.hasValue && sampleState.value != null)
          SampleResultsCard(result: sampleState.value!),
      ],
    );
  }
  
  Future<void> _detectAndSelect() async {
    final offset = await ref
        .read(sampleAnalysisProvider.notifier)
        .detectInterestingSegment(widget.media);
    setState(() => _selectedOffset = offset);
  }
}
```

---

## State Management (Riverpod)

KidsLens uses **flutter_riverpod** with **riverpod_generator** for type-safe, compile-time verified state management following official Riverpod 3.x best practices.

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
```

### App Entry Point

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: KidsLensApp(),
    ),
  );
}

class KidsLensApp extends ConsumerWidget {
  const KidsLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'KidsLens',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
```

### Media Provider (AsyncNotifier Pattern)

```dart
// lib/state/providers/media_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/media_file.dart';
import '../../services/media_service.dart';

part 'media_provider.g.dart';

@freezed
class MediaState with _$MediaState {
  const factory MediaState({
    MediaFile? currentMedia,
    @Default([]) List<MediaFile> recentFiles,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _MediaState;
}

@riverpod
class MediaNotifier extends _$MediaNotifier {
  @override
  MediaState build() => const MediaState();
  
  Future<void> importMedia(String path) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final mediaService = ref.read(mediaServiceProvider);
      final mediaFile = await mediaService.importFile(path);
      
      state = state.copyWith(
        isLoading: false,
        currentMedia: mediaFile,
        recentFiles: [mediaFile, ...state.recentFiles].take(10).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  void clearMedia() {
    state = state.copyWith(currentMedia: null);
  }
}
```

### Analysis Provider (AsyncNotifier with Streaming)

```dart
// lib/state/providers/analysis_provider.dart
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/analysis_result.dart';
import '../../data/models/timeline.dart';
import '../../jobs/analysis_job.dart';
import '../../jobs/cancellation_token.dart';

part 'analysis_provider.g.dart';

enum AnalysisStatus { idle, running, paused, completed, failed, cancelled }

@freezed
class AnalysisState with _$AnalysisState {
  const factory AnalysisState({
    @Default(AnalysisStatus.idle) AnalysisStatus status,
    @Default(0.0) double progress,
    String? currentStep,
    Duration? estimatedRemaining,
    AnalysisResult? result,
    UnifiedTimeline? timeline,
    String? errorMessage,
  }) = _AnalysisState;
}

@riverpod
class AnalysisNotifier extends _$AnalysisNotifier {
  CancellationToken? _cancellationToken;
  StreamSubscription? _progressSubscription;
  
  @override
  AnalysisState build() => const AnalysisState();
  
  Future<void> startAnalysis({
    required String mediaPath,
    required AnalysisSettings settings,
  }) async {
    _cancellationToken = CancellationToken();
    
    state = state.copyWith(
      status: AnalysisStatus.running,
      progress: 0.0,
      errorMessage: null,
    );
    
    try {
      final analysisService = ref.read(analysisServiceProvider);
      
      // Subscribe to progress updates
      _progressSubscription = analysisService.progressStream.listen((progress) {
        state = state.copyWith(
          progress: progress.percentage,
          currentStep: progress.step,
          estimatedRemaining: progress.eta,
        );
      });
      
      final result = await analysisService.analyze(
        mediaPath: mediaPath,
        settings: settings,
        cancellationToken: _cancellationToken!,
      );
      
      state = state.copyWith(
        status: AnalysisStatus.completed,
        progress: 1.0,
        result: result,
        timeline: result.timeline,
      );
    } on CancelledException {
      state = state.copyWith(status: AnalysisStatus.cancelled);
    } catch (e) {
      state = state.copyWith(
        status: AnalysisStatus.failed,
        errorMessage: e.toString(),
      );
    } finally {
      _progressSubscription?.cancel();
    }
  }
  
  void pause() {
    _cancellationToken?.pause();
    state = state.copyWith(status: AnalysisStatus.paused);
  }
  
  void resume() {
    _cancellationToken?.resume();
    state = state.copyWith(status: AnalysisStatus.running);
  }
  
  void cancel() {
    _cancellationToken?.cancel();
    state = state.copyWith(status: AnalysisStatus.cancelled);
  }
  
  void reset() {
    _cancellationToken = null;
    state = const AnalysisState();
  }
}
```

### Timeline Provider (Notifier for Synchronous State)

```dart
// lib/state/providers/timeline_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/timeline.dart';
import '../../data/models/detection.dart';

part 'timeline_provider.g.dart';

@freezed
class TimelineState with _$TimelineState {
  const factory TimelineState({
    UnifiedTimeline? timeline,
    @Default({}) Set<String> selectedDetectionIds,
    Duration? playheadPosition,
    @Default(1.0) double zoomLevel,
  }) = _TimelineState;
}

@riverpod
class TimelineNotifier extends _$TimelineNotifier {
  @override
  TimelineState build() => const TimelineState();
  
  void setTimeline(UnifiedTimeline timeline) {
    state = state.copyWith(timeline: timeline);
  }
  
  void selectDetection(String detectionId) {
    state = state.copyWith(
      selectedDetectionIds: {...state.selectedDetectionIds, detectionId},
    );
  }
  
  void deselectDetection(String detectionId) {
    state = state.copyWith(
      selectedDetectionIds: state.selectedDetectionIds
          .where((id) => id != detectionId)
          .toSet(),
    );
  }
  
  void confirmDetection(String detectionId) {
    final timeline = state.timeline;
    if (timeline == null) return;
    
    state = state.copyWith(
      timeline: timeline.updateDetection(
        detectionId,
        (d) => d.copyWith(userStatus: DetectionUserStatus.confirmed),
      ),
    );
  }
  
  void rejectDetection(String detectionId) {
    final timeline = state.timeline;
    if (timeline == null) return;
    
    state = state.copyWith(
      timeline: timeline.updateDetection(
        detectionId,
        (d) => d.copyWith(userStatus: DetectionUserStatus.rejected),
      ),
    );
  }
  
  void adjustDetectionBounds(
    String detectionId, {
    Duration? newStart,
    Duration? newEnd,
  }) {
    final timeline = state.timeline;
    if (timeline == null) return;
    
    state = state.copyWith(
      timeline: timeline.updateDetection(
        detectionId,
        (d) => d.copyWith(
          startTime: newStart ?? d.startTime,
          endTime: newEnd ?? d.endTime,
          userStatus: DetectionUserStatus.adjusted,
        ),
      ),
    );
  }
  
  void setPlayheadPosition(Duration position) {
    state = state.copyWith(playheadPosition: position);
  }
  
  void setZoomLevel(double zoom) {
    state = state.copyWith(zoomLevel: zoom.clamp(0.1, 10.0));
  }
}
```

### Model Provider (AsyncNotifier for Downloads)

```dart
// lib/state/providers/model_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/model_manager_service.dart';
import '../../data/models/model_info.dart';

part 'model_provider.g.dart';

@freezed
class ModelState with _$ModelState {
  const factory ModelState({
    @Default([]) List<ModelInfo> availableModels,
    @Default({}) Map<String, DownloadProgress> downloadProgress,
    @Default({}) Set<String> downloadedModels,
    ModelConfig? selectedConfig,
  }) = _ModelState;
}

@freezed
class DownloadProgress with _$DownloadProgress {
  const factory DownloadProgress({
    required double percentage,
    required int bytesDownloaded,
    required int totalBytes,
  }) = _DownloadProgress;
}

@riverpod
class ModelNotifier extends _$ModelNotifier {
  @override
  Future<ModelState> build() async {
    final modelManager = ref.read(modelManagerServiceProvider);
    
    final availableModels = await modelManager.loadRegistry();
    final downloadedModels = await modelManager.getDownloadedModels();
    
    return ModelState(
      availableModels: availableModels,
      downloadedModels: downloadedModels.toSet(),
    );
  }
  
  Future<void> downloadModel(String modelId) async {
    final modelManager = ref.read(modelManagerServiceProvider);
    
    try {
      await modelManager.downloadModel(
        modelId,
        onProgress: (progress) {
          state = AsyncData(state.value!.copyWith(
            downloadProgress: {
              ...state.value!.downloadProgress,
              modelId: DownloadProgress(
                percentage: progress.percentage,
                bytesDownloaded: progress.bytesDownloaded,
                totalBytes: progress.totalBytes,
              ),
            },
          ));
        },
      );
      
      // Update downloaded models set
      state = AsyncData(state.value!.copyWith(
        downloadedModels: {...state.value!.downloadedModels, modelId},
        downloadProgress: Map.from(state.value!.downloadProgress)
          ..remove(modelId),
      ));
    } catch (e) {
      // Remove from progress on error
      state = AsyncData(state.value!.copyWith(
        downloadProgress: Map.from(state.value!.downloadProgress)
          ..remove(modelId),
      ));
      rethrow;
    }
  }
  
  Future<void> deleteModel(String modelId) async {
    final modelManager = ref.read(modelManagerServiceProvider);
    await modelManager.deleteModel(modelId);
    
    state = AsyncData(state.value!.copyWith(
      downloadedModels: state.value!.downloadedModels
          .where((id) => id != modelId)
          .toSet(),
    ));
  }
  
  void setSelectedConfig(ModelConfig config) {
    state = AsyncData(state.value!.copyWith(selectedConfig: config));
  }
}
```

### Service Providers

```dart
// lib/state/providers/service_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../services/media_service.dart';
import '../../services/analysis_service.dart';
import '../../services/model_manager_service.dart';
import '../../native/bindings/ffmpeg_bindings.dart';
import '../../native/bindings/whisper_bindings.dart';
import '../../native/bindings/onnx_bindings.dart';

part 'service_providers.g.dart';

// Native bindings (singletons)
@Riverpod(keepAlive: true)
FFmpegBindings ffmpegBindings(Ref ref) => FFmpegBindings();

@Riverpod(keepAlive: true)
WhisperBindings whisperBindings(Ref ref) => WhisperBindings();

@Riverpod(keepAlive: true)
ONNXBindings onnxBindings(Ref ref) => ONNXBindings();

// Services
@Riverpod(keepAlive: true)
MediaService mediaService(Ref ref) {
  return MediaService(ref.watch(ffmpegBindingsProvider));
}

@Riverpod(keepAlive: true)
ModelManagerService modelManagerService(Ref ref) {
  return ModelManagerService();
}

@Riverpod(keepAlive: true)
AnalysisService analysisService(Ref ref) {
  return AnalysisService(
    ffmpeg: ref.watch(ffmpegBindingsProvider),
    whisper: ref.watch(whisperBindingsProvider),
    onnx: ref.watch(onnxBindingsProvider),
    modelManager: ref.watch(modelManagerServiceProvider),
  );
}
```

### Using Providers in Widgets

```dart
// Example: Detection Review Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers/timeline_provider.dart';
import '../state/providers/analysis_provider.dart';

class DetectionReviewScreen extends ConsumerWidget {
  const DetectionReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineNotifierProvider);
    final analysisState = ref.watch(analysisNotifierProvider);
    
    final timeline = timelineState.timeline;
    if (timeline == null) {
      return const Center(child: Text('No analysis results'));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Detections'),
        actions: [
          TextButton(
            onPressed: () => _confirmAll(ref, timeline),
            child: const Text('Confirm All'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: timeline.detections.length,
        itemBuilder: (context, index) {
          final detection = timeline.detections[index];
          final isSelected = timelineState.selectedDetectionIds
              .contains(detection.id);
          
          return DetectionCard(
            detection: detection,
            isSelected: isSelected,
            onTap: () => ref
                .read(timelineNotifierProvider.notifier)
                .selectDetection(detection.id),
            onConfirm: () => ref
                .read(timelineNotifierProvider.notifier)
                .confirmDetection(detection.id),
            onReject: () => ref
                .read(timelineNotifierProvider.notifier)
                .rejectDetection(detection.id),
          );
        },
      ),
    );
  }
  
  void _confirmAll(WidgetRef ref, UnifiedTimeline timeline) {
    final notifier = ref.read(timelineNotifierProvider.notifier);
    for (final detection in timeline.detections) {
      if (detection.userStatus == DetectionUserStatus.pending) {
        notifier.confirmDetection(detection.id);
      }
    }
  }
}
```

### Computed/Derived Providers

```dart
// lib/state/providers/derived_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'timeline_provider.dart';
import 'analysis_provider.dart';

part 'derived_providers.g.dart';

/// Pending detections that need user review
@riverpod
List<Detection> pendingDetections(Ref ref) {
  final timeline = ref.watch(
    timelineNotifierProvider.select((s) => s.timeline),
  );
  if (timeline == null) return [];
  
  return timeline.detections
      .where((d) => d.userStatus == DetectionUserStatus.pending)
      .toList();
}

/// Count of each detection type
@riverpod
Map<DetectionType, int> detectionCounts(Ref ref) {
  final timeline = ref.watch(
    timelineNotifierProvider.select((s) => s.timeline),
  );
  if (timeline == null) return {};
  
  final counts = <DetectionType, int>{};
  for (final detection in timeline.detections) {
    counts[detection.type] = (counts[detection.type] ?? 0) + 1;
  }
  return counts;
}

/// Whether analysis can be started
@riverpod
bool canStartAnalysis(Ref ref) {
  final media = ref.watch(
    mediaNotifierProvider.select((s) => s.currentMedia),
  );
  final analysisStatus = ref.watch(
    analysisNotifierProvider.select((s) => s.status),
  );
  
  return media != null && analysisStatus == AnalysisStatus.idle;
}

/// Total disk space used by downloaded models
@riverpod
Future<int> totalModelDiskUsage(Ref ref) async {
  final modelState = await ref.watch(modelNotifierProvider.future);
  final modelManager = ref.read(modelManagerServiceProvider);
  
  var total = 0;
  for (final modelId in modelState.downloadedModels) {
    final info = modelState.availableModels
        .firstWhere((m) => m.id == modelId);
    total += info.sizeBytes;
  }
  return total;
}
```

### Code Generation

Run build_runner to generate provider code:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or watch for changes during development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## Memory Management System

### Native Resource Manager

```dart
/// Manages all native FFI resources with deterministic cleanup
class NativeResourceManager {
  static final NativeResourceManager instance = NativeResourceManager._();
  NativeResourceManager._();
  
  final Map<int, Weak<NativeResource>> _resources = {};
  final Finalizer<int> _finalizer = Finalizer((id) {
    instance._cleanupResource(id);
  });
  
  int _nextId = 0;
  
  /// Register a native resource for tracking
  T register<T extends NativeResource>(T resource) {
    final id = _nextId++;
    _resources[id] = Weak(resource);
    _finalizer.attach(resource, id, detach: resource);
    return resource;
  }
  
  /// Explicitly release a resource
  void release(NativeResource resource) {
    resource.dispose();
    _finalizer.detach(resource);
  }
  
  void _cleanupResource(int id) {
    final weak = _resources.remove(id);
    // Resource already collected by GC, ensure native side is cleaned
    _nativeCleanup(id);
  }
  
  /// Force cleanup of all resources (app shutdown)
  Future<void> disposeAll() async {
    for (final weak in _resources.values) {
      weak.target?.dispose();
    }
    _resources.clear();
  }
}

/// Base class for FFI-backed resources
abstract class NativeResource {
  bool _disposed = false;
  
  bool get isDisposed => _disposed;
  
  @mustCallSuper
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    releaseNative();
  }
  
  /// Override to release native resources
  void releaseNative();
}
```

### Frame Buffer Pool

```dart
/// Memory-bounded frame buffer for video analysis
class FrameBufferPool {
  static const int maxFrames4K = 30;  // ~750MB for 4K
  static const int maxFramesHD = 60;  // ~120MB for 1080p
  static const int maxFramesSD = 120; // ~30MB for 480p
  
  final Queue<PooledFrame> _available = Queue();
  final Set<PooledFrame> _inUse = {};
  final int _maxFrames;
  final int _frameSize;
  
  int _allocatedCount = 0;
  final _availableNotifier = Completer<void>();
  
  FrameBufferPool({
    required Resolution resolution,
  }) : _maxFrames = _calculateMaxFrames(resolution),
       _frameSize = resolution.width * resolution.height * 3;
  
  static int _calculateMaxFrames(Resolution res) {
    final pixels = res.width * res.height;
    if (pixels > 3840 * 2160) return maxFrames4K ~/ 2;  // 8K
    if (pixels > 1920 * 1080) return maxFrames4K;       // 4K
    if (pixels > 1280 * 720) return maxFramesHD;        // 1080p
    return maxFramesSD;                                  // SD
  }
  
  /// Acquire a frame buffer, waiting if pool is exhausted (backpressure)
  Future<PooledFrame> acquire({Duration? timeout}) async {
    // Try to get an available frame
    if (_available.isNotEmpty) {
      final frame = _available.removeFirst();
      _inUse.add(frame);
      return frame;
    }
    
    // Allocate new if under limit
    if (_allocatedCount < _maxFrames) {
      final frame = PooledFrame(
        buffer: Uint8List(_frameSize),
        pool: this,
      );
      _allocatedCount++;
      _inUse.add(frame);
      return frame;
    }
    
    // Wait for a frame to be released (backpressure)
    final completer = Completer<PooledFrame>();
    _waiters.add(completer);
    
    if (timeout != null) {
      return completer.future.timeout(timeout, onTimeout: () {
        _waiters.remove(completer);
        throw TimeoutException('Frame buffer pool exhausted');
      });
    }
    
    return completer.future;
  }
  
  /// Release a frame back to the pool
  void release(PooledFrame frame) {
    _inUse.remove(frame);
    
    if (_waiters.isNotEmpty) {
      final waiter = _waiters.removeFirst();
      _inUse.add(frame);
      waiter.complete(frame);
    } else {
      _available.add(frame);
    }
  }
  
  final Queue<Completer<PooledFrame>> _waiters = Queue();
  
  /// Memory pressure handler - shrink pool
  Future<void> handleMemoryPressure() async {
    // Release half of available frames
    final toRelease = _available.length ~/ 2;
    for (var i = 0; i < toRelease; i++) {
      if (_available.isNotEmpty) {
        _available.removeFirst();
        _allocatedCount--;
      }
    }
  }
}
```

---

## Job System with Checkpointing

```dart
/// Job state machine for long-running operations
enum JobState {
  queued,
  running,
  paused,
  cancelled,
  failed,
  completed,
}

/// Cancellation token for cooperative cancellation
class CancellationToken {
  bool _isCancelled = false;
  final _completer = Completer<void>();
  final List<VoidCallback> _callbacks = [];
  
  bool get isCancelled => _isCancelled;
  Future<void> get cancelled => _completer.future;
  
  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    _completer.complete();
    for (final callback in _callbacks) {
      callback();
    }
  }
  
  void onCancel(VoidCallback callback) {
    if (_isCancelled) {
      callback();
    } else {
      _callbacks.add(callback);
    }
  }
  
  /// Throw if cancelled
  void throwIfCancelled() {
    if (_isCancelled) throw CancelledException();
  }
}

/// Analysis job with checkpoint/resume support
class AnalysisJob extends NativeResource {
  final String id;
  final MediaFile media;
  final AnalysisSettings settings;
  final CancellationToken cancellationToken;
  
  JobState _state = JobState.queued;
  AnalysisCheckpoint? _checkpoint;
  final _progressController = StreamController<AnalysisProgress>.broadcast();
  
  Stream<AnalysisProgress> get progress => _progressController.stream;
  JobState get state => _state;
  
  /// Run analysis with checkpoint support
  Future<AnalysisResult> run() async {
    _state = JobState.running;
    
    try {
      // Phase 1: Audio extraction (or resume from checkpoint)
      final audioTrack = _checkpoint?.audioTrack ?? 
          await _extractAudio();
      await _saveCheckpoint(AnalysisCheckpoint(audioTrack: audioTrack));
      
      cancellationToken.throwIfCancelled();
      
      // Phase 2: ASR transcription
      final transcript = _checkpoint?.transcript ??
          await _transcribe(audioTrack);
      await _saveCheckpoint(AnalysisCheckpoint(
        audioTrack: audioTrack,
        transcript: transcript,
      ));
      
      cancellationToken.throwIfCancelled();
      
      // Phase 3: Profanity detection
      final profanityMatches = _checkpoint?.profanityMatches ??
          await _detectProfanity(transcript);
      await _saveCheckpoint(AnalysisCheckpoint(
        audioTrack: audioTrack,
        transcript: transcript,
        profanityMatches: profanityMatches,
      ));
      
      cancellationToken.throwIfCancelled();
      
      // Phase 4: Visual analysis (with per-frame checkpoints)
      final frameResults = await _analyzeVisual(
        startFromFrame: _checkpoint?.lastAnalyzedFrame ?? 0,
      );
      
      // Phase 5: Build timeline
      final timeline = _buildTimeline(profanityMatches, frameResults);
      
      _state = JobState.completed;
      return AnalysisResult(
        transcript: transcript,
        profanityMatches: profanityMatches,
        frameResults: frameResults,
        timeline: timeline,
      );
      
    } on CancelledException {
      _state = JobState.cancelled;
      rethrow;
    } catch (e) {
      _state = JobState.failed;
      rethrow;
    }
  }
  
  /// Pause the job (saves checkpoint)
  Future<void> pause() async {
    _state = JobState.paused;
    await _saveCheckpoint(_checkpoint!);
  }
  
  /// Resume from checkpoint
  Future<AnalysisResult> resume() async {
    _checkpoint = await _loadCheckpoint();
    return run();
  }
  
  Future<void> _saveCheckpoint(AnalysisCheckpoint checkpoint) async {
    _checkpoint = checkpoint;
    final json = checkpoint.toJson();
    await File(_checkpointPath).writeAsString(jsonEncode(json));
  }
  
  String get _checkpointPath => 
      '${_cacheDir}/${id}_checkpoint.json';
  
  @override
  void releaseNative() {
    _progressController.close();
  }
}

/// Checkpoint data for resume capability
class AnalysisCheckpoint {
  final AudioTrack? audioTrack;
  final Transcript? transcript;
  final List<ProfanityMatch>? profanityMatches;
  final int lastAnalyzedFrame;
  final List<FrameAnalysisResult>? partialFrameResults;
  final DateTime timestamp;
  
  AnalysisCheckpoint({
    this.audioTrack,
    this.transcript,
    this.profanityMatches,
    this.lastAnalyzedFrame = 0,
    this.partialFrameResults,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'audioTrackPath': audioTrack?.path,
    'transcript': transcript?.toJson(),
    'profanityMatches': profanityMatches?.map((m) => m.toJson()).toList(),
    'lastAnalyzedFrame': lastAnalyzedFrame,
    'partialFrameResults': partialFrameResults?.map((r) => r.toJson()).toList(),
    'timestamp': timestamp.toIso8601String(),
  };
}
```

---

## Frame Sampling Strategy

Instead of analyzing every frame, use intelligent sampling:

```dart
/// Intelligent frame sampling for efficient analysis
class FrameSamplingService {
  final FFmpegBindings _ffmpeg;
  
  /// Extract frames using scene detection + fixed interval
  Stream<SampledFrame> sampleFrames(
    MediaFile media, {
    double sceneChangeThreshold = 0.4,
    double framesPerSecond = 2.0,
    CancellationToken? cancellationToken,
  }) async* {
    // Step 1: Detect scene changes (keyframes)
    final sceneChanges = await _detectSceneChanges(
      media,
      threshold: sceneChangeThreshold,
    );
    
    // Step 2: Add fixed-interval samples between scenes
    final allSampleTimes = <Duration>{};
    
    // Add scene change timestamps
    for (final scene in sceneChanges) {
      allSampleTimes.add(scene.timestamp);
    }
    
    // Add fixed-interval samples
    final interval = Duration(milliseconds: (1000 / framesPerSecond).round());
    var current = Duration.zero;
    while (current < media.duration) {
      allSampleTimes.add(current);
      current += interval;
    }
    
    // Sort and deduplicate (within 100ms tolerance)
    final sortedTimes = allSampleTimes.toList()..sort();
    final deduped = _deduplicateTimestamps(sortedTimes, tolerance: Duration(milliseconds: 100));
    
    // Step 3: Extract frames at sample times
    for (final timestamp in deduped) {
      cancellationToken?.throwIfCancelled();
      
      final frame = await _extractFrameAt(media, timestamp);
      yield SampledFrame(
        timestamp: timestamp,
        data: frame,
        isSceneChange: sceneChanges.any((s) => 
          (s.timestamp - timestamp).abs() < Duration(milliseconds: 100)),
      );
    }
  }
  
  /// Detect scene changes using FFmpeg scene filter
  Future<List<SceneChange>> _detectSceneChanges(
    MediaFile media, {
    double threshold = 0.4,
  }) async {
    // ffmpeg -i input.mp4 -vf "select='gt(scene,0.4)',showinfo" -f null -
    final result = await _ffmpeg.runFilter(
      media.path,
      filter: "select='gt(scene,$threshold)',showinfo",
      outputFormat: 'null',
    );
    
    return _parseSceneChangeOutput(result.stderr);
  }
}
```

---

## Temporal Aggregation for Visual Analysis

```dart
/// Aggregate frame-by-frame results into coherent timeline segments
class TemporalAggregator {
  /// Minimum duration for a segment to be considered
  final Duration minimumSegmentDuration;
  
  /// Gap tolerance for merging adjacent detections
  final Duration mergeGapTolerance;
  
  /// Hysteresis thresholds for start/stop
  final double startThreshold;
  final double stopThreshold;
  
  TemporalAggregator({
    this.minimumSegmentDuration = const Duration(milliseconds: 500),
    this.mergeGapTolerance = const Duration(milliseconds: 500),
    this.startThreshold = 0.6,
    this.stopThreshold = 0.4,
  });
  
  /// Aggregate frame results into timeline segments
  List<TimelineSegment> aggregate(
    List<FrameAnalysisResult> frameResults,
    ContentType contentType,
  ) {
    final segments = <TimelineSegment>[];
    TimelineSegment? currentSegment;
    bool inSegment = false;
    
    for (final frame in frameResults) {
      final score = _getScore(frame, contentType);
      
      if (!inSegment && score >= startThreshold) {
        // Start new segment (hysteresis: high threshold to start)
        inSegment = true;
        currentSegment = TimelineSegment(
          start: frame.timestamp,
          end: frame.timestamp,
          type: contentType,
          confidence: score,
        );
      } else if (inSegment) {
        if (score >= stopThreshold) {
          // Continue segment (hysteresis: lower threshold to continue)
          currentSegment = currentSegment!.copyWith(
            end: frame.timestamp,
            confidence: (currentSegment.confidence + score) / 2,
          );
        } else {
          // End segment
          inSegment = false;
          if (currentSegment!.duration >= minimumSegmentDuration) {
            segments.add(currentSegment);
          }
          currentSegment = null;
        }
      }
    }
    
    // Close any open segment
    if (currentSegment != null && 
        currentSegment.duration >= minimumSegmentDuration) {
      segments.add(currentSegment);
    }
    
    // Merge segments within gap tolerance
    return _mergeAdjacentSegments(segments);
  }
  
  List<TimelineSegment> _mergeAdjacentSegments(List<TimelineSegment> segments) {
    if (segments.length < 2) return segments;
    
    final merged = <TimelineSegment>[];
    var current = segments.first;
    
    for (var i = 1; i < segments.length; i++) {
      final next = segments[i];
      
      if (current.type == next.type &&
          next.start - current.end <= mergeGapTolerance) {
        // Merge
        current = current.copyWith(
          end: next.end,
          confidence: (current.confidence + next.confidence) / 2,
        );
      } else {
        merged.add(current);
        current = next;
      }
    }
    
    merged.add(current);
    return merged;
  }
  
  double _getScore(FrameAnalysisResult frame, ContentType type) {
    switch (type) {
      case ContentType.nsfw:
        return frame.nsfw.unsafeScore;
      case ContentType.violence:
        return frame.violence.violent;
      case ContentType.blood:
        return frame.blood?.detected ?? 0.0;
      default:
        return 0.0;
    }
  }
}
```

---

## Profanity Detection with Phonetic Matching

```dart
/// Advanced profanity detection with multiple matching strategies
class ProfanityDetector {
  final Map<String, Set<String>> _wordLists = {};
  final Set<String> _customWords = {};
  final Set<String> _excludedWords = {};
  
  /// Double Metaphone encoder for phonetic matching
  late final DoubleMetaphone _metaphone;
  
  /// Levenshtein distance calculator
  late final LevenshteinDistance _levenshtein;
  
  ProfanityDetector() {
    _metaphone = DoubleMetaphone();
    _levenshtein = LevenshteinDistance();
  }
  
  /// Detect profanity with multiple strategies
  List<ProfanityMatch> detect(Transcript transcript) {
    final matches = <ProfanityMatch>[];
    
    for (final segment in transcript.segments) {
      for (final word in segment.words) {
        final match = _matchWord(word);
        if (match != null) {
          matches.add(match);
        }
      }
      
      // Also check multi-word phrases
      final phraseMatches = _matchPhrases(segment);
      matches.addAll(phraseMatches);
    }
    
    return matches;
  }
  
  ProfanityMatch? _matchWord(TranscriptWord word) {
    final normalized = _normalize(word.word);
    
    if (_excludedWords.contains(normalized)) {
      return null;
    }
    
    // Strategy 1: Exact match
    if (_isInWordList(normalized)) {
      return ProfanityMatch(
        word: word,
        matchedProfanity: normalized,
        confidence: 1.0,
        type: MatchType.exact,
      );
    }
    
    // Strategy 2: Leetspeak normalization
    final leetNormalized = _normalizeLeetspeak(normalized);
    if (leetNormalized != normalized && _isInWordList(leetNormalized)) {
      return ProfanityMatch(
        word: word,
        matchedProfanity: leetNormalized,
        confidence: 0.95,
        type: MatchType.leetspeak,
      );
    }
    
    // Strategy 3: Phonetic matching (catches ASR mishearings)
    final phoneticMatch = _findPhoneticMatch(normalized);
    if (phoneticMatch != null) {
      return ProfanityMatch(
        word: word,
        matchedProfanity: phoneticMatch.word,
        confidence: phoneticMatch.confidence,
        type: MatchType.phonetic,
      );
    }
    
    // Strategy 4: Edit distance (catches typos/partial words)
    final fuzzyMatch = _findFuzzyMatch(normalized);
    if (fuzzyMatch != null) {
      return ProfanityMatch(
        word: word,
        matchedProfanity: fuzzyMatch.word,
        confidence: fuzzyMatch.confidence,
        type: MatchType.fuzzy,
      );
    }
    
    // Strategy 5: Obfuscation patterns (f***, sh--)
    final deobfuscated = _deobfuscate(normalized);
    if (deobfuscated != normalized && _isInWordList(deobfuscated)) {
      return ProfanityMatch(
        word: word,
        matchedProfanity: deobfuscated,
        confidence: 0.9,
        type: MatchType.obfuscated,
      );
    }
    
    return null;
  }
  
  /// Phonetic matching using Double Metaphone
  _PhoneticMatchResult? _findPhoneticMatch(String word) {
    final codes = _metaphone.encode(word);
    
    for (final listWord in _allProfaneWords) {
      final listCodes = _metaphone.encode(listWord);
      
      if (codes.primary == listCodes.primary ||
          codes.primary == listCodes.alternate ||
          codes.alternate == listCodes.primary) {
        // Phonetic match - calculate confidence based on similarity
        final similarity = 1.0 - (_levenshtein.distance(word, listWord) / 
            max(word.length, listWord.length));
        
        if (similarity >= 0.7) {
          return _PhoneticMatchResult(
            word: listWord,
            confidence: similarity * 0.9, // Cap at 0.9 for phonetic
          );
        }
      }
    }
    
    return null;
  }
  
  /// Fuzzy matching with edit distance
  _PhoneticMatchResult? _findFuzzyMatch(String word) {
    // Only for words of length >= 4 to avoid false positives
    if (word.length < 4) return null;
    
    final maxDistance = (word.length / 4).ceil(); // 25% tolerance
    
    for (final listWord in _allProfaneWords) {
      if ((listWord.length - word.length).abs() > maxDistance) continue;
      
      final distance = _levenshtein.distance(word, listWord);
      if (distance <= maxDistance) {
        final confidence = 1.0 - (distance / word.length);
        if (confidence >= 0.75) {
          return _PhoneticMatchResult(
            word: listWord,
            confidence: confidence * 0.85, // Cap at 0.85 for fuzzy
          );
        }
      }
    }
    
    return null;
  }
  
  /// Leetspeak normalization
  String _normalizeLeetspeak(String word) {
    const leetspeakMap = {
      '0': 'o', '1': 'i', '3': 'e', '4': 'a', '5': 's',
      '7': 't', '8': 'b', '@': 'a', '\$': 's', '!': 'i',
      '(': 'c', ')': 'd', '|': 'l', '+': 't',
    };
    
    var result = word;
    leetspeakMap.forEach((leet, letter) {
      result = result.replaceAll(leet, letter);
    });
    
    return result;
  }
  
  /// Deobfuscate masked profanity (f***, sh--)
  String _deobfuscate(String word) {
    // Remove common masking characters
    final cleaned = word.replaceAll(RegExp(r'[\*\-\_\.\#]'), '');
    
    if (cleaned.length < 3) return word;
    
    // Try to match partial patterns
    for (final profane in _allProfaneWords) {
      if (profane.length == word.length) {
        // Check if non-mask characters match
        var matches = true;
        for (var i = 0; i < word.length; i++) {
          if (!RegExp(r'[\*\-\_\.\#]').hasMatch(word[i])) {
            if (word[i].toLowerCase() != profane[i].toLowerCase()) {
              matches = false;
              break;
            }
          }
        }
        if (matches) return profane;
      }
    }
    
    return cleaned;
  }
}

class _PhoneticMatchResult {
  final String word;
  final double confidence;
  
  _PhoneticMatchResult({required this.word, required this.confidence});
}
```

---

## GPU Detection and Fallback

```dart
/// Detect GPU capabilities and select optimal acceleration
class GPUAccelerationManager {
  AcceleratorInfo? _detectedAccelerator;
  bool _initialized = false;
  
  /// Detect available GPU acceleration
  Future<AcceleratorInfo> detectAccelerator() async {
    if (_initialized) return _detectedAccelerator!;
    
    // Try accelerators in order of preference
    final accelerators = [
      _tryNvidiaCuda,
      _tryAppleMetal,
      _tryAmdRocm,
      _tryIntelOneAPI,
      _tryVulkan,
      _tryCPU,
    ];
    
    for (final tryAccelerator in accelerators) {
      final result = await tryAccelerator();
      if (result != null) {
        _detectedAccelerator = result;
        _initialized = true;
        return result;
      }
    }
    
    // Fallback to CPU
    _detectedAccelerator = AcceleratorInfo(
      type: AcceleratorType.cpu,
      name: 'CPU',
      vramMB: 0,
      recommendedBatchSize: 1,
    );
    _initialized = true;
    return _detectedAccelerator!;
  }
  
  Future<AcceleratorInfo?> _tryNvidiaCuda() async {
    if (!Platform.isWindows && !Platform.isLinux) return null;
    
    try {
      // Check for CUDA runtime
      final cudaLib = DynamicLibrary.open(
        Platform.isWindows ? 'cudart64_12.dll' : 'libcudart.so.12',
      );
      
      // Query GPU properties
      final props = await _queryCudaProperties();
      
      return AcceleratorInfo(
        type: AcceleratorType.cuda,
        name: props.deviceName,
        vramMB: props.totalMemoryMB,
        computeCapability: '${props.major}.${props.minor}',
        recommendedBatchSize: _calculateOptimalBatch(props.totalMemoryMB),
      );
    } catch (e) {
      return null;
    }
  }
  
  Future<AcceleratorInfo?> _tryAppleMetal() async {
    if (!Platform.isMacOS) return null;
    
    try {
      // Query Metal device
      final metalInfo = await _queryMetalDevice();
      
      return AcceleratorInfo(
        type: AcceleratorType.metal,
        name: metalInfo.deviceName,
        vramMB: metalInfo.recommendedMaxWorkingSetSize ~/ (1024 * 1024),
        isAppleSilicon: metalInfo.isAppleSilicon,
        recommendedBatchSize: metalInfo.isAppleSilicon ? 8 : 4,
      );
    } catch (e) {
      return null;
    }
  }
  
  Future<AcceleratorInfo?> _tryVulkan() async {
    try {
      final vulkanLib = DynamicLibrary.open(
        Platform.isWindows ? 'vulkan-1.dll' :
        Platform.isMacOS ? 'libMoltenVK.dylib' : 'libvulkan.so.1',
      );
      
      final props = await _queryVulkanProperties();
      
      return AcceleratorInfo(
        type: AcceleratorType.vulkan,
        name: props.deviceName,
        vramMB: props.memoryHeapsMB,
        recommendedBatchSize: 4,
      );
    } catch (e) {
      return null;
    }
  }
  
  int _calculateOptimalBatch(int vramMB) {
    // Assuming ~200MB per batch item for typical models
    const bytesPerBatch = 200;
    final maxBatch = vramMB ~/ bytesPerBatch;
    return min(max(maxBatch, 1), 16); // Clamp to 1-16
  }
  
  /// Get ONNX execution providers in priority order
  List<String> getOnnxExecutionProviders() {
    switch (_detectedAccelerator?.type) {
      case AcceleratorType.cuda:
        return ['CUDAExecutionProvider', 'CPUExecutionProvider'];
      case AcceleratorType.metal:
        return ['CoreMLExecutionProvider', 'CPUExecutionProvider'];
      case AcceleratorType.rocm:
        return ['ROCMExecutionProvider', 'CPUExecutionProvider'];
      case AcceleratorType.vulkan:
        return ['VulkanExecutionProvider', 'CPUExecutionProvider'];
      default:
        return ['CPUExecutionProvider'];
    }
  }
}

class AcceleratorInfo {
  final AcceleratorType type;
  final String name;
  final int vramMB;
  final String? computeCapability;
  final bool isAppleSilicon;
  final int recommendedBatchSize;
  
  AcceleratorInfo({
    required this.type,
    required this.name,
    required this.vramMB,
    this.computeCapability,
    this.isAppleSilicon = false,
    required this.recommendedBatchSize,
  });
}

enum AcceleratorType {
  cpu,
  cuda,
  metal,
  rocm,
  vulkan,
  oneapi,
}
```

---

## Unified Timeline Data Structure

```dart
/// Track-based composition model for complex edits
class UnifiedTimeline {
  final Duration mediaDuration;
  final List<TimelineTrack> tracks;
  
  UnifiedTimeline({
    required this.mediaDuration,
    List<TimelineTrack>? tracks,
  }) : tracks = tracks ?? [
    TimelineTrack(type: TrackType.audio, name: 'Audio Modifications'),
    TimelineTrack(type: TrackType.video, name: 'Video Modifications'),
    TimelineTrack(type: TrackType.detection, name: 'Detections'),
  ];
  
  /// Get all modifications affecting a specific time
  List<Modification> getModificationsAt(Duration time) {
    return tracks
        .expand((track) => track.segments)
        .where((seg) => seg.start <= time && seg.end >= time)
        .map((seg) => seg.modification)
        .whereType<Modification>()
        .toList();
  }
  
  /// Check for overlapping modifications on same track
  List<OverlapConflict> findConflicts() {
    final conflicts = <OverlapConflict>[];
    
    for (final track in tracks) {
      final segments = track.segments.toList()
        ..sort((a, b) => a.start.compareTo(b.start));
      
      for (var i = 0; i < segments.length - 1; i++) {
        final current = segments[i];
        final next = segments[i + 1];
        
        if (current.end > next.start) {
          conflicts.add(OverlapConflict(
            track: track,
            segment1: current,
            segment2: next,
            overlapDuration: current.end - next.start,
          ));
        }
      }
    }
    
    return conflicts;
  }
  
  /// Resolve conflicts with specified strategy
  void resolveConflicts(ConflictResolution strategy) {
    for (final track in tracks) {
      switch (strategy) {
        case ConflictResolution.keepFirst:
          _resolveKeepFirst(track);
          break;
        case ConflictResolution.keepLast:
          _resolveKeepLast(track);
          break;
        case ConflictResolution.merge:
          _resolveMerge(track);
          break;
        case ConflictResolution.split:
          _resolveSplit(track);
          break;
      }
    }
  }
  
  /// Export to EDL (Edit Decision List) format
  String toEDL() {
    final buffer = StringBuffer();
    buffer.writeln('TITLE: KidsLens Export');
    buffer.writeln('FCM: NON-DROP FRAME');
    buffer.writeln();
    
    var eventNumber = 1;
    for (final track in tracks) {
      for (final segment in track.segments) {
        buffer.writeln(
          '${eventNumber.toString().padLeft(3, '0')}  '
          '${segment.modification?.type ?? 'DETECT'}  '
          '${_formatTimecode(segment.start)}  '
          '${_formatTimecode(segment.end)}'
        );
        eventNumber++;
      }
    }
    
    return buffer.toString();
  }
}

class TimelineTrack {
  final TrackType type;
  final String name;
  final List<TimelineSegment> segments;
  bool isLocked;
  bool isVisible;
  
  TimelineTrack({
    required this.type,
    required this.name,
    List<TimelineSegment>? segments,
    this.isLocked = false,
    this.isVisible = true,
  }) : segments = segments ?? [];
  
  void addSegment(TimelineSegment segment) {
    segments.add(segment);
    segments.sort((a, b) => a.start.compareTo(b.start));
  }
}

enum TrackType { audio, video, detection, custom }

enum ConflictResolution { keepFirst, keepLast, merge, split }
```

---

## A/V Synchronization

```dart
/// Ensures audio and video modifications remain synchronized
class AVSyncManager {
  /// Timestamp tolerance for considering A/V in sync
  static const Duration syncTolerance = Duration(milliseconds: 40);
  
  /// Merge audio and video timelines into synchronized output
  SynchronizedTimeline synchronize(
    List<TimelineSegment> audioMods,
    List<TimelineSegment> videoMods,
  ) {
    final allPoints = <Duration>{};
    
    // Collect all boundary points
    for (final mod in [...audioMods, ...videoMods]) {
      allPoints.add(mod.start);
      allPoints.add(mod.end);
    }
    
    // Snap nearby points together within tolerance
    final snappedPoints = _snapPoints(allPoints.toList()..sort());
    
    // Create synchronized segments
    final syncedSegments = <SynchronizedSegment>[];
    
    for (var i = 0; i < snappedPoints.length - 1; i++) {
      final start = snappedPoints[i];
      final end = snappedPoints[i + 1];
      
      final activeAudio = audioMods
          .where((m) => _overlaps(m, start, end))
          .toList();
      final activeVideo = videoMods
          .where((m) => _overlaps(m, start, end))
          .toList();
      
      if (activeAudio.isNotEmpty || activeVideo.isNotEmpty) {
        syncedSegments.add(SynchronizedSegment(
          start: start,
          end: end,
          audioModifications: activeAudio,
          videoModifications: activeVideo,
        ));
      }
    }
    
    return SynchronizedTimeline(segments: syncedSegments);
  }
  
  List<Duration> _snapPoints(List<Duration> points) {
    if (points.isEmpty) return points;
    
    final snapped = <Duration>[points.first];
    
    for (var i = 1; i < points.length; i++) {
      final current = points[i];
      final previous = snapped.last;
      
      if (current - previous <= syncTolerance) {
        // Snap to midpoint
        snapped.removeLast();
        snapped.add(Duration(
          microseconds: (current.inMicroseconds + previous.inMicroseconds) ~/ 2,
        ));
      } else {
        snapped.add(current);
      }
    }
    
    return snapped;
  }
  
  bool _overlaps(TimelineSegment seg, Duration start, Duration end) {
    return seg.start < end && seg.end > start;
  }
}

class SynchronizedSegment {
  final Duration start;
  final Duration end;
  final List<TimelineSegment> audioModifications;
  final List<TimelineSegment> videoModifications;
  
  Duration get duration => end - start;
  
  SynchronizedSegment({
    required this.start,
    required this.end,
    required this.audioModifications,
    required this.videoModifications,
  });
}

class SynchronizedTimeline {
  final List<SynchronizedSegment> segments;
  
  SynchronizedTimeline({required this.segments});
  
  /// Generate FFmpeg filter complex for synchronized modifications
  String toFFmpegFilterComplex() {
    final audioFilters = <String>[];
    final videoFilters = <String>[];
    
    for (final segment in segments) {
      final enable = "enable='between(t,${segment.start.inMilliseconds/1000},"
          "${segment.end.inMilliseconds/1000})'";
      
      // Audio filters
      for (final mod in segment.audioModifications) {
        audioFilters.add(_audioModToFilter(mod, enable));
      }
      
      // Video filters
      for (final mod in segment.videoModifications) {
        videoFilters.add(_videoModToFilter(mod, enable));
      }
    }
    
    return '''
      [0:a]${audioFilters.join(',')}[a];
      [0:v]${videoFilters.join(',')}[v]
    ''';
  }
  
  String _audioModToFilter(TimelineSegment mod, String enable) {
    switch (mod.modification) {
      case AudioMute():
        return "volume=0:$enable";
      case AudioBeep(frequency: final f):
        return "aevalsrc='sin($f*2*PI*t)':$enable";
      default:
        return "";
    }
  }
  
  String _videoModToFilter(TimelineSegment mod, String enable) {
    switch (mod.modification) {
      case VideoBlur(intensity: final i):
        return "boxblur=$i:$i:$enable";
      case VideoPixelate(blockSize: final b):
        return "scale=iw/$b:ih/$b,scale=iw*$b:ih*$b:flags=neighbor:$enable";
      case VideoBlackBox():
        return "drawbox=0:0:iw:ih:black:t=fill:$enable";
      default:
        return "";
    }
  }
}
```

---

## Detection Review UI

```dart
/// UI for reviewing and correcting AI detections using Riverpod
class DetectionReviewScreen extends ConsumerStatefulWidget {
  final MediaFile media;
  
  const DetectionReviewScreen({super.key, required this.media});
  
  @override
  ConsumerState<DetectionReviewScreen> createState() => _DetectionReviewScreenState();
}

class _DetectionReviewScreenState extends ConsumerState<DetectionReviewScreen> {
  int _currentIndex = 0;
  ContentType? _filterType;
  
  @override
  Widget build(BuildContext context) {
    final timelineState = ref.watch(timelineNotifierProvider);
    final timeline = timelineState.timeline;
    
    if (timeline == null) {
      return const Scaffold(
        body: Center(child: Text('No analysis results available')),
      );
    }
    
    // Get filtered detections
    final allDetections = timeline.detections;
    final detections = _filterType != null
        ? allDetections.where((d) => d.type == _filterType).toList()
        : allDetections;
    
    if (detections.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.reviewDetections)),
        body: Center(child: Text(l10n.noDetectionsFound)),
      );
    }
    
    final detection = detections[_currentIndex.clamp(0, detections.length - 1)];
    final reviewedCount = detections
        .where((d) => d.userStatus != DetectionUserStatus.pending)
        .length;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.reviewDetections} (${_currentIndex + 1}/${detections.length})'),
        actions: [
          // Filter by type
          PopupMenuButton<ContentType?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (type) => setState(() {
              _filterType = type;
              _currentIndex = 0;
            }),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All')),
              ...ContentType.values.map((t) => 
                PopupMenuItem(value: t, child: Text(t.displayName))
              ),
            ],
          ),
          // Export feedback
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportFeedback(timeline),
            tooltip: l10n.exportFeedback,
          ),
        ],
      ),
      body: Column(
        children: [
          // Video preview at detection timestamp
          Expanded(
            flex: 2,
            child: DetectionPreviewPlayer(
              media: widget.media,
              timestamp: detection.startTime,
              duration: detection.duration,
            ),
          ),
          
          // Detection info card
          DetectionInfoCard(
            detection: detection,
            onConfirmCorrect: () => ref
                .read(timelineNotifierProvider.notifier)
                .confirmDetection(detection.id),
            onMarkFalsePositive: () => ref
                .read(timelineNotifierProvider.notifier)
                .rejectDetection(detection.id),
            onAdjustTimestamp: () => _showTimestampEditor(detection),
          ),
          
          // Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _currentIndex > 0 
                    ? () => setState(() => _currentIndex--) 
                    : null,
              ),
              // Quick actions
              ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Colors.green),
                label: Text(l10n.correct),
                onPressed: () {
                  ref.read(timelineNotifierProvider.notifier)
                      .confirmDetection(detection.id);
                  _goToNext(detections.length);
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.close, color: Colors.red),
                label: Text(l10n.falsePositive),
                onPressed: () {
                  ref.read(timelineNotifierProvider.notifier)
                      .rejectDetection(detection.id);
                  _goToNext(detections.length);
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _currentIndex < detections.length - 1 
                    ? () => setState(() => _currentIndex++) 
                    : null,
              ),
            ],
          ),
          
          // Progress indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: reviewedCount / detections.length,
                ),
                const SizedBox(height: 8),
                Text('$reviewedCount of ${detections.length} reviewed'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _goToNext(int total) {
    if (_currentIndex < total - 1) {
      setState(() => _currentIndex++);
    }
  }
  
  void _showTimestampEditor(Detection detection) {
    showDialog(
      context: context,
      builder: (context) => TimestampAdjustmentDialog(
        initialStart: detection.startTime,
        initialEnd: detection.endTime,
        media: widget.media,
        onSave: (newStart, newEnd) {
          ref.read(timelineNotifierProvider.notifier).adjustDetectionBounds(
            detection.id,
            newStart: newStart,
            newEnd: newEnd,
          );
        },
      ),
    );
  }
  
  Future<void> _exportFeedback(UnifiedTimeline timeline) async {
    final feedback = FeedbackExport(
      mediaHash: await widget.media.computeHash(),
      detections: timeline.detections.map((d) => d.toFeedback()).toList(),
      modelVersions: timeline.modelVersions,
      exportDate: DateTime.now(),
    );
    
    final path = await getSaveLocation(
      suggestedName: 'kidslens_feedback.json',
    );
    
    if (path != null) {
      await File(path).writeAsString(jsonEncode(feedback.toJson()));
    }
  }
}

/// Detection data model (immutable, stored in timeline)
@freezed
class Detection with _$Detection {
  const factory Detection({
    required String id,
    required ContentType type,
    required Duration startTime,
    required Duration endTime,
    required double confidence,
    required String description,
    @Default(DetectionUserStatus.pending) DetectionUserStatus userStatus,
    String? userNote,
  }) = _Detection;
  
  Duration get duration => endTime - startTime;
}

enum DetectionUserStatus {
  pending,
  confirmed,
  rejected,
  adjusted,
}
```

---

## Error Handling System

```dart
/// Typed error hierarchy for the application
sealed class KidsLensError implements Exception {
  final String message;
  final String? technicalDetails;
  final bool isRetryable;
  
  const KidsLensError(this.message, {
    this.technicalDetails,
    this.isRetryable = false,
  });
  
  String get userMessage;
  String get remediation;
}

class ModelDownloadError extends KidsLensError {
  final String modelId;
  final int? httpStatusCode;
  
  const ModelDownloadError(this.modelId, {
    super.message = 'Failed to download model',
    super.technicalDetails,
    this.httpStatusCode,
  }) : super(isRetryable: true);
  
  @override
  String get userMessage => 'Could not download the $modelId model.';
  
  @override
  String get remediation => 'Check your internet connection and try again.';
}

class GPUInitializationError extends KidsLensError {
  final AcceleratorType attemptedType;
  
  const GPUInitializationError(this.attemptedType, {
    super.message = 'GPU initialization failed',
    super.technicalDetails,
  }) : super(isRetryable: true);
  
  @override
  String get userMessage => 
      'Could not initialize ${attemptedType.name} acceleration.';
  
  @override
  String get remediation => 
      'The app will use CPU processing instead. This may be slower.';
}

class UnsupportedMediaError extends KidsLensError {
  final String? codec;
  final String? container;
  
  const UnsupportedMediaError({
    this.codec,
    this.container,
    super.message = 'Unsupported media format',
  }) : super(isRetryable: false);
  
  @override
  String get userMessage => 
      'This media format is not supported: ${codec ?? container ?? "unknown"}';
  
  @override
  String get remediation => 
      'Try converting the file to MP4 (H.264) format first.';
}

class CorruptedMediaError extends KidsLensError {
  final String? probeError;
  
  const CorruptedMediaError({
    this.probeError,
    super.message = 'Media file appears corrupted',
  }) : super(isRetryable: false);
  
  @override
  String get userMessage => 'The media file could not be read properly.';
  
  @override
  String get remediation => 
      'The file may be corrupted or incomplete. Try re-downloading it.';
}

class OutOfMemoryError extends KidsLensError {
  final int requiredMB;
  final int availableMB;
  
  const OutOfMemoryError({
    required this.requiredMB,
    required this.availableMB,
    super.message = 'Not enough memory',
  }) : super(isRetryable: true);
  
  @override
  String get userMessage => 
      'Not enough memory available (need ${requiredMB}MB, have ${availableMB}MB).';
  
  @override
  String get remediation => 
      'Close other applications or try with a smaller model.';
}

class InsufficientDiskSpaceError extends KidsLensError {
  final int requiredMB;
  final int availableMB;
  
  const InsufficientDiskSpaceError({
    required this.requiredMB,
    required this.availableMB,
    super.message = 'Not enough disk space',
  }) : super(isRetryable: true);
  
  @override
  String get userMessage => 
      'Not enough disk space (need ${requiredMB}MB, have ${availableMB}MB).';
  
  @override
  String get remediation => 
      'Free up disk space and try again.';
}

/// Error handler with retry logic
class ErrorHandler {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    bool Function(Exception)? shouldRetry,
  }) async {
    var attempt = 0;
    
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        final isRetryable = e is KidsLensError && e.isRetryable;
        final customRetryable = shouldRetry?.call(e as Exception) ?? false;
        
        if ((isRetryable || customRetryable) && attempt < maxRetries) {
          await Future.delayed(retryDelay * attempt);
          continue;
        }
        
        rethrow;
      }
    }
  }
}
```

---

## ONNX Model Validation

```dart
/// Validate ONNX models before use
class ONNXModelValidator {
  /// Validate model structure and compatibility
  Future<ModelValidationResult> validate(String modelPath) async {
    final file = File(modelPath);
    if (!await file.exists()) {
      return ModelValidationResult.error('Model file not found');
    }
    
    try {
      // Load model metadata without running inference
      final metadata = await _loadModelMetadata(modelPath);
      
      // Check opset version
      if (metadata.opsetVersion < 11) {
        return ModelValidationResult.warning(
          'Model uses opset ${metadata.opsetVersion}, may have compatibility issues',
        );
      }
      
      // Validate input shapes
      for (final input in metadata.inputs) {
        if (input.shape.contains(-1) && !input.shape.first == -1) {
          // Only batch dimension should be dynamic
          return ModelValidationResult.warning(
            'Model has dynamic shapes beyond batch dimension',
          );
        }
      }
      
      // Check for quantization
      final isQuantized = metadata.isQuantized;
      
      return ModelValidationResult.success(
        metadata: metadata,
        isQuantized: isQuantized,
      );
      
    } catch (e) {
      return ModelValidationResult.error('Failed to validate model: $e');
    }
  }
  
  Future<ModelMetadata> _loadModelMetadata(String path) async {
    // Use ONNX Runtime to inspect model
    final session = await _createInspectionSession(path);
    
    final inputs = session.inputNames.map((name) {
      final info = session.getInputInfo(name);
      return TensorInfo(
        name: name,
        shape: info.shape,
        dtype: info.dtype,
      );
    }).toList();
    
    final outputs = session.outputNames.map((name) {
      final info = session.getOutputInfo(name);
      return TensorInfo(
        name: name,
        shape: info.shape,
        dtype: info.dtype,
      );
    }).toList();
    
    session.release();
    
    return ModelMetadata(
      inputs: inputs,
      outputs: outputs,
      opsetVersion: await _getOpsetVersion(path),
      isQuantized: await _checkQuantization(path),
    );
  }
}

class ModelMetadata {
  final List<TensorInfo> inputs;
  final List<TensorInfo> outputs;
  final int opsetVersion;
  final bool isQuantized;
  
  ModelMetadata({
    required this.inputs,
    required this.outputs,
    required this.opsetVersion,
    required this.isQuantized,
  });
}

class TensorInfo {
  final String name;
  final List<int> shape;
  final String dtype;
  
  TensorInfo({
    required this.name,
    required this.shape,
    required this.dtype,
  });
}

class ModelValidationResult {
  final bool isValid;
  final String? warningMessage;
  final String? errorMessage;
  final ModelMetadata? metadata;
  final bool isQuantized;
  
  ModelValidationResult.success({
    this.metadata,
    this.isQuantized = false,
  }) : isValid = true, warningMessage = null, errorMessage = null;
  
  ModelValidationResult.warning(this.warningMessage)
      : isValid = true, errorMessage = null, metadata = null, isQuantized = false;
  
  ModelValidationResult.error(this.errorMessage)
      : isValid = false, warningMessage = null, metadata = null, isQuantized = false;
}
```

---

## Performance Monitoring

```dart
/// Monitor and adapt to performance characteristics
class PerformanceMonitor {
  final Map<String, List<Duration>> _operationTimings = {};
  final Map<String, int> _operationCounts = {};
  
  /// Record operation timing
  Future<T> measure<T>(String operation, Future<T> Function() fn) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await fn();
    } finally {
      stopwatch.stop();
      _recordTiming(operation, stopwatch.elapsed);
    }
  }
  
  void _recordTiming(String operation, Duration duration) {
    _operationTimings.putIfAbsent(operation, () => []);
    _operationTimings[operation]!.add(duration);
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
    
    // Keep only last 100 timings
    if (_operationTimings[operation]!.length > 100) {
      _operationTimings[operation]!.removeAt(0);
    }
  }
  
  /// Get average timing for an operation
  Duration getAverageTiming(String operation) {
    final timings = _operationTimings[operation];
    if (timings == null || timings.isEmpty) {
      return Duration.zero;
    }
    
    final totalMicroseconds = timings.fold<int>(
      0, 
      (sum, d) => sum + d.inMicroseconds,
    );
    
    return Duration(microseconds: totalMicroseconds ~/ timings.length);
  }
  
  /// Estimate remaining time for analysis
  Duration estimateRemainingTime({
    required int totalFrames,
    required int analyzedFrames,
    required Duration audioDuration,
    required Duration transcribedDuration,
  }) {
    final frameAnalysisRate = getAverageTiming('frame_analysis');
    final transcriptionRate = getAverageTiming('transcription_chunk');
    
    final remainingFrames = totalFrames - analyzedFrames;
    final remainingAudio = audioDuration - transcribedDuration;
    
    final frameTime = frameAnalysisRate * remainingFrames;
    final transcriptionTime = Duration(
      microseconds: (remainingAudio.inMicroseconds * 
          transcriptionRate.inMicroseconds / 
          const Duration(seconds: 30).inMicroseconds).round(),
    );
    
    return frameTime > transcriptionTime ? frameTime : transcriptionTime;
  }
  
  /// Generate performance report
  PerformanceReport generateReport() {
    return PerformanceReport(
      operationAverages: Map.fromEntries(
        _operationTimings.keys.map((op) => 
          MapEntry(op, getAverageTiming(op)),
        ),
      ),
      operationCounts: Map.from(_operationCounts),
      timestamp: DateTime.now(),
    );
  }
}

/// Adaptive quality controller based on performance
class AdaptiveQualityController {
  final PerformanceMonitor _monitor;
  
  /// Target: analysis should complete within 3x real-time
  static const double targetRealtimeMultiple = 3.0;
  
  AdaptiveQualityController(this._monitor);
  
  /// Adjust frame sampling rate based on performance
  double adjustFrameSamplingRate(double currentFps, Duration mediaDuration) {
    final avgFrameTime = _monitor.getAverageTiming('frame_analysis');
    
    // Calculate current analysis rate
    final framesPerSecond = 1000000 / avgFrameTime.inMicroseconds;
    final currentMultiple = mediaDuration.inSeconds * currentFps / 
        (mediaDuration.inSeconds * framesPerSecond);
    
    if (currentMultiple > targetRealtimeMultiple * 1.2) {
      // Too slow, reduce sampling rate
      return currentFps * 0.75;
    } else if (currentMultiple < targetRealtimeMultiple * 0.5) {
      // Fast enough, can increase quality
      return min(currentFps * 1.25, 5.0); // Max 5 fps
    }
    
    return currentFps;
  }
  
  /// Recommend model tier based on performance
  ModelTier recommendModelTier(Duration mediaDuration) {
    final cpuScore = _calculateCPUScore();
    final gpuScore = _calculateGPUScore();
    
    final totalScore = cpuScore + gpuScore;
    
    if (totalScore >= 80) return ModelTier.maximum;
    if (totalScore >= 60) return ModelTier.high;
    if (totalScore >= 40) return ModelTier.balanced;
    if (totalScore >= 20) return ModelTier.performance;
    return ModelTier.minimum;
  }
  
  double _calculateCPUScore() {
    // Based on observed performance
    final transcriptionRate = _monitor.getAverageTiming('transcription_chunk');
    // Baseline: 30s chunk in 15s = 2x realtime = 50 points
    return (30 / transcriptionRate.inSeconds * 25).clamp(0, 50);
  }
  
  double _calculateGPUScore() {
    final frameAnalysisRate = _monitor.getAverageTiming('frame_analysis');
    // Baseline: 100ms per frame = 50 points
    return (100 / frameAnalysisRate.inMilliseconds * 50).clamp(0, 50);
  }
}

enum ModelTier {
  minimum,    // tiny models only
  performance, // base/small models
  balanced,    // small/medium models
  high,        // medium/large models
  maximum,     // large models + all features
}
```

---

## Artifact Format Specification

```dart
/// Versioned analysis artifact for caching and resume
class AnalysisArtifact {
  static const int currentVersion = 1;
  
  final int version;
  final String mediaHash;
  final MediaMetadata mediaMetadata;
  final AnalysisSettings settingsUsed;
  final ModelVersions modelVersions;
  final Transcript? transcript;
  final List<ProfanityMatch> profanityMatches;
  final List<FrameAnalysisResult> frameResults;
  final UnifiedTimeline timeline;
  final DateTime createdAt;
  final DateTime? completedAt;
  final AnalysisStatus status;
  
  AnalysisArtifact({
    this.version = currentVersion,
    required this.mediaHash,
    required this.mediaMetadata,
    required this.settingsUsed,
    required this.modelVersions,
    this.transcript,
    required this.profanityMatches,
    required this.frameResults,
    required this.timeline,
    required this.createdAt,
    this.completedAt,
    required this.status,
  });
  
  /// Save artifact to JSON file
  Future<void> save(String path) async {
    final json = toJson();
    await File(path).writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }
  
  /// Load artifact from JSON file
  static Future<AnalysisArtifact?> load(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    
    final json = jsonDecode(await file.readAsString());
    
    // Check version compatibility
    final version = json['version'] as int;
    if (version > currentVersion) {
      throw IncompatibleArtifactError(
        'Artifact version $version is newer than supported ($currentVersion)',
      );
    }
    
    return AnalysisArtifact.fromJson(json);
  }
  
  /// Check if artifact can be reused for given settings
  bool isCompatibleWith(AnalysisSettings newSettings) {
    // Same model versions
    if (modelVersions != newSettings.modelVersions) return false;
    
    // Thresholds can be re-applied without re-analysis
    return true;
  }
  
  /// Regenerate timeline with new thresholds
  UnifiedTimeline regenerateTimeline(AnalysisSettings newSettings) {
    // Re-run profanity detection with new word list
    final newProfanity = ProfanityDetector(newSettings.profanityConfig)
        .detect(transcript!);
    
    // Re-run temporal aggregation with new thresholds
    final aggregator = TemporalAggregator(
      startThreshold: newSettings.nsfwStartThreshold,
      stopThreshold: newSettings.nsfwStopThreshold,
    );
    
    final nsfwSegments = aggregator.aggregate(frameResults, ContentType.nsfw);
    final violenceSegments = aggregator.aggregate(frameResults, ContentType.violence);
    
    // Build new timeline
    return UnifiedTimeline.fromSegments([
      ...newProfanity.map((m) => m.toTimelineSegment()),
      ...nsfwSegments,
      ...violenceSegments,
    ]);
  }
  
  Map<String, dynamic> toJson() => {
    'version': version,
    'mediaHash': mediaHash,
    'mediaMetadata': mediaMetadata.toJson(),
    'settingsUsed': settingsUsed.toJson(),
    'modelVersions': modelVersions.toJson(),
    'transcript': transcript?.toJson(),
    'profanityMatches': profanityMatches.map((m) => m.toJson()).toList(),
    'frameResults': frameResults.map((r) => r.toJson()).toList(),
    'timeline': timeline.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'status': status.name,
  };
}

class ModelVersions {
  final String? whisperModel;
  final String? mmsModel;
  final String nsfwModel;
  final String violenceModel;
  final String? bloodModel;
  final String? weaponsModel;
  
  ModelVersions({
    this.whisperModel,
    this.mmsModel,
    required this.nsfwModel,
    required this.violenceModel,
    this.bloodModel,
    this.weaponsModel,
  });
  
  @override
  bool operator ==(Object other) =>
      other is ModelVersions &&
      whisperModel == other.whisperModel &&
      mmsModel == other.mmsModel &&
      nsfwModel == other.nsfwModel &&
      violenceModel == other.violenceModel;
  
  @override
  int get hashCode => Object.hash(whisperModel, mmsModel, nsfwModel, violenceModel);
}
```

---

## UI Attribution Screen

```dart
/// About screen with legal disclaimer and model attributions
class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // App info
          _AppInfoSection(),
          
          Divider(height: 32),
          
          // Legal disclaimer
          _LegalDisclaimerSection(),
          
          Divider(height: 32),
          
          // Model attributions
          _ModelAttributionsSection(),
          
          Divider(height: 32),
          
          // Open source licenses
          _OpenSourceLicensesSection(),
        ],
      ),
    );
  }
}

class _LegalDisclaimerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.legalDisclaimer,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        Text(
          '''
KidsLens is designed to help identify and filter potentially inappropriate content in videos. However:

• AI detection is not 100% accurate. Always review detected content before sharing.
• This tool is intended for personal use with content you own or have rights to modify.
• Users are responsible for ensuring their use complies with applicable laws and content licenses.
• KidsLens does not collect, transmit, or store any of your media content.
• All processing is performed locally on your device.
          ''',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ModelAttributionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aiModelAttributions,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        
        _AttributionCard(
          title: 'OpenAI Whisper',
          description: 'Automatic Speech Recognition',
          license: 'MIT License',
          url: 'https://github.com/openai/whisper',
        ),
        
        _AttributionCard(
          title: 'whisper.cpp',
          description: 'C++ implementation of Whisper',
          license: 'MIT License',
          author: 'Georgi Gerganov',
          url: 'https://github.com/ggerganov/whisper.cpp',
        ),
        
        _AttributionCard(
          title: 'Meta MMS (Massively Multilingual Speech)',
          description: 'Multilingual ASR for 1100+ languages',
          license: 'MIT License',
          author: 'Meta AI',
          url: 'https://github.com/facebookresearch/fairseq',
        ),
        
        _AttributionCard(
          title: 'NSFW Detection Model',
          description: 'Content classification for images',
          license: 'MIT License',
          author: 'GantMan',
          url: 'https://github.com/GantMan/nsfw_model',
        ),
        
        _AttributionCard(
          title: 'Violence Detection (ViT)',
          description: 'Vision Transformer for violence classification',
          license: 'Apache 2.0',
          author: 'jaranohaal',
          url: 'https://huggingface.co/jaranohaal/vit-base-violence-detection',
        ),
        
        _AttributionCard(
          title: 'LDNOOBW Profanity Word Lists',
          description: 'Multilingual profanity word lists (29 languages)',
          license: 'CC-BY-4.0',
          author: 'Shutterstock',
          url: 'https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words',
        ),
        
        _AttributionCard(
          title: 'ONNX Runtime',
          description: 'Cross-platform ML inference engine',
          license: 'MIT License',
          author: 'Microsoft',
          url: 'https://github.com/microsoft/onnxruntime',
        ),
        
        _AttributionCard(
          title: 'FFmpeg',
          description: 'Media processing toolkit',
          license: 'LGPL 2.1+',
          url: 'https://ffmpeg.org',
        ),
      ],
    );
  }
}

class _AttributionCard extends StatelessWidget {
  final String title;
  final String description;
  final String license;
  final String? author;
  final String url;
  
  const _AttributionCard({
    required this.title,
    required this.description,
    required this.license,
    this.author,
    required this.url,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            SizedBox(height: 4),
            Row(
              children: [
                Chip(label: Text(license, style: TextStyle(fontSize: 10))),
                if (author != null) ...[
                  SizedBox(width: 8),
                  Text('by $author', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.open_in_new),
          onPressed: () => launchUrl(Uri.parse(url)),
        ),
        isThreeLine: true,
      ),
    );
  }
}
```

---

## Project Structure

```
kidslens-video-editor/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── l10n/
│   │   ├── arb_parser.dart          # Custom ARB parser
│   │   ├── app_en.arb
│   │   ├── app_es.arb
│   │   └── app_ar.arb
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   │   ├── app_exceptions.dart
│   │   │   └── error_handler.dart
│   │   ├── extensions/
│   │   ├── utils/
│   │   └── di/
│   │       └── service_locator.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── media_file.dart
│   │   │   ├── transcript.dart
│   │   │   ├── analysis_result.dart
│   │   │   ├── timeline.dart
│   │   │   ├── artifact.dart
│   │   │   └── modification.dart
│   │   └── repositories/
│   ├── state/
│   │   ├── providers/
│   │   │   ├── media_provider.dart        # @riverpod MediaNotifier
│   │   │   ├── media_provider.g.dart      # Generated
│   │   │   ├── analysis_provider.dart     # @riverpod AnalysisNotifier
│   │   │   ├── analysis_provider.g.dart   # Generated
│   │   │   ├── timeline_provider.dart     # @riverpod TimelineNotifier
│   │   │   ├── timeline_provider.g.dart   # Generated
│   │   │   ├── model_provider.dart        # @riverpod ModelNotifier
│   │   │   └── model_provider.g.dart      # Generated
│   │   └── notifiers/
│   ├── presentation/
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── import_screen.dart
│   │   │   ├── preview_screen.dart
│   │   │   ├── timeline_editor_screen.dart
│   │   │   ├── detection_review_screen.dart
│   │   │   ├── sample_analysis_screen.dart
│   │   │   ├── model_selection_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   ├── export_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   └── about_screen.dart
│   │   ├── widgets/
│   │   │   ├── common/
│   │   │   ├── timeline/
│   │   │   │   ├── timeline_track.dart
│   │   │   │   ├── timeline_segment.dart
│   │   │   │   └── timestamp_editor.dart
│   │   │   ├── player/
│   │   │   │   ├── video_player.dart      # Custom FFmpeg-based player
│   │   │   │   ├── player_controls.dart
│   │   │   │   └── thumbnail_strip.dart
│   │   │   ├── detection/
│   │   │   │   ├── detection_card.dart
│   │   │   │   └── confidence_indicator.dart
│   │   │   ├── model/
│   │   │   │   ├── model_card.dart
│   │   │   │   └── hardware_info_card.dart
│   │   │   └── dialogs/
│   │   └── themes/
│   ├── services/
│   │   ├── media_service.dart
│   │   ├── asr_service.dart
│   │   ├── visual_analysis_service.dart
│   │   ├── profanity_service.dart
│   │   ├── timeline_service.dart
│   │   ├── modification_service.dart
│   │   ├── model_manager_service.dart
│   │   ├── sample_analysis_service.dart
│   │   ├── export_service.dart
│   │   └── performance_monitor.dart
│   ├── jobs/
│   │   ├── job_system.dart
│   │   ├── analysis_job.dart
│   │   ├── export_job.dart
│   │   ├── cancellation_token.dart
│   │   └── checkpoint_manager.dart
│   └── native/
│       ├── bindings/
│       │   ├── ffmpeg_bindings.dart
│       │   ├── whisper_bindings.dart
│       │   ├── mms_bindings.dart
│       │   └── onnx_bindings.dart
│       ├── resource_manager.dart
│       ├── frame_buffer_pool.dart
│       ├── gpu_manager.dart
│       └── memory_monitor.dart
├── native/
│   ├── ffmpeg/
│   │   ├── CMakeLists.txt
│   │   ├── ffmpeg_wrapper.h
│   │   ├── ffmpeg_wrapper.cpp
│   │   └── build_scripts/
│   │       ├── build_windows.ps1
│   │       ├── build_macos.sh
│   │       └── build_linux.sh
│   ├── whisper/
│   │   ├── CMakeLists.txt
│   │   ├── whisper_wrapper.h
│   │   ├── whisper_wrapper.cpp
│   │   └── build_scripts/
│   ├── mms/
│   │   ├── CMakeLists.txt
│   │   ├── mms_wrapper.h
│   │   ├── mms_wrapper.cpp
│   │   └── build_scripts/
│   └── onnx/
│       ├── CMakeLists.txt
│       ├── onnx_wrapper.h
│       ├── onnx_wrapper.cpp
│       └── build_scripts/
├── assets/
│   ├── wordlists/
│   │   ├── ar.txt
│   │   ├── en.txt
│   │   ├── es.txt
│   │   └── ... (29 languages)
│   └── audio/
│       └── beep_1000hz.wav
├── test/
│   ├── unit/
│   │   ├── profanity_detector_test.dart
│   │   ├── temporal_aggregator_test.dart
│   │   └── timeline_test.dart
│   ├── integration/
│   │   ├── analysis_pipeline_test.dart
│   │   └── export_test.dart
│   ├── golden/
│   │   └── timeline_generation/
│   └── performance/
│       ├── frame_analysis_benchmark.dart
│       └── transcription_benchmark.dart
├── scripts/
│   ├── build_native_libs.ps1
│   ├── download_test_fixtures.dart
│   └── generate_bindings.dart
├── docs/
│   └── implement/
│       ├── implementation-plan.md
│       ├── ai-models-reference.md
│       └── mobile-future-plan.md
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## Implementation Phases

### Phase 0: Project Foundation (Weeks 1-2)

**Goals:**
- Project scaffolding and CI/CD
- Walking skeleton: FFmpeg + Whisper proof of concept
- Native build pipeline validation

**Deliverables:**
1. Flutter project structure
2. CMake build system for native libraries
3. FFmpeg "hello world" (probe file metadata)
4. whisper.cpp "hello world" (transcribe 5s audio)
5. CI pipeline for Windows/macOS/Linux
6. Documentation of native artifact contract

### Phase 1: Core Native Layer (Weeks 3-6)

**Goals:**
- Complete FFmpeg FFI bindings
- Complete whisper.cpp FFI bindings
- Meta MMS integration
- ONNX Runtime FFI bindings

**Deliverables:**
1. Native resource manager with finalizers
2. Frame buffer pool with backpressure
3. FFmpeg wrapper (probe, extract audio, extract frames, filter graphs, mux)
4. Whisper wrapper (transcribe with word timestamps)
5. MMS wrapper (transcribe multilingual)
6. ONNX wrapper (load model, run inference)
7. GPU detection and acceleration manager
8. Unit tests for all bindings

### Phase 2: Analysis Pipeline (Weeks 7-10)

**Goals:**
- ASR service with model selection
- Visual analysis with scene detection + sampling
- Profanity detection with phonetic matching
- Temporal aggregation

**Deliverables:**
1. ASR service (Whisper + MMS with user selection)
2. Frame sampling with scene detection
3. NSFW classifier integration
4. Violence classifier integration
5. Blood/gore detection
6. Weapons detection (optional)
7. Profanity detector with all matching strategies
8. Temporal aggregator with hysteresis
9. Unified timeline builder
10. Analysis artifact format and caching

### Phase 3: Job System & Resilience (Weeks 11-13)

**Goals:**
- Job system with state machine
- Checkpoint/resume support
- Cancellation handling
- Error recovery

**Deliverables:**
1. Job system (queued/running/paused/cancelled/completed)
2. CancellationToken pattern
3. Checkpoint manager with artifact persistence
4. Retry logic with exponential backoff
5. Graceful degradation (GPU→CPU fallback)
6. Memory pressure handling
7. Error taxonomy and user-facing messages

### Phase 4: UI Foundation (Weeks 14-17)

**Goals:**
- Custom video player
- State management system
- Core screens
- Localization system

**Deliverables:**
1. Riverpod providers with code generation (@riverpod)
2. Custom ARB parser for localization
3. Custom video player (FFmpeg decode → Flutter texture)
4. Import screen with format detection
5. Preview screen with playback controls
6. Settings screen
7. Model selection screen with hardware info
8. Onboarding flow
9. About screen with attributions

### Phase 5: Timeline & Detection Review (Weeks 18-21)

**Goals:**
- Timeline editor
- Detection review UI
- Sample analysis mode
- Modification preview

**Deliverables:**
1. Track-based timeline editor
2. Detection overlay visualization
3. Detection review screen with confirm/reject/adjust
4. Sample analysis (5-second preview)
5. Timestamp adjustment UI
6. Modification preview (low-res or overlay)
7. Progress UI with ETA
8. Feedback export

### Phase 6: Export & Modifications (Weeks 22-25)

**Goals:**
- Audio modifications (mute, beep)
- Video modifications (blur, pixelate, black box, skip)
- A/V sync manager
- Export with quality options

**Deliverables:**
1. Audio modification filters
2. Video modification filters
3. A/V synchronization manager
4. FFmpeg filter complex generator
5. Export job with progress
6. Quality/format selection
7. Lossless re-mux where possible
8. Export presets

### Phase 7: Polish & Performance (Weeks 26-28)

**Goals:**
- Performance optimization
- Adaptive quality
- Additional languages
- Documentation

**Deliverables:**
1. Performance monitoring and logging
2. Adaptive quality controller
3. Parallel analysis with isolate pool
4. Model quantization support
5. Additional UI languages
6. User documentation
7. Performance tuning

### Phase 8: Testing & Release (Weeks 29-32)

**Goals:**
- Comprehensive testing
- Bug fixes
- Release preparation

**Deliverables:**
1. Unit tests (>80% coverage)
2. Integration tests
3. Golden tests for timeline generation
4. Performance regression tests
5. Platform-specific installers (MSIX, DMG, AppImage)
6. Release builds with code signing
7. User documentation finalization

---

## Hardware Requirements

### Minimum Requirements

| Component | Specification |
|-----------|---------------|
| CPU | 4 cores, 2.0 GHz |
| RAM | 8 GB |
| GPU | Integrated (CPU inference) |
| Storage | 10 GB free |
| Recommended Models | Whisper tiny, NSFW-MobileNet, Violence-MobileNet |

### Recommended Requirements

| Component | Specification |
|-----------|---------------|
| CPU | 8 cores, 3.0 GHz |
| RAM | 16 GB |
| GPU | NVIDIA RTX 3060+ / Apple M1+ |
| Storage | 30 GB free (SSD) |
| Recommended Models | Whisper small, NSFW-Inception, Violence-ViT |

### High-End Requirements

| Component | Specification |
|-----------|---------------|
| CPU | 12+ cores, 3.5 GHz |
| RAM | 32 GB |
| GPU | NVIDIA RTX 4070+ / Apple M2 Pro+ |
| Storage | 50 GB free (NVMe SSD) |
| Recommended Models | Whisper large-v3-turbo, Meta MMS, All detectors |

---

## Success Metrics

1. **Processing Speed**: ≤ 3x real-time for full analysis on recommended hardware
2. **Detection Accuracy**: > 95% precision for profanity, > 90% for visual content
3. **Sample Analysis**: < 10 seconds for 5-second sample
4. **Export Quality**: Visually lossless with modifications applied
5. **Memory Usage**: < 4GB RAM for standard analysis
6. **Resume Capability**: 100% checkpoint/resume reliability
7. **False Positive Rate**: < 10% with default thresholds
8. **User Correction Time**: < 30 seconds to review/correct a detection

---

*Document Version: 2.0*  
*Last Updated: January 2025*  
*Authors: KidsLens Development Team*
