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
- **Runtime**: bundled official llama.cpp `llama-server` on `127.0.0.1`
- **Default VLM Bundle**: official Qwen3-VL GGUF bundle from the model catalog
- **Policy Taxonomy**: includes explicit nudity, sexual content, suggestive
  content, kissing/romance, immodest female clothing, violence, gore, blood,
  weapons, substances, and profanity. VLM findings may include optional
  `exposureSignals` and `weaponState` fields for explainable policy severity.
- **Persistence**: per-media evidence JSON, `AnalysisRunManifest`,
  `vss_checkpoint.json`, and local search index files
- **Legacy Option**: `legacy_nsfw_region_v8` remains selectable and is used only
  as a startup fallback when the VSS local model/runtime is unavailable

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
