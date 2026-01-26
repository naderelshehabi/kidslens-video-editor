import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/widgets/common/empty_state.dart';

void main() {
  group('EmptyState', () {
    Widget createEmptyState({
      required IconData icon,
      required String title,
      String? message,
      String? actionLabel,
      VoidCallback? onAction,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: icon,
            title: title,
            message: message,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ),
      );
    }

    testWidgets('renders icon', (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
      ));

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders title', (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items found',
      ));

      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders message when provided', (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
        message: 'Add some items to get started',
      ));

      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('does not render message when null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
        message: null,
      ));

      // Only title should be present, no message text
      expect(find.text('No items'), findsOneWidget);
    });

    testWidgets('renders action button when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
        actionLabel: 'Add Item',
        onAction: () {},
      ));

      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('does not render action button when label is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
        actionLabel: null,
        onAction: () {},
      ));

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('does not render action button when onAction is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
        actionLabel: 'Add Item',
        onAction: null,
      ));

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('calls onAction when button tapped',
        (WidgetTester tester) async {
      var actionCalled = false;

      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
        actionLabel: 'Add Item',
        onAction: () => actionCalled = true,
      ));

      await tester.tap(find.text('Add Item'));
      await tester.pump();

      expect(actionCalled, isTrue);
    });

    testWidgets('is centered in parent', (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
      ));

      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('icon has correct size', (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
      ));

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.inbox));
      expect(iconWidget.size, equals(64));
    });

    testWidgets('text is centered', (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
        message: 'Test message',
      ));

      final titleText = tester.widget<Text>(find.text('No items'));
      expect(titleText.textAlign, equals(TextAlign.center));

      final messageText = tester.widget<Text>(find.text('Test message'));
      expect(messageText.textAlign, equals(TextAlign.center));
    });

    testWidgets('renders video library icon for media empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.video_library_outlined,
        title: 'No Media Loaded',
        message: 'Import a video or audio file to start analyzing content.',
      ));

      expect(find.byIcon(Icons.video_library_outlined), findsOneWidget);
      expect(find.text('No Media Loaded'), findsOneWidget);
      expect(
        find.text('Import a video or audio file to start analyzing content.'),
        findsOneWidget,
      );
    });

    testWidgets('handles long title text', (WidgetTester tester) async {
      const longTitle =
          'This is a very long title that should wrap properly across multiple lines';

      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: longTitle,
      ));

      expect(find.text(longTitle), findsOneWidget);
    });

    testWidgets('handles long message text', (WidgetTester tester) async {
      const longMessage =
          'This is a very long message that explains in detail what the user '
          'should do next. It should wrap properly and remain readable even '
          'on smaller screens or narrow containers.';

      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'Empty',
        message: longMessage,
      ));

      expect(find.text(longMessage), findsOneWidget);
    });

    testWidgets('renders with different icons', (WidgetTester tester) async {
      final icons = [
        Icons.search_off,
        Icons.folder_open,
        Icons.error_outline,
        Icons.cloud_off,
      ];

      for (final icon in icons) {
        await tester.pumpWidget(createEmptyState(
          icon: icon,
          title: 'Empty State',
        ));

        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    testWidgets('has proper padding', (WidgetTester tester) async {
      await tester.pumpWidget(createEmptyState(
        icon: Icons.inbox,
        title: 'No items',
      ));

      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(Column),
          matching: find.byType(Padding),
        ).first,
      );

      expect(padding.padding, equals(const EdgeInsets.all(32)));
    });
  });
}
