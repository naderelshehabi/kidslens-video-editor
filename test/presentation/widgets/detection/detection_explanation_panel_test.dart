import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/presentation/widgets/detection/detection_explanation_panel.dart';
import 'package:kidslens_video_editor/presentation/widgets/detection_region_overlay.dart';

void main() {
  group('DetectionExplanationPanel', () {
    testWidgets('renders sanitized policy metadata and rationale',
        (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: DetectionExplanationPanel(
            detection: _policyDetection(),
            showFramePreview: false,
          ),
        ),
      );

      expect(find.text('Female Legs Exposure'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('92% confidence'), findsOneWidget);
      expect(find.text('Region-level'), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('Blur Region'), findsOneWidget);
      expect(find.text('Rationale'), findsOneWidget);
      expect(
        find.text('Exposed legs were localized in the frame.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Sources', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Evidence', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Regions', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Frame', findRichText: true),
        findsOneWidget,
      );

      expect(find.textContaining('rawProviderJson'), findsNothing);
      expect(find.textContaining('unsafe raw model dump'), findsNothing);
    });

    testWidgets('shows supporting frame preview with bounding box overlay',
        (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: SizedBox(
            width: 360,
            child: DetectionExplanationPanel(
              detection: _policyDetection(),
            ),
          ),
        ),
      );

      expect(find.text('Frame frame_001'), findsOneWidget);
      expect(find.byType(DetectionRegionOverlay), findsOneWidget);
      expect(find.text('Female Legs Exposure 92%'), findsNothing);
    });

    testWidgets('renders scene-level state when boundary is unavailable',
        (tester) async {
      await tester.pumpWidget(
        _TestHost(
          child: DetectionExplanationPanel(
            detection: _sceneDetection(),
            compact: true,
            showFramePreview: false,
          ),
        ),
      );

      expect(find.text('Violence'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Scene-level'), findsOneWidget);
      expect(find.text('Cut Scene'), findsOneWidget);
      expect(find.text('A fight is visible across the scene.'), findsOneWidget);
    });
  });
}

class _TestHost extends StatelessWidget {
  const _TestHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 520,
              child: child,
            ),
          ),
        ),
      );
}

Detection _policyDetection() => const Detection(
      id: 'det-policy',
      mediaId: 'media-1',
      type: ContentType.nsfw,
      startTime: Duration(seconds: 5),
      endTime: Duration(seconds: 8),
      confidence: 0.92,
      description: 'Policy detection',
      metadata: {
        'policyCategoryId': 'female_legs_exposure',
        'policySeverity': 'high',
        'rationale': 'Exposed legs were localized in the frame.',
        'sourceModels': ['qwen3.5-vl-local', 'local-grounder'],
        'supportingEvidenceIds': ['ev_1', 'ev_2'],
        'groundingStatus': 'grounded',
        'regionIds': ['region_legs'],
        'action': 'blurRegion',
        'frameId': 'frame_001',
        'rawProviderJson': 'unsafe raw model dump',
        'boundingBoxes': [
          {'x': 0.25, 'y': 0.4, 'width': 0.3, 'height': 0.5},
        ],
      },
    );

Detection _sceneDetection() => const Detection(
      id: 'det-scene',
      mediaId: 'media-1',
      type: ContentType.nsfw,
      startTime: Duration(seconds: 12),
      endTime: Duration(seconds: 15),
      confidence: 0.84,
      description: 'Scene-level violence',
      metadata: {
        'policyCategoryId': 'violence',
        'policySeverity': 'medium',
        'rationale': 'A fight is visible across the scene.',
        'groundingStatus': 'scene_level_only',
        'action': 'cutScene',
      },
    );
