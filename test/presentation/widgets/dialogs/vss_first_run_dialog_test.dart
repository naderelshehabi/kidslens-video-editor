import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/widgets/dialogs/vss_first_run_dialog.dart';

void main() {
  group('VssFirstRunDialog', () {
    testWidgets('returns download when user starts local setup',
        (tester) async {
      VssFirstRunAction? action;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                action = await VssFirstRunDialog.show(
                  context: context,
                  modelName: 'Qwen3-VL 8B Instruct GGUF Q4_K_M',
                  runtimeName: 'llama.cpp b9628 Windows CUDA 13.3',
                  modelMissing: true,
                  runtimeMissing: true,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('vss_first_run_dialog')), findsOneWidget);
      expect(find.text('Download Local AI Runtime'), findsOneWidget);
      expect(find.text('Qwen3-VL 8B Instruct GGUF Q4_K_M'), findsOneWidget);
      expect(find.text('llama.cpp b9628 Windows CUDA 13.3'), findsOneWidget);

      await tester.tap(find.text('Download Now'));
      await tester.pumpAndSettle();

      expect(action, VssFirstRunAction.download);
    });

    testWidgets('returns legacy fallback when user chooses legacy analysis',
        (tester) async {
      VssFirstRunAction? action;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                action = await VssFirstRunDialog.show(
                  context: context,
                  modelName: 'Qwen3-VL 8B Instruct GGUF Q4_K_M',
                  runtimeName: 'llama.cpp b9628 Windows CUDA 13.3',
                  modelMissing: true,
                  runtimeMissing: false,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Qwen3-VL 8B Instruct GGUF Q4_K_M'), findsOneWidget);
      expect(find.text('llama.cpp b9628 Windows CUDA 13.3'), findsNothing);

      await tester.tap(find.text('Use Legacy Analysis Instead'));
      await tester.pumpAndSettle();

      expect(action, VssFirstRunAction.useLegacy);
    });
  });
}
