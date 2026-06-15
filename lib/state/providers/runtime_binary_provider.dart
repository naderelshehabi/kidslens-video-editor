import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/runtime_binary_manager.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';

class RuntimeBinaryState {
  const RuntimeBinaryState({
    this.installStates = const <LocalRuntimeId, RuntimeBinaryInstallState>{},
    this.activeInstalls =
        const <LocalRuntimeId, RuntimeBinaryInstallProgress>{},
    this.isLoading = false,
    this.errorMessage,
  });

  final Map<LocalRuntimeId, RuntimeBinaryInstallState> installStates;
  final Map<LocalRuntimeId, RuntimeBinaryInstallProgress> activeInstalls;
  final bool isLoading;
  final String? errorMessage;

  RuntimeBinaryState copyWith({
    Map<LocalRuntimeId, RuntimeBinaryInstallState>? installStates,
    Map<LocalRuntimeId, RuntimeBinaryInstallProgress>? activeInstalls,
    bool? isLoading,
    String? errorMessage,
  }) =>
      RuntimeBinaryState(
        installStates: installStates ?? this.installStates,
        activeInstalls: activeInstalls ?? this.activeInstalls,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );

  bool isInstalled(LocalRuntimeId runtimeId) =>
      installStates[runtimeId]?.isInstalled ?? false;

  bool isInstalling(LocalRuntimeId runtimeId) =>
      activeInstalls.containsKey(runtimeId);
}

final runtimeBinaryNotifierProvider =
    StateNotifierProvider<RuntimeBinaryNotifier, RuntimeBinaryState>(
  (ref) => RuntimeBinaryNotifier(ref.watch(runtimeBinaryManagerProvider)),
);

class RuntimeBinaryNotifier extends StateNotifier<RuntimeBinaryState> {
  RuntimeBinaryNotifier(this._manager) : super(const RuntimeBinaryState());

  final RuntimeBinaryManager _manager;

  Future<void> loadInstallStates({
    Iterable<LocalRuntimeId> runtimeIds = const <LocalRuntimeId>[
      LocalRuntimeId.cudaLlamaCpp,
      LocalRuntimeId.vulkanLlamaCpp,
    ],
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final nextStates = Map<LocalRuntimeId, RuntimeBinaryInstallState>.from(
        state.installStates,
      );
      for (final runtimeId in runtimeIds) {
        nextStates[runtimeId] = await _manager.getInstallState(runtimeId);
      }
      state = state.copyWith(
        installStates: nextStates,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load local runtime status: $error',
      );
    }
  }

  Future<void> ensureInstalled(LocalRuntimeId runtimeId) async {
    try {
      await for (final progress in _manager.ensureInstalled(runtimeId)) {
        state = state.copyWith(
          activeInstalls: {
            ...state.activeInstalls,
            runtimeId: progress,
          },
        );
      }
      final active = Map<LocalRuntimeId, RuntimeBinaryInstallProgress>.from(
        state.activeInstalls,
      )..remove(runtimeId);
      final installState = await _manager.getInstallState(runtimeId);
      state = state.copyWith(
        activeInstalls: active,
        installStates: {
          ...state.installStates,
          runtimeId: installState,
        },
      );
    } catch (error) {
      final active = Map<LocalRuntimeId, RuntimeBinaryInstallProgress>.from(
        state.activeInstalls,
      )..remove(runtimeId);
      state = state.copyWith(
        activeInstalls: active,
        errorMessage: 'Failed to install local runtime: $error',
      );
    }
  }

  void clearError() {
    state = state.copyWith();
  }
}
