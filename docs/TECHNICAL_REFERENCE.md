# KidsLens Video Editor - Technical Reference

## 1. System Architecture & Tech Stack

### core Technologies
- **Language**: Dart (SDK >=3.0)
- **Framework**: Flutter (SDK >=3.22)
- **State Management**: Riverpod (riverpod, flutter_riverpod)
- **Video Processing**: FFmpeg (via FFI / Process execution) & `media_kit` for playback.
- **Speech Recognition**: whisper.cpp (via FFI, GPU-accelerated with auto CPU fallback)
- **Local Persistence**: `shared_preferences` (Settings), JSON (Project files).

### Hardware Acceleration
- **GPU Support**: Vulkan (cross-platform), CUDA (NVIDIA), Metal (macOS)
- **Auto-Fallback**: If GPU unavailable, automatically uses CPU
- **Build-time Detection**: CMake detects Vulkan SDK and enables GPU support if available

### Local Family-Safety VLM Pipeline
- **Default Detection Pipeline**: `vss_family_safety_v1`
- **Runtime**: official pinned llama.cpp `llama-server` on `127.0.0.1`.
  The Local Model Bundles settings tab can install the CUDA or Vulkan Windows
  runtime from the official llama.cpp release and reports install/progress
  state through `RuntimeBinaryNotifier`.
- **Default VLM Bundle**: official Qwen3-VL GGUF bundle from the model catalog.
  Until RTX 5070 validation in Phase 10, Qwen3-VL GGUF selections are exposed
  in settings as validation-ready choices instead of production-approved
  defaults.
- **First Run**: starting VSS analysis with a missing model bundle or runtime
  opens a local setup dialog. Users can start the official downloads or persist
  a switch to the legacy pipeline for that run path.
- **Downloads**: official Hugging Face model bundles and GitHub llama.cpp
  runtime archives use bounded parallel HTTP range requests for large files,
  verify sizes/checksums, and fall back to a single stream when a server does
  not support `Range`.
- **RTX Validation**: `scripts/vss_validation_runner.dart` validates a supplied
  `EvaluationDataset` manifest and clip directory, consumes prediction JSON or
  invokes an external real-pipeline command per profile/clip, polls
  `nvidia-smi` for peak VRAM, and writes comparison reports under
  `docs/implement/validation-reports/`. Reports include `rtxValidationGate`,
  which can fail CI via `--fail-on-validation-gate` when recall, latency,
  schema/crash, VRAM, or missing runtime-telemetry gates fail. The
  production-default model flip remains gated on a passing report using the
  user-supplied unsafe validation clip set.
- **Search Embeddings**: when `qwen3_embedding_0_6b_gguf_q8` is downloaded,
  VSS starts a second local `llama-server` embedding instance and posts batched
  OpenAI-compatible `/v1/embeddings` requests. If the embedding bundle or server
  is unavailable, analysis continues with the deterministic hash embedding
  fallback and logs the reason.
- **Policy Taxonomy**: includes explicit nudity, sexual content, suggestive
  content, kissing/romance, immodest female clothing, violence, gore, blood,
  weapons, substances, and profanity. VLM findings may include optional
  `exposureSignals` and `weaponState` fields for explainable policy severity.
- **Grounding**: VSS stores normalized `[0,1]` grounded-region boxes. If a
  Qwen-style response emits pixel coordinates, the grounding provider repairs
  them using the sent frame dimensions and records `schemaRepairWarnings` in the
  grounded-region evidence.
- **Persistence**: per-media evidence JSON, `AnalysisRunManifest`,
  `vss_checkpoint.json`, and local search index files
- **Legacy Option**: `legacy_nsfw_region_v8` remains selectable and is used only
  as a startup fallback when the VSS local model/runtime is unavailable

#### Local Runtime Requirements

| Component | Requirement |
|-----------|-------------|
| Network boundary | loopback-only; non-local endpoints are rejected before inference |
| Model sources | official provider repos or KidsLens-owned reproducible conversions only |
| Runtime | pinned official llama.cpp `llama-server`; CUDA preferred on NVIDIA, Vulkan fallback |
| Target GPU | RTX 5070-class high-end consumer GPU for production validation |
| VRAM gate | peak VRAM must stay at or below 12288 MB in RTX validation |
| Latency gate | default profile p95 chunk latency must stay at or below 8000 ms |
| Disk headroom | 10-15 GB for VLM bundle, embedding bundle, runtime archive, and analysis cache |

Approximate installed artifact sizes:

| Artifact | Role | Expected Size |
|----------|------|---------------|
| Qwen3-VL 8B Q4_K_M GGUF | default VLM validation candidate | 5-7 GB |
| Qwen3-VL 4B Q4_K_M GGUF | lightweight VLM candidate | 3-4 GB |
| Qwen3 embedding 0.6B Q8 GGUF | local semantic search | 0.7-1 GB |
| llama.cpp CUDA/Vulkan runtime | local inference helper process | 0.5-2 GB |

### Architectural Pattern
The application follows a **Clean Architecture** approach, separated into layers:

1.  **Presentation Layer** (`lib/presentation/`): UI Widgets, Screens, and ViewModels (Notifiers).
    *   *Widgets*: Pure UI components.
    *   *Screens*: Composition of widgets representing partial or full usage flows.
    *   *State*: Riverpod providers handling UI logic.
2.  **Domain/Data Layer** (`lib/data/`, `lib/core/`):
    *   *Models*: Immutable data classes (`MediaFile`, `Project`, `EditAction`).
    *   *Services*: Business logic implementations (`ThumbnailService`, `ExportService`).
3.  **Core Layer** (`lib/core/`):
    *   Constants, Utils, and Themes.

---

## 2. Project Structure

```bash
lib/
├── app.dart                # App entry point, Theme setup
├── main.dart               # Platform initialization
├── core/                   # Shared utilities & constants
│   ├── constants/
│   └── theme/
├── data/                   # Data models
│   └── models/             # MediaFile, Project, etc.
├── l10n/                   # Localization (arb files)
├── native/                 # Native bindings (FFI)
│   ├── bindings/           # Dart FFI bindings
│   └── bridges/            # C/C++ bridges (if any)
├── presentation/           # UI Layer
│   ├── screens/            # Full-page views
│   ├── widgets/            # Reusable components
│   └── viewmodels/         # (Optional) specific VM logic
├── services/               # Application services
│   ├── thumbnail_service.dart
│   └── export_service.dart
└── state/                  # Riverpod Providers
    ├── providers/          
    └── notifiers/          # State logic
```

---

## 3. UI Widget Trees

### Editor Screen Hierarchy (`EditorScreen`)
The main workspace of the application.

```
EditorScreen
├── Scaffold
│   ├── Column
│   │   ├── _buildMenuBar (Top Toolbar)
│   │   │   ├── File | Edit | Analysis | Help
│   │   │   └── Quick Actions (Save, Settings, Theme Toggle)
│   │   └── Expanded (Main Content)
│   │       ├── Row
│   │       │   ├── MediaBinPanel (Left - 280px)
│   │       │   │   └── GridView (Media Assets)
│   │       │   ├── VerticalResizer
│   │       │   ├── PreviewPanel (Center)
│   │       │   │   └── VideoPlayer (media_kit)
│   │       │   ├── VerticalResizer
│   │       │   └── DetectionPanel (Right - 280px)
│   │       │       └── ListView (AI Detections)
│   │       └── Column (Bottom)
│   │           ├── HorizontalResizer
│   │           └── TimelinePanel
│   │               ├── Toolbar (Play/Pause, Zoom)
│   │               └── TimelineArea
│   │                   ├── TrackHeaders
│   │                   └── HorizontalScrollView
│   │                       ├── TimeRuler
│   │                       └── VideoTrack (Thumbnails)
```

### Settings Screen Hierarchy
```
SettingsScreen
├── Scaffold
    ├── AppBar
    └── SingleChildScrollView
        └── Column
            ├── Appearance (Theme Mode)
            ├── Thumbnails (Interval Selection)
            ├── Export Defaults (Format, Quality)
            ├── Auto-Save (Interval)
            ├── Cache & Storage (Clear Cache)
            └── Reset (Reset All)
```

---

## 4. FFmpeg Integration & Binaries

The application relies on **FFmpeg** for thumbnail extraction and video exporting. It does not use a pre-packaged Flutter plugin for FFmpeg binaries to maintain flexibility and reduce app size.

### Binary Location
*   **Windows**: `native/ffmpeg/binaries/windows-x64/bin/ffmpeg.exe`
*   **Linux**: `native/ffmpeg/binaries/linux-x64/bin/ffmpeg`
*   **macOS**: `native/ffmpeg/binaries/macos-universal/bin/ffmpeg`

### Download Script (`scripts/download_ffmpeg.dart`)
A custom Dart script handles fetching the correct binaries for the development OS.

**Supported Sources**:
*   **Windows**: `BtbN/FFmpeg-Builds` (GitHub)
*   **macOS**: `evermeet.cx`
*   **Linux**: `johnvansickle.com`

**Usage**:
To download binaries for your current platform:
```bash
dart run scripts/download_ffmpeg.dart
```

To force a specific platform (e.g., preparing a Linux build on Windows):
```bash
dart run scripts/download_ffmpeg.dart --platform=linux-x64
```

### Integration Logic (`ThumbnailService`)
The `ThumbnailService` locates the binary at runtime:

1.  Checks `native/ffmpeg/binaries/<platform>/bin/ffmpeg`.
2.  If found, executes commands directly (`Process.run`).
3.  Command Example (Thumbnail Extraction):
    ```bash
    ffmpeg -i input.mp4 -vf "fps=1/60,scale=320:-1" -q:v 2 thumb_%04d.jpg
    ```

---

## 5. Cross-Platform Extension Guide

To build and run KidsLens on Linux or macOS, follow these steps to ensure native dependencies are present.

### Linux Support
1.  **System Dependencies**: Ensure you have dependencies for `flutter` and `media_kit`.
    ```bash
    sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
    ```
    *Note: `media_kit` (video playback) requires specific Linux libs (`mpv` dependencies).*

2.  **FFmpeg Setup**:
    Run the download script in the project root:
    ```bash
    dart run scripts/download_ffmpeg.dart
    ```
    This will fetch the Linux static build from John Van Sickle's repository and place it in the `native/` folder.

3.  **Run**:
    ```bash
    flutter run -d linux
    ```

### macOS Support
1.  **Permissions**:
    Use `client_side` entitlements for network and file access if sandboxed (Mac App Store), though for local development, standard `runner` permissions usually suffice.
    
2.  **FFmpeg Setup**:
    Run the download script:
    ```bash
    dart run scripts/download_ffmpeg.dart
    ```
    This fetches the macOS universal binary (Intel/Apple Silicon) from `evermeet.cx`.

3.  **CocoaPods**:
    Ensure `video_player_media_kit` dependencies are installed:
    ```bash
    cd macos && pod install && cd ..
    ```

4.  **Run**:
    ```bash
    flutter run -d macos
    ```

### Adding a New Platform
If you need to support a new architecture (e.g., Windows on ARM64):
1.  Modify `scripts/download_ffmpeg.dart`:
    *   Add the logic to detect `windows-arm64`.
    *   Add the download URL for the ARM64 FFmpeg build.
2.  Update `lib/native/bindings/ffmpeg_constants.dart` (or similar location resolver) to look in `binaries/windows-arm64/`.
