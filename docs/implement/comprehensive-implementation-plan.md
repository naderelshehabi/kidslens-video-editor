# KidsLens Video Editor - Comprehensive Implementation Plan

## Executive Summary

This document provides a detailed audit of the current codebase against the original implementation plan, identifies all TODOs, missing features, and outlines a comprehensive plan to complete the implementation, including:
- Bundling FFmpeg with the application binaries
- Analysis Settings page with model selection and download from HuggingFace
- UI for configurable model parameters (model sizes: tiny/base/small/medium/large variants)

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-29 | Initial audit and plan |
| 1.1 | 2026-01-29 | Added Analysis Settings page, model download UI, second-pass audit |

---

## Part 1: Codebase Audit - Implementation Status

### 1.1 Core Architecture Components

| Component | Status | Notes |
|-----------|--------|-------|
| Project Structure | ✅ Complete | Follows planned directory structure |
| Flutter/Riverpod Setup | ✅ Complete | Proper provider architecture in place |
| Data Models (Freezed) | ✅ Complete | All core models implemented |
| Error Handling System | ✅ Complete | Typed exception hierarchy exists |
| Job System | ✅ Complete | Job, cancellation, checkpointing implemented |

### 1.2 Native Bindings (FFI)

| Component | Status | Notes |
|-----------|--------|-------|
| FFmpeg Bindings | ⚠️ Partial | Uses CLI (PATH), NOT native FFI as planned |
| Whisper Bindings | ❌ Stub Only | TODO: Actual FFI implementation needed |
| ONNX Runtime Bindings | ❌ Stub Only | TODO: Actual FFI implementation needed |
| MMS Bindings | ❌ Stub Only | TODO: Actual FFI implementation needed |

### 1.3 Services

| Service | Status | Notes |
|---------|--------|-------|
| MediaService | ✅ Complete | Full implementation |
| AnalysisService | ⚠️ Partial | Structure complete, needs real AI backends |
| ProfanityService | ⚠️ Partial | Missing: wordlist loading, Double Metaphone |
| ModelManagerService | ⚠️ Partial | Download logic exists, needs full integration |
| ExportService | ✅ Complete | Full FFmpeg filter complex support |
| ThumbnailService | ✅ Complete | Working implementation |
| SampleAnalysisService | ⚠️ Partial | Missing: scene detection, actual sample extraction |
| BeepAudioService | ✅ Complete | Beep tone generation working |
| ProjectService | ✅ Complete | Project persistence working |

### 1.4 Missing Services (Per Implementation Plan)

| Service | Status | Notes |
|---------|--------|-------|
| ASRService | ❌ Missing | Dedicated ASR orchestration service |
| VisualAnalysisService | ❌ Missing | Visual content moderation service |
| TimelineService | ❌ Missing | Timeline manipulation service |
| ModificationService | ❌ Missing | Apply modifications to media |
| PerformanceMonitor | ❌ Missing | Performance tracking and adaptive quality |

### 1.5 UI Screens

| Screen | Status | Notes |
|--------|--------|-------|
| EditorScreen | ✅ Complete | Main editing interface |
| OnboardingScreen | ⚠️ Basic | In app.dart, needs full implementation |
| AboutScreen | ❌ Missing | Legal disclaimer, model attributions |
| AnalysisSettingsScreen | ❌ Missing | **NEW** Model selection, download, parameters |
| ModelDownloadPage | ❌ Missing | **NEW** HuggingFace model browser/downloader |
| DetectionReviewScreen | ❌ Missing | Dedicated detection review UI |
| SettingsScreen | ❌ Missing | User settings/preferences |
| SampleAnalysisScreen | ❌ Missing | Test detection on samples |

### 1.6 Native Resource Management

| Component | Status | Notes |
|-----------|--------|-------|
| NativeResourceManager | ✅ Complete | Finalizer-based cleanup |
| FrameBufferPool | ✅ Complete | Backpressure support |
| MemoryMonitor | ✅ Complete | Cross-platform memory monitoring |
| GPUAccelerationManager | ⚠️ Partial | CUDA/Metal detection, Vulkan TODO |

### 1.7 Analysis Pipeline Components

| Component | Status | Notes |
|-----------|--------|-------|
| TemporalAggregator | ❌ Missing | Aggregate frame results into segments |
| FrameSamplingService | ❌ Missing | Intelligent frame sampling |
| AVSyncManager | ❌ Missing | Audio/video sync management |
| ONNXModelValidator | ❌ Missing | Model validation before use |
| AdaptiveQualityController | ❌ Missing | Dynamic quality adjustment |

---

## Part 2: All TODOs in Codebase

### 2.1 Native Bindings TODOs

#### `lib/native/bindings/whisper_bindings.dart:45`
```dart
// TODO: Implement actual Whisper transcription via FFI
```
**Priority:** HIGH
**Effort:** Large
**Description:** Replace placeholder with actual whisper.cpp FFI bindings.

#### `lib/native/bindings/onnx_bindings.dart:21`
```dart
// TODO: Initialize ONNX Runtime session options with execution providers
```
**Priority:** HIGH
**Effort:** Medium
**Description:** Configure GPU/CPU execution providers.

#### `lib/native/bindings/onnx_bindings.dart:45`
```dart
// TODO: Implement actual ONNX model loading
```
**Priority:** HIGH
**Effort:** Large
**Description:** Load ONNX models via FFI.

#### `lib/native/bindings/onnx_bindings.dart:67`
```dart
// TODO: Implement actual ONNX inference
```
**Priority:** HIGH
**Effort:** Large
**Description:** Run inference on image data.

#### `lib/native/bindings/onnx_bindings.dart:101`
```dart
// TODO: Implement actual metadata extraction
```
**Priority:** MEDIUM
**Effort:** Small
**Description:** Extract input/output tensor shapes from model.

#### `lib/native/bindings/mms_bindings.dart:44`
```dart
// TODO: Implement actual MMS transcription via FFI
```
**Priority:** HIGH
**Effort:** Large
**Description:** Implement Meta MMS FFI bindings.

#### `lib/native/bindings/mms_bindings.dart:96`
```dart
// TODO: Implement language detection
```
**Priority:** MEDIUM
**Effort:** Medium
**Description:** Detect spoken language in audio.

### 2.2 Service Layer TODOs

#### `lib/services/profanity_service.dart:13`
```dart
// TODO: Load from assets/wordlists/{language}.txt
```
**Priority:** HIGH
**Effort:** Small
**Description:** Load profanity wordlists from assets.

#### `lib/services/profanity_service.dart:132`
```dart
// TODO: Implement Double Metaphone encoding
```
**Priority:** MEDIUM
**Effort:** Medium
**Description:** Phonetic matching for profanity detection.

#### `lib/services/sample_analysis_service.dart:59`
```dart
// TODO: Implement scene change detection to find interesting segments
```
**Priority:** MEDIUM
**Effort:** Medium
**Description:** Use FFmpeg scene detection for sample selection.

#### `lib/services/sample_analysis_service.dart:78`
```dart
// TODO: Extract sample segment and run analysis
```
**Priority:** MEDIUM
**Effort:** Medium
**Description:** Extract and analyze sample video segment.

### 2.3 Provider TODOs

#### `lib/state/providers/model_provider.dart:52`
```dart
// TODO: Implement actual model loading via ModelManagerService
```
**Priority:** HIGH
**Effort:** Medium
**Description:** Connect provider to ModelManagerService.

#### `lib/state/providers/model_provider.dart:78`
```dart
// TODO: Implement actual model download via ModelManagerService
```
**Priority:** HIGH
**Effort:** Medium
**Description:** Implement download progress streaming.

#### `lib/state/providers/model_provider.dart:109`
```dart
// TODO: Implement actual model deletion via ModelManagerService
```
**Priority:** LOW
**Effort:** Small
**Description:** Delete downloaded model files.

### 2.4 Utility TODOs

#### `lib/core/utils/file_utils.dart:292`
```dart
// TODO: Implement platform-specific disk space check
```
**Priority:** LOW
**Effort:** Medium
**Description:** Check available disk space before download/export.

### 2.5 GPU Manager TODOs

#### `lib/native/gpu_manager.dart:88`
```dart
// TODO: Implement Vulkan detection
```
**Priority:** LOW
**Effort:** Medium
**Description:** Detect Vulkan GPU support on Linux.

### 2.6 UI TODOs

#### `lib/presentation/screens/editor_screen.dart:556`
```dart
// TODO: Implement playback toggle
```
**Priority:** MEDIUM
**Effort:** Small
**Description:** Toggle video playback in editor.

---

## Part 3: New Requirement - Bundled FFmpeg

### 3.1 Current State

The application currently relies on FFmpeg being installed on the user's system and accessible via PATH:
- Uses `Process.run()` to call `ffmpeg` and `ffprobe` CLI tools
- Searches common installation paths as fallback
- Shows error if FFmpeg not found

### 3.2 Target State

Bundle FFmpeg binaries with the application for each platform:
- Windows: x64 and ARM64 builds
- macOS: Universal binary (Intel + Apple Silicon)
- Linux: x64 and ARM64 builds

### 3.3 Implementation Approach

Two options available:

**Option A: Bundled FFmpeg CLI (Recommended for v1.0)**
- Bundle pre-built FFmpeg/FFprobe executables with app
- Modify FFmpegBindings to use bundled binaries
- Simpler implementation, proven stability

**Option B: FFmpeg FFI (Future Enhancement)**
- Create native C wrapper around FFmpeg libraries
- Direct FFI calls for better performance
- More complex, requires per-platform builds

---

## Part 4: Implementation Phases

### Phase 1: FFmpeg Bundling (1-2 weeks)

#### 1.1 Create Native Assets Structure
```
native/
├── ffmpeg/
│   ├── binaries/
│   │   ├── windows/
│   │   │   ├── x64/
│   │   │   │   ├── ffmpeg.exe
│   │   │   │   └── ffprobe.exe
│   │   │   └── arm64/
│   │   ├── macos/
│   │   │   └── universal/
│   │   │       ├── ffmpeg
│   │   │       └── ffprobe
│   │   └── linux/
│   │       ├── x64/
│   │       └── arm64/
│   ├── download_ffmpeg.dart    # Script to download binaries
│   └── README.md               # Build/license information
```

#### 1.2 Tasks

| Task | Description | Effort |
|------|-------------|--------|
| 1.2.1 | Create directory structure | Small |
| 1.2.2 | Write FFmpeg download script | Medium |
| 1.2.3 | Update FFmpegBindings to locate bundled binaries | Medium |
| 1.2.4 | Configure CMake/platform builds to include binaries | Medium |
| 1.2.5 | Add FFmpeg license (LGPL) to attribution screen | Small |
| 1.2.6 | Test on all target platforms | Medium |

#### 1.3 FFmpegBindings Modification

```dart
class FFmpegBindings extends NativeResource {
  // New: Get bundled binary path
  String? _getBundledFFmpegPath() {
    final executableDir = Platform.resolvedExecutable;
    final appDir = path.dirname(executableDir);
    
    String binaryName;
    String platformDir;
    
    if (Platform.isWindows) {
      binaryName = 'ffmpeg.exe';
      platformDir = 'windows';
    } else if (Platform.isMacOS) {
      binaryName = 'ffmpeg';
      platformDir = 'macos';
    } else if (Platform.isLinux) {
      binaryName = 'ffmpeg';
      platformDir = 'linux';
    } else {
      return null;
    }
    
    // Check bundled location
    final bundledPath = path.join(appDir, 'ffmpeg', binaryName);
    if (File(bundledPath).existsSync()) {
      return bundledPath;
    }
    
    return null;
  }
  
  Future<String?> _findExecutable(String name) async {
    // First, try bundled binary
    final bundled = _getBundledFFmpegPath();
    if (bundled != null) {
      return bundled.replaceAll('ffmpeg', name);
    }
    
    // Fallback to system PATH...
  }
}
```

---

### Phase 2: Complete Profanity Detection (1 week)

#### 2.1 Tasks

| Task | Description | Effort |
|------|-------------|--------|
| 2.1.1 | Create profanity wordlists for 29 languages | Medium |
| 2.1.2 | Implement asset loading in ProfanityService | Small |
| 2.1.3 | Implement Double Metaphone algorithm | Medium |
| 2.1.4 | Add configurable sensitivity thresholds | Small |
| 2.1.5 | Write unit tests for profanity detection | Medium |

#### 2.2 Wordlist Structure
```
assets/wordlists/
├── en.txt      # English
├── es.txt      # Spanish
├── ar.txt      # Arabic
├── de.txt      # German
├── fr.txt      # French
├── ... (29 languages total)
└── metadata.json  # Language metadata
```

---

### Phase 3: Native FFI Bindings (4-6 weeks)

#### 3.1 Whisper.cpp Integration

| Task | Description | Effort |
|------|-------------|--------|
| 3.1.1 | Create C wrapper for whisper.cpp | Large |
| 3.1.2 | Write CMake build scripts per platform | Medium |
| 3.1.3 | Generate Dart FFI bindings (ffigen) | Medium |
| 3.1.4 | Implement streaming transcription | Medium |
| 3.1.5 | Add model loading/unloading | Medium |
| 3.1.6 | Implement word-level timestamps | Medium |
| 3.1.7 | Test all Whisper model sizes | Medium |

#### 3.2 ONNX Runtime Integration

| Task | Description | Effort |
|------|-------------|--------|
| 3.2.1 | Create C wrapper for ONNX Runtime | Large |
| 3.2.2 | Implement GPU execution provider support | Medium |
| 3.2.3 | Generate Dart FFI bindings | Medium |
| 3.2.4 | Implement batch inference | Medium |
| 3.2.5 | Add model validation | Small |
| 3.2.6 | Memory management for tensors | Medium |

#### 3.3 Meta MMS Integration (Optional)

| Task | Description | Effort |
|------|-------------|--------|
| 3.3.1 | Create C wrapper for fairseq2 | Large |
| 3.3.2 | Platform-specific builds | Large |
| 3.3.3 | Generate Dart FFI bindings | Medium |
| 3.3.4 | Implement language detection | Medium |

---

### Phase 4: Missing Services (2-3 weeks)

#### 4.1 ASRService

```dart
/// lib/services/asr_service.dart
class ASRService {
  final WhisperBindings whisper;
  final MMSBindings mms;
  final ModelManagerService modelManager;
  
  /// Transcribe audio with automatic model selection
  Stream<TranscriptionProgress> transcribe(
    String audioPath, {
    String? language,
    ASRModel? preferredModel,
  });
  
  /// Get recommended model for hardware
  ASRModel getRecommendedModel();
}
```

#### 4.2 VisualAnalysisService

```dart
/// lib/services/visual_analysis_service.dart
class VisualAnalysisService {
  final ONNXBindings onnx;
  final ModelManagerService modelManager;
  final FrameBufferPool framePool;
  
  /// Analyze frames for content moderation
  Stream<FrameAnalysisProgress> analyzeFrames(
    Stream<FrameData> frames,
    VisualAnalysisSettings settings,
  );
  
  /// Run inference on single frame
  Future<FrameAnalysisResult> analyzeFrame(FrameData frame);
}
```

#### 4.3 TemporalAggregator

```dart
/// lib/services/temporal_aggregator.dart
class TemporalAggregator {
  /// Aggregate frame results into coherent segments
  List<TimelineSegment> aggregate(
    List<FrameAnalysisResult> frameResults, {
    Duration minSegmentDuration = const Duration(milliseconds: 500),
    Duration hysteresis = const Duration(milliseconds: 200),
  });
}
```

#### 4.4 FrameSamplingService

```dart
/// lib/services/frame_sampling_service.dart
class FrameSamplingService {
  final FFmpegBindings ffmpeg;
  
  /// Get frames using intelligent sampling
  Stream<FrameData> sampleFrames(
    String videoPath, {
    double baseFps = 2.0,
    bool includeKeyframes = true,
    bool boostOnSceneChange = true,
  });
}
```

#### 4.5 PerformanceMonitor

```dart
/// lib/services/performance_monitor.dart
class PerformanceMonitor {
  /// Record operation timing
  void recordTiming(String operation, Duration duration);
  
  /// Get average timing for operation
  Duration? getAverageTiming(String operation);
  
  /// Determine optimal model tier for hardware
  ModelTier getRecommendedTier();
}
```

---

### Phase 5: Missing UI Screens (3-4 weeks)

#### 5.1 AnalysisSettingsScreen (NEW - HIGH PRIORITY)

```dart
/// lib/presentation/screens/analysis_settings/analysis_settings_screen.dart
class AnalysisSettingsScreen extends ConsumerStatefulWidget {
  // Opened from "Analysis Settings" menu
  // Navigation sidebar with tabs:
  // - ASR Models (download, select Whisper variants)
  // - Visual Models (download, select NSFW/Violence/etc.)
  // - Detection Thresholds (sensitivity sliders)
  // - Model Configuration (language, GPU, threads)
  // - Performance (memory limits, batch size)
  
  // Features:
  // - Browse models by parameter count (39M to 1.55B)
  // - Download from HuggingFace with progress
  // - Show hardware requirements vs available
  // - Select active model per category
  // - Configure model-specific parameters
}
```

#### 5.2 DetectionReviewScreen

```dart
/// lib/presentation/screens/detection_review_screen.dart  
class DetectionReviewScreen extends ConsumerStatefulWidget {
  // List all detections with preview
  // Accept/Reject/Adjust controls
  // Jump to detection in timeline
  // Batch operations
}
```

#### 5.3 SettingsScreen

```dart
/// lib/presentation/screens/settings_screen.dart
class SettingsScreen extends ConsumerWidget {
  // General app settings (theme, language)
  // Default modification types
  // Export quality defaults
  // Cache management
  // (Note: Model/detection settings moved to AnalysisSettingsScreen)
}
```

#### 5.4 AboutScreen

```dart
/// lib/presentation/screens/about_screen.dart
class AboutScreen extends StatelessWidget {
  // App version info
  // Legal disclaimer
  // Model attributions (Whisper, ONNX, etc.)
  // Open source licenses
  // Privacy statement
}
```

#### 5.5 SampleAnalysisScreen

```dart
/// lib/presentation/screens/sample_analysis_screen.dart
class SampleAnalysisScreen extends ConsumerStatefulWidget {
  // Select sample segment
  // Preview sample
  // Run quick analysis
  // Adjust settings before full analysis
}
```

---

### Phase 6: Integration & Polish (2 weeks)

#### 6.1 Connect Model Provider to Service

| Task | Description | Effort |
|------|-------------|--------|
| 6.1.1 | Wire ModelProvider to ModelManagerService | Medium |
| 6.1.2 | Implement download progress streaming | Small |
| 6.1.3 | Add model validation on download complete | Small |
| 6.1.4 | Persist selected model configuration | Small |

#### 6.2 Complete Sample Analysis

| Task | Description | Effort |
|------|-------------|--------|
| 6.2.1 | Implement segment extraction | Medium |
| 6.2.2 | Wire to scene change detection | Small |
| 6.2.3 | Quick analysis pipeline | Medium |
| 6.2.4 | Settings preview UI | Medium |

#### 6.3 Playback Integration

| Task | Description | Effort |
|------|-------------|--------|
| 6.3.1 | Implement playback toggle | Small |
| 6.3.2 | Sync playhead with video | Small |
| 6.3.3 | Preview modifications in real-time | Medium |

#### 6.4 Disk Space Checks

| Task | Description | Effort |
|------|-------------|--------|
| 6.4.1 | Windows disk space via FFI | Small |
| 6.4.2 | macOS disk space via FFI | Small |
| 6.4.3 | Linux disk space via FFI | Small |
| 6.4.4 | Pre-download/export validation | Small |

---

## Part 5: Implementation Priority Matrix

### Critical Path (Must Complete)

| Priority | Item | Blocks |
|----------|------|--------|
| 1 | FFmpeg Bundling | Export, Thumbnails, Playback |
| 2 | Profanity Wordlist Loading | Audio Detection |
| 3 | Model Provider Integration | AI Features |
| 4 | Whisper FFI or Fallback | Transcription |
| 5 | ONNX FFI or Fallback | Visual Detection |

### High Priority (v1.0 Release)

| Priority | Item | Reason |
|----------|------|--------|
| 6 | ModelSelectionScreen | User model choice |
| 7 | DetectionReviewScreen | User override capability |
| 8 | AboutScreen | Legal/attribution requirement |
| 9 | Double Metaphone | Profanity accuracy |
| 10 | Playback Toggle | Basic UX |

### Medium Priority (v1.0 Nice-to-Have)

| Priority | Item | Reason |
|----------|------|--------|
| 11 | SampleAnalysisScreen | Quick preview |
| 12 | SettingsScreen | User preferences |
| 13 | TemporalAggregator | Detection quality |
| 14 | FrameSamplingService | Analysis efficiency |
| 15 | Scene Detection Sample Selection | Better samples |

### Lower Priority (Post v1.0)

| Priority | Item | Reason |
|----------|------|--------|
| 16 | MMS Integration | Multi-language support |
| 17 | Vulkan Detection | Linux GPU support |
| 18 | PerformanceMonitor | Optimization |
| 19 | AdaptiveQualityController | Auto-tuning |
| 20 | AVSyncManager | Advanced sync |

---

## Part 6: Estimated Timeline

### Minimal Viable Product (MVP)

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| FFmpeg Bundling | 1-2 weeks | Bundled binaries, updated bindings |
| Profanity Wordlists | 3-5 days | Asset loading, 29 languages |
| Model Integration | 1 week | Provider + Service connection |
| Essential UI | 1 week | ModelSelection, About screens |
| **Total MVP** | **4-5 weeks** | |

### Full v1.0 Release

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| MVP | 4-5 weeks | Core functionality |
| Whisper FFI | 2-3 weeks | Native transcription |
| ONNX FFI | 2-3 weeks | Native inference |
| Detection Review | 1 week | Full review UI |
| Settings & Polish | 1-2 weeks | User configuration |
| Testing & Fixes | 2 weeks | All platforms |
| **Total v1.0** | **12-16 weeks** | |

---

## Part 7: Technical Decisions

### 7.1 FFmpeg Strategy

**Decision: Bundle CLI binaries for v1.0, consider FFI for v2.0**

Rationale:
- CLI approach is proven and stable
- FFI would require significant C wrapper development
- Bundled binaries provide same functionality with less risk
- Can migrate to FFI later if performance demands it

### 7.2 AI Model Fallback

**Decision: Implement stub/fallback for all AI models**

Rationale:
- App should function even if FFI fails to load
- Fallback to external tools (Whisper CLI) if native fails
- Display clear error messages when AI unavailable
- Allow manual transcription input as ultimate fallback

### 7.3 Model Distribution

**Decision: Download on demand from HuggingFace**

Rationale:
- Models are too large to bundle (100MB-4GB each)
- HuggingFace provides reliable CDN
- Support resume for interrupted downloads
- Validate checksums after download

---

## Part 8: File Checklist

### New Files to Create

```
lib/
├── data/
│   └── models/
│       └── huggingface_model.dart          # HuggingFace model data
├── services/
│   ├── asr_service.dart                    # ASR orchestration
│   ├── visual_analysis_service.dart        # Visual moderation
│   ├── temporal_aggregator.dart            # Frame aggregation
│   ├── frame_sampling_service.dart         # Intelligent sampling
│   ├── performance_monitor.dart            # Performance tracking
│   └── huggingface_model_registry.dart     # Model URLs and metadata
├── presentation/
│   ├── screens/
│   │   ├── analysis_settings/              # NEW: Analysis Settings
│   │   │   ├── analysis_settings_screen.dart
│   │   │   ├── asr_models_tab.dart
│   │   │   ├── visual_models_tab.dart
│   │   │   ├── thresholds_tab.dart
│   │   │   ├── model_config_tab.dart
│   │   │   └── performance_tab.dart
│   │   ├── detection_review_screen.dart    # Detection review
│   │   ├── settings_screen.dart            # App settings
│   │   ├── about_screen.dart               # About/legal
│   │   └── sample_analysis_screen.dart     # Sample preview
│   └── widgets/
│       └── models/                         # NEW: Model widgets
│           ├── model_card.dart
│           ├── model_download_button.dart
│           ├── hardware_requirements.dart
│           └── parameter_slider.dart

native/
├── ffmpeg/
│   ├── binaries/
│   │   └── ... (platform binaries)
│   ├── download_ffmpeg.dart
│   └── README.md
├── whisper/
│   ├── CMakeLists.txt
│   ├── whisper_wrapper.h
│   ├── whisper_wrapper.cpp
│   └── build_scripts/
├── onnx/
│   ├── CMakeLists.txt
│   ├── onnx_wrapper.h
│   ├── onnx_wrapper.cpp
│   └── build_scripts/

assets/
└── wordlists/
    ├── en.txt
    ├── es.txt
    ├── ar.txt
    └── ... (26 more languages)

scripts/
├── download_ffmpeg.ps1          # Windows FFmpeg download
├── download_ffmpeg.sh           # Unix FFmpeg download
└── bundle_native_assets.dart    # Package native assets

docs/
└── implement/
    └── comprehensive-implementation-plan.md (this file)
```

### Files to Modify

| File | Modifications |
|------|---------------|
| `lib/native/bindings/ffmpeg_bindings.dart` | Add bundled binary detection |
| `lib/native/bindings/whisper_bindings.dart` | Replace stubs with FFI |
| `lib/native/bindings/onnx_bindings.dart` | Replace stubs with FFI |
| `lib/native/bindings/mms_bindings.dart` | Replace stubs with FFI |
| `lib/services/profanity_service.dart` | Asset loading, Double Metaphone |
| `lib/services/sample_analysis_service.dart` | Scene detection, extraction |
| `lib/services/model_manager_service.dart` | Add HuggingFace download URLs |
| `lib/state/providers/model_provider.dart` | Service integration, download progress |
| `lib/native/gpu_manager.dart` | Vulkan detection |
| `lib/core/utils/file_utils.dart` | Disk space check |
| `lib/presentation/screens/editor_screen.dart` | Wire Analysis Settings menu, playback toggle |
| `lib/data/models/model_info.dart` | Add parameter count, HuggingFace URL fields |
| `lib/app.dart` | Route to new screens |
| `pubspec.yaml` | Asset declarations |
| `windows/CMakeLists.txt` | Bundle FFmpeg |
| `macos/Runner.xcodeproj` | Bundle FFmpeg |
| `linux/CMakeLists.txt` | Bundle FFmpeg |

---

## Part 9: Risk Assessment

### High Risk Items

| Risk | Mitigation |
|------|------------|
| Whisper FFI complexity | Start with CLI fallback, iterate to FFI |
| ONNX cross-platform builds | Use pre-built ONNX Runtime packages |
| FFmpeg licensing | Use LGPL build, document in About screen |
| Large app size with models | Download on demand, offer model choices |

### Medium Risk Items

| Risk | Mitigation |
|------|------------|
| GPU detection failure | Graceful fallback to CPU |
| Memory pressure | FrameBufferPool backpressure |
| Long analysis times | Checkpoint/resume, progress UI |

### Low Risk Items

| Risk | Mitigation |
|------|------------|
| Wordlist quality | Start with vetted lists, allow user additions |
| Platform build differences | CI/CD per platform |

---

## Appendix A: FFmpeg Download Script

```dart
// scripts/download_ffmpeg.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

const ffmpegReleases = {
  'windows-x64': 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip',
  'windows-arm64': 'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-winarm64-gpl.zip',
  'macos-universal': 'https://evermeet.cx/ffmpeg/ffmpeg-6.1.1.zip',
  'linux-x64': 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz',
  'linux-arm64': 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-arm64-static.tar.xz',
};

Future<void> main(List<String> args) async {
  final platform = args.isNotEmpty ? args[0] : _detectPlatform();
  await downloadFFmpeg(platform);
}

String _detectPlatform() {
  if (Platform.isWindows) {
    return Platform.version.contains('arm') ? 'windows-arm64' : 'windows-x64';
  }
  if (Platform.isMacOS) return 'macos-universal';
  if (Platform.isLinux) {
    return Platform.version.contains('arm') ? 'linux-arm64' : 'linux-x64';
  }
  throw UnsupportedError('Unsupported platform');
}

Future<void> downloadFFmpeg(String platform) async {
  final url = ffmpegReleases[platform]!;
  print('Downloading FFmpeg for $platform from $url');
  
  // Download, extract, and place in native/ffmpeg/binaries/{platform}/
  // Implementation details...
}
```

---

## Appendix B: Model Provider Integration Example

```dart
// Updated lib/state/providers/model_provider.dart

@Riverpod(keepAlive: true)
class ModelNotifier extends _$ModelNotifier {
  @override
  ModelState build() => const ModelState();

  ModelManagerService get _service => ref.read(modelManagerServiceProvider);

  Future<void> loadAvailableModels() async {
    state = state.copyWith(isLoading: true);
    try {
      final available = await _service.getAvailableModels();
      final downloaded = await _service.getDownloadedModels();
      
      state = state.copyWith(
        isLoading: false,
        availableModels: available,
        downloadedModels: downloaded,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> downloadModel(String modelId) async {
    try {
      await for (final progress in _service.downloadModel(modelId)) {
        state = state.copyWith(
          activeDownloads: {
            ...state.activeDownloads,
            modelId: progress,
          },
        );
      }
      
      final downloads = Map<String, ModelDownloadProgress>.from(
        state.activeDownloads,
      )..remove(modelId);
      
      state = state.copyWith(
        activeDownloads: downloads,
        downloadedModels: {...state.downloadedModels, modelId},
      );
    } catch (e) {
      // Handle error...
    }
  }
}
```

---

## Part 10: Analysis Settings Page (NEW REQUIREMENT)

### 10.1 Overview

The Analysis Settings page is accessed from the "Analysis Settings" menu item in the Analysis menu. It provides a comprehensive interface for:
- Browsing and downloading AI models from HuggingFace
- Selecting model variants by parameter count (tiny, base, small, medium, large, etc.)
- Configuring model-specific parameters
- Managing detection thresholds and sensitivity

### 10.2 UI Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Analysis Settings                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐                                                         │
│  │   Navigation    │   ┌────────────────────────────────────────────────┐   │
│  │                 │   │                                                │   │
│  │  📊 Models      │   │   Content Area (based on selected tab)         │   │
│  │    ASR Models   │   │                                                │   │
│  │    Visual Models│   │                                                │   │
│  │                 │   │                                                │   │
│  │  ⚙️ Detection   │   │                                                │   │
│  │    Thresholds   │   │                                                │   │
│  │    Profanity    │   │                                                │   │
│  │                 │   │                                                │   │
│  │  🔧 Performance │   │                                                │   │
│  │    GPU Settings │   │                                                │   │
│  │    Memory       │   │                                                │   │
│  │                 │   │                                                │   │
│  └─────────────────┘   └────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 10.3 Model Selection & Download UI

#### ASR Models Tab

```dart
/// lib/presentation/screens/analysis_settings/asr_models_tab.dart
class ASRModelsTab extends ConsumerWidget {
  // Display Whisper model variants:
  // - whisper-tiny (39M params, 75MB, ~10x speed)
  // - whisper-tiny.en (39M params, 75MB, English-only)
  // - whisper-base (74M params, 142MB, ~7x speed)
  // - whisper-base.en (74M params, 142MB, English-only)
  // - whisper-small (244M params, 466MB, ~4x speed) [RECOMMENDED]
  // - whisper-small.en (244M params, 466MB, English-only)
  // - whisper-medium (769M params, 1.5GB, ~2x speed)
  // - whisper-medium.en (769M params, 1.5GB, English-only)
  // - whisper-large-v3 (1.55B params, 2.9GB, 1x speed) [BEST ACCURACY]
  // - whisper-large-v3-turbo (809M params, 1.6GB, ~4x speed) [BEST VALUE]
  
  // For each model show:
  // - Name and badge (Recommended, Best Accuracy, etc.)
  // - Parameter count (39M, 74M, 244M, 769M, 1.55B)
  // - Download size
  // - RAM requirement
  // - Speed rating (star rating or bar)
  // - Accuracy rating (star rating or bar)
  // - Download button / Downloaded checkmark
  // - Download progress bar (if downloading)
  // - Delete button (if downloaded)
}
```

#### Visual Models Tab

```dart
/// lib/presentation/screens/analysis_settings/visual_models_tab.dart
class VisualModelsTab extends ConsumerWidget {
  // NSFW Detection Models:
  // - nsfw-mobilenet-v2 (3.4M params, 20MB, fast)
  // - nsfw-inception-v3 (23M params, 95MB, medium)
  // - nsfw-efficientnet-b4 (19M params, 75MB, balanced) [RECOMMENDED]
  
  // Violence Detection Models:
  // - violence-mobilenet (4M params, 15MB, fast)
  // - violence-convnext-tiny (28M params, 110MB, medium)
  // - violence-vit-base (86M params, 330MB, best) [RECOMMENDED]
  
  // Blood/Gore Detection Models:
  // - gore-efficientnet-b2 (9M params, 35MB)
  // - blood-yolo-nano (3M params, 12MB)
  
  // Weapons Detection Models:
  // - weapons-yolov8-small (11M params, 22MB)
  // - weapons-detr-resnet50 (41M params, 160MB)
}
```

### 10.4 Model Card Widget

```dart
/// lib/presentation/widgets/models/model_card.dart
class ModelCard extends ConsumerWidget {
  final ModelInfo model;
  final bool isDownloaded;
  final bool isDownloading;
  final double? downloadProgress;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          // Header with name and badge
          ListTile(
            title: Text(model.displayName),
            subtitle: Text('${model.parameterCount} parameters'),
            trailing: model.badge != null 
              ? Chip(label: Text(model.badge!))
              : null,
          ),
          
          // Stats row
          Row(
            children: [
              _StatChip(icon: Icons.storage, label: model.sizeFormatted),
              _StatChip(icon: Icons.memory, label: model.minRamFormatted),
              _StatChip(icon: Icons.speed, label: model.speedDescription),
              _StatChip(icon: Icons.check_circle, label: '${model.accuracyPercent}%'),
            ],
          ),
          
          // Action buttons
          if (isDownloading)
            LinearProgressIndicator(value: downloadProgress)
          else if (isDownloaded)
            Row(
              children: [
                if (isSelected)
                  Chip(label: Text('Selected'), color: Colors.green)
                else
                  TextButton(onPressed: onSelect, child: Text('Select')),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: onDelete,
                ),
              ],
            )
          else
            ElevatedButton.icon(
              icon: Icon(Icons.download),
              label: Text('Download'),
              onPressed: onDownload,
            ),
        ],
      ),
    );
  }
}
```

### 10.5 HuggingFace Model Registry

```dart
/// lib/services/huggingface_model_registry.dart
class HuggingFaceModelRegistry {
  static const String baseUrl = 'https://huggingface.co';
  
  /// All available ASR models with HuggingFace URLs
  static final List<HuggingFaceModel> asrModels = [
    HuggingFaceModel(
      id: 'whisper-tiny',
      displayName: 'Whisper Tiny',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-tiny.bin',
      parameters: '39M',
      sizeBytes: 75 * 1024 * 1024,
      ramRequired: 1 * 1024 * 1024 * 1024,
      speedMultiplier: 10.0,
      accuracyPercent: 85,
      languages: ['multilingual'],
    ),
    HuggingFaceModel(
      id: 'whisper-tiny.en',
      displayName: 'Whisper Tiny (English)',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-tiny.en.bin',
      parameters: '39M',
      sizeBytes: 75 * 1024 * 1024,
      ramRequired: 1 * 1024 * 1024 * 1024,
      speedMultiplier: 10.0,
      accuracyPercent: 88,
      languages: ['en'],
    ),
    // ... additional models
    HuggingFaceModel(
      id: 'whisper-large-v3',
      displayName: 'Whisper Large v3',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-large-v3.bin',
      parameters: '1.55B',
      sizeBytes: 2900 * 1024 * 1024,
      ramRequired: 10 * 1024 * 1024 * 1024,
      speedMultiplier: 1.0,
      accuracyPercent: 98,
      languages: ['multilingual'],
      badge: 'Best Accuracy',
    ),
    HuggingFaceModel(
      id: 'whisper-large-v3-turbo',
      displayName: 'Whisper Large v3 Turbo',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-large-v3-turbo.bin',
      parameters: '809M',
      sizeBytes: 1600 * 1024 * 1024,
      ramRequired: 6 * 1024 * 1024 * 1024,
      speedMultiplier: 4.0,
      accuracyPercent: 96,
      languages: ['multilingual'],
      badge: 'Recommended',
    ),
  ];
  
  /// Get download URL for a model
  static String getDownloadUrl(HuggingFaceModel model) {
    return '$baseUrl/${model.huggingFaceId}/resolve/main/${model.fileName}';
  }
}

/// Model data from HuggingFace
@freezed
class HuggingFaceModel with _$HuggingFaceModel {
  const factory HuggingFaceModel({
    required String id,
    required String displayName,
    required String huggingFaceId,
    required String fileName,
    required String parameters,
    required int sizeBytes,
    required int ramRequired,
    required double speedMultiplier,
    required int accuracyPercent,
    required List<String> languages,
    String? badge,
    String? description,
  }) = _HuggingFaceModel;
}
```

### 10.6 Detection Thresholds Tab

```dart
/// lib/presentation/screens/analysis_settings/thresholds_tab.dart
class ThresholdsTab extends ConsumerWidget {
  // Threshold sliders for each detection type:
  // - NSFW Sensitivity (0.0 - 1.0, default 0.6)
  // - Violence Sensitivity (0.0 - 1.0, default 0.6)
  // - Blood/Gore Sensitivity (0.0 - 1.0, default 0.6)
  // - Weapons Sensitivity (0.0 - 1.0, default 0.6)
  // - Profanity Fuzzy Match Threshold (0.0 - 1.0, default 0.8)
  
  // Each slider shows:
  // - Label with current value
  // - Visual indicator (more sensitive = more false positives)
  // - Reset to default button
  
  // Preset buttons:
  // - Strict (lower thresholds, catches more)
  // - Balanced (default)
  // - Permissive (higher thresholds, fewer false positives)
}
```

### 10.7 Model Configuration Parameters

```dart
/// lib/presentation/screens/analysis_settings/model_config_tab.dart
class ModelConfigTab extends ConsumerWidget {
  // ASR Configuration:
  // - Language selection dropdown (auto-detect, en, es, ar, etc.)
  // - Translate to English toggle
  // - Word-level timestamps toggle
  // - Beam search size (1-5, affects accuracy vs speed)
  
  // Visual Configuration:
  // - Batch size slider (1-16, based on VRAM)
  // - Frame sampling rate (1-10 frames per second)
  // - Use scene detection toggle
  
  // Performance Configuration:
  // - GPU acceleration toggle
  // - CPU threads slider (1 - max cores)
  // - Use FP16 (half precision) toggle
  // - Max concurrent analyses (1-8)
}
```

### 10.8 Tasks for Analysis Settings Implementation

| Task | Description | Priority | Effort |
|------|-------------|----------|--------|
| 10.8.1 | Create AnalysisSettingsScreen scaffold | HIGH | Medium |
| 10.8.2 | Create navigation sidebar | HIGH | Small |
| 10.8.3 | Implement ASRModelsTab | HIGH | Medium |
| 10.8.4 | Implement VisualModelsTab | HIGH | Medium |
| 10.8.5 | Create ModelCard widget | HIGH | Medium |
| 10.8.6 | Create HuggingFaceModelRegistry | HIGH | Medium |
| 10.8.7 | Implement model download with progress | HIGH | Medium |
| 10.8.8 | Implement ThresholdsTab | MEDIUM | Small |
| 10.8.9 | Implement ModelConfigTab | MEDIUM | Medium |
| 10.8.10 | Add hardware capability detection display | MEDIUM | Small |
| 10.8.11 | Wire to Analysis menu item | HIGH | Small |
| 10.8.12 | Persist settings to SharedPreferences | HIGH | Small |
| 10.8.13 | Add model validation after download | MEDIUM | Small |
| 10.8.14 | Add disk space warning before download | LOW | Small |

### 10.9 Data Model Updates

```dart
/// lib/data/models/huggingface_model.dart
@freezed
class HuggingFaceModel with _$HuggingFaceModel {
  const factory HuggingFaceModel({
    /// Unique identifier
    required String id,
    
    /// Display name
    required String displayName,
    
    /// HuggingFace repository ID (e.g., 'ggerganov/whisper.cpp')
    required String huggingFaceId,
    
    /// File name to download
    required String fileName,
    
    /// Parameter count as string (e.g., '39M', '1.55B', '7B', '60B')
    required String parameters,
    
    /// Parameter count as integer for sorting
    required int parameterCount,
    
    /// Download size in bytes
    required int sizeBytes,
    
    /// Minimum RAM required in bytes
    required int ramRequired,
    
    /// Speed multiplier relative to realtime (higher = faster)
    required double speedMultiplier,
    
    /// Accuracy percentage (0-100)
    required int accuracyPercent,
    
    /// Model type (asr, nsfw, violence, blood, weapons)
    required String modelType,
    
    /// Supported languages (for ASR)
    @Default([]) List<String> languages,
    
    /// Optional badge (Recommended, Best Accuracy, etc.)
    String? badge,
    
    /// Model description
    String? description,
    
    /// Whether GPU is required
    @Default(false) bool requiresGpu,
    
    /// Minimum VRAM if GPU required
    @Default(0) int minVramBytes,
    
    /// License type
    String? license,
  }) = _HuggingFaceModel;
  
  factory HuggingFaceModel.fromJson(Map<String, dynamic> json) =>
      _$HuggingFaceModelFromJson(json);
}
```

### 10.10 Files to Create for Analysis Settings

```
lib/
├── data/
│   └── models/
│       └── huggingface_model.dart           # HuggingFace model data
├── services/
│   └── huggingface_model_registry.dart      # Model registry with URLs
├── presentation/
│   ├── screens/
│   │   └── analysis_settings/
│   │       ├── analysis_settings_screen.dart  # Main settings screen
│   │       ├── asr_models_tab.dart            # ASR model selection
│   │       ├── visual_models_tab.dart         # Visual model selection
│   │       ├── thresholds_tab.dart            # Detection thresholds
│   │       ├── model_config_tab.dart          # Model parameters
│   │       └── performance_tab.dart           # GPU/Memory settings
│   └── widgets/
│       └── models/
│           ├── model_card.dart                # Model display card
│           ├── model_download_button.dart     # Download with progress
│           ├── hardware_requirements.dart     # HW requirement display
│           └── parameter_slider.dart          # Config slider widget
```

---

## Part 11: Complete TODO Inventory (Second Pass)

### 11.1 All TODOs by File

| # | File | Line | TODO Description | Priority |
|---|------|------|------------------|----------|
| 1 | `whisper_bindings.dart` | 45 | Implement Whisper transcription via FFI | HIGH |
| 2 | `onnx_bindings.dart` | 21 | Initialize ONNX session with execution providers | HIGH |
| 3 | `onnx_bindings.dart` | 45 | Implement ONNX model loading | HIGH |
| 4 | `onnx_bindings.dart` | 67 | Implement ONNX inference | HIGH |
| 5 | `onnx_bindings.dart` | 101 | Implement metadata extraction | MEDIUM |
| 6 | `mms_bindings.dart` | 44 | Implement MMS transcription via FFI | HIGH |
| 7 | `mms_bindings.dart` | 96 | Implement language detection | MEDIUM |
| 8 | `profanity_service.dart` | 13 | Load wordlists from assets | HIGH |
| 9 | `profanity_service.dart` | 132 | Implement Double Metaphone | MEDIUM |
| 10 | `sample_analysis_service.dart` | 59 | Implement scene change detection | MEDIUM |
| 11 | `sample_analysis_service.dart` | 78 | Extract and analyze sample segment | MEDIUM |
| 12 | `model_provider.dart` | 52 | Implement model loading via service | HIGH |
| 13 | `model_provider.dart` | 78 | Implement model download via service | HIGH |
| 14 | `model_provider.dart` | 109 | Implement model deletion via service | LOW |
| 15 | `file_utils.dart` | 292 | Platform-specific disk space check | LOW |
| 16 | `gpu_manager.dart` | 88 | Implement Vulkan detection | LOW |
| 17 | `editor_screen.dart` | 556 | Implement playback toggle | MEDIUM |

### 11.2 Missing Features from Original Scope

| # | Feature | Category | Priority | Notes |
|---|---------|----------|----------|-------|
| 1 | Whisper FFI native bindings | Native | HIGH | Core ASR functionality |
| 2 | ONNX Runtime FFI bindings | Native | HIGH | Core visual detection |
| 3 | Meta MMS FFI bindings | Native | MEDIUM | Multilingual support |
| 4 | ASRService orchestration | Service | HIGH | Model selection, fallback |
| 5 | VisualAnalysisService | Service | HIGH | Frame analysis pipeline |
| 6 | TemporalAggregator | Service | MEDIUM | Detection smoothing |
| 7 | FrameSamplingService | Service | MEDIUM | Intelligent sampling |
| 8 | TimelineService | Service | LOW | Timeline manipulation |
| 9 | ModificationService | Service | LOW | Apply edits |
| 10 | PerformanceMonitor | Service | LOW | Adaptive quality |
| 11 | AVSyncManager | Service | LOW | Audio/video sync |
| 12 | ONNXModelValidator | Service | MEDIUM | Model validation |
| 13 | AdaptiveQualityController | Service | LOW | Auto-tuning |
| 14 | AboutScreen | UI | MEDIUM | Legal, attributions |
| 15 | AnalysisSettingsScreen | UI | HIGH | **NEW** Model management |
| 16 | DetectionReviewScreen | UI | MEDIUM | Review detections |
| 17 | SettingsScreen | UI | MEDIUM | App preferences |
| 18 | SampleAnalysisScreen | UI | LOW | Quick preview |
| 19 | Full OnboardingScreen | UI | LOW | First-run experience |
| 20 | Profanity wordlists (29 langs) | Data | HIGH | Enable detection |
| 21 | Bundled FFmpeg | Native | HIGH | **NEW** Remove PATH dependency |
| 22 | HuggingFace model download | Service | HIGH | **NEW** Model management |

### 11.3 Menu Items Without Handlers

From `editor_screen.dart`, these menu items have `null` handlers:

| Menu | Item | Status |
|------|------|--------|
| File | Export... | ⚠️ Needs implementation |
| Edit | Cut Selection | ⚠️ Needs implementation |
| Edit | Mute Selection | ⚠️ Needs implementation |
| Edit | Blur Selection | ⚠️ Needs implementation |
| Analysis | Stop Analysis | ⚠️ Needs implementation |
| Analysis | Analysis Settings | ⚠️ **Needs AnalysisSettingsScreen** |

---

## Summary (Updated)

This comprehensive plan identifies:
- **17 TODO items** requiring implementation
- **22 missing features** from the original scope
- **6 menu items** without handlers
- **2 major new requirements:**
  1. Bundled FFmpeg binaries
  2. Analysis Settings page with model download from HuggingFace

### Updated Priority List

1. **FFmpeg bundling** (unblocks all media operations)
2. **Analysis Settings Screen** (model selection, download, configuration)
3. **HuggingFace model registry and download** (enables AI features)
4. **Profanity wordlist loading** (enables audio detection)
5. **Model provider integration** (connects UI to services)
6. **Whisper/ONNX FFI implementation** (core AI functionality)
7. **Essential UI screens** (About, Detection Review)
8. **Missing menu handlers** (Export, Analysis Stop, etc.)

### Updated Timeline

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| FFmpeg Bundling | 1-2 weeks | Bundled binaries, updated bindings |
| Analysis Settings UI | 2-3 weeks | Full model management UI |
| Profanity Wordlists | 3-5 days | Asset loading, 29 languages |
| Native FFI (Whisper) | 2-3 weeks | Working transcription |
| Native FFI (ONNX) | 2-3 weeks | Working visual detection |
| Remaining UI | 2 weeks | About, Settings, Review screens |
| Testing & Polish | 2 weeks | All platforms |
| **Total v1.0** | **14-18 weeks** | |
