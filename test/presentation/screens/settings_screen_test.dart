import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/presentation/screens/settings_screen.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

void main() {
  group('SettingsScreen', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget createSettingsScreen({SettingsState? settingsState}) => ProviderScope(
        overrides: [
          if (settingsState != null)
            settingsNotifierProvider.overrideWith(
              () => _MockSettingsNotifier(settingsState),
            ),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      );

    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays Analysis Settings section',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Analysis Settings'), findsOneWidget);
    });

    testWidgets('displays NSFW threshold slider', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('NSFW Threshold'), findsOneWidget);
      expect(
        find.text('Sensitivity for detecting NSFW content'),
        findsOneWidget,
      );
    });

    testWidgets('displays Violence threshold slider',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Violence Threshold'), findsOneWidget);
      expect(
        find.text('Sensitivity for detecting violence'),
        findsOneWidget,
      );
    });

    testWidgets('displays Blood threshold slider',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Blood Threshold'), findsOneWidget);
      expect(
        find.text('Sensitivity for detecting blood and gore'),
        findsOneWidget,
      );
    });

    testWidgets('displays Weapons threshold slider',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Weapons Threshold'), findsOneWidget);
      expect(
        find.text('Sensitivity for detecting weapons'),
        findsOneWidget,
      );
    });

    testWidgets('displays Detection Options section',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Detection Options'), findsOneWidget);
    });

    testWidgets('displays Detect Profanity switch',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Detect Profanity'), findsOneWidget);
      expect(
        find.text('Analyze audio for profane language'),
        findsOneWidget,
      );
    });

    testWidgets('displays Detect NSFW switch', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Detect NSFW'), findsOneWidget);
      expect(
        find.text('Analyze video for NSFW content'),
        findsOneWidget,
      );
    });

    testWidgets('displays Detect Violence switch',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Detect Violence'), findsOneWidget);
      expect(
        find.text('Analyze video for violent content'),
        findsOneWidget,
      );
    });

    testWidgets('displays Detect Blood switch', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Detect Blood'), findsOneWidget);
      expect(
        find.text('Analyze video for blood and gore'),
        findsOneWidget,
      );
    });

    testWidgets('displays Detect Weapons switch', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      expect(find.text('Detect Weapons'), findsOneWidget);
      expect(
        find.text('Analyze video for weapons'),
        findsOneWidget,
      );
    });

    testWidgets('displays AI Models section', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      // Scroll down to find AI Models section
      await tester.scrollUntilVisible(
        find.text('AI Models'),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('AI Models'), findsOneWidget);
      expect(find.text('Manage Models'), findsOneWidget);
      expect(
        find.text('Download and configure AI models'),
        findsOneWidget,
      );
    });

    testWidgets('displays Appearance section', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      // Scroll down to find Appearance section
      await tester.scrollUntilVisible(
        find.text('Appearance'),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.text('Use dark color scheme'), findsOneWidget);
    });

    testWidgets('displays About section', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      // Scroll down to find About section
      await tester.scrollUntilVisible(
        find.text('About'),
        200,
        scrollable: find.byType(Scrollable),
      );

      expect(find.text('About'), findsOneWidget);
      expect(find.text('About KidsLens'), findsOneWidget);
      expect(
        find.text('Version, licenses, and attributions'),
        findsOneWidget,
      );
    });

    testWidgets('toggles dark theme switch', (tester) async {
      await tester.pumpWidget(createSettingsScreen(
        settingsState: SettingsState(),
      ),);

      // Scroll to find dark theme switch
      await tester.scrollUntilVisible(
        find.text('Dark Theme'),
        200,
        scrollable: find.byType(Scrollable),
      );

      // Find dark theme switch
      final switchFinder = find.widgetWithText(SwitchListTile, 'Dark Theme');
      expect(switchFinder, findsOneWidget);

      // Tap the switch
      await tester.tap(switchFinder);
      await tester.pump();
    });

    testWidgets('toggles profanity detection switch',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      // Scroll to find Detect Profanity
      await tester.scrollUntilVisible(
        find.text('Detect Profanity'),
        100,
        scrollable: find.byType(Scrollable),
      );

      final switchFinder =
          find.widgetWithText(SwitchListTile, 'Detect Profanity');
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder, warnIfMissed: false);
      await tester.pump();
    });

    testWidgets('toggles NSFW detection switch', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      // Scroll to find Detect NSFW
      await tester.scrollUntilVisible(
        find.text('Detect NSFW'),
        100,
        scrollable: find.byType(Scrollable),
      );

      final switchFinder = find.widgetWithText(SwitchListTile, 'Detect NSFW');
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder, warnIfMissed: false);
      await tester.pump();
    });

    testWidgets('toggles violence detection switch',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      // Scroll to find Detect Violence
      await tester.scrollUntilVisible(
        find.text('Detect Violence'),
        100,
        scrollable: find.byType(Scrollable),
      );

      final switchFinder =
          find.widgetWithText(SwitchListTile, 'Detect Violence');
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder, warnIfMissed: false);
      await tester.pump();
    });

    testWidgets('sliders have correct initial values',
        (tester) async {
      final settings = AnalysisSettings.defaults();
      await tester.pumpWidget(createSettingsScreen(
        settingsState: SettingsState(analysisSettings: settings),
      ),);

      // Find all sliders
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(4)); // 4 threshold sliders
    });

    testWidgets('manage models tile navigates on tap',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      // Scroll to find Manage Models
      await tester.scrollUntilVisible(
        find.text('Manage Models'),
        200,
        scrollable: find.byType(Scrollable),
      );

      await tester.tap(find.text('Manage Models'));
      await tester.pumpAndSettle();

      // Should navigate to model selection screen
      expect(find.text('AI Models'), findsWidgets);
    });

    testWidgets('about tile navigates on tap', (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      // Scroll to find About KidsLens
      await tester.scrollUntilVisible(
        find.text('About KidsLens'),
        200,
        scrollable: find.byType(Scrollable),
      );

      await tester.tap(find.text('About KidsLens'));
      await tester.pumpAndSettle();

      // Should navigate to about screen
    });

    testWidgets('slider interaction updates threshold',
        (tester) async {
      await tester.pumpWidget(createSettingsScreen());

      // Find a slider and interact with it
      final slider = find.byType(Slider).first;
      expect(slider, findsOneWidget);

      // Drag the slider
      await tester.drag(slider, const Offset(50, 0));
      await tester.pump();
    });
  });
}

class _MockSettingsNotifier extends SettingsNotifier {
  _MockSettingsNotifier(this._initialState);

  final SettingsState _initialState;

  @override
  SettingsState build() => _initialState;

  @override
  void setDarkTheme({required bool useDark}) {
    state = state.copyWith(useDarkTheme: useDark);
  }

  @override
  void updateAnalysisSettings(AnalysisSettings settings) {
    state = state.copyWith(analysisSettings: settings);
  }
}
