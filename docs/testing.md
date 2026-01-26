# KidsLens Video Editor - Testing Guide

This document covers the testing strategy, structure, and best practices for the KidsLens Video Editor.

## Table of Contents

- [Test Structure](#test-structure)
- [Running Tests](#running-tests)
- [Unit Testing](#unit-testing)
- [Widget Testing](#widget-testing)
- [Integration Testing](#integration-testing)
- [Mocking Strategies](#mocking-strategies)
- [Coverage Requirements](#coverage-requirements)
- [Testing Best Practices](#testing-best-practices)

---

## Test Structure

### Directory Layout

```
test/
├── core/                           # Core utility tests
│   ├── app_exceptions_test.dart
│   ├── duration_extensions_test.dart
│   ├── result_test.dart
│   └── string_extensions_test.dart
│
├── data/                           # Data model tests
│   └── models/
│       ├── media_file_test.dart
│       ├── detection_test.dart
│       ├── modification_test.dart
│       └── timeline_test.dart
│
├── services/                       # Service layer tests
│   ├── media_service_test.dart
│   ├── profanity_service_test.dart
│   ├── analysis_service_test.dart
│   └── export_service_test.dart
│
├── state/                          # State management tests
│   └── providers/
│       ├── media_provider_test.dart
│       ├── analysis_provider_test.dart
│       ├── timeline_provider_test.dart
│       └── derived_providers_test.dart
│
├── presentation/                   # UI tests
│   ├── screens/
│   │   ├── home_screen_test.dart
│   │   └── settings_screen_test.dart
│   └── widgets/
│       ├── detection_list_test.dart
│       └── timeline_view_test.dart
│
└── widget_test.dart                # Basic smoke tests

integration_test/
└── app_test.dart                   # End-to-end tests
```

### Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Unit test | `{class}_test.dart` | `profanity_service_test.dart` |
| Widget test | `{widget}_test.dart` | `detection_list_test.dart` |
| Integration | `{feature}_test.dart` | `analysis_flow_test.dart` |
| Test group | `'ClassName'` | `group('ProfanityService', ...)` |
| Test case | `'should {behavior}'` | `test('should detect profanity', ...)` |

---

## Running Tests

### Basic Commands

```bash
# Run all tests
flutter test

# Run with verbose output
flutter test --reporter expanded

# Run specific file
flutter test test/services/profanity_service_test.dart

# Run tests matching a pattern
flutter test --name "ProfanityService"

# Run tests in a directory
flutter test test/services/

# Run with concurrency limit
flutter test --concurrency 4
```

### Watch Mode

```bash
# Install test watcher (third-party)
flutter pub global activate test_cov

# Run in watch mode
test_cov --watch
```

### Coverage

```bash
# Generate coverage report
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open report (Windows)
start coverage/html/index.html

# Open report (macOS/Linux)
open coverage/html/index.html
```

### CI Integration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run code generation
        run: dart run build_runner build
      
      - name: Analyze
        run: dart analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

---

## Unit Testing

### Testing Services

```dart
// test/services/profanity_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

void main() {
  group('ProfanityService', () {
    late ProfanityService service;

    setUp(() {
      service = ProfanityService();
    });

    group('detect', () {
      test('should detect exact word matches', () {
        final transcript = Transcript(
          segments: [
            TranscriptSegment(
              id: 'seg_1',
              startTime: Duration.zero,
              endTime: const Duration(seconds: 5),
              text: 'This contains a badword here',
              words: [
                const TranscriptWord(
                  word: 'badword',
                  startTime: Duration(seconds: 2),
                  endTime: Duration(seconds: 3),
                  confidence: 0.95,
                ),
              ],
            ),
          ],
          language: 'en',
        );

        service.addCustomWords(['badword']);
        final matches = service.detect(transcript);

        expect(matches, hasLength(1));
        expect(matches.first.matchedProfanity, equals('badword'));
        expect(matches.first.type, equals(MatchType.exact));
        expect(matches.first.confidence, equals(1.0));
      });

      test('should detect leetspeak variations', () {
        final transcript = _createTranscript('h4te');

        service.addCustomWords(['hate']);
        final matches = service.detect(transcript);

        expect(matches, hasLength(1));
        expect(matches.first.type, equals(MatchType.leetspeak));
        expect(matches.first.confidence, lessThan(1.0));
      });

      test('should respect exclusion list', () {
        final transcript = _createTranscript('hello');

        service.addCustomWords(['hello']);
        service.excludeWords(['hello']);
        final matches = service.detect(transcript);

        expect(matches, isEmpty);
      });

      test('should return empty list for clean transcript', () {
        final transcript = _createTranscript('This is a clean sentence');

        final matches = service.detect(transcript);

        expect(matches, isEmpty);
      });
    });

    group('leetspeak normalization', () {
      test('should normalize common substitutions', () {
        // Testing private method through public behavior
        service.addCustomWords(['password']);
        
        final transcript = _createTranscript('p4ssw0rd');
        final matches = service.detect(transcript);

        expect(matches, hasLength(1));
      });
    });
  });
}

Transcript _createTranscript(String text) {
  return Transcript(
    segments: [
      TranscriptSegment(
        id: 'seg_1',
        startTime: Duration.zero,
        endTime: const Duration(seconds: 1),
        text: text,
        words: text.split(' ').map((word) {
          return TranscriptWord(
            word: word,
            startTime: Duration.zero,
            endTime: const Duration(milliseconds: 500),
            confidence: 0.9,
          );
        }).toList(),
      ),
    ],
    language: 'en',
  );
}
```

### Testing Data Models

```dart
// test/data/models/detection_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

void main() {
  group('Detection', () {
    test('should calculate duration correctly', () {
      final detection = Detection(
        id: 'det_1',
        type: ContentType.profanity,
        startTime: const Duration(seconds: 10),
        endTime: const Duration(seconds: 15),
        confidence: 0.9,
        description: 'Test detection',
      );

      expect(detection.duration, equals(const Duration(seconds: 5)));
    });

    test('should report correct review status', () {
      final pending = Detection(
        id: 'det_1',
        type: ContentType.nsfw,
        startTime: Duration.zero,
        endTime: const Duration(seconds: 1),
        confidence: 0.8,
        description: 'Test',
        userStatus: DetectionUserStatus.pending,
      );

      final confirmed = pending.copyWith(
        userStatus: DetectionUserStatus.confirmed,
      );

      expect(pending.isReviewed, isFalse);
      expect(pending.isPending, isTrue);
      expect(confirmed.isReviewed, isTrue);
      expect(confirmed.isConfirmed, isTrue);
    });

    group('factory constructors', () {
      test('profanity should set correct defaults', () {
        final detection = Detection.profanity(
          id: 'det_1',
          startTime: Duration.zero,
          endTime: const Duration(seconds: 1),
          confidence: 0.95,
          word: 'testword',
        );

        expect(detection.type, equals(ContentType.profanity));
        expect(detection.source, equals('asr'));
        expect(detection.description, contains('testword'));
      });

      test('visual should set correct defaults', () {
        final detection = Detection.visual(
          id: 'det_1',
          type: ContentType.violence,
          startTime: Duration.zero,
          endTime: const Duration(seconds: 1),
          confidence: 0.85,
        );

        expect(detection.source, equals('visual'));
        expect(detection.description, contains('Violent'));
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        final original = Detection(
          id: 'det_1',
          type: ContentType.blood,
          startTime: const Duration(milliseconds: 1500),
          endTime: const Duration(milliseconds: 3000),
          confidence: 0.75,
          description: 'Test detection',
          userStatus: DetectionUserStatus.confirmed,
        );

        final json = original.toJson();
        final restored = Detection.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}
```

### Testing Extensions

```dart
// test/core/duration_extensions_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/core/extensions/duration_extensions.dart';

void main() {
  group('DurationExtensions', () {
    group('formatted', () {
      test('should format hours correctly', () {
        const duration = Duration(hours: 2, minutes: 30, seconds: 45);
        expect(duration.formatted, equals('2:30:45'));
      });

      test('should format without hours', () {
        const duration = Duration(minutes: 5, seconds: 30);
        expect(duration.formatted, equals('5:30'));
      });

      test('should pad seconds with zero', () {
        const duration = Duration(minutes: 1, seconds: 5);
        expect(duration.formatted, equals('1:05'));
      });
    });

    group('toTimestamp', () {
      test('should return milliseconds timestamp', () {
        const duration = Duration(seconds: 5, milliseconds: 500);
        expect(duration.toTimestamp, equals('00:00:05.500'));
      });
    });
  });
}
```

---

## Widget Testing

### Basic Widget Test

```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/app.dart';

void main() {
  testWidgets('App smoke test - launches successfully', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KidsLensApp(),
      ),
    );

    expect(find.text('KidsLens Video Editor'), findsOneWidget);
  });

  testWidgets('App shows welcome message', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KidsLensApp(),
      ),
    );

    expect(find.text('Welcome to KidsLens'), findsOneWidget);
  });
}
```

### Testing with Provider Overrides

```dart
// test/presentation/screens/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/screens/home_screen.dart';
import 'package:kidslens_video_editor/state/providers/media_provider.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('shows empty state when no media loaded', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('No Media Loaded'), findsOneWidget);
      expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
    });

    testWidgets('shows media info when loaded', (tester) async {
      final testMedia = MediaFile(
        id: '1',
        path: '/test/video.mp4',
        name: 'video.mp4',
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
              return _TestMediaNotifier(MediaState(currentMedia: testMedia));
            }),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('video.mp4'), findsOneWidget);
      expect(find.text('5:00'), findsOneWidget);
    });

    testWidgets('shows loading indicator when importing', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaNotifierProvider.overrideWith(() {
              return _TestMediaNotifier(const MediaState(isLoading: true));
            }),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading media...'), findsOneWidget);
    });

    testWidgets('shows error message and dismiss button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaNotifierProvider.overrideWith(() {
              return _TestMediaNotifier(
                const MediaState(errorMessage: 'File not found'),
              );
            }),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      expect(find.text('File not found'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });
  });
}

// Test helper notifier
class _TestMediaNotifier extends MediaNotifier {
  final MediaState _initialState;

  _TestMediaNotifier(this._initialState);

  @override
  MediaState build() => _initialState;
}
```

### Testing User Interactions

```dart
// test/presentation/widgets/detection_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/widgets/detection/detection_list.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

void main() {
  group('DetectionList', () {
    final testDetections = [
      Detection(
        id: 'det_1',
        type: ContentType.profanity,
        startTime: const Duration(seconds: 10),
        endTime: const Duration(seconds: 12),
        confidence: 0.95,
        description: 'Profanity detected: "word"',
      ),
      Detection(
        id: 'det_2',
        type: ContentType.violence,
        startTime: const Duration(seconds: 30),
        endTime: const Duration(seconds: 35),
        confidence: 0.85,
        description: 'Violence detected',
      ),
    ];

    testWidgets('displays all detections', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DetectionList(detections: testDetections),
            ),
          ),
        ),
      );

      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('Profanity detected: "word"'), findsOneWidget);
      expect(find.text('Violence detected'), findsOneWidget);
    });

    testWidgets('tapping item calls onSelect', (tester) async {
      String? selectedId;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DetectionList(
                detections: testDetections,
                onSelect: (id) => selectedId = id,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Profanity detected: "word"'));
      await tester.pump();

      expect(selectedId, equals('det_1'));
    });

    testWidgets('shows confirmation dialog on confirm tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DetectionList(
                detections: testDetections,
                showActions: true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pumpAndSettle();

      expect(find.text('Confirm Detection'), findsOneWidget);
    });
  });
}
```

---

## Integration Testing

### Full Flow Test

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kidslens_video_editor/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('complete analysis flow', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KidsLensApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: App launches with welcome screen
      expect(find.text('Welcome to KidsLens'), findsOneWidget);

      // Step 2: Tap import button
      await tester.tap(find.text('New Project'));
      await tester.pumpAndSettle();

      // Step 3: Verify import screen
      expect(find.text('Select a file to import'), findsOneWidget);

      // ... continue with flow
    });

    testWidgets('settings persistence', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KidsLensApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Toggle dark mode
      await tester.tap(find.text('Dark Theme'));
      await tester.pumpAndSettle();

      // Verify theme changed
      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.themeMode, equals(ThemeMode.dark));
    });
  });
}
```

### Running Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test/app_test.dart

# Run with specific device
flutter test integration_test/app_test.dart -d windows

# Run with screenshots
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d windows
```

---

## Mocking Strategies

### Mock Services

```dart
// test/mocks/mock_services.dart
import 'package:kidslens_video_editor/services/media_service.dart';
import 'package:kidslens_video_editor/services/analysis_service.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

class MockMediaService implements MediaService {
  MediaFile? _mockResult;
  Exception? _mockError;

  void setMockResult(MediaFile file) => _mockResult = file;
  void setMockError(Exception error) => _mockError = error;

  @override
  Future<MediaFile> importMedia(String path) async {
    if (_mockError != null) throw _mockError!;
    return _mockResult!;
  }

  @override
  Future<String> extractAudio(String videoPath, String outputPath) async {
    return outputPath;
  }

  @override
  Stream<FrameData> extractFrames(
    String videoPath, {
    double fps = 2.0,
    int? startFrame,
    int? endFrame,
  }) async* {
    // Yield mock frames
  }

  @override
  Future<String> generateThumbnail(String videoPath, String outputPath) async {
    return outputPath;
  }

  @override
  Future<Duration> getDuration(String path) async {
    return _mockResult?.duration ?? Duration.zero;
  }
}

class MockAnalysisService implements AnalysisService {
  List<AnalysisProgress> _mockProgress = [];
  AnalysisResult? _mockResult;

  void setMockProgress(List<AnalysisProgress> progress) {
    _mockProgress = progress;
  }

  void setMockResult(AnalysisResult result) {
    _mockResult = result;
  }

  @override
  Stream<AnalysisProgress> analyze(
    String mediaPath,
    AnalysisSettings settings, {
    AnalysisCheckpoint? checkpoint,
  }) async* {
    for (final progress in _mockProgress) {
      yield progress;
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
}
```

### Using Mocks in Tests

```dart
// test/services/analysis_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../mocks/mock_services.dart';

void main() {
  group('AnalysisService integration', () {
    late MockMediaService mockMediaService;

    setUp(() {
      mockMediaService = MockMediaService();
    });

    test('should handle media service errors', () async {
      mockMediaService.setMockError(
        MediaFileNotFoundException('/invalid/path.mp4'),
      );

      expect(
        () => mockMediaService.importMedia('/invalid/path.mp4'),
        throwsA(isA<MediaFileNotFoundException>()),
      );
    });
  });
}
```

### Mocking Riverpod Providers

```dart
// test/state/providers/analysis_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/state/providers/analysis_provider.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import '../mocks/mock_services.dart';

void main() {
  group('AnalysisNotifier', () {
    late ProviderContainer container;
    late MockAnalysisService mockAnalysisService;

    setUp(() {
      mockAnalysisService = MockAnalysisService();
      container = ProviderContainer(
        overrides: [
          analysisServiceProvider.overrideWithValue(mockAnalysisService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should update progress during analysis', () async {
      mockAnalysisService.setMockProgress([
        const AnalysisProgress(
          stepName: 'Extracting audio',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0.5,
        ),
        const AnalysisProgress(
          stepName: 'Complete',
          currentStep: 4,
          totalSteps: 4,
          stepProgress: 1.0,
        ),
      ]);

      final notifier = container.read(analysisNotifierProvider.notifier);
      await notifier.startAnalysis(
        mediaPath: '/test.mp4',
        settings: AnalysisSettings.defaults(),
      );

      final state = container.read(analysisNotifierProvider);
      expect(state.status, equals(AnalysisStatus.completed));
    });
  });
}
```

---

## Coverage Requirements

### Minimum Coverage Thresholds

| Layer | Minimum | Target |
|-------|---------|--------|
| Core utilities | 90% | 95% |
| Data models | 85% | 95% |
| Services | 80% | 90% |
| State providers | 80% | 90% |
| UI widgets | 70% | 80% |
| Overall | 75% | 85% |

### Enforcing Coverage

```yaml
# .github/workflows/coverage.yml
- name: Check coverage
  run: |
    flutter test --coverage
    # Extract total coverage percentage
    COVERAGE=$(lcov --summary coverage/lcov.info | grep 'lines' | grep -oP '\d+\.\d+')
    if (( $(echo "$COVERAGE < 75" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 75% threshold"
      exit 1
    fi
```

### Excluding from Coverage

```dart
// coverage:ignore-file
// coverage:ignore-start
// coverage:ignore-end
// coverage:ignore-line
```

Use for:
- Generated code (`.g.dart`, `.freezed.dart`)
- Main entry point
- Platform-specific code without test support

---

## Testing Best Practices

### 1. Arrange-Act-Assert Pattern

```dart
test('should detect exact word matches', () {
  // Arrange
  final service = ProfanityService();
  service.addCustomWords(['badword']);
  final transcript = _createTranscript('This has badword in it');

  // Act
  final matches = service.detect(transcript);

  // Assert
  expect(matches, hasLength(1));
  expect(matches.first.matchedProfanity, equals('badword'));
});
```

### 2. Test One Thing at a Time

```dart
// ✅ Good - tests one behavior
test('should return empty list for clean transcript', () {
  final matches = service.detect(cleanTranscript);
  expect(matches, isEmpty);
});

// ❌ Bad - tests multiple behaviors
test('should detect profanity and exclude whitelisted words and normalize leetspeak', () {
  // Too many things!
});
```

### 3. Use Descriptive Test Names

```dart
// ✅ Good
test('should reject detection when user marks as false positive', () {...});

// ❌ Bad
test('test rejection', () {...});
```

### 4. Group Related Tests

```dart
group('Detection', () {
  group('creation', () {
    test('should calculate duration correctly', () {...});
    test('should set default user status to pending', () {...});
  });

  group('user actions', () {
    test('should mark as confirmed when user confirms', () {...});
    test('should mark as rejected when user rejects', () {...});
  });

  group('serialization', () {
    test('should serialize to JSON', () {...});
    test('should deserialize from JSON', () {...});
  });
});
```

### 5. Use Test Fixtures

```dart
// test/fixtures/test_data.dart
class TestFixtures {
  static MediaFile get sampleVideo => MediaFile(
    id: 'test_video_1',
    path: '/test/sample.mp4',
    name: 'sample.mp4',
    duration: const Duration(minutes: 5),
    width: 1920,
    height: 1080,
    fileSize: 100000000,
    mediaType: MediaType.video,
  );

  static Transcript get sampleTranscript => Transcript(
    segments: [
      TranscriptSegment(
        id: 'seg_1',
        startTime: Duration.zero,
        endTime: const Duration(seconds: 5),
        text: 'Hello world',
        words: [
          const TranscriptWord(
            word: 'Hello',
            startTime: Duration.zero,
            endTime: Duration(milliseconds: 500),
            confidence: 0.95,
          ),
          const TranscriptWord(
            word: 'world',
            startTime: Duration(milliseconds: 500),
            endTime: Duration(seconds: 1),
            confidence: 0.92,
          ),
        ],
      ),
    ],
    language: 'en',
  );
}
```

### 6. Clean Up After Tests

```dart
group('MediaService', () {
  late MediaService service;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('test_');
    service = MediaService(MockFFmpegBindings());
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // Tests...
});
```

### 7. Test Error Conditions

```dart
group('error handling', () {
  test('should throw when file not found', () {
    expect(
      () => service.importMedia('/nonexistent/file.mp4'),
      throwsA(isA<MediaFileNotFoundException>()),
    );
  });

  test('should throw with descriptive message', () {
    expect(
      () => service.importMedia('/bad/file.mp4'),
      throwsA(
        predicate<MediaFileNotFoundException>(
          (e) => e.path == '/bad/file.mp4' && e.message.contains('not found'),
        ),
      ),
    );
  });
});
```

### 8. Test Async Operations

```dart
test('should emit progress updates', () async {
  final progressUpdates = <AnalysisProgress>[];

  await for (final progress in service.analyze(path, settings)) {
    progressUpdates.add(progress);
  }

  expect(progressUpdates, isNotEmpty);
  expect(progressUpdates.last.stepProgress, equals(1.0));
});

test('should timeout long operations', () async {
  expect(
    () => service.analyze(path, settings).timeout(
      const Duration(seconds: 5),
    ).drain(),
    throwsA(isA<TimeoutException>()),
  );
});
```
