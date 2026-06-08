import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/local_model_bundles_tab.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalModelBundlesTab', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Widget host({List<ModelBundleManifest>? catalog}) =>
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: LocalModelBundlesTab(
                catalog: catalog ?? _catalogSubset,
              ),
            ),
          ),
        );

    testWidgets('renders pipeline runtime and bundle selectors',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      expect(find.text('Local Model Bundles'), findsOneWidget);
      expect(find.byKey(const Key('pipeline_selector')), findsOneWidget);
      expect(find.byKey(const Key('local_runtime_selector')), findsOneWidget);
      expect(find.byKey(const Key('vlm_bundle_selector')), findsOneWidget);
      expect(
          find.byKey(const Key('grounding_bundle_selector')), findsOneWidget);
      expect(
          find.byKey(const Key('embedding_bundle_selector')), findsOneWidget);
      expect(find.text('No approved bundle'), findsNWidgets(3));
    });

    testWidgets('updates pipeline and local runtime selectors', (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('pipeline_selector')),
          matching: find.byType(DropdownButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('VSS Family Safety (Default)'), findsWidgets);
      expect(find.text('Legacy NSFW Region (Legacy option)'), findsOneWidget);
      await tester.tap(find.text('Legacy NSFW Region (Legacy option)').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('local_runtime_selector')),
          matching: find.byType(DropdownButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('DirectML ONNX').last);
      await tester.pumpAndSettle();

      final settingsState = container.read(settingsNotifierProvider);
      expect(
        settingsState.analysisSettings.analysisPipelineId,
        DetectionPipelineIds.legacyNsfwRegionV8,
      );
      expect(
          settingsState.localRuntimeId, LocalRuntimeId.directmlOnnx.jsonValue);
    });

    testWidgets('shows governance and capability status for candidates',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      expect(find.text('Google Gemma 4 E4B IT'), findsOneWidget);
      expect(find.text('Evaluation only'), findsWidgets);
      expect(find.text('Official source'), findsWidgets);
      expect(find.text('Commercial allowed'), findsWidgets);
      expect(find.text('Checksum pending'), findsWidgets);
      expect(find.text('RTX 5070 pending'), findsWidgets);
      expect(find.text('Video input'), findsWidgets);
      expect(find.text('Bounding boxes'), findsWidgets);
      expect(find.text('Point localization'), findsWidgets);
    });

    testWidgets('keeps blocked LocateAnything unavailable for download',
        (tester) async {
      await tester.pumpWidget(
        host(catalog: [
          ModelBundleCatalog.byModelId('nvidia_locateanything_3b')
        ]),
      );
      await tester.pump();

      expect(find.text('NVIDIA LocateAnything 3B'), findsOneWidget);
      expect(find.text('Blocked'), findsOneWidget);
      expect(find.text('Commercial blocked'), findsOneWidget);

      final installButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Download Official Artifact').last,
      );
      expect(installButton.onPressed, isNull);
    });

    testWidgets('persists terms acceptance for terms-gated candidates',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      await tester.ensureVisible(find.text('Accept Terms'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept Terms'));
      await tester.pumpAndSettle();

      expect(
        container.read(settingsNotifierProvider).acceptedModelBundleTerms,
        contains('meta_llama_4_scout_17b_16e_instruct'),
      );
      expect(find.text('Terms accepted'), findsOneWidget);
    });
  });
}

final _catalogSubset = <ModelBundleManifest>[
  ModelBundleCatalog.byModelId('google_gemma_4_e4b_it'),
  ModelBundleCatalog.byModelId('nvidia_locateanything_3b'),
  ModelBundleCatalog.byModelId('meta_llama_4_scout_17b_16e_instruct'),
];
