import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/screens/about_screen.dart';

void main() {
  group('AboutScreen', () {
    Widget createAboutScreen() => const MaterialApp(
          home: AboutScreen(),
        );

    group('app header', () {
      testWidgets('renders app name', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('KidsLens Video Editor'), findsOneWidget);
      });

      testWidgets('renders version', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Version 1.0.0'), findsOneWidget);
      });

      testWidgets('renders app description', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(
          find.text(
            'AI-powered video content moderation for family-friendly content',
          ),
          findsOneWidget,
        );
      });

      testWidgets('renders app icon', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.byIcon(Icons.movie_filter_rounded), findsWidgets);
      });
    });

    group('legal disclaimer section', () {
      testWidgets('renders Important Notice title', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Important Notice'), findsOneWidget);
      });

      testWidgets('renders warning icon', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('renders content detection limitations text',
          (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Content Detection Limitations'), findsOneWidget);
      });

      testWidgets('renders disclaimer about manual review', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(
          find.textContaining('Always manually review AI detections'),
          findsOneWidget,
        );
      });
    });

    group('model attributions section', () {
      testWidgets('renders AI Model Attributions title', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('AI Model Attributions'), findsOneWidget);
      });

      testWidgets('renders smart toy icon', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);
      });

      testWidgets('renders Whisper attribution', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Whisper'), findsOneWidget);
        expect(find.text('by OpenAI'), findsOneWidget);
      });

      testWidgets('renders ONNX Runtime attribution', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('ONNX Runtime'), findsOneWidget);
        expect(find.text('by Microsoft'), findsOneWidget);
      });

      testWidgets('renders FFmpeg attribution', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('FFmpeg'), findsOneWidget);
        expect(find.text('by FFmpeg Team'), findsOneWidget);
      });

      testWidgets('renders license types for attributions', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('MIT License'), findsNWidgets(2));
        expect(find.text('LGPL v2.1+'), findsOneWidget);
      });
    });

    group('privacy statement section', () {
      testWidgets('renders Privacy title', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Privacy'), findsOneWidget);
      });

      testWidgets('renders privacy tip icon', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.byIcon(Icons.privacy_tip_rounded), findsOneWidget);
      });

      testWidgets('renders 100% Local Processing feature', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('100% Local Processing'), findsOneWidget);
      });

      testWidgets('renders No Cloud Upload feature', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('No Cloud Upload'), findsOneWidget);
      });

      testWidgets('renders No Tracking feature', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('No Tracking'), findsOneWidget);
      });

      testWidgets('renders privacy priority message', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(
          find.text('Your privacy is our priority. Edit with confidence.'),
          findsOneWidget,
        );
      });
    });

    group('documentation section', () {
      testWidgets('renders Documentation title', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Documentation'), findsOneWidget);
      });

      testWidgets('renders menu book icon', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
      });

      testWidgets('renders Getting Started link', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Getting Started'), findsOneWidget);
      });

      testWidgets('renders Architecture link', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Architecture'), findsOneWidget);
      });

      testWidgets('renders API Reference link', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('API Reference'), findsOneWidget);
      });

      testWidgets('renders Report an Issue link', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Report an Issue'), findsOneWidget);
      });
    });

    group('open source licenses', () {
      testWidgets('renders Open Source Licenses button', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.text('Open Source Licenses'), findsOneWidget);
      });

      testWidgets('renders description icon for licenses', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.byIcon(Icons.description_rounded), findsOneWidget);
      });

      testWidgets('tapping licenses button shows license page',
          (tester) async {
        await tester.pumpWidget(createAboutScreen());

        // Scroll to make the licenses button visible
        await tester.scrollUntilVisible(
          find.text('Open Source Licenses'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Source Licenses'));
        await tester.pumpAndSettle();

        // LicensePage should be shown
        expect(find.byType(LicensePage), findsOneWidget);
      });

      testWidgets('license page shows app name', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        // Scroll to make the licenses button visible
        await tester.scrollUntilVisible(
          find.text('Open Source Licenses'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Source Licenses'));
        await tester.pumpAndSettle();

        expect(find.text('KidsLens Video Editor'), findsOneWidget);
      });
    });

    group('footer', () {
      testWidgets('renders copyright text', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(
          find.text('© 2024 KidsLens. All rights reserved.'),
          findsOneWidget,
        );
      });
    });

    group('layout', () {
      testWidgets('has scrollable body', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('renders AppBar with title', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('About'), findsOneWidget);
      });

      testWidgets('renders multiple Card widgets', (tester) async {
        await tester.pumpWidget(createAboutScreen());

        expect(find.byType(Card), findsWidgets);
      });
    });
  });
}
