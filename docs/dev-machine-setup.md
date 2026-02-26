# Dev Machine Setup (Windows, Flutter + CUDA 13.1)

This guide defines the **standard, supported** development setup for this repository.

## 1) Official compatibility baseline

For CUDA builds in this project, use only toolchain combinations that are officially supported:

- CUDA: **13.1**
- Visual Studio: **Visual Studio 2022 (17.x)** with MSVC 193x
- Workload: **Desktop development with C++**
- OS: Windows versions supported by CUDA + Flutter desktop

Official references:

- CUDA Installation Guide for Windows: https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/
- CUDA 13.1 Release Notes: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html
- Visual Studio C++ installation: https://learn.microsoft.com/en-us/cpp/build/vscpp-step-0-installation
- Flutter Windows setup: https://docs.flutter.dev/platform-integration/windows/setup

## 2) Install prerequisites

### A. Flutter (Windows desktop)

1. Install Flutter SDK.
2. Ensure Windows desktop target is available.
3. Verify with:

```powershell
flutter doctor -v
flutter devices
```

### B. Visual Studio 2022 (required for CUDA 13.1)

Install Visual Studio 2022 Build Tools:

```powershell
winget install --id=Microsoft.VisualStudio.2022.BuildTools -e
```

Then open **Visual Studio Installer** → **Modify** on Build Tools and add:

- Workload: **Desktop development with C++**
- Recommended components:
  - MSVC v143 toolset
  - Windows 10/11 SDK
  - CMake tools for C++

### C. NVIDIA driver + CUDA Toolkit 13.1

1. Install an NVIDIA driver compatible with CUDA 13.x (see CUDA release notes).
2. Install CUDA Toolkit 13.1.
3. Ensure **Visual Studio Integration** is installed (`visual_studio_integration_13.1`).
4. If you installed VS 2022 Build Tools **after** CUDA, rerun CUDA installer and add `visual_studio_integration_13.1` so CUDA files are registered into the VS 2022 Build Tools instance.

Verify:

```powershell
where nvcc
nvcc --version
nvidia-smi
```

## 3) Verify CUDA toolchain integration

Confirm CUDA build customizations exist for VS 2022:

```powershell
Get-ChildItem "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\VC\v170\BuildCustomizations" -Filter "CUDA*.props"
Get-ChildItem "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Microsoft\VC\v170\BuildCustomizations" -Filter "CUDA*.props"
```

Expected: files such as `CUDA 13.1.props`.

## 4) Verify CUDA runtime with official samples

Use official CUDA samples (recommended by NVIDIA):

1. Clone: https://github.com/NVIDIA/cuda-samples
2. Build and run `deviceQuery` and `bandwidthTest`.
3. Confirm both pass.

## 5) Build this project (standard path)

From repository root:

```powershell
flutter clean
flutter pub get
flutter build windows --debug
```

Expected CMake configure output includes one of:

- `Whisper GPU backend: CUDA` (CUDA toolchain detected)
- `Whisper GPU backend: Vulkan` (CUDA unavailable but Vulkan SDK available)
- `Whisper GPU backend: CPU-only` (no GPU backend available)

### VS2022-forced build workflow (recommended when VS2026 is also installed)

If Flutter auto-selects VS2026 on your machine, use the repo script that forces VS2022 CMake:

```powershell
.\scripts\build_windows_vs2022.ps1 -Configuration Debug
```

For release builds:

```powershell
.\scripts\build_windows_vs2022.ps1 -Configuration Release
```

This keeps the workflow standards-based (CUDA 13.1 + VS2022 toolchain) without unsupported compiler flags.

## 6) Runtime verification in app

1. Start app:

```powershell
flutter run -d windows --debug
```

2. In Analysis Settings → Performance, select NVIDIA GPU.
3. Run transcription and observe GPU activity in `nvidia-smi`.

## 7) Supported vs unsupported machine setups

### Supported (for CUDA 13.1)

- Windows + Visual Studio 2022 + CUDA 13.1 + NVIDIA driver

### Not standard for this repo

- Visual Studio 2026 with CUDA 13.1 (toolchain support mismatch)

If you must keep Visual Studio 2026 installed, keep VS 2022 installed as well and use VS 2022 for CUDA builds.

## 8) Troubleshooting checklist

- `flutter doctor -v` has no Windows/Visual Studio errors.
- `nvcc --version` reports 13.1.
- `nvidia-smi` works and reports driver/GPU.
- VS 2022 BuildCustomizations contains `CUDA 13.1.props`.
- CUDA samples `deviceQuery` and `bandwidthTest` pass.
- Project configure prints `Whisper GPU backend: CUDA`.
