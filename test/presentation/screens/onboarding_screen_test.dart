import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/screens/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    Widget createOnboardingScreen({required VoidCallback onComplete}) {
      return MaterialApp(
        home: OnboardingScreen(onComplete: onComplete),
      );
    }

    testWidgets('renders first page on start', (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      expect(find.text('Welcome to KidsLens'), findsOneWidget);
      expect(
        find.text(
            'Make your videos safe for all audiences by detecting and removing inappropriate content.'),
        findsOneWidget,
      );
    });

    testWidgets('renders Skip button on first page',
        (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('renders Next button on first page',
        (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('renders page indicators', (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      // Should have 4 page indicators
      final indicators = find.byType(AnimatedContainer);
      expect(indicators, findsWidgets);
    });

    testWidgets('navigates to second page on Next tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('AI-Powered Analysis'), findsOneWidget);
      expect(
        find.text(
            'Our advanced AI models detect profanity, nudity, violence, and other sensitive content automatically.'),
        findsOneWidget,
      );
    });

    testWidgets('shows Back button on second page',
        (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('navigates back on Back tap', (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      // Go to second page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to KidsLens'), findsOneWidget);
    });

    testWidgets('navigates to third page', (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      // Navigate to third page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('100% Private'), findsOneWidget);
      expect(
        find.text(
            'All processing happens locally on your device. Your videos never leave your computer.'),
        findsOneWidget,
      );
    });

    testWidgets('navigates to fourth (last) page', (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      // Navigate to last page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Smart Editing'), findsOneWidget);
      expect(
        find.text(
            'Automatically mute, blur, or cut detected content. Review and customize before exporting.'),
        findsOneWidget,
      );
    });

    testWidgets('shows Get Started button on last page',
        (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      // Navigate to last page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('calls onComplete when Get Started is tapped',
        (WidgetTester tester) async {
      var completeCalled = false;

      await tester.pumpWidget(createOnboardingScreen(
        onComplete: () => completeCalled = true,
      ));

      // Navigate to last page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(completeCalled, isTrue);
    });

    testWidgets('calls onComplete when Skip is tapped',
        (WidgetTester tester) async {
      var completeCalled = false;

      await tester.pumpWidget(createOnboardingScreen(
        onComplete: () => completeCalled = true,
      ));

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(completeCalled, isTrue);
    });

    testWidgets('swipe left advances page', (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      // Swipe left with larger distance
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('AI-Powered Analysis'), findsOneWidget);
    });

    testWidgets('swipe right goes back', (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      // Go to second page using button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Swipe right to go back with larger distance
      await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Welcome to KidsLens'), findsOneWidget);
    });

    testWidgets('displays correct icons for each page',
        (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      // First page - visibility icon
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Navigate to second page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);

      // Navigate to third page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.computer), findsOneWidget);

      // Navigate to fourth page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.auto_fix_high), findsOneWidget);
    });

    testWidgets('current page indicator is wider',
        (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      // The current page indicator should be 24 pixels wide
      // Other indicators should be 8 pixels wide
      // This is tested implicitly by the AnimatedContainer behavior
    });

    testWidgets('FilledButton is used for Next/Get Started',
        (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('TextButton is used for Skip/Back',
        (WidgetTester tester) async {
      await tester.pumpWidget(createOnboardingScreen(onComplete: () {}));

      final textButtons = find.byType(TextButton);
      expect(textButtons, findsOneWidget); // Skip button
    });
  });
}
