# KidsLens Video Editor - State Management Guide

This document explains the state management architecture using Riverpod, including provider patterns, state flow, and best practices.

## Table of Contents

- [Riverpod Overview](#riverpod-overview)
- [Provider Architecture](#provider-architecture)
- [Provider Types](#provider-types)
- [State Flow Diagrams](#state-flow-diagrams)
- [Best Practices](#best-practices)
- [Code Examples](#code-examples)

---

## Riverpod Overview

KidsLens uses **Flutter Riverpod** with **riverpod_annotation** for code generation. This provides:

- Type-safe dependency injection
- Automatic disposal of resources
- Fine-grained reactivity
- Easy testing and mocking

### Why Riverpod?

| Feature | Benefit |
|---------|---------|
| **Compile-time safety** | Catch errors at build time |
| **No context required** | Access state anywhere |
| **Lazy initialization** | Providers created on first use |
| **Automatic caching** | Computed values memoized |
| **Easy testing** | Override providers in tests |

---

## Provider Architecture

### Layer Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  ConsumerWidget / ConsumerStatefulWidget                │    │
│  │  • ref.watch() for reactive rebuilds                    │    │
│  │  • ref.read() for one-time reads                        │    │
│  │  • ref.listen() for side effects                        │    │
│  └─────────────────────────────────────────────────────────┘    │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                      NOTIFIER LAYER                             │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  @Riverpod(keepAlive: true)                             │    │
│  │  class MyNotifier extends _$MyNotifier {                │    │
│  │    • Manages mutable state                              │    │
│  │    • Exposes methods for state updates                  │    │
│  │    • Coordinates with services                          │    │
│  │  }                                                      │    │
│  └─────────────────────────────────────────────────────────┘    │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DERIVED PROVIDERS                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  @riverpod                                               │    │
│  │  SomeType derivedValue(Ref ref) {                       │    │
│  │    final a = ref.watch(notifierAProvider);              │    │
│  │    final b = ref.watch(notifierBProvider);              │    │
│  │    return computeFrom(a, b);                            │    │
│  │  }                                                      │    │
│  └─────────────────────────────────────────────────────────┘    │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE PROVIDERS                            │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  @Riverpod(keepAlive: true)                             │    │
│  │  MyService myService(Ref ref) {                         │    │
│  │    return MyService(                                    │    │
│  │      dependency: ref.watch(dependencyProvider),         │    │
│  │    );                                                   │    │
│  │  }                                                      │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Provider Hierarchy

```
                    ┌──────────────────────┐
                    │   Native Bindings    │
                    │ (FFmpeg, Whisper,    │
                    │  ONNX, MMS)          │
                    └──────────┬───────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │ MediaService │   │AnalysisService│  │ ExportService│
    └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
           │                  │                  │
           ▼                  ▼                  ▼
    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │MediaNotifier │   │AnalysisNotifier│ │ ExportNotifier│
    └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
           │                  │                  │
           └──────────────────┼──────────────────┘
                              │
                              ▼
                    ┌──────────────────────┐
                    │  Derived Providers   │
                    │ • canStartAnalysis   │
                    │ • canStartExport     │
                    │ • pendingDetections  │
                    │ • detectionCounts    │
                    └──────────────────────┘
```

---

## Provider Types

### 1. Notifier Providers (Mutable State)

Used for state that can be modified over time.

```dart
// lib/state/providers/media_provider.dart
part 'media_provider.g.dart';

class MediaState {
  final MediaFile? currentMedia;
  final bool isLoading;
  final String? errorMessage;
  final List<MediaFile> recentFiles;

  const MediaState({
    this.currentMedia,
    this.isLoading = false,
    this.errorMessage,
    this.recentFiles = const [],
  });

  MediaState copyWith({...});
}

@Riverpod(keepAlive: true)
class MediaNotifier extends _$MediaNotifier {
  @override
  MediaState build() => const MediaState();

  Future<void> importMedia(String path) async {
    state = state.copyWith(isLoading: true);
    try {
      // Business logic...
      state = state.copyWith(isLoading: false, currentMedia: media);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearMedia() {
    state = state.copyWith(currentMedia: null);
  }
}
```

**Key Points:**
- Use `@Riverpod(keepAlive: true)` for persistent state
- Define immutable state classes with `copyWith`
- Override `build()` to return initial state
- Modify state via methods

### 2. Service Providers (Singletons)

Used for service instances that should live for the app lifetime.

```dart
// lib/state/providers/service_providers.dart
part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
FFmpegBindings ffmpegBindings(FfmpegBindingsRef ref) => FFmpegBindings();

@Riverpod(keepAlive: true)
MediaService mediaService(MediaServiceRef ref) {
  return MediaService(ref.watch(ffmpegBindingsProvider));
}

@Riverpod(keepAlive: true)
AnalysisService analysisService(AnalysisServiceRef ref) {
  return AnalysisService(
    ffmpeg: ref.watch(ffmpegBindingsProvider),
    whisper: ref.watch(whisperBindingsProvider),
    mms: ref.watch(mmsBindingsProvider),
    onnx: ref.watch(onnxBindingsProvider),
    modelManager: ref.watch(modelManagerServiceProvider),
    profanity: ref.watch(profanityServiceProvider),
  );
}
```

**Key Points:**
- Services are created once and cached
- Dependencies injected via `ref.watch()`
- Services contain business logic, not state

### 3. Derived Providers (Computed Values)

Used for values computed from other providers.

```dart
// lib/state/providers/derived_providers.dart
part 'derived_providers.g.dart';

@riverpod
List<Detection> pendingDetections(Ref ref) {
  final timeline = ref.watch(
    timelineNotifierProvider.select((s) => s.timeline),
  );
  if (timeline == null) return [];

  return timeline.detections
      .where((d) => d.userStatus == DetectionUserStatus.pending)
      .toList();
}

@riverpod
bool canStartAnalysis(Ref ref) {
  final media = ref.watch(
    mediaNotifierProvider.select((s) => s.currentMedia),
  );
  final analysisStatus = ref.watch(
    analysisNotifierProvider.select((s) => s.status),
  );

  return media != null && analysisStatus == AnalysisStatus.pending;
}

@riverpod
Map<ContentType, int> detectionCounts(Ref ref) {
  final timeline = ref.watch(
    timelineNotifierProvider.select((s) => s.timeline),
  );
  if (timeline == null) return {};

  final counts = <ContentType, int>{};
  for (final detection in timeline.detections) {
    counts[detection.type] = (counts[detection.type] ?? 0) + 1;
  }
  return counts;
}
```

**Key Points:**
- Auto-dispose (no `keepAlive`) for computed values
- Use `.select()` for fine-grained reactivity
- Recomputed when dependencies change

---

## State Flow Diagrams

### Media Import Flow

```
┌─────────────────┐
│ User taps       │
│ "Import Media"  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ UI Widget                                                       │
│   ref.read(mediaNotifierProvider.notifier).importMedia(path);   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ MediaNotifier.importMedia()                                     │
│   1. state = state.copyWith(isLoading: true);                   │
│   2. final media = await mediaService.importMedia(path);        │
│   3. state = state.copyWith(isLoading: false, currentMedia);    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ MediaService.importMedia()                                      │
│   1. Verify file exists                                         │
│   2. Call FFmpeg bindings to probe metadata                     │
│   3. Create MediaFile model                                     │
│   4. Return to notifier                                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ UI Reactivity                                                   │
│   • ref.watch(mediaNotifierProvider) triggers rebuild           │
│   • canStartAnalysisProvider recomputes (now true)              │
│   • UI updates to show media info                               │
└─────────────────────────────────────────────────────────────────┘
```

### Analysis Flow

```
┌─────────────────┐
│ User taps       │
│ "Start Analysis"│
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ ref.read(analysisNotifierProvider.notifier).startAnalysis()     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ AnalysisNotifier.startAnalysis()                                │
│   state = state.copyWith(status: running, progress: 0);         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ AnalysisService.analyze() Stream<AnalysisProgress>              │
│                                                                 │
│   Phase 1: Audio Extraction + ASR                               │
│     ├─ yield progress(step: 1, progress: 0.0 → 1.0)             │
│     └─ Transcript result                                        │
│                                                                 │
│   Phase 2: Profanity Detection                                  │
│     ├─ yield progress(step: 2, progress: 0.0 → 1.0)             │
│     └─ ProfanityMatch[] result                                  │
│                                                                 │
│   Phase 3: Visual Analysis                                      │
│     ├─ yield progress(step: 3, progress: 0.0 → 1.0)             │
│     └─ FrameAnalysisResult[] result                             │
│                                                                 │
│   Phase 4: Timeline Building                                    │
│     ├─ yield progress(step: 4, progress: 1.0)                   │
│     └─ UnifiedTimeline result                                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ AnalysisNotifier listens to stream                              │
│   progress.listen((p) {                                         │
│     state = state.copyWith(                                     │
│       progress: p.overallProgress,                              │
│       currentStep: p.stepName,                                  │
│     );                                                          │
│   });                                                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ On completion:                                                  │
│   • timelineNotifier.setTimeline(result)                        │
│   • state = state.copyWith(status: completed, result: result)   │
│   • UI rebuilds with results                                    │
└─────────────────────────────────────────────────────────────────┘
```

### Selection State Flow

```
┌─────────────────┐
│ User selects    │
│ a detection     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│ DetectionListItem widget                                        │
│   onTap: () {                                                   │
│     ref.read(timelineNotifierProvider.notifier)                 │
│       .selectDetection(detection.id);                           │
│   }                                                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ TimelineNotifier.selectDetection(id)                            │
│   1. Update timeline with isSelected: true                      │
│   2. Add to selectedDetectionIds set                            │
│   3. state = state.copyWith(timeline, selectedIds);             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ Reactive updates:                                               │
│   • Timeline view highlights selected segment                   │
│   • Detail panel shows detection info                           │
│   • Action buttons become enabled                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Best Practices

### 1. Use `select()` for Fine-Grained Reactivity

Instead of watching the entire state:
```dart
// ❌ Rebuilds on any state change
final state = ref.watch(mediaNotifierProvider);
final media = state.currentMedia;

// ✅ Rebuilds only when currentMedia changes
final media = ref.watch(
  mediaNotifierProvider.select((s) => s.currentMedia),
);
```

### 2. Use `read()` for One-Time Actions

```dart
// ✅ Correct: Use read() in callbacks
ElevatedButton(
  onPressed: () {
    ref.read(analysisNotifierProvider.notifier).startAnalysis(...);
  },
  child: Text('Start'),
)

// ❌ Wrong: Don't use watch() in callbacks
ElevatedButton(
  onPressed: () {
    ref.watch(...); // This doesn't make sense
  },
)
```

### 3. Keep State Immutable

```dart
class MediaState {
  final MediaFile? currentMedia;
  final List<MediaFile> recentFiles;

  const MediaState({
    this.currentMedia,
    this.recentFiles = const [],
  });

  // ✅ Return new instance, don't mutate
  MediaState copyWith({
    MediaFile? currentMedia,
    List<MediaFile>? recentFiles,
  }) {
    return MediaState(
      currentMedia: currentMedia ?? this.currentMedia,
      recentFiles: recentFiles ?? this.recentFiles,
    );
  }
}
```

### 4. Handle Loading and Error States

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(mediaNotifierProvider);

  if (state.isLoading) {
    return const CircularProgressIndicator();
  }

  if (state.errorMessage != null) {
    return ErrorWidget(
      message: state.errorMessage!,
      onRetry: () => ref.read(mediaNotifierProvider.notifier).clearError(),
    );
  }

  if (state.currentMedia == null) {
    return const EmptyState();
  }

  return MediaView(media: state.currentMedia!);
}
```

### 5. Dispose Resources in Notifiers

```dart
@Riverpod(keepAlive: true)
class AnalysisNotifier extends _$AnalysisNotifier {
  StreamSubscription<AnalysisProgress>? _subscription;

  @override
  AnalysisState build() {
    // Clean up when notifier is disposed
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const AnalysisState();
  }

  void cancel() {
    _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(status: AnalysisStatus.cancelled);
  }
}
```

### 6. Use `listen()` for Side Effects

```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  void initState() {
    super.initState();
    
    // Listen for state changes and perform side effects
    ref.listenManual(
      analysisNotifierProvider.select((s) => s.status),
      (previous, next) {
        if (next == AnalysisStatus.completed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Analysis complete!')),
          );
        }
      },
    );
  }
}
```

### 7. Test with Provider Overrides

```dart
void main() {
  group('HomeScreen', () {
    testWidgets('shows media info when loaded', (tester) async {
      final testMedia = MediaFile(
        id: '1',
        path: '/test.mp4',
        name: 'test.mp4',
        duration: const Duration(minutes: 5),
        width: 1920,
        height: 1080,
        fileSize: 100000000,
        mediaType: MediaType.video,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaNotifierProvider.overrideWith(() {
              return TestMediaNotifier(testMedia);
            }),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('test.mp4'), findsOneWidget);
    });
  });
}
```

---

## Code Examples

### Complete Notifier Example

```dart
// lib/state/providers/settings_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

part 'settings_provider.g.dart';

/// Application settings state (immutable)
class SettingsState {
  final AnalysisSettings analysisSettings;
  final String? selectedLanguage;
  final bool useDarkTheme;
  final bool showOnboarding;
  final String? modelCachePath;
  final String? exportPath;

  SettingsState({
    AnalysisSettings? analysisSettings,
    this.selectedLanguage,
    this.useDarkTheme = false,
    this.showOnboarding = true,
    this.modelCachePath,
    this.exportPath,
  }) : analysisSettings = analysisSettings ?? AnalysisSettings.defaults();

  SettingsState copyWith({
    AnalysisSettings? analysisSettings,
    String? selectedLanguage,
    bool? useDarkTheme,
    bool? showOnboarding,
    String? modelCachePath,
    String? exportPath,
  }) {
    return SettingsState(
      analysisSettings: analysisSettings ?? this.analysisSettings,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      useDarkTheme: useDarkTheme ?? this.useDarkTheme,
      showOnboarding: showOnboarding ?? this.showOnboarding,
      modelCachePath: modelCachePath ?? this.modelCachePath,
      exportPath: exportPath ?? this.exportPath,
    );
  }
}

/// Provider for managing application settings
@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  @override
  SettingsState build() => SettingsState();

  void updateAnalysisSettings(AnalysisSettings settings) {
    state = state.copyWith(analysisSettings: settings);
  }

  void setLanguage(String language) {
    state = state.copyWith(selectedLanguage: language);
  }

  void setDarkTheme(bool useDark) {
    state = state.copyWith(useDarkTheme: useDark);
  }

  void setOnboardingComplete() {
    state = state.copyWith(showOnboarding: false);
  }

  void setModelCachePath(String path) {
    state = state.copyWith(modelCachePath: path);
  }

  void setExportPath(String path) {
    state = state.copyWith(exportPath: path);
  }

  void resetToDefaults() {
    state = SettingsState();
  }
}
```

### Using Providers in Widgets

```dart
// lib/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for reactive updates
    final settings = ref.watch(settingsNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Theme'),
            value: settings.useDarkTheme,
            onChanged: (value) {
              // Use read() for actions
              ref.read(settingsNotifierProvider.notifier)
                .setDarkTheme(value);
            },
          ),
          ListTile(
            title: const Text('Detection Sensitivity'),
            subtitle: Text(
              'NSFW: ${(settings.analysisSettings.nsfwThreshold * 100).toInt()}%',
            ),
            onTap: () => _showSensitivityDialog(context, ref),
          ),
          ListTile(
            title: const Text('Reset to Defaults'),
            onTap: () {
              ref.read(settingsNotifierProvider.notifier).resetToDefaults();
            },
          ),
        ],
      ),
    );
  }

  void _showSensitivityDialog(BuildContext context, WidgetRef ref) {
    // Dialog implementation...
  }
}
```

### Combining Multiple Providers

```dart
// Widget that depends on multiple providers
class AnalysisControlPanel extends ConsumerWidget {
  const AnalysisControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch derived provider for computed value
    final canStart = ref.watch(canStartAnalysisProvider);
    
    // Watch specific parts of state
    final isRunning = ref.watch(
      analysisNotifierProvider.select((s) => s.status == AnalysisStatus.running),
    );
    final progress = ref.watch(
      analysisNotifierProvider.select((s) => s.progress),
    );
    final settings = ref.watch(
      settingsNotifierProvider.select((s) => s.analysisSettings),
    );

    return Column(
      children: [
        if (isRunning)
          LinearProgressIndicator(value: progress)
        else
          ElevatedButton(
            onPressed: canStart
                ? () => _startAnalysis(ref, settings)
                : null,
            child: const Text('Start Analysis'),
          ),
        if (isRunning)
          TextButton(
            onPressed: () {
              ref.read(analysisNotifierProvider.notifier).cancel();
            },
            child: const Text('Cancel'),
          ),
      ],
    );
  }

  void _startAnalysis(WidgetRef ref, AnalysisSettings settings) {
    final mediaPath = ref.read(
      mediaNotifierProvider.select((s) => s.currentMedia?.path),
    );
    if (mediaPath != null) {
      ref.read(analysisNotifierProvider.notifier).startAnalysis(
        mediaPath: mediaPath,
        settings: settings,
      );
    }
  }
}
```
