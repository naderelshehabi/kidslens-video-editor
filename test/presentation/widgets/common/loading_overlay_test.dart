import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/widgets/common/loading_overlay.dart';

void main() {
  group('LoadingOverlay', () {
    Widget createLoadingOverlay({
      required bool isLoading,
      required Widget child,
      String? message,
      double? progress,
    }) => MaterialApp(
        home: Scaffold(
          body: LoadingOverlay(
            isLoading: isLoading,
            message: message,
            progress: progress,
            child: child,
          ),
        ),
      );

    testWidgets('shows child when not loading', (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: false,
        child: const Text('Child Content'),
      ),);

      expect(find.text('Child Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows loading indicator when loading',
        (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
      ),);

      expect(find.text('Child Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
        message: 'Loading data...',
      ),);

      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('shows linear progress when progress is provided',
        (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
        progress: 0.5,
      ),);

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows circular progress when no progress value',
        (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
      ),);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows progress percentage when progress is provided',
        (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
        progress: 0.75,
      ),);

      expect(find.text('75.0%'), findsOneWidget);
    });

    testWidgets('overlay covers entire child', (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const SizedBox(
          width: 300,
          height: 300,
          child: Text('Child Content'),
        ),
      ),);

      // Overlay should be on top via Stack
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('shows dark overlay when loading', (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
      ),);

      // Find the container with the dark overlay color
      final container = find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.color == Colors.black54,
      );
      expect(container, findsOneWidget);
    });

    testWidgets('no overlay when not loading', (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: false,
        child: const Text('Child Content'),
      ),);

      final container = find.byWidgetPredicate(
        (widget) =>
            widget is Container && widget.color == Colors.black54,
      );
      expect(container, findsNothing);
    });

    testWidgets('shows card for loading content', (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
      ),);

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('progress value of 0 shows 0.0%', (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
        progress: 0,
      ),);

      expect(find.text('0.0%'), findsOneWidget);
    });

    testWidgets('progress value of 1 shows 100.0%',
        (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
        progress: 1,
      ),);

      expect(find.text('100.0%'), findsOneWidget);
    });

    testWidgets('message and progress can be shown together',
        (tester) async {
      await tester.pumpWidget(createLoadingOverlay(
        isLoading: true,
        child: const Text('Child Content'),
        message: 'Processing...',
        progress: 0.42,
      ),);

      expect(find.text('Processing...'), findsOneWidget);
      expect(find.text('42.0%'), findsOneWidget);
    });

    testWidgets('child remains accessible when not loading',
        (tester) async {
      var buttonTapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LoadingOverlay(
            isLoading: false,
            child: ElevatedButton(
              onPressed: () => buttonTapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      ),);

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(buttonTapped, isTrue);
    });
  });
}
