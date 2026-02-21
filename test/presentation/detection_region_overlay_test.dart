import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/widgets/detection_region_overlay.dart';

void main() {
  group('DetectionRegionOverlay', () {
    Widget createWidget({
      List<DetectionRegion> regions = const [],
      bool showLabels = false,
      bool showConfidence = false,
      Widget? child,
    }) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: DetectionRegionOverlay(
              regions: regions,
              showLabels: showLabels,
              showConfidence: showConfidence,
              child: child,
            ),
          ),
        ),
      );

    /// Helper to find widgets that are descendants of DetectionRegionOverlay.
    Finder descendantOfOverlay(Finder matching) => find.descendant(
        of: find.byType(DetectionRegionOverlay),
        matching: matching,
      );

    group('rendering with 0 regions', () {
      testWidgets('renders without error', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(find.byType(DetectionRegionOverlay), findsOneWidget);
      });

      testWidgets('no count badge is shown', (tester) async {
        await tester.pumpWidget(createWidget());

        // The count badge would contain a Text with a number.
        // With 0 regions, no count badge text should appear.
        expect(descendantOfOverlay(find.text('0')), findsNothing);
      });

      testWidgets('CustomPaint is present', (tester) async {
        await tester.pumpWidget(createWidget());

        expect(
          descendantOfOverlay(find.byType(CustomPaint)),
          findsOneWidget,
        );
      });
    });

    group('rendering with 1 region', () {
      final singleRegion = [
        const DetectionRegion(
          x: 0.1,
          y: 0.2,
          width: 0.3,
          height: 0.4,
          label: 'person',
          confidence: 0.95,
        ),
      ];

      testWidgets('renders without error', (tester) async {
        await tester.pumpWidget(createWidget(regions: singleRegion));

        expect(find.byType(DetectionRegionOverlay), findsOneWidget);
      });

      testWidgets('no count badge shown for single region', (tester) async {
        await tester.pumpWidget(createWidget(regions: singleRegion));

        // Count badge only appears when regions.length > 1
        expect(descendantOfOverlay(find.text('1')), findsNothing);
      });

      testWidgets('CustomPaint is present', (tester) async {
        await tester.pumpWidget(createWidget(regions: singleRegion));

        expect(
          descendantOfOverlay(find.byType(CustomPaint)),
          findsOneWidget,
        );
      });
    });

    group('rendering with multiple regions', () {
      final multipleRegions = [
        const DetectionRegion(
          x: 0.1,
          y: 0.1,
          width: 0.2,
          height: 0.2,
          label: 'person',
        ),
        const DetectionRegion(
          x: 0.5,
          y: 0.5,
          width: 0.3,
          height: 0.3,
          label: 'cat',
        ),
        const DetectionRegion(
          x: 0.7,
          y: 0.1,
          width: 0.2,
          height: 0.15,
          label: 'dog',
        ),
      ];

      testWidgets('renders without error', (tester) async {
        await tester.pumpWidget(createWidget(regions: multipleRegions));

        expect(find.byType(DetectionRegionOverlay), findsOneWidget);
      });

      testWidgets('count badge is shown with correct count text',
          (tester) async {
        await tester.pumpWidget(createWidget(regions: multipleRegions));

        expect(
          descendantOfOverlay(find.text('${multipleRegions.length}')),
          findsOneWidget,
        );
      });

      testWidgets('count badge text matches regions.length', (tester) async {
        final twoRegions = [
          const DetectionRegion(x: 0.0, y: 0.0, width: 0.5, height: 0.5),
          const DetectionRegion(x: 0.5, y: 0.5, width: 0.5, height: 0.5),
        ];

        await tester.pumpWidget(createWidget(regions: twoRegions));

        expect(descendantOfOverlay(find.text('2')), findsOneWidget);
      });

      testWidgets('count badge is inside a styled container', (tester) async {
        await tester.pumpWidget(createWidget(regions: multipleRegions));

        // Find the Text widget showing the count
        final textFinder = descendantOfOverlay(
          find.text('${multipleRegions.length}'),
        );
        expect(textFinder, findsOneWidget);

        // The text should be inside a Container with decoration
        final container = tester.widget<Container>(
          find.ancestor(
            of: textFinder,
            matching: find.byType(Container),
          ).first,
        );
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, equals(Colors.black87));
        expect(decoration.borderRadius, equals(BorderRadius.circular(4)));
      });

      testWidgets('count badge text is white, bold, and small',
          (tester) async {
        await tester.pumpWidget(createWidget(regions: multipleRegions));

        final text = tester.widget<Text>(
          descendantOfOverlay(find.text('${multipleRegions.length}')),
        );
        expect(text.style?.color, equals(Colors.white));
        expect(text.style?.fontSize, equals(9));
        expect(text.style?.fontWeight, equals(FontWeight.bold));
      });
    });

    group('showLabels mode', () {
      final multipleRegions = [
        const DetectionRegion(
          x: 0.1,
          y: 0.1,
          width: 0.2,
          height: 0.2,
          label: 'person',
        ),
        const DetectionRegion(
          x: 0.5,
          y: 0.5,
          width: 0.3,
          height: 0.3,
          label: 'cat',
        ),
      ];

      testWidgets('no count badge even with multiple regions', (tester) async {
        await tester.pumpWidget(createWidget(
          regions: multipleRegions,
          showLabels: true,
        ));

        // Count badge is only shown when !showLabels
        expect(
          descendantOfOverlay(find.text('${multipleRegions.length}')),
          findsNothing,
        );
      });

      testWidgets('CustomPaint is still present', (tester) async {
        await tester.pumpWidget(createWidget(
          regions: multipleRegions,
          showLabels: true,
        ));

        expect(
          descendantOfOverlay(find.byType(CustomPaint)),
          findsOneWidget,
        );
      });

      testWidgets('renders without error in showLabels mode', (tester) async {
        await tester.pumpWidget(createWidget(
          regions: multipleRegions,
          showLabels: true,
          showConfidence: true,
        ));

        expect(find.byType(DetectionRegionOverlay), findsOneWidget);
      });
    });

    group('with child widget', () {
      testWidgets('child is rendered in the stack', (tester) async {
        await tester.pumpWidget(createWidget(
          child: const Placeholder(key: Key('test-child')),
        ));

        expect(find.byKey(const Key('test-child')), findsOneWidget);
        expect(
          descendantOfOverlay(find.byType(Placeholder)),
          findsOneWidget,
        );
      });

      testWidgets('overlay CustomPaint is on top of child', (tester) async {
        await tester.pumpWidget(createWidget(
          regions: [
            const DetectionRegion(
              x: 0.1,
              y: 0.1,
              width: 0.5,
              height: 0.5,
            ),
          ],
          child: const Placeholder(key: Key('test-child')),
        ));

        // Both child and CustomPaint should be present
        expect(
          descendantOfOverlay(find.byType(Placeholder)),
          findsOneWidget,
        );
        // Note: Placeholder itself contains a CustomPaint internally,
        // so we expect at least one CustomPaint from the overlay painter.
        expect(
          descendantOfOverlay(find.byType(CustomPaint)),
          findsWidgets,
        );

        // Find the Stack that is the direct child of DetectionRegionOverlay
        final stack = tester.widget<Stack>(
          descendantOfOverlay(find.byType(Stack)),
        );
        final children = stack.children;

        // The child (Placeholder) should come before the Positioned.fill
        // containing CustomPaint in the Stack's children list
        int childIndex = -1;
        int paintIndex = -1;
        for (var i = 0; i < children.length; i++) {
          if (children[i] is Placeholder) {
            childIndex = i;
          }
          if (children[i] is Positioned) {
            final positioned = children[i] as Positioned;
            if (positioned.child is CustomPaint) {
              paintIndex = i;
            }
          }
        }

        expect(childIndex, greaterThanOrEqualTo(0),
            reason: 'Child should be in Stack');
        expect(paintIndex, greaterThan(childIndex),
            reason: 'CustomPaint overlay should be after child in Stack');
      });

      testWidgets('renders without child when child is null', (tester) async {
        await tester.pumpWidget(createWidget(child: null));

        expect(find.byType(DetectionRegionOverlay), findsOneWidget);
        // Stack and CustomPaint still exist within the overlay
        expect(
          descendantOfOverlay(find.byType(Stack)),
          findsOneWidget,
        );
        expect(
          descendantOfOverlay(find.byType(CustomPaint)),
          findsOneWidget,
        );
      });
    });

    group('DetectionRegion model', () {
      test('construction with all fields', () {
        const region = DetectionRegion(
          x: 0.1,
          y: 0.2,
          width: 0.3,
          height: 0.4,
          categoryId: 'violence',
          label: 'fight scene',
          confidence: 0.87,
        );

        expect(region.x, equals(0.1));
        expect(region.y, equals(0.2));
        expect(region.width, equals(0.3));
        expect(region.height, equals(0.4));
        expect(region.categoryId, equals('violence'));
        expect(region.label, equals('fight scene'));
        expect(region.confidence, equals(0.87));
      });

      test('construction with optional fields null', () {
        const region = DetectionRegion(
          x: 0.0,
          y: 0.0,
          width: 1.0,
          height: 1.0,
        );

        expect(region.x, equals(0.0));
        expect(region.y, equals(0.0));
        expect(region.width, equals(1.0));
        expect(region.height, equals(1.0));
        expect(region.categoryId, isNull);
        expect(region.label, isNull);
        expect(region.confidence, isNull);
      });

      test('coordinates are stored correctly', () {
        const region = DetectionRegion(
          x: 0.5,
          y: 0.75,
          width: 0.25,
          height: 0.125,
        );

        expect(region.x, closeTo(0.5, 1e-10));
        expect(region.y, closeTo(0.75, 1e-10));
        expect(region.width, closeTo(0.25, 1e-10));
        expect(region.height, closeTo(0.125, 1e-10));
      });
    });

    group('edge cases', () {
      testWidgets('handles large number of regions', (tester) async {
        final manyRegions = List.generate(
          50,
          (i) => DetectionRegion(
            x: (i % 10) * 0.1,
            y: (i ~/ 10) * 0.2,
            width: 0.08,
            height: 0.15,
            label: 'region $i',
          ),
        );

        await tester.pumpWidget(createWidget(regions: manyRegions));

        expect(find.byType(DetectionRegionOverlay), findsOneWidget);
        expect(descendantOfOverlay(find.text('50')), findsOneWidget);
      });

      testWidgets('handles regions with zero dimensions', (tester) async {
        final zeroRegions = [
          const DetectionRegion(x: 0.5, y: 0.5, width: 0.0, height: 0.0),
          const DetectionRegion(x: 0.0, y: 0.0, width: 0.0, height: 0.0),
        ];

        await tester.pumpWidget(createWidget(regions: zeroRegions));

        expect(find.byType(DetectionRegionOverlay), findsOneWidget);
        expect(descendantOfOverlay(find.text('2')), findsOneWidget);
      });

      testWidgets('handles regions at boundary coordinates', (tester) async {
        final boundaryRegions = [
          const DetectionRegion(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
          const DetectionRegion(x: 1.0, y: 1.0, width: 0.0, height: 0.0),
        ];

        await tester.pumpWidget(createWidget(regions: boundaryRegions));

        expect(find.byType(DetectionRegionOverlay), findsOneWidget);
      });
    });
  });
}
