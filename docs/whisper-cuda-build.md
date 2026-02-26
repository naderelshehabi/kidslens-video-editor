# Building Whisper with CUDA (with CPU Fallback)

This guide explains how to build the Windows app so Whisper uses CUDA when available, and falls back to CPU when CUDA is unavailable at runtime.

> Recommended first step: complete [Dev Machine Setup](dev-machine-setup.md) to ensure your toolchain matches supported CUDA requirements.

## Overview

The project already supports automatic fallback behavior:

- **Preferred**: CUDA backend for Whisper (NVIDIA GPU)
- **Fallback**: CPU backend if CUDA initialization fails

This is implemented in `native/whisper/whisper_wrapper.cpp` and used by the Dart isolate transcription path.

---

## 1) Prerequisites

### Required

- Windows 10/11
- Visual Studio 2022
- Visual Studio workload: **Desktop development with C++**
- MSVC toolset (v143) and Windows SDK installed
- NVIDIA driver (up to date)
- NVIDIA CUDA Toolkit installed
- CUDA Visual Studio Integration installed

### Verify prerequisites

Open PowerShell and run:

```powershell
where nvcc
nvcc --version
nvidia-smi
```

Expected:

- `nvcc` resolves to a CUDA Toolkit path
- `nvidia-smi` lists your NVIDIA GPU

---

## 2) Clean and Reconfigure Build

From repository root:

```powershell
flutter clean
flutter pub get
flutter build windows --debug
```

This forces CMake to reconfigure native dependencies (including Whisper) with current CUDA toolchain availability.

---

## 3) Confirm Whisper Build Backend

After a build, inspect:

- `build/windows/x64/CMakeCache.txt`

Look for:

```text
WHISPER_USE_CUDA:BOOL=ON
```

If it is `OFF`, Whisper was not compiled with CUDA and transcription will run CPU-only.

---

## 4) Runtime Behavior (CPU Fallback)

At runtime, Whisper initialization is attempted with requested GPU settings. If GPU init fails, it automatically retries with CPU.

So behavior is:

1. Try GPU (CUDA backend)
2. If init/transcribe fails, retry on CPU

This ensures transcription still works even when CUDA is unavailable or unstable.

---

## 5) Verify in App

1. Run app:

```powershell
flutter run -d windows --debug
```

2. Open **Analysis Settings → Performance**.
3. Enable GPU and select NVIDIA GPU.
4. Run transcription.

Useful checks:

- `nvidia-smi` should show utilization during transcription if CUDA is active
- App logs should indicate ASR isolate config and backend information

---

## 6) Troubleshooting

### A) `CMAKE_CUDA_COMPILER:FILEPATH=NOTFOUND`

Cause: CMake cannot use CUDA compiler/toolset for current VS generator.

Fix:

1. Re-run CUDA installer and ensure **CUDA Visual Studio Integration** is selected
2. Ensure Visual Studio C++ workload/components are installed
3. Reboot
4. Re-run:

```powershell
flutter clean
flutter build windows --debug
```

### B) `No CUDA toolset found`

Cause: CUDA toolkit exists, but Visual Studio integration/toolset is missing or mismatched.

Fix:

- Reinstall CUDA with VS integration enabled
- Verify Visual Studio 2022 C++ toolchain is present

### C) NVIDIA visible in Task Manager, but Whisper uses CPU

Cause: Whisper was built without CUDA (`WHISPER_USE_CUDA=OFF`) or CUDA init failed at runtime.

Fix:

- Confirm build cache value is `ON`
- Rebuild after fixing CUDA toolchain
- Check runtime logs for fallback messages

---

## 7) Optional: Release Build

```powershell
flutter build windows --release
```

Then verify `WHISPER_USE_CUDA` in the corresponding generated build cache if needed.

---

## Notes

- ONNX content-analysis GPU execution is configured separately from Whisper backend selection.
- Transcription GPU usage depends specifically on Whisper being compiled with CUDA support.
