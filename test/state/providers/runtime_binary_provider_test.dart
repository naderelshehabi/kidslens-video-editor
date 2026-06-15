import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/runtime_binary_manager.dart';
import 'package:kidslens_video_editor/state/providers/runtime_binary_provider.dart';

void main() {
  group('RuntimeBinaryNotifier', () {
    test('loads install states and records completed install', () async {
      final manager = _FakeRuntimeBinaryManager();
      final notifier = RuntimeBinaryNotifier(manager);

      await notifier.loadInstallStates();

      expect(
        notifier.state.installStates[LocalRuntimeId.cudaLlamaCpp]?.isInstalled,
        isFalse,
      );

      await notifier.ensureInstalled(LocalRuntimeId.cudaLlamaCpp);

      expect(manager.ensureRequests, [LocalRuntimeId.cudaLlamaCpp]);
      expect(notifier.state.activeInstalls, isEmpty);
      expect(
        notifier.state.installStates[LocalRuntimeId.cudaLlamaCpp]?.isInstalled,
        isTrue,
      );
      expect(notifier.state.errorMessage, isNull);
    });
  });
}

class _FakeRuntimeBinaryManager extends RuntimeBinaryManager {
  _FakeRuntimeBinaryManager() : super(customRuntimeRoot: '.test-runtimes');

  final ensureRequests = <LocalRuntimeId>[];
  final installed = <LocalRuntimeId>{};

  @override
  Future<RuntimeBinaryInstallState> getInstallState(
    LocalRuntimeId runtimeId,
  ) async =>
      RuntimeBinaryInstallState(
        isInstalled: installed.contains(runtimeId),
        installDirectory: '.test-runtimes/${runtimeId.jsonValue}',
        executablePath: installed.contains(runtimeId)
            ? '.test-runtimes/${runtimeId.jsonValue}/llama-server.exe'
            : null,
        missingFiles: installed.contains(runtimeId)
            ? const []
            : const ['llama-server.exe'],
      );

  @override
  Stream<RuntimeBinaryInstallProgress> ensureInstalled(
    LocalRuntimeId runtimeId,
  ) async* {
    ensureRequests.add(runtimeId);
    yield RuntimeBinaryInstallProgress(
      runtimeId: runtimeId,
      percentage: 0.25,
      downloadedBytes: 25,
      totalBytes: 100,
      status: RuntimeBinaryInstallStatus.downloading,
      currentAsset: 'llama.zip',
    );
    installed.add(runtimeId);
    yield RuntimeBinaryInstallProgress(
      runtimeId: runtimeId,
      percentage: 1,
      downloadedBytes: 100,
      totalBytes: 100,
      status: RuntimeBinaryInstallStatus.complete,
      currentAsset: 'llama.zip',
    );
  }
}
