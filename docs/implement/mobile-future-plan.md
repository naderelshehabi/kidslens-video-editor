# KidsLens - Mobile Platform Implementation (Future Phase)

**Status:** Planned for Future Release  
**Prerequisites:** Desktop v1.0 Complete  
**Target Platforms:** Android, iOS

---

## Overview

This document outlines the mobile-specific implementation considerations for KidsLens, to be addressed after the desktop version (Windows, macOS, Linux) reaches production readiness.

---

## 1. Platform-Specific Constraints

### 1.1 iOS Constraints

| Constraint | Impact | Mitigation Strategy |
|------------|--------|---------------------|
| Background processing limits | Long analysis interrupted | Use Background Tasks API with checkpointing |
| App size limits (200MB OTA) | Can't bundle large models | On-demand model download |
| Metal-only GPU | No CUDA fallback | Metal acceleration required |
| Memory pressure (2-4GB) | Can't load large models | Quantized models only (tiny/base) |
| Thermal throttling | Sustained inference slows | Adaptive frame rate |
| App Store review | Content moderation apps scrutinized | Clear documentation of purpose |

### 1.2 Android Constraints

| Constraint | Impact | Mitigation Strategy |
|------------|--------|---------------------|
| Device fragmentation | Inconsistent performance | Tiered device profiles |
| Background processing (Doze) | Analysis interrupted | Foreground service + WorkManager |
| Memory limits (varies by device) | OOM on low-end devices | Aggressive memory management |
| GPU diversity (Mali/Adreno/PowerVR) | NNAPI compatibility varies | CPU fallback always available |
| Storage types (eMMC vs UFS) | I/O bottlenecks | Adaptive buffer sizing |

---

## 2. Mobile-Specific Architecture

### 2.1 Model Selection for Mobile

| Model | Desktop | Mobile | Notes |
|-------|---------|--------|-------|
| Whisper large-v3 | ✓ | ✗ | Too large (3GB) |
| Whisper medium | ✓ | ✗ | Too large (1.5GB) |
| Whisper small | ✓ | ⚠️ | Only on high-end devices |
| Whisper base | ✓ | ✓ | Recommended for mobile |
| Whisper tiny | ✓ | ✓ | Low-end devices |
| NSFW MobileNet | ✓ | ✓ | Optimized for mobile |
| Violence ViT-base | ✓ | ⚠️ | Use quantized version |

### 2.2 Memory Management for Mobile

```dart
class MobileMemoryManager {
  static const int lowMemoryThresholdMB = 512;
  static const int criticalMemoryThresholdMB = 256;
  
  /// Monitor memory pressure on mobile
  Stream<MemoryPressureLevel> watchMemoryPressure() async* {
    // iOS: Use os_proc_available_memory
    // Android: Use ActivityManager.getMemoryInfo
  }
  
  /// Trigger emergency cleanup
  Future<void> handleMemoryPressure(MemoryPressureLevel level) async {
    switch (level) {
      case MemoryPressureLevel.moderate:
        await _clearFrameBufferPool();
        break;
      case MemoryPressureLevel.critical:
        await _unloadNonEssentialModels();
        await _flushAllCaches();
        break;
      case MemoryPressureLevel.terminal:
        await _saveCheckpointAndPause();
        break;
    }
  }
}
```

### 2.3 Background Processing

```dart
/// iOS Background Task Handler
class iOSBackgroundProcessor {
  Future<void> registerBackgroundTasks() async {
    // BGProcessingTaskRequest for long analysis
    // BGAppRefreshTaskRequest for incremental work
  }
  
  Future<void> handleBackgroundTask(String taskId) async {
    // Must complete within 30 seconds for refresh tasks
    // Up to several minutes for processing tasks
    // Always checkpoint before expiration
  }
}

/// Android WorkManager Integration
class AndroidBackgroundProcessor {
  Future<void> scheduleAnalysis(String mediaPath) async {
    // Use WorkManager for reliable background execution
    // Expedited work for user-initiated tasks
    // Constraints: requiresCharging, requiresStorageNotLow
  }
}
```

---

## 3. Mobile UI Considerations

### 3.1 Touch-Optimized Timeline Editor

- Larger touch targets (minimum 48dp)
- Pinch-to-zoom on timeline
- Haptic feedback for segment boundaries
- Simplified modification options (presets over sliders)

### 3.2 Offline-First Architecture

- Queue analysis jobs for later if models not downloaded
- Progressive model download with resume support
- Clear indication of offline capabilities

### 3.3 Battery Optimization

- Show estimated battery impact before analysis
- Pause analysis when battery critical
- Recommend charging for long videos

---

## 4. Mobile-Specific Testing

### 4.1 Device Lab Requirements

| Category | Devices |
|----------|---------|
| iOS High-end | iPhone 15 Pro, iPad Pro M2 |
| iOS Mid-range | iPhone 13, iPad Air |
| iOS Low-end | iPhone SE, iPad 9th gen |
| Android High-end | Pixel 8 Pro, Samsung S24 |
| Android Mid-range | Pixel 7a, Samsung A54 |
| Android Low-end | Pixel 4a, Samsung A14 |

### 4.2 Mobile-Specific Test Cases

- Background/foreground transitions during analysis
- Memory pressure simulation
- Thermal throttling behavior
- Interrupted downloads resume
- Low storage handling
- Orientation changes during export

---

## 5. Estimated Mobile Timeline

| Phase | Duration | Deliverables |
|-------|----------|--------------|
| Mobile Proof of Concept | 4 weeks | FFmpeg + Whisper running on Android/iOS |
| Core Adaptation | 8 weeks | Analysis pipeline working within mobile constraints |
| UI Optimization | 4 weeks | Touch-optimized interface |
| Platform Integration | 4 weeks | Background processing, notifications |
| Testing & Polish | 4 weeks | Device lab testing, performance tuning |
| **Total** | **24 weeks** | Production-ready mobile apps |

---

## 6. Mobile-Specific Dependencies

### 6.1 Native Libraries (Mobile Builds)

| Library | iOS | Android |
|---------|-----|---------|
| FFmpeg | Static xcframework | Shared .so per ABI |
| whisper.cpp | Metal-enabled build | NNAPI/Vulkan build |
| ONNX Runtime | CoreML EP | NNAPI EP |

### 6.2 Platform APIs

| Feature | iOS API | Android API |
|---------|---------|-------------|
| Background tasks | BGTaskScheduler | WorkManager |
| Memory monitoring | os_proc_available_memory | ActivityManager |
| GPU inference | Metal Performance Shaders | NNAPI / Vulkan |
| File access | FileManager | Storage Access Framework |

---

*This document will be expanded when mobile development begins.*

*Last Updated: January 2026*
