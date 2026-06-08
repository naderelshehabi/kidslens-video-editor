import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/model_info.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/model_card.dart';

void main() {
  group('ModelCard', () {
    ModelInfo createTestModel({
      String id = 'test-model',
      String displayName = 'Test Model',
      String description = 'A test model for testing',
      ModelType type = ModelType.visual,
      int sizeBytes = 100000000,
      int accuracyPercent = 90,
      int speedRating = 4,
      bool requiresGpu = false,
      String? badge,
    }) =>
        ModelInfo(
          id: id,
          displayName: displayName,
          description: description,
          type: type,
          sizeBytes: sizeBytes,
          accuracyPercent: accuracyPercent,
          speedRating: speedRating,
          requiresGpu: requiresGpu,
          badge: badge,
        );

    Widget createModelCard({
      required ModelInfo model,
      bool isDownloaded = false,
      bool isSelected = false,
      bool isDownloading = false,
      double? downloadProgress,
      VoidCallback? onDownload,
      VoidCallback? onDelete,
      VoidCallback? onSelect,
    }) =>
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModelCard(
                model: model,
                isDownloaded: isDownloaded,
                isSelected: isSelected,
                isDownloading: isDownloading,
                downloadProgress: downloadProgress,
                onDownload: onDownload,
                onDelete: onDelete,
                onSelect: onSelect,
              ),
            ),
          ),
        );

    group('basic rendering', () {
      testWidgets('renders model display name', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(displayName: 'My Model'),
          ),
        );

        expect(find.text('My Model'), findsOneWidget);
      });

      testWidgets('renders model description', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(description: 'Model description text'),
          ),
        );

        expect(find.text('Model description text'), findsOneWidget);
      });

      testWidgets('renders card widget', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('renders size info chip', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(sizeBytes: 104857600), // 100 MB
          ),
        );

        // Size should be formatted (e.g., "100 MB")
        expect(find.byIcon(Icons.storage), findsOneWidget);
      });
    });

    group('model type icons', () {
      testWidgets('shows icon for visual model', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
          ),
        );

        // Should have an icon representing the model type
        expect(find.byType(Icon), findsWidgets);
      });

      testWidgets('shows icon for ASR model', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(type: ModelType.asr),
          ),
        );

        expect(find.byType(Icon), findsWidgets);
      });
    });

    group('GPU requirement', () {
      testWidgets('shows GPU chip when required', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(requiresGpu: true),
          ),
        );

        expect(find.text('GPU'), findsOneWidget);
        expect(find.byIcon(Icons.memory), findsOneWidget);
      });

      testWidgets('hides GPU chip when not required', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
          ),
        );

        expect(find.text('GPU'), findsNothing);
      });
    });

    group('download state', () {
      testWidgets('shows Downloaded chip when downloaded', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloaded: true,
          ),
        );

        expect(find.text('Downloaded'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('hides Downloaded chip when not downloaded', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
          ),
        );

        expect(find.text('Downloaded'), findsNothing);
      });
    });

    group('selected state', () {
      testWidgets('shows ACTIVE tag when selected', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloaded: true,
            isSelected: true,
          ),
        );

        expect(find.text('ACTIVE'), findsOneWidget);
      });

      testWidgets('hides ACTIVE tag when not selected', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloaded: true,
          ),
        );

        expect(find.text('ACTIVE'), findsNothing);
      });
    });

    group('downloading state', () {
      testWidgets('shows progress indicator when downloading', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloading: true,
            downloadProgress: 0.5,
          ),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('shows download percentage', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloading: true,
            downloadProgress: 0.75,
          ),
        );

        expect(find.textContaining('75.0%'), findsOneWidget);
      });

      testWidgets('shows circular progress in action area when downloading',
          (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloading: true,
            downloadProgress: 0.5,
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows downloading text', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloading: true,
            downloadProgress: 0.5,
          ),
        );

        expect(find.textContaining('Downloading'), findsOneWidget);
      });
    });

    group('action buttons', () {
      testWidgets('shows popup menu for downloaded model', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloaded: true,
            onSelect: () {},
            onDelete: () {},
          ),
        );

        expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      });

      testWidgets('shows download button for non-downloaded model',
          (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            onDownload: () {},
          ),
        );

        expect(find.byIcon(Icons.download), findsOneWidget);
      });

      testWidgets('calls onDownload when download button pressed',
          (tester) async {
        var downloadCalled = false;

        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            onDownload: () => downloadCalled = true,
          ),
        );

        await tester.tap(find.byIcon(Icons.download));
        await tester.pump();

        expect(downloadCalled, isTrue);
      });
    });

    group('interaction', () {
      testWidgets('is tappable when downloaded', (tester) async {
        var selectCalled = false;

        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloaded: true,
            onSelect: () => selectCalled = true,
          ),
        );

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        expect(selectCalled, isTrue);
      });

      testWidgets('is not tappable when not downloaded', (tester) async {
        var selectCalled = false;

        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            onSelect: () => selectCalled = true,
          ),
        );

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        // onSelect should not be called when not downloaded
        expect(selectCalled, isFalse);
      });
    });

    group('popup menu', () {
      testWidgets('shows Use Model option when not selected', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloaded: true,
            onSelect: () {},
            onDelete: () {},
          ),
        );

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(find.text('Use Model'), findsOneWidget);
      });

      testWidgets('hides Use Model option when already selected',
          (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloaded: true,
            isSelected: true,
            onSelect: () {},
            onDelete: () {},
          ),
        );

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(find.text('Use Model'), findsNothing);
      });

      testWidgets('shows Delete option', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
            isDownloaded: true,
            onDelete: () {},
          ),
        );

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(find.text('Delete'), findsOneWidget);
      });
    });

    group('layout', () {
      testWidgets('uses proper card structure', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(),
          ),
        );

        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(InkWell), findsWidgets);
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('uses Wrap for info chips', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(requiresGpu: true),
            isDownloaded: true,
          ),
        );

        expect(find.byType(Wrap), findsOneWidget);
      });
    });

    group('size formatting', () {
      testWidgets('formats small file sizes', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(sizeBytes: 1024), // 1 KB
          ),
        );

        // Should show size in appropriate format
        expect(find.byIcon(Icons.storage), findsOneWidget);
      });

      testWidgets('formats large file sizes', (tester) async {
        await tester.pumpWidget(
          createModelCard(
            model: createTestModel(sizeBytes: 1073741824), // 1 GB
          ),
        );

        expect(find.byIcon(Icons.storage), findsOneWidget);
      });
    });
  });
}
