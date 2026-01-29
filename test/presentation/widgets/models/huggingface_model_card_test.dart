import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/huggingface_model_card.dart';

void main() {
  group('HuggingFaceModelCard', () {
    HuggingFaceModel createTestModel({
      String id = 'test-model',
      String displayName = 'Test Model',
      String huggingFaceId = 'test/repo',
      String fileName = 'model.bin',
      String parameters = '39M',
      int parameterCount = 39000000,
      int sizeBytes = 78000000,
      int ramRequired = 256000000,
      double speedMultiplier = 10.0,
      int accuracyPercent = 95,
      HuggingFaceModelType modelType = HuggingFaceModelType.asr,
      List<String> languages = const ['en'],
      String? badge,
      String? description,
      bool requiresGpu = false,
      int minVramBytes = 0,
    }) =>
        HuggingFaceModel(
          id: id,
          displayName: displayName,
          huggingFaceId: huggingFaceId,
          fileName: fileName,
          parameters: parameters,
          parameterCount: parameterCount,
          sizeBytes: sizeBytes,
          ramRequired: ramRequired,
          speedMultiplier: speedMultiplier,
          accuracyPercent: accuracyPercent,
          modelType: modelType,
          languages: languages,
          badge: badge,
          description: description,
          requiresGpu: requiresGpu,
          minVramBytes: minVramBytes,
        );

    Widget createModelCard({
      required HuggingFaceModel model,
      bool isDownloaded = false,
      bool isSelected = false,
      bool isDownloading = false,
      double? downloadProgress,
      String? hardwareWarning,
      VoidCallback? onDownload,
      VoidCallback? onDelete,
      VoidCallback? onSelect,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: HuggingFaceModelCard(
                model: model,
                isDownloaded: isDownloaded,
                isSelected: isSelected,
                isDownloading: isDownloading,
                downloadProgress: downloadProgress,
                hardwareWarning: hardwareWarning,
                onDownload: onDownload,
                onDelete: onDelete,
                onSelect: onSelect,
              ),
            ),
          ),
        );

    group('basic rendering', () {
      testWidgets('renders model display name', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(displayName: 'Whisper Tiny'),
        ),);

        expect(find.text('Whisper Tiny'), findsOneWidget);
      });

      testWidgets('renders card widget', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
        ),);

        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('renders description when provided', (tester) async {
        await tester.pumpWidget(createModelCard(
          model:
              createTestModel(description: 'A fast and lightweight ASR model'),
        ),);

        expect(find.text('A fast and lightweight ASR model'), findsOneWidget);
      });

      testWidgets('does not show description when null', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
        ),);

        // Should not find description text (only model name)
        expect(find.text('Test Model'), findsOneWidget);
      });
    });

    group('parameter count', () {
      testWidgets('renders parameter count', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
        ),);

        expect(find.text('39M'), findsOneWidget);
      });

      testWidgets('shows memory icon for parameters', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
        ),);

        expect(find.byIcon(Icons.memory), findsOneWidget);
      });

      testWidgets('renders large parameter count correctly', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(parameters: '1.55B'),
        ),);

        expect(find.text('1.55B'), findsOneWidget);
      });
    });

    group('size formatting', () {
      testWidgets('renders size in MB', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(), // ~74 MB
        ),);

        expect(find.byIcon(Icons.storage), findsOneWidget);
        expect(find.text('74 MB'), findsOneWidget);
      });

      testWidgets('renders size in GB for large models', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(sizeBytes: 3200000000), // ~2.98 GB
        ),);

        expect(find.text('2.98 GB'), findsOneWidget);
      });

      testWidgets('shows storage icon', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
        ),);

        expect(find.byIcon(Icons.storage), findsOneWidget);
      });
    });

    group('RAM requirement', () {
      testWidgets('renders RAM requirement', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(), // 244 MB
        ),);

        expect(find.byIcon(Icons.sd_card), findsOneWidget);
        expect(find.text('244 MB'), findsOneWidget);
      });

      testWidgets('renders RAM in GB for large requirements', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(ramRequired: 6000000000), // ~5.6 GB
        ),);

        expect(find.text('5.6 GB'), findsOneWidget);
      });
    });

    group('badge', () {
      testWidgets('renders badge when present', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(badge: 'Recommended'),
        ),);

        expect(find.text('RECOMMENDED'), findsOneWidget);
      });

      testWidgets('does not render badge when null', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
        ),);

        expect(find.text('RECOMMENDED'), findsNothing);
        expect(find.text('BEST'), findsNothing);
      });

      testWidgets('renders Best Accuracy badge', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(badge: 'Best Accuracy'),
        ),);

        expect(find.text('BEST ACCURACY'), findsOneWidget);
      });

      testWidgets('renders Best Value badge', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(badge: 'Best Value'),
        ),);

        expect(find.text('BEST VALUE'), findsOneWidget);
      });
    });

    group('speed indicator', () {
      testWidgets('shows Very Fast for high speed multiplier', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(speedMultiplier: 12),
        ),);

        expect(find.text('Very Fast'), findsOneWidget);
        expect(find.byIcon(Icons.speed), findsOneWidget);
      });

      testWidgets('shows Fast for good speed multiplier', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(speedMultiplier: 8),
        ),);

        expect(find.text('Fast'), findsOneWidget);
      });

      testWidgets('shows Moderate for medium speed multiplier',
          (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(speedMultiplier: 5),
        ),);

        expect(find.text('Moderate'), findsOneWidget);
      });

      testWidgets('shows Slow for low speed multiplier', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(speedMultiplier: 2.5),
        ),);

        expect(find.text('Slow'), findsOneWidget);
      });
    });

    group('accuracy indicator', () {
      testWidgets('shows accuracy percentage', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
        ),);

        expect(find.text('95%'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });

      testWidgets('shows high accuracy value', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(accuracyPercent: 99),
        ),);

        expect(find.text('99%'), findsOneWidget);
      });
    });

    group('download state - not downloaded', () {
      testWidgets('shows download button when not downloaded', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          onDownload: () {},
        ),);

        expect(find.byIcon(Icons.download), findsOneWidget);
      });

      testWidgets('calls onDownload when download button pressed',
          (tester) async {
        var downloadCalled = false;

        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          onDownload: () => downloadCalled = true,
        ),);

        await tester.tap(find.byIcon(Icons.download));
        await tester.pump();

        expect(downloadCalled, isTrue);
      });

      testWidgets('card is not tappable when not downloaded', (tester) async {
        var selectCalled = false;

        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          onSelect: () => selectCalled = true,
        ),);

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        expect(selectCalled, isFalse);
      });
    });

    group('download state - downloaded', () {
      testWidgets('does not show download button when downloaded',
          (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
          onSelect: () {},
          onDelete: () {},
        ),);

        // The download icon should not be in the download button
        // (might appear in other contexts, so we check for ModelDownloadButton)
        expect(find.widgetWithIcon(FilledButton, Icons.download), findsNothing);
      });

      testWidgets('shows delete button when downloaded', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
          onSelect: () {},
          onDelete: () {},
        ),);

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('calls onDelete when delete button pressed', (tester) async {
        var deleteCalled = false;

        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
          onSelect: () {},
          onDelete: () => deleteCalled = true,
        ),);

        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pump();

        expect(deleteCalled, isTrue);
      });

      testWidgets('shows Use button when downloaded but not selected',
          (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
          onSelect: () {},
          onDelete: () {},
        ),);

        expect(find.text('Use'), findsOneWidget);
      });

      testWidgets('card is tappable when downloaded', (tester) async {
        var selectCalled = false;

        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
          onSelect: () => selectCalled = true,
        ),);

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        expect(selectCalled, isTrue);
      });
    });

    group('selected state', () {
      testWidgets('shows ACTIVE tag when selected', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
          isSelected: true,
        ),);

        expect(find.text('ACTIVE'), findsOneWidget);
      });

      testWidgets('hides ACTIVE tag when not selected', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
        ),);

        expect(find.text('ACTIVE'), findsNothing);
      });

      testWidgets('card has border when selected', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
          isSelected: true,
        ),);

        final card = tester.widget<Card>(find.byType(Card));
        final shape = card.shape! as RoundedRectangleBorder;
        expect(shape.side, isNot(BorderSide.none));
      });

      testWidgets('shows Active button when selected', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
          isSelected: true,
          onSelect: () {},
        ),);

        expect(find.text('Active'), findsOneWidget);
      });
    });

    group('downloading state', () {
      testWidgets('shows progress indicator when downloading', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloading: true,
          downloadProgress: 0.5,
        ),);

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('shows download percentage text', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloading: true,
          downloadProgress: 0.75,
        ),);

        expect(find.textContaining('75.0%'), findsOneWidget);
      });

      testWidgets('shows downloading text', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloading: true,
          downloadProgress: 0.5,
        ),);

        expect(find.textContaining('Downloading'), findsOneWidget);
      });

      testWidgets('shows indeterminate progress text when progress is null',
          (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloading: true,
        ),);

        expect(find.text('Downloading...'), findsOneWidget);
      });

      testWidgets('hides action buttons when downloading', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloading: true,
          downloadProgress: 0.5,
          onDownload: () {},
        ),);

        // Download button should not be visible during download
        expect(find.text('Use'), findsNothing);
      });
    });

    group('hardware warning', () {
      testWidgets('shows warning when hardware warning is provided',
          (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          hardwareWarning: 'Requires 8GB RAM',
        ),);

        expect(find.text('Requires 8GB RAM'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      });

      testWidgets('does not show warning when null', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
        ),);

        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });
    });

    group('card elevation and styling', () {
      testWidgets('has higher elevation when selected', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
          isSelected: true,
        ),);

        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, equals(4));
      });

      testWidgets('has lower elevation when not selected', (tester) async {
        await tester.pumpWidget(createModelCard(
          model: createTestModel(),
          isDownloaded: true,
        ),);

        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, equals(1));
      });
    });
  });
}
