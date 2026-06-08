import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';
import 'package:kidslens_video_editor/presentation/widgets/editor/detection_panel.dart';

void main() {
  group('DetectionPanel explainability', () {
    testWidgets('renders policy category, rationale, source, and action',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 460,
              height: 720,
              child: DetectionPanel(
                detections: [_detection()],
                editActions: const <EditAction>[],
                onSeekToDetection: (_) {},
                onApplyAction: (_, __) {},
                onRejectDetection: (_) {},
                onAcceptDetection: (_) {},
                onToggleEditAction: (_) {},
                onRemoveEditAction: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Female Legs Exposure'), findsWidgets);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('91% confidence'), findsOneWidget);
      expect(find.text('Region-level'), findsOneWidget);
      expect(find.text('Pending review'), findsOneWidget);
      expect(find.text('Blur Region'), findsWidgets);
      expect(find.text('Rationale'), findsOneWidget);
      expect(
        find.text('Exposed legs were localized in the frame.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Sources', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('rawProviderJson'), findsNothing);
    });
  });
}

Detection _detection() => const Detection(
      id: 'det-policy',
      mediaId: 'media-1',
      type: ContentType.nsfw,
      startTime: Duration(seconds: 5),
      endTime: Duration(seconds: 8),
      confidence: 0.91,
      description: 'Policy detection',
      metadata: {
        'policyCategoryId': 'female_legs_exposure',
        'policySeverity': 'high',
        'rationale': 'Exposed legs were localized in the frame.',
        'sourceModels': ['qwen3.5-vl-local'],
        'groundingStatus': 'grounded',
        'regionIds': ['region_legs'],
        'action': 'blurRegion',
        'rawProviderJson': 'unsafe raw model dump',
        'boundingBoxes': [
          {'x': 0.25, 'y': 0.4, 'width': 0.3, 'height': 0.5},
        ],
      },
    );
