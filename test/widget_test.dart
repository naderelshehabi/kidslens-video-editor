// Basic smoke test for KidsLens Video Editor app.
//
// This test verifies that the app can launch without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/app.dart';

void main() {
  testWidgets('App smoke test - launches successfully',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: KidsLensApp(),
      ),
    );

    // Verify that the app title is displayed
    expect(find.text('KidsLens Video Editor'), findsOneWidget);
  });

  testWidgets('App smoke test - shows welcome message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KidsLensApp(),
      ),
    );

    // Verify welcome message is shown
    expect(find.text('Welcome to KidsLens'), findsOneWidget);
  });

  testWidgets('App smoke test - shows import buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KidsLensApp(),
      ),
    );

    // Verify import buttons exist
    expect(find.text('New Project'), findsOneWidget);
    expect(find.text('Open Project'), findsOneWidget);
  });
}
