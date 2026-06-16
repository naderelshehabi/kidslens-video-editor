import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/presentation/screens/analysis_settings/local_model_bundles_tab.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/runtime_binary_manager.dart';
import 'package:kidslens_video_editor/state/providers/runtime_binary_provider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalModelBundlesTab', () {
    late ProviderContainer container;
    late _FakeRuntimeBinaryNotifier runtimeNotifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      runtimeNotifier = _FakeRuntimeBinaryNotifier();
      container = ProviderContainer(
        overrides: [
          runtimeBinaryNotifierProvider.overrideWith((ref) => runtimeNotifier),
        ],
      );
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
        find.byKey(const Key('grounding_bundle_selector')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('embedding_bundle_selector')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('local_ai_runtime_card')), findsOneWidget);
      expect(find.text('Local AI Runtime'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('vlm_bundle_selector')),
          matching: find.byType(DropdownButton<String?>),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Qwen3-VL 8B Instruct GGUF Q4_K_M (ready to validate)'),
        findsOneWidget,
      );
      await tester.tap(find.text('None selected').last);
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('embedding_bundle_selector')),
          matching: find.byType(DropdownButton<String?>),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Qwen3 Embedding 0.6B GGUF Q8 (ready to validate)'),
        findsOneWidget,
      );
      await tester.tap(find.text('None selected').last);
      await tester.pumpAndSettle();

      expect(find.text('No compatible bundle'), findsOneWidget);
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
        settingsState.localRuntimeId,
        LocalRuntimeId.directmlOnnx.jsonValue,
      );
    });

    testWidgets('installs and selects a local llama runtime', (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      expect(find.text('Not installed'), findsNWidgets(2));

      final installButton = find.byKey(
        Key(
          '${LocalRuntimeId.vulkanLlamaCpp.jsonValue}_install_runtime_button',
        ),
      );
      await tester.ensureVisible(installButton);
      await tester.pumpAndSettle();
      await tester.tap(installButton);
      await tester.pumpAndSettle();

      expect(runtimeNotifier.installRequests, [LocalRuntimeId.vulkanLlamaCpp]);
      expect(
        container.read(settingsNotifierProvider).localRuntimeId,
        LocalRuntimeId.vulkanLlamaCpp.jsonValue,
      );
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

    testWidgets(
      'keeps blocked LocateAnything unavailable for download',
      (tester) async {
        await tester.pumpWidget(
          host(
            catalog: [
              ModelBundleCatalog.byModelId('nvidia_locateanything_3b'),
            ],
          ),
        );
        await tester.pump();

        expect(find.text('NVIDIA LocateAnything 3B'), findsOneWidget);
        expect(find.text('Blocked'), findsOneWidget);
        expect(find.text('Commercial blocked'), findsOneWidget);

        final installButton = tester.widget<OutlinedButton>(
          find
              .widgetWithText(OutlinedButton, 'Download Official Artifact')
              .last,
        );
        expect(installButton.onPressed, isNull);
      },
    );

    testWidgets(
      'keeps raw official weights unavailable for runtime download',
      (tester) async {
        await tester.pumpWidget(
          host(
            catalog: [
              ModelBundleCatalog.byModelId(
                'nvidia_nemotron_nano_12b_v2_vl_fp8',
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.text('NVIDIA Nemotron Nano 12B v2 VL FP8'), findsOneWidget);
        expect(
          find.textContaining('Raw official weights require conversion'),
          findsOneWidget,
        );

        final installButton = tester.widget<OutlinedButton>(
          find
              .widgetWithText(OutlinedButton, 'Download Official Artifact')
              .last,
        );
        expect(installButton.onPressed, isNull);
      },
    );

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
  ModelBundleCatalog.byModelId('qwen3_vl_8b_instruct_gguf_q4km'),
  ModelBundleCatalog.byModelId('qwen3_vl_4b_instruct_gguf_q4km'),
  ModelBundleCatalog.byModelId('qwen3_embedding_0_6b_gguf_q8'),
  ModelBundleCatalog.byModelId('google_gemma_4_e4b_it'),
  ModelBundleCatalog.byModelId('nvidia_locateanything_3b'),
  ModelBundleCatalog.byModelId('meta_llama_4_scout_17b_16e_instruct'),
];

class _FakeRuntimeBinaryNotifier extends RuntimeBinaryNotifier {
  _FakeRuntimeBinaryNotifier()
      : super(RuntimeBinaryManager(customRuntimeRoot: '.test-runtimes'));

  final installRequests = <LocalRuntimeId>[];

  @override
  Future<void> loadInstallStates({
    Iterable<LocalRuntimeId> runtimeIds = const <LocalRuntimeId>[
      LocalRuntimeId.cudaLlamaCpp,
      LocalRuntimeId.vulkanLlamaCpp,
    ],
  }) async {
    state = RuntimeBinaryState(
      installStates: {
        for (final runtimeId in runtimeIds)
          runtimeId: RuntimeBinaryInstallState(
            isInstalled: false,
            installDirectory: '.test-runtimes/${runtimeId.jsonValue}',
            executablePath: null,
            missingFiles: const ['llama-server.exe'],
          ),
      },
    );
  }

  @override
  Future<void> ensureInstalled(LocalRuntimeId runtimeId) async {
    installRequests.add(runtimeId);
    state = state.copyWith(
      installStates: {
        ...state.installStates,
        runtimeId: RuntimeBinaryInstallState(
          isInstalled: true,
          installDirectory: '.test-runtimes/${runtimeId.jsonValue}',
          executablePath:
              '.test-runtimes/${runtimeId.jsonValue}/llama-server.exe',
          missingFiles: const [],
        ),
      },
    );
  }
}
