# KidsLens Video Editor - Deployment Guide

This document covers the build and deployment process for the KidsLens Video Editor across all supported platforms.

## Table of Contents

- [Overview](#overview)
- [Windows Build Process](#windows-build-process)
- [macOS Build Process](#macos-build-process-future)
- [Linux Build Process](#linux-build-process-future)
- [Native Library Bundling](#native-library-bundling)
- [Code Signing](#code-signing)
- [Installer Creation](#installer-creation)
- [Auto-Update System](#auto-update-system)
- [Release Checklist](#release-checklist)

---

## Overview

### Supported Platforms

| Platform | Status | Architecture | Notes |
|----------|--------|--------------|-------|
| Windows 10/11 | ✅ Active | x64, ARM64 | Primary platform |
| macOS 12+ | 🔜 Future | Intel, Apple Silicon | See roadmap |
| Linux (Ubuntu 22+) | 🔜 Future | x64, ARM64 | See roadmap |

### Build Types

| Type | Use Case | Optimizations |
|------|----------|---------------|
| Debug | Development | No optimization, asserts enabled |
| Profile | Performance testing | Optimized, profiling enabled |
| Release | Production | Fully optimized, no debug info |

---

## Windows Build Process

### Prerequisites

1. **Flutter SDK** 3.16.0 or later
2. **Visual Studio 2022** with:
   - Desktop development with C++
   - Windows 10 SDK
   - C++ CMake tools

3. **Native Libraries** (pre-built):
   - FFmpeg 6.x DLLs
   - whisper.cpp wrapper DLL
   - ONNX Runtime DLL

### Step-by-Step Build

#### 1. Clean Previous Builds

```powershell
flutter clean
Remove-Item -Recurse -Force build\windows -ErrorAction SilentlyContinue
```

#### 2. Get Dependencies

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

#### 3. Run Tests

```powershell
flutter test
dart analyze
```

#### 4. Build Release

```powershell
# Standard release build
flutter build windows --release

# With verbose output
flutter build windows --release --verbose

# Build output location
# build\windows\x64\runner\Release\
```

#### 5. Verify Build

```powershell
# Check that executable was created
Test-Path "build\windows\x64\runner\Release\kidslens_video_editor.exe"

# Check file size (should be several MB)
Get-Item "build\windows\x64\runner\Release\kidslens_video_editor.exe" | Select-Object Name, Length
```

### Build Output Structure

```
build\windows\x64\runner\Release\
├── kidslens_video_editor.exe      # Main executable
├── flutter_windows.dll             # Flutter engine
├── data\                           # App data
│   ├── flutter_assets\             # Dart code + assets
│   │   ├── AssetManifest.json
│   │   ├── FontManifest.json
│   │   ├── kernel_blob.bin         # Compiled Dart code
│   │   ├── assets\                 # App assets
│   │   │   ├── wordlists\
│   │   │   ├── audio\
│   │   │   └── logos\
│   │   └── ...
│   └── icudtl.dat                  # ICU data
│
├── ffmpeg_wrapper.dll              # FFmpeg wrapper
├── avcodec-60.dll                  # FFmpeg libraries
├── avformat-60.dll
├── avutil-58.dll
├── avfilter-9.dll
├── swscale-7.dll
├── swresample-4.dll
│
├── whisper_wrapper.dll             # Whisper wrapper
├── whisper.dll                     # Whisper library
├── ggml.dll                        # GGML library
│
├── onnxruntime.dll                 # ONNX Runtime
├── onnxruntime_providers_cuda.dll  # (Optional) CUDA provider
├── onnxruntime_providers_dml.dll   # (Optional) DirectML provider
│
└── msvcp140.dll                    # VC++ Runtime
    vcruntime140.dll
    vcruntime140_1.dll
```

### Windows ARM64 Build

```powershell
# Set target architecture
$env:CMAKE_GENERATOR_PLATFORM = "ARM64"

# Build for ARM64
flutter build windows --release

# Note: Native libraries must also be ARM64
```

---

## macOS Build Process (Future)

### Prerequisites

1. **Xcode 14+**
2. **CocoaPods** (`sudo gem install cocoapods`)
3. **Apple Developer Account** (for signing)

### Build Commands

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build release
flutter build macos --release

# Output location
# build/macos/Build/Products/Release/KidsLens.app
```

### Universal Binary (Intel + Apple Silicon)

```bash
# Build for both architectures
flutter build macos --release

# The output should be a universal binary
# Verify with:
lipo -info "build/macos/Build/Products/Release/KidsLens.app/Contents/MacOS/KidsLens"
```

### App Bundle Structure

```
KidsLens.app/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── KidsLens              # Main executable
│   ├── Frameworks/
│   │   ├── FlutterMacOS.framework
│   │   ├── libffmpeg_wrapper.dylib
│   │   ├── libwhisper_wrapper.dylib
│   │   └── libonnxruntime.dylib
│   ├── Resources/
│   │   └── flutter_assets/
│   └── _CodeSignature/
```

### Notarization

```bash
# Create ZIP for notarization
ditto -c -k --keepParent "build/macos/Build/Products/Release/KidsLens.app" "KidsLens.zip"

# Submit for notarization
xcrun notarytool submit KidsLens.zip \
    --apple-id "developer@example.com" \
    --team-id "XXXXXXXXXX" \
    --password "@keychain:AC_PASSWORD" \
    --wait

# Staple the ticket
xcrun stapler staple "build/macos/Build/Products/Release/KidsLens.app"
```

---

## Linux Build Process (Future)

### Prerequisites

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    clang cmake ninja-build pkg-config \
    libgtk-3-dev liblzma-dev

# Fedora
sudo dnf install -y \
    clang cmake ninja-build pkgconfig \
    gtk3-devel xz-devel
```

### Build Commands

```bash
# Build release
flutter build linux --release

# Output location
# build/linux/x64/release/bundle/
```

### Bundle Structure

```
bundle/
├── kidslens_video_editor          # Main executable
├── lib/
│   ├── libflutter_linux_gtk.so    # Flutter engine
│   ├── libffmpeg_wrapper.so
│   ├── libwhisper_wrapper.so
│   └── libonnxruntime.so
└── data/
    ├── flutter_assets/
    └── icudtl.dat
```

### Creating AppImage

```bash
# Install appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# Create AppDir structure
mkdir -p AppDir/usr/{bin,lib,share/applications,share/icons}
cp -r build/linux/x64/release/bundle/* AppDir/usr/bin/
cp assets/logos/icon.png AppDir/usr/share/icons/kidslens.png

# Create desktop file
cat > AppDir/kidslens.desktop << EOF
[Desktop Entry]
Name=KidsLens Video Editor
Exec=kidslens_video_editor
Icon=kidslens
Type=Application
Categories=AudioVideo;Video;
EOF

# Create AppImage
./appimagetool-x86_64.AppImage AppDir KidsLens-x86_64.AppImage
```

---

## Native Library Bundling

### Windows CMake Configuration

Add to `windows/CMakeLists.txt`:

```cmake
# Copy native libraries to output directory
set(NATIVE_LIBS_DIR "${CMAKE_SOURCE_DIR}/native_libs")

file(GLOB NATIVE_DLLS "${NATIVE_LIBS_DIR}/*.dll")

foreach(DLL ${NATIVE_DLLS})
    add_custom_command(TARGET ${BINARY_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${DLL}"
        "$<TARGET_FILE_DIR:${BINARY_NAME}>"
    )
endforeach()
```

### Library Organization

```
windows/
├── native_libs/
│   ├── ffmpeg/
│   │   ├── ffmpeg_wrapper.dll
│   │   ├── avcodec-60.dll
│   │   ├── avformat-60.dll
│   │   ├── avutil-58.dll
│   │   ├── avfilter-9.dll
│   │   ├── swscale-7.dll
│   │   └── swresample-4.dll
│   ├── whisper/
│   │   ├── whisper_wrapper.dll
│   │   ├── whisper.dll
│   │   └── ggml.dll
│   └── onnx/
│       ├── onnxruntime.dll
│       └── onnxruntime_providers_dml.dll
└── CMakeLists.txt
```

### Dependency Verification Script

```powershell
# scripts/verify_dependencies.ps1

$requiredDlls = @(
    "ffmpeg_wrapper.dll",
    "avcodec-60.dll",
    "avformat-60.dll",
    "avutil-58.dll",
    "whisper_wrapper.dll",
    "onnxruntime.dll"
)

$releaseDir = "build\windows\x64\runner\Release"

$missing = @()
foreach ($dll in $requiredDlls) {
    if (-not (Test-Path "$releaseDir\$dll")) {
        $missing += $dll
    }
}

if ($missing.Count -gt 0) {
    Write-Error "Missing DLLs: $($missing -join ', ')"
    exit 1
}

Write-Host "All required DLLs present" -ForegroundColor Green
```

---

## Code Signing

### Windows Code Signing

```powershell
# Sign with certificate
$certPath = "path\to\certificate.pfx"
$certPassword = $env:CERT_PASSWORD

# Sign main executable
signtool sign /f $certPath /p $certPassword /tr http://timestamp.digicert.com /td sha256 /fd sha256 `
    "build\windows\x64\runner\Release\kidslens_video_editor.exe"

# Sign DLLs
Get-ChildItem "build\windows\x64\runner\Release\*.dll" | ForEach-Object {
    signtool sign /f $certPath /p $certPassword /tr http://timestamp.digicert.com /td sha256 /fd sha256 $_
}

# Verify signature
signtool verify /pa "build\windows\x64\runner\Release\kidslens_video_editor.exe"
```

### macOS Code Signing

```bash
# Sign with Developer ID
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (XXXXXXXXXX)" \
    --options runtime \
    "build/macos/Build/Products/Release/KidsLens.app"

# Verify signature
codesign --verify --deep --strict --verbose=2 \
    "build/macos/Build/Products/Release/KidsLens.app"
```

---

## Installer Creation

### Windows - Inno Setup

Create `installer/kidslens.iss`:

```iss
#define MyAppName "KidsLens Video Editor"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "KidsLens"
#define MyAppURL "https://kidslens.app"
#define MyAppExeName "kidslens_video_editor.exe"

[Setup]
AppId={{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..\dist
OutputBaseFilename=KidsLens-Setup-{#MyAppVersion}
SetupIconFile=..\assets\logos\icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
// Check for VC++ Runtime
function NeedsVCRedist: Boolean;
begin
  Result := not FileExists(ExpandConstant('{syswow64}\vcruntime140.dll'));
end;
```

Build installer:
```powershell
# Requires Inno Setup installed
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer\kidslens.iss
```

### Windows - MSIX Package

```powershell
# Create MSIX package
flutter pub run msix:create --release

# Or manually with MakeAppx
MakeAppx pack /d "build\windows\x64\runner\Release" /p "KidsLens.msix"

# Sign MSIX
signtool sign /f certificate.pfx /p password /fd sha256 KidsLens.msix
```

### macOS - DMG Creation

```bash
# Create DMG with create-dmg
npm install -g create-dmg

create-dmg \
    --volname "KidsLens Video Editor" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "KidsLens.app" 150 190 \
    --app-drop-link 450 190 \
    --background "installer/dmg-background.png" \
    "dist/KidsLens-1.0.0.dmg" \
    "build/macos/Build/Products/Release/KidsLens.app"
```

---

## Auto-Update System

### Update Check Flow

```
┌─────────────────┐
│   App Launch    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check Version   │
│ (Background)    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ Compare with    │────▶│ No Update       │
│ Remote Version  │     │ Available       │
└────────┬────────┘     └─────────────────┘
         │
         ▼ (Update Available)
┌─────────────────┐
│ Show Update     │
│ Notification    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Download Update │
│ in Background   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Prompt to       │
│ Restart         │
└─────────────────┘
```

### Version Manifest

Host at `https://updates.kidslens.app/latest.json`:

```json
{
  "version": "1.1.0",
  "releaseDate": "2026-02-01",
  "releaseNotes": "Bug fixes and performance improvements",
  "platforms": {
    "windows-x64": {
      "url": "https://updates.kidslens.app/KidsLens-1.1.0-win-x64.exe",
      "sha256": "abc123...",
      "size": 125000000
    },
    "macos-universal": {
      "url": "https://updates.kidslens.app/KidsLens-1.1.0.dmg",
      "sha256": "def456...",
      "size": 150000000
    },
    "linux-x64": {
      "url": "https://updates.kidslens.app/KidsLens-1.1.0.AppImage",
      "sha256": "ghi789...",
      "size": 130000000
    }
  },
  "minimumVersion": "1.0.0"
}
```

---

## Release Checklist

### Pre-Release

- [ ] All tests pass (`flutter test`)
- [ ] No analyzer warnings (`dart analyze`)
- [ ] Version bumped in `pubspec.yaml`
- [ ] Changelog updated
- [ ] Native libraries are current version
- [ ] Localization strings complete
- [ ] Screenshots/marketing materials updated

### Build

- [ ] Clean build (`flutter clean`)
- [ ] Dependencies updated (`flutter pub get`)
- [ ] Code generated (`dart run build_runner build`)
- [ ] Release build successful (`flutter build windows --release`)
- [ ] Native DLLs copied to output
- [ ] Build artifacts verified

### Testing

- [ ] Smoke test on clean Windows install
- [ ] Test all major features
- [ ] Test native library functionality
- [ ] Test installer/uninstaller
- [ ] Test auto-update from previous version
- [ ] Performance profiling complete

### Signing & Packaging

- [ ] Executable code signed
- [ ] DLLs code signed
- [ ] Installer created and signed
- [ ] Installer tested on clean system

### Distribution

- [ ] Upload to distribution server
- [ ] Update version manifest
- [ ] Create GitHub release
- [ ] Update download page
- [ ] Announce release

### Post-Release

- [ ] Monitor crash reports
- [ ] Monitor user feedback
- [ ] Tag release in git
- [ ] Update documentation if needed

---

## Troubleshooting

### Build Failures

**Missing Visual Studio components:**
```
CMake Error: CMAKE_C_COMPILER not set
```
Solution: Install "Desktop development with C++" workload in Visual Studio.

**Flutter version mismatch:**
```
Error: The current Flutter SDK version is X.X.X. This package requires SDK version >=3.16.0
```
Solution: Upgrade Flutter with `flutter upgrade`.

### Runtime Errors

**DLL not found:**
```
The code execution cannot proceed because ffmpeg_wrapper.dll was not found
```
Solution: Ensure all required DLLs are in the same directory as the executable.

**VC++ Runtime missing:**
```
VCRUNTIME140.dll not found
```
Solution: Install Visual C++ Redistributable 2015-2022.

### Installer Issues

**Access denied during installation:**
Solution: Run installer as administrator or use per-user installation.

**Files in use during update:**
Solution: Close all instances of the application before updating.
