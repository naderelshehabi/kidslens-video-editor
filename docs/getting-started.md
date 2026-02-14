# KidsLens Video Editor - Getting Started Guide

This guide will help you set up your development environment and get started with the KidsLens Video Editor project.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Setup](#project-setup)
- [Running the App](#running-the-app)
- [Running Tests](#running-tests)
- [Building for Release](#building-for-release)
- [Project Structure](#project-structure)
- [Development Workflow](#development-workflow)

---

## Prerequisites

### Required Software

| Software | Minimum Version | Purpose |
|----------|-----------------|---------|
| **Flutter SDK** | 3.16.0+ | UI framework |
| **Dart SDK** | 3.2.0+ | Programming language |
| **Git** | 2.x | Version control |

### Platform-Specific Requirements

#### Windows

| Software | Purpose | Download |
|----------|---------|----------|
| **Visual Studio 2022** | C++ build tools | [visualstudio.microsoft.com](https://visualstudio.microsoft.com/) |
| **Windows 10 SDK** | Windows APIs | Included with VS |
| **Vulkan SDK** *(optional)* | GPU acceleration | [vulkan.lunarg.com](https://vulkan.lunarg.com/sdk/home) |

During Visual Studio installation, select:
- "Desktop development with C++"
- Windows 10 SDK (10.0.x or later)
- C++ CMake tools for Windows

> **GPU Acceleration**: Install the Vulkan SDK for faster AI inference. The app works without it (CPU fallback).

#### macOS (Future)

| Software | Purpose |
|----------|---------|
| **Xcode** | macOS build tools |
| **CocoaPods** | Dependency management |

#### Linux (Future)

| Software | Purpose |
|----------|---------|
| **Clang** | C++ compiler |
| **CMake** | Build system |
| **GTK 3.x** | UI toolkit |
| **pkg-config** | Library discovery |

Install on Ubuntu/Debian:
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

### Verify Installation

```bash
# Check Flutter installation
flutter doctor -v

# Expected output should show:
# ✓ Flutter (Channel stable, 3.16.x or later)
# ✓ Windows Version (or your platform)
# ✓ Visual Studio - develop for Windows (or Xcode/Linux toolchain)
```

---

## Project Setup

### 1. Clone the Repository

```bash
git clone https://github.com/naderelshehabi/kidslens-video-editor.git
cd kidslens-video-editor
```

### 2. Install Dependencies

```bash
# Get Flutter dependencies
flutter pub get
```

### 3. Generate Code

The project uses code generation for:
- **Riverpod** - State management providers
- **Freezed** - Immutable data classes
- **JSON Serializable** - JSON serialization

```bash
# Run code generation (one-time)
dart run build_runner build --delete-conflicting-outputs

# Or run in watch mode during development
dart run build_runner watch --delete-conflicting-outputs
```

### 4. Verify Setup

```bash
# Run analysis to check for issues
dart analyze

# Run tests to verify everything works
flutter test
```

---

## Running the App

### Development Mode

```bash
# Run on Windows (default)
flutter run -d windows

# Run with verbose logging
flutter run -d windows --verbose

# Run in debug mode (default)
flutter run -d windows --debug

# Run in profile mode (for performance testing)
flutter run -d windows --profile
```

### Hot Reload

During development, the app supports hot reload:
- Press `r` in the terminal for hot reload
- Press `R` for hot restart (full restart)
- Press `q` to quit

### Device Selection

```bash
# List available devices
flutter devices

# Run on a specific device
flutter run -d <device-id>
```

---

## Running Tests

### Unit Tests

```bash
# Run all unit tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/profanity_service_test.dart

# Run tests matching a pattern
flutter test --name "ProfanityService"

# Run tests in a directory
flutter test test/core/

# Run with verbose output
flutter test --reporter expanded
```

### Integration Tests

```bash
# Run integration tests
flutter test integration_test/

# Run specific integration test
flutter test integration_test/app_test.dart
```

### Test Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage report (requires lcov)
# On Windows with Chocolatey:
# choco install lcov
genhtml coverage/lcov.info -o coverage/html
start coverage/html/index.html
```

### Continuous Testing

```bash
# Watch mode - re-run tests on file changes
# (requires test_cov package or custom script)
flutter pub global activate test_cov
test_cov --watch
```

---

## Building for Release

### Windows Release Build

```bash
# Build Windows release
flutter build windows --release

# Output location:
# build/windows/x64/runner/Release/
```

### Build Artifacts

After building, you'll find:
```
build/windows/x64/runner/Release/
├── kidslens_video_editor.exe    # Main executable
├── flutter_windows.dll          # Flutter engine
├── data/                        # App assets
│   ├── flutter_assets/
│   └── ...
└── *.dll                        # Native dependencies
```

### Creating an Installer

For distribution, consider using:
- **Inno Setup** - Windows installer creator
- **MSIX** - Modern Windows packaging

Example Inno Setup script structure:
```iss
[Setup]
AppName=KidsLens Video Editor
AppVersion=1.0.0
DefaultDirName={autopf}\KidsLens
OutputBaseFilename=KidsLensSetup

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs
```

### Native Library Bundling

The release build requires native libraries to be bundled:

| Library | Files (Windows) | Purpose |
|---------|-----------------|---------|
| FFmpeg | `ffmpeg_wrapper.dll`, `avcodec-*.dll`, etc. | Media processing |
| Whisper | `whisper_wrapper.dll` | Speech recognition (auto-built) |
| ONNX Runtime | `onnxruntime.dll` | AI inference |

> **Note**: `whisper_wrapper.dll` is automatically built during `flutter build windows`. No manual setup required.

### GPU Acceleration (Optional)

For faster speech recognition, you can enable GPU acceleration. The app automatically falls back to CPU if GPU is unavailable.

#### Installing Vulkan SDK (Recommended for GPU support)

1. Download the Vulkan SDK from [vulkan.lunarg.com](https://vulkan.lunarg.com/sdk/home)
2. Run the installer and ensure environment variables are set
3. Rebuild the project:

```bash
# Clean and rebuild to enable GPU support
flutter clean
flutter build windows --release
```

The build system will automatically detect the Vulkan SDK and enable GPU acceleration.

#### GPU Support Status

| GPU Type | Acceleration | Notes |
|----------|--------------|-------|
| NVIDIA | Vulkan or CUDA | Vulkan recommended for simplicity |
| AMD | Vulkan | Full support |
| Intel | Vulkan | Integrated GPU support |
| None | CPU | Automatic fallback, always works |

#### Verifying GPU Acceleration

When the app loads a Whisper model, it logs whether GPU is active:

```
Model loaded: small (GPU: true)   // GPU acceleration enabled
Model loaded: small (GPU: false)  // CPU mode (fallback)
```

---

## Project Structure

```
kidslens-video-editor/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── app.dart                  # Root widget & theme
│   │
│   ├── core/                     # Core utilities
│   │   ├── constants/            # App constants
│   │   ├── errors/               # Exception types
│   │   ├── extensions/           # Dart extensions
│   │   └── utils/                # Utility functions
│   │
│   ├── data/                     # Data layer
│   │   └── models/               # Freezed data models
│   │
│   ├── jobs/                     # Background job system
│   │   ├── job_system.dart
│   │   ├── analysis_job.dart
│   │   ├── export_job.dart
│   │   ├── cancellation_token.dart
│   │   └── checkpoint_manager.dart
│   │
│   ├── l10n/                     # Localization
│   │   ├── app_en.arb            # English strings
│   │   ├── app_es.arb            # Spanish strings
│   │   └── app_ar.arb            # Arabic strings
│   │
│   ├── native/                   # Native FFI layer
│   │   ├── bindings/             # FFI bindings
│   │   ├── resource_manager.dart
│   │   ├── memory_monitor.dart
│   │   ├── gpu_manager.dart
│   │   └── frame_buffer_pool.dart
│   │
│   ├── presentation/             # UI layer
│   │   ├── screens/              # App screens
│   │   ├── widgets/              # Reusable widgets
│   │   └── themes/               # Theme definitions
│   │
│   ├── services/                 # Business logic
│   │   ├── analysis_service.dart
│   │   ├── export_service.dart
│   │   ├── media_service.dart
│   │   ├── model_manager_service.dart
│   │   ├── profanity_service.dart
│   │   └── sample_analysis_service.dart
│   │
│   └── state/                    # State management
│       └── providers/            # Riverpod providers
│
├── test/                         # Unit tests
│   ├── core/
│   ├── data/
│   ├── presentation/
│   ├── services/
│   └── state/
│
├── integration_test/             # Integration tests
│
├── assets/                       # Static assets
│   ├── audio/                    # Audio files (beeps, etc.)
│   ├── logos/                    # App logos
│   └── wordlists/                # Profanity word lists
│
├── windows/                      # Windows platform code
│   ├── CMakeLists.txt
│   ├── runner/                   # Windows runner
│   └── flutter/                  # Flutter embedding
│
├── docs/                         # Documentation
│   ├── architecture.md
│   ├── api-reference.md
│   ├── getting-started.md        # This file
│   └── ...
│
├── pubspec.yaml                  # Dependencies
├── analysis_options.yaml         # Lint rules
└── README.md
```

---

## Development Workflow

### 1. Creating a New Feature

1. **Create a branch:**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Add data models** (if needed):
   ```dart
   // lib/data/models/my_model.dart
   @freezed
   class MyModel with _$MyModel {
     const factory MyModel({...}) = _MyModel;
   }
   ```

3. **Run code generation:**
   ```bash
   dart run build_runner build
   ```

4. **Add service logic** (if needed):
   ```dart
   // lib/services/my_service.dart
   class MyService {
     Future<void> doSomething() async {...}
   }
   ```

5. **Add providers:**
   ```dart
   // lib/state/providers/my_provider.dart
   @Riverpod(keepAlive: true)
   class MyNotifier extends _$MyNotifier {...}
   ```

6. **Create UI widgets:**
   ```dart
   // lib/presentation/widgets/my_widget.dart
   class MyWidget extends ConsumerWidget {...}
   ```

7. **Write tests:**
   ```dart
   // test/services/my_service_test.dart
   void main() {
     group('MyService', () {
       test('should do something', () {...});
     });
   }
   ```

### 2. Code Style

Follow the project's lint rules defined in `analysis_options.yaml`:

```bash
# Check for lint issues
dart analyze

# Fix auto-fixable issues
dart fix --apply
```

### 3. Commit Guidelines

Use conventional commits:
```
feat: add profanity detection settings
fix: correct timeline segment overlap
docs: update API reference
test: add media service tests
refactor: simplify analysis pipeline
```

### 4. Pre-commit Checklist

Before committing:
1. ✅ Run `dart analyze` - no errors or warnings
2. ✅ Run `flutter test` - all tests pass
3. ✅ Run code generation if models changed
4. ✅ Update documentation if API changed

---

## Common Issues

### Code Generation Fails

```bash
# Clear build cache and regenerate
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Windows Build Fails

1. Ensure Visual Studio C++ workload is installed
2. Check `flutter doctor` for Windows issues
3. Try cleaning and rebuilding:
   ```bash
   flutter clean
   flutter pub get
   flutter build windows
   ```

### Native Libraries Not Found

1. Verify DLLs are in the correct location
2. Check the library loading code matches your file names
3. Ensure libraries are for the correct architecture (x64)

### Hot Reload Not Working

1. Hot reload doesn't work for native code changes
2. Changes to `const` values require hot restart
3. Use `R` (capital) for hot restart when needed

---

## Next Steps

- Read the [Architecture Guide](architecture.md) to understand the codebase
- Check the [API Reference](api-reference.md) for detailed documentation
- Review [State Management](state-management.md) for Riverpod patterns
- See [Native Integration](native-integration.md) for FFI details
