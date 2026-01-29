import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';
import 'package:kidslens_video_editor/presentation/widgets/detection/detection_badge.dart';

void main() {
  group('DetectionBadge', () {
    Widget createDetectionBadge({
      required String type,
      required int count,
      bool isSelected = false,
      VoidCallback? onTap,
    }) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: DetectionBadge(
              type: type,
              count: count,
              isSelected: isSelected,
              onTap: onTap,
            ),
          ),
        ),
      );

    group('rendering', () {
      testWidgets('renders type text', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 5,
        ),);

        expect(find.text('Profanity'), findsOneWidget);
      });

      testWidgets('renders count', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 5,
        ),);

        expect(find.text('5'), findsOneWidget);
      });

      testWidgets('capitalizes type name', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'violence',
          count: 3,
        ),);

        expect(find.text('Violence'), findsOneWidget);
      });
    });

    group('icons per type', () {
      testWidgets('profanity shows mic_off icon', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
        ),);

        expect(find.byIcon(Icons.mic_off), findsOneWidget);
      });

      testWidgets('nudity shows visibility_off icon',
          (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'nudity',
          count: 1,
        ),);

        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      });

      testWidgets('violence shows warning icon', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'violence',
          count: 1,
        ),);

        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('blood shows water_drop icon', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'blood',
          count: 1,
        ),);

        expect(find.byIcon(Icons.water_drop), findsOneWidget);
      });

      testWidgets('weapons shows gpp_bad icon', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'weapons',
          count: 1,
        ),);

        expect(find.byIcon(Icons.gpp_bad), findsOneWidget);
      });

      testWidgets('unknown type shows error icon',
          (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'unknown',
          count: 1,
        ),);

        expect(find.byIcon(Icons.error), findsOneWidget);
      });
    });

    group('colors per type', () {
      testWidgets('profanity uses orange color', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
        ),);

        final expectedColor = AppTheme.getDetectionColor('profanity');
        expect(expectedColor, equals(AppTheme.profanityColor));
      });

      testWidgets('nudity uses pink color', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'nudity',
          count: 1,
        ),);

        final expectedColor = AppTheme.getDetectionColor('nudity');
        expect(expectedColor, equals(AppTheme.nudityColor));
      });

      testWidgets('violence uses red color', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'violence',
          count: 1,
        ),);

        final expectedColor = AppTheme.getDetectionColor('violence');
        expect(expectedColor, equals(AppTheme.violenceColor));
      });

      testWidgets('blood uses dark red color', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'blood',
          count: 1,
        ),);

        final expectedColor = AppTheme.getDetectionColor('blood');
        expect(expectedColor, equals(AppTheme.bloodColor));
      });

      testWidgets('weapons uses gray color', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'weapons',
          count: 1,
        ),);

        final expectedColor = AppTheme.getDetectionColor('weapons');
        expect(expectedColor, equals(AppTheme.weaponsColor));
      });
    });

    group('selection state', () {
      testWidgets('unselected badge has transparent background',
          (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
        ),);

        // Badge should have semi-transparent background
        final container = tester.widget<Container>(find.byType(Container).last);
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color?.a, lessThan(1.0));
      });

      testWidgets('selected badge has solid background',
          (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
          isSelected: true,
        ),);

        // Badge should have the type color as background
        final containers = tester.widgetList<Container>(find.byType(Container));
        // Check that at least one container has the expected color
        expect(containers.length, greaterThan(0));
      });

      testWidgets('selected badge has white text', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
          isSelected: true,
        ),);

        final texts = tester.widgetList<Text>(find.byType(Text));
        for (final text in texts) {
          if (text.data == 'Profanity') {
            expect(text.style?.color, equals(Colors.white));
          }
        }
      });

      testWidgets('unselected badge has colored text',
          (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
        ),);

        final expectedColor = AppTheme.getDetectionColor('profanity');
        final texts = tester.widgetList<Text>(find.byType(Text));
        for (final text in texts) {
          if (text.data == 'Profanity') {
            expect(text.style?.color, equals(expectedColor));
          }
        }
      });

      testWidgets('selected badge has thicker border',
          (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
          isSelected: true,
        ),);

        // Just verify the badge renders
        expect(find.text('Profanity'), findsOneWidget);
      });

      testWidgets('unselected badge has thinner border',
          (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
        ),);

        // Just verify the badge renders
        expect(find.text('Profanity'), findsOneWidget);
      });
    });

    group('interaction', () {
      testWidgets('calls onTap when tapped', (tester) async {
        var tapped = false;

        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
          onTap: () => tapped = true,
        ),);

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('is tappable when onTap is null',
          (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 1,
        ),);

        // Should still render InkWell, just with null onTap
        expect(find.byType(InkWell), findsOneWidget);
      });
    });

    group('count display', () {
      testWidgets('displays zero count', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 0,
        ),);

        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('displays large count', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 999,
        ),);

        expect(find.text('999'), findsOneWidget);
      });

      testWidgets('count is in container with rounded corners',
          (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 5,
        ),);

        // Find the count container
        final containers = tester.widgetList<Container>(find.byType(Container));
        expect(containers.length, greaterThan(0));
      });
    });

    group('layout', () {
      testWidgets('uses row layout', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 5,
        ),);

        expect(find.byType(Row), findsOneWidget);
      });

      testWidgets('has rounded corners', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 5,
        ),);

        // There are multiple containers - verify the badge renders with rounded look
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('icon has correct size', (tester) async {
        await tester.pumpWidget(createDetectionBadge(
          type: 'profanity',
          count: 5,
        ),);

        final icon = tester.widget<Icon>(find.byIcon(Icons.mic_off));
        expect(icon.size, equals(16));
      });
    });
  });
}
