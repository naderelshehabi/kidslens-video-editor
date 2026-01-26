import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/core/errors/error_handler.dart';
import 'package:kidslens_video_editor/presentation/widgets/common/error_display.dart';

void main() {
  group('ErrorDisplay', () {
    Widget createErrorDisplay({
      ErrorResult? error,
      VoidCallback? onRetry,
      VoidCallback? onDismiss,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ErrorDisplay(
            error: error,
            onRetry: onRetry,
            onDismiss: onDismiss,
          ),
        ),
      );
    }

    ErrorResult createError({
      String userMessage = 'An error occurred',
      String remediation = 'Please try again',
      bool isRetryable = true,
    }) {
      return ErrorResult(
        userMessage: userMessage,
        remediation: remediation,
        isRetryable: isRetryable,
        originalError: Exception('Test error'),
      );
    }

    testWidgets('renders nothing when error is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(error: null));

      expect(find.byType(Card), findsNothing);
      expect(find.byType(SizedBox), findsWidgets); // SizedBox.shrink()
    });

    testWidgets('renders card when error is provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(error: createError()));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('displays user message', (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(
        error: createError(userMessage: 'Failed to load file'),
      ));

      expect(find.text('Failed to load file'), findsOneWidget);
    });

    testWidgets('displays remediation message', (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(
        error: createError(remediation: 'Check your connection'),
      ));

      expect(find.text('Check your connection'), findsOneWidget);
    });

    testWidgets('displays error icon', (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(error: createError()));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button when retryable and onRetry provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(
        error: createError(isRetryable: true),
        onRetry: () {},
      ));

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('hides retry button when not retryable',
        (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(
        error: createError(isRetryable: false),
        onRetry: () {},
      ));

      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('hides retry button when onRetry is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(
        error: createError(isRetryable: true),
        onRetry: null,
      ));

      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('shows dismiss button when onDismiss provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(
        error: createError(),
        onDismiss: () {},
      ));

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hides dismiss button when onDismiss is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(
        error: createError(),
        onDismiss: null,
      ));

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('calls onRetry when retry button tapped',
        (WidgetTester tester) async {
      var retryCalled = false;

      await tester.pumpWidget(createErrorDisplay(
        error: createError(isRetryable: true),
        onRetry: () => retryCalled = true,
      ));

      await tester.tap(find.text('Try Again'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('calls onDismiss when dismiss button tapped',
        (WidgetTester tester) async {
      var dismissCalled = false;

      await tester.pumpWidget(createErrorDisplay(
        error: createError(),
        onDismiss: () => dismissCalled = true,
      ));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(dismissCalled, isTrue);
    });

    testWidgets('displays both retry and dismiss buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(
        error: createError(isRetryable: true),
        onRetry: () {},
        onDismiss: () {},
      ));

      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('uses error container color scheme',
        (WidgetTester tester) async {
      await tester.pumpWidget(createErrorDisplay(error: createError()));

      // Card should use errorContainer color from theme
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, isNotNull);
    });

    testWidgets('handles long error messages gracefully',
        (WidgetTester tester) async {
      const longMessage =
          'This is a very long error message that should still display correctly '
          'even when it exceeds the typical width of the error display widget. '
          'The text should wrap properly and remain readable.';

      await tester.pumpWidget(createErrorDisplay(
        error: createError(userMessage: longMessage),
      ));

      expect(find.text(longMessage), findsOneWidget);
    });

    testWidgets('handles long remediation messages gracefully',
        (WidgetTester tester) async {
      const longRemediation =
          'To fix this issue, please try the following steps: '
          '1. Check your internet connection. '
          '2. Restart the application. '
          '3. Contact support if the issue persists.';

      await tester.pumpWidget(createErrorDisplay(
        error: createError(remediation: longRemediation),
      ));

      expect(find.text(longRemediation), findsOneWidget);
    });
  });

  group('ErrorDisplay.showSnackBar', () {
    testWidgets('shows snackbar with error message',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  ErrorDisplay.showSnackBar(
                    context,
                    ErrorResult(
                      userMessage: 'Snackbar error',
                      remediation: 'Fix it',
                      isRetryable: false,
                      originalError: Exception('Test'),
                    ),
                  );
                },
                child: const Text('Show Error'),
              ),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Snackbar error'), findsOneWidget);
    });

    testWidgets('shows retry action for retryable errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  ErrorDisplay.showSnackBar(
                    context,
                    ErrorResult(
                      userMessage: 'Retryable error',
                      remediation: 'Fix it',
                      isRetryable: true,
                      originalError: Exception('Test'),
                    ),
                  );
                },
                child: const Text('Show Error'),
              ),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('hides retry action for non-retryable errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  ErrorDisplay.showSnackBar(
                    context,
                    ErrorResult(
                      userMessage: 'Non-retryable error',
                      remediation: 'Fix it',
                      isRetryable: false,
                      originalError: Exception('Test'),
                    ),
                  );
                },
                child: const Text('Show Error'),
              ),
            );
          },
        ),
      ));

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsNothing);
    });
  });
}
