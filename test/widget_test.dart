// Basic smoke test for KidsLens Video Editor app.
//
// This test verifies that the app can launch without crashing.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Mock SharedPreferences to skip onboarding and show welcome screen
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
  });

  testWidgets('App smoke test - launches successfully', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: KidsLensApp(),
      ),
    );

    // Wait for SharedPreferences to load and widget tree to settle
    await tester.pumpAndSettle();

    // Verify that the app title is displayed in the welcome screen
    expect(find.text('KidsLens Video Editor'), findsOneWidget);
  });

  testWidgets('App smoke test - shows welcome subtitle', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KidsLensApp(),
      ),
    );

    // Wait for SharedPreferences to load and widget tree to settle
    await tester.pumpAndSettle();

    // Verify welcome subtitle is shown
    expect(find.text('Create safe media for the whole family'), findsOneWidget);
  });

  testWidgets('App smoke test - shows project buttons', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KidsLensApp(),
      ),
    );

    // Wait for SharedPreferences to load and widget tree to settle
    await tester.pumpAndSettle();

    // Verify project buttons exist
    expect(find.text('New Project'), findsOneWidget);
    expect(find.text('Open Project'), findsOneWidget);
  });
}
