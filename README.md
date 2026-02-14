# KidsLens Video Editor

<p align="center">
  <img src="assets/images/app_logo.png" alt="KidsLens Logo" width="300"/>
</p>

<p align="center">
  <strong>A desktop video editor to detect and remove unsafe visual and audio content from videos, making them safe for the entire family.</strong>
</p>

---

## Overview

KidsLens is a powerful desktop application that uses local AI models to analyze and clean video content, ensuring it's appropriate for children and family viewing. All processing happens on your computer - no data is sent to the cloud.

## Documentation

For detailed technical information, please refer to the documentation in the `docs/` folder:

- [Technical Reference](docs/TECHNICAL_REFERENCE.md) - **New!** Comprehensive guide on architecture, UI, and FFmpeg setup.
- [Architecture](docs/architecture.md) - High-level system design.
- [Native Integration](docs/native-integration.md) - Details on FFI and native libraries.
- [Getting Started](docs/getting-started.md) - Setup guide for developers.

## Features

- **Visual Content Detection**: Identify inappropriate scenes using ONNX Runtime
- **Audio Profanity Detection**: Detect offensive language in audio tracks
- **Speech Transcription**: Automatic speech-to-text with Whisper AI
- **Multi-language Support**: Analyze content in 100+ languages with Meta MMS
- **Timeline Editing**: Visual timeline with precise detection markers
- **Safe Export**: Remove or blur detected content automatically
- **Family-Friendly UI**: Kid-safe interface with green and blue color palette

## Getting Started

See [docs/getting-started.md](docs/getting-started.md) for detailed setup instructions.

### Quick Start

```bash
# Install dependencies
flutter pub get

# Run on Windows
flutter run -d windows

# Run on macOS
flutter run -d macos

# Run on Linux
flutter run -d linux
```

## Documentation

- [Architecture Overview](docs/architecture.md)
- [Getting Started Guide](docs/getting-started.md)
- [State Management](docs/state-management.md)
- [Native Integration](docs/native-integration.md)
- [Testing Guide](docs/testing.md)
- [Deployment Guide](docs/deployment.md)

## Requirements

- Flutter 3.16+
- Dart 3.2+
- Windows 10+, macOS 11+, or Linux (Ubuntu 20.04+)
- 8GB RAM minimum (16GB recommended for 4K videos)
- GPU recommended for optimal performance

### Speech Recognition (Built-in)

Speech-to-text transcription is built into the app via **whisper.cpp** FFI integration. No external tools needed - just run `flutter build windows` and whisper support is included.

### GPU Acceleration (Optional)

For faster AI processing, install the **Vulkan SDK**:

1. Download from [vulkan.lunarg.com](https://vulkan.lunarg.com/sdk/home)
2. Install and ensure environment variables are set
3. Rebuild: `flutter clean && flutter build windows --release`

The app automatically uses GPU when available and falls back to CPU otherwise.

| GPU Type | Status |
|----------|--------|
| NVIDIA (Vulkan/CUDA) | ✅ Supported |
| AMD (Vulkan) | ✅ Supported |
| Intel (Vulkan) | ✅ Supported |
| No GPU | ✅ CPU fallback |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
