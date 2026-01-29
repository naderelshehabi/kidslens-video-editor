# FFmpeg Bundling for KidsLens Video Editor

This directory contains bundled FFmpeg binaries for the KidsLens Video Editor application.

## License Information

**FFmpeg is licensed under the LGPL v2.1 or later.**

The bundled FFmpeg binaries are compiled as **LGPL-compliant** builds, meaning:
- They do not include GPL-only components (like x264 encoder with GPL options)
- They can be redistributed with proprietary/closed-source applications
- The LGPL license terms must still be followed

### LGPL Compliance Requirements

When distributing KidsLens Video Editor with bundled FFmpeg:

1. **Attribution**: Include FFmpeg license and copyright notice
2. **Source Availability**: Provide access to FFmpeg source code (link to upstream is sufficient)
3. **Library Replacement**: Users must be able to replace the FFmpeg libraries if desired
4. **License Text**: Include the full LGPL license text

### License Files

- [LGPL v2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html)
- [FFmpeg License](https://ffmpeg.org/legal.html)

## Directory Structure

```
native/ffmpeg/
├── README.md           # This file
├── LICENSE.txt         # LGPL license text
└── binaries/
    ├── windows-x64/
    │   ├── ffmpeg.exe
    │   └── ffprobe.exe
    ├── windows-arm64/
    │   ├── ffmpeg.exe
    │   └── ffprobe.exe
    ├── macos-universal/
    │   ├── ffmpeg
    │   └── ffprobe
    ├── linux-x64/
    │   ├── ffmpeg
    │   └── ffprobe
    └── linux-arm64/
        ├── ffmpeg
        └── ffprobe
```

## Downloading FFmpeg Binaries

### Using Dart Script (Recommended)

```bash
# Download for current platform
dart run scripts/download_ffmpeg.dart

# Download for specific platform
dart run scripts/download_ffmpeg.dart --platform=windows-x64
dart run scripts/download_ffmpeg.dart --platform=macos-universal
dart run scripts/download_ffmpeg.dart --platform=linux-x64
```

### Using Platform Scripts

**Windows (PowerShell):**
```powershell
.\scripts\download_ffmpeg.ps1
# Or for specific architecture
.\scripts\download_ffmpeg.ps1 -Architecture arm64
```

**macOS/Linux (Shell):**
```bash
./scripts/download_ffmpeg.sh
# Or for specific platform
./scripts/download_ffmpeg.sh --platform=linux-arm64
```

## Binary Sources

We use well-maintained community builds:

| Platform | Source | Build Type |
|----------|--------|------------|
| Windows x64/ARM64 | [BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds) | LGPL shared |
| macOS Universal | [evermeet.cx](https://evermeet.cx/ffmpeg/) | Static |
| Linux x64/ARM64 | [johnvansickle.com](https://johnvansickle.com/ffmpeg/) | Static |

## Build Information

The bundled FFmpeg binaries include the following components:

### Core Libraries
- libavcodec - Codec library
- libavformat - Container format library
- libavutil - Utility library
- libavfilter - Filter library
- libswscale - Scaling library
- libswresample - Audio resampling library

### Enabled Features (LGPL-compatible)
- H.264/H.265 decoding (via platform decoders)
- AAC audio encoding/decoding
- MP3 audio decoding
- Various container formats (MP4, MKV, MOV, AVI, etc.)
- Video filters (scale, crop, overlay, etc.)
- Audio filters (volume, fade, mix, etc.)

## Updating FFmpeg

To update to a newer FFmpeg version:

1. Run the download script with the desired version:
   ```bash
   dart run scripts/download_ffmpeg.dart --version=7.0
   ```

2. Test the application thoroughly with the new binaries

3. Update this README with the new version information

## Troubleshooting

### Windows: "VCRUNTIME140.dll not found"
Install the [Visual C++ Redistributable](https://aka.ms/vs/17/release/vc_redist.x64.exe).

### macOS: "ffmpeg cannot be opened because the developer cannot be verified"
Run: `xattr -d com.apple.quarantine native/ffmpeg/binaries/macos-universal/ffmpeg`

### Linux: Permission denied
Run: `chmod +x native/ffmpeg/binaries/linux-x64/ffmpeg native/ffmpeg/binaries/linux-x64/ffprobe`

## Version History

| Date | FFmpeg Version | Notes |
|------|----------------|-------|
| 2026-01-29 | 7.x | Initial bundling setup |

## Contact

For issues related to FFmpeg bundling, please open an issue on the project repository.
