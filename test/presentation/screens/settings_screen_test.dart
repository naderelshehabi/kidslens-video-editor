import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsScreen', () {
    setUp(() async {
      // Initialize SharedPreferences with empty values for testing
      SharedPreferences.setMockInitialValues({});
    });

    Widget createSettingsScreen() => const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        );

    group('layout', () {
      testWidgets('renders AppBar with Settings title', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('has scrollable body', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });

      testWidgets('renders multiple Card widgets', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byType(Card), findsWidgets);
      });
    });

    group('appearance section', () {
      testWidgets('renders Appearance section header', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Appearance'), findsOneWidget);
      });

      testWidgets('renders palette icon for appearance', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byIcon(Icons.palette_rounded), findsOneWidget);
      });

      testWidgets('renders Theme Mode option', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Theme Mode'), findsOneWidget);
      });

      testWidgets('renders theme mode dropdown', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byType(DropdownButton<ThemeMode>), findsOneWidget);
      });

      testWidgets('theme dropdown contains all theme modes', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Open the dropdown
        await tester.tap(find.byType(DropdownButton<ThemeMode>));
        await tester.pumpAndSettle();

        expect(find.text('System'), findsWidgets);
        expect(find.text('Light'), findsWidgets);
        expect(find.text('Dark'), findsWidgets);
      });

      testWidgets('tapping theme dropdown opens menu', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        await tester.tap(find.byType(DropdownButton<ThemeMode>));
        await tester.pumpAndSettle();

        // Should see dropdown menu items
        expect(find.byType(DropdownMenuItem<ThemeMode>), findsWidgets);
      });
    });

    group('export defaults section', () {
      testWidgets('renders Export Defaults section header', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Export Defaults'), findsOneWidget);
      });

      testWidgets('renders movie creation icon', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byIcon(Icons.movie_creation_rounded), findsOneWidget);
      });

      testWidgets('renders Default Quality option', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Default Quality'), findsOneWidget);
      });

      testWidgets('renders export quality dropdown', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byType(DropdownButton<ExportQuality>), findsOneWidget);
      });

      testWidgets('export quality dropdown shows all options', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Open the dropdown
        await tester.tap(find.byType(DropdownButton<ExportQuality>));
        await tester.pumpAndSettle();

        expect(find.text('Low (480p)'), findsWidgets);
        expect(find.text('Medium (720p)'), findsWidgets);
        expect(find.text('High (1080p)'), findsWidgets);
        expect(find.text('Ultra (4K)'), findsWidgets);
        expect(find.text('Original'), findsWidgets);
      });

      testWidgets('renders Default Format option', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Default Format'), findsOneWidget);
      });

      testWidgets('renders export format dropdown', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byType(DropdownButton<ExportFormat>), findsOneWidget);
      });

      testWidgets('export format dropdown shows all options', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Open the dropdown
        await tester.tap(find.byType(DropdownButton<ExportFormat>));
        await tester.pumpAndSettle();

        expect(find.text('MP4 (H.264)'), findsWidgets);
        expect(find.text('WebM (VP9)'), findsWidgets);
        expect(find.text('MOV (ProRes)'), findsWidgets);
      });
    });

    group('auto-save section', () {
      testWidgets('renders Auto-Save section header', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Auto-Save'), findsOneWidget);
      });

      testWidgets('renders save icon', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byIcon(Icons.save_rounded), findsOneWidget);
      });

      testWidgets('renders Auto-Save Interval option', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Auto-Save Interval'), findsOneWidget);
      });

      testWidgets('renders auto-save interval dropdown', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byType(DropdownButton<int>), findsOneWidget);
      });
    });

    group('cache section', () {
      testWidgets('renders Cache & Storage section header', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Cache & Storage'), findsOneWidget);
      });

      testWidgets('renders storage icon', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byIcon(Icons.storage_rounded), findsOneWidget);
      });

      testWidgets('renders Cache Size label', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Cache Size'), findsOneWidget);
      });

      testWidgets('renders Clear cache button', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Clear'), findsOneWidget);
      });

      testWidgets('clear cache button has delete icon', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      });

      testWidgets('clear cache button is tappable', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Scroll to make the clear button visible
        await tester.scrollUntilVisible(
          find.text('Clear'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();

        // Find the Clear button (TextButton.icon renders as TextButton)
        final clearButton = find.text('Clear');
        expect(clearButton, findsOneWidget);

        // Tap and verify dialog appears
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        expect(find.text('Clear Cache'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('renders Refresh Cache Info option', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Refresh Cache Info'), findsOneWidget);
      });
    });

    // Note: Updates section was removed from the UI.
    // If an Updates section is added in the future, uncomment and update these tests:
    //
    // group('updates section', () {
    //   testWidgets('renders Updates section header', ...);
    //   testWidgets('renders system update icon', ...);
    //   testWidgets('renders Check for Updates toggle', ...);
    //   testWidgets('renders Check Now button', ...);
    //   testWidgets('renders version info', ...);
    // });

    group('reset section', () {
      testWidgets('renders Reset section header', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Scroll to make reset section visible
        await tester.scrollUntilVisible(
          find.text('Reset All Settings'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump();

        // Reset text appears twice: section header and button
        expect(find.text('Reset'), findsNWidgets(2));
      });

      testWidgets('renders restart icon', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
      });

      testWidgets('renders Reset All Settings option', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.text('Reset All Settings'), findsOneWidget);
      });

      testWidgets('renders Reset button', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        expect(find.widgetWithText(OutlinedButton, 'Reset'), findsOneWidget);
      });

      testWidgets('tapping reset button shows confirmation dialog',
          (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Scroll to make reset button visible
        await tester.scrollUntilVisible(
          find.widgetWithText(OutlinedButton, 'Reset'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
        await tester.pumpAndSettle();

        expect(find.text('Reset Settings'), findsOneWidget);
        expect(
          find.text(
            'This will restore all settings to their default values. '
            'This action cannot be undone.',
          ),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('reset confirmation dialog has cancel button',
          (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Scroll to make reset button visible
        await tester.scrollUntilVisible(
          find.widgetWithText(OutlinedButton, 'Reset'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Reset'));
        await tester.pumpAndSettle();

        // Cancel button should dismiss dialog
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Reset Settings'), findsNothing);
      });
    });

    group('interactions', () {
      testWidgets('changing theme mode updates display', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Open theme dropdown
        await tester.tap(find.byType(DropdownButton<ThemeMode>));
        await tester.pumpAndSettle();

        // Select Dark mode
        await tester.tap(find.text('Dark').last);
        await tester.pumpAndSettle();

        // Subtitle should update (find the subtitle text)
        expect(find.text('Dark'), findsWidgets);
      });

      testWidgets('changing export quality updates display', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Open quality dropdown
        await tester.tap(find.byType(DropdownButton<ExportQuality>));
        await tester.pumpAndSettle();

        // Select Ultra quality
        await tester.tap(find.text('Ultra (4K)').last);
        await tester.pumpAndSettle();

        expect(find.text('Ultra (4K)'), findsWidgets);
      });

      testWidgets('changing export format updates display', (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pump();

        // Open format dropdown
        await tester.tap(find.byType(DropdownButton<ExportFormat>));
        await tester.pumpAndSettle();

        // Select WebM format
        await tester.tap(find.text('WebM (VP9)').last);
        await tester.pumpAndSettle();

        expect(find.text('WebM (VP9)'), findsWidgets);
      });
    });
  });
}
