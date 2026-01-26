import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';

part 'model_provider.g.dart';

/// State for AI model management
class ModelState {
  final List<ModelInfo> availableModels;
  final Set<String> downloadedModels;
  final Map<String, ModelDownloadProgress> activeDownloads;
  final ModelConfig? selectedConfig;
  final bool isLoading;
  final String? errorMessage;

  const ModelState({
    this.availableModels = const [],
    this.downloadedModels = const {},
    this.activeDownloads = const {},
    this.selectedConfig,
    this.isLoading = false,
    this.errorMessage,
  });

  ModelState copyWith({
    List<ModelInfo>? availableModels,
    Set<String>? downloadedModels,
    Map<String, ModelDownloadProgress>? activeDownloads,
    ModelConfig? selectedConfig,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ModelState(
      availableModels: availableModels ?? this.availableModels,
      downloadedModels: downloadedModels ?? this.downloadedModels,
      activeDownloads: activeDownloads ?? this.activeDownloads,
      selectedConfig: selectedConfig ?? this.selectedConfig,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for managing AI models
@Riverpod(keepAlive: true)
class ModelNotifier extends _$ModelNotifier {
  @override
  ModelState build() => const ModelState();

  Future<void> loadAvailableModels() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // TODO: Implement actual model loading via ModelManagerService
      await Future<void>.delayed(const Duration(milliseconds: 100));
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> downloadModel(String modelId) async {
    try {
      // Initialize download progress
      state = state.copyWith(
        activeDownloads: {
          ...state.activeDownloads,
          modelId: ModelDownloadProgress(
            modelId: modelId,
            percentage: 0.0,
            downloadedBytes: 0,
            totalBytes: 0,
          ),
        },
      );

      // TODO: Implement actual model download via ModelManagerService
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Mark as downloaded
      final downloads = Map<String, ModelDownloadProgress>.from(state.activeDownloads)
        ..remove(modelId);
      state = state.copyWith(
        activeDownloads: downloads,
        downloadedModels: {...state.downloadedModels, modelId},
      );
    } catch (e) {
      final downloads = Map<String, ModelDownloadProgress>.from(state.activeDownloads)
        ..remove(modelId);
      state = state.copyWith(
        activeDownloads: downloads,
        errorMessage: 'Failed to download model: $e',
      );
    }
  }

  void updateDownloadProgress(String modelId, ModelDownloadProgress progress) {
    state = state.copyWith(
      activeDownloads: {
        ...state.activeDownloads,
        modelId: progress,
      },
    );
  }

  Future<void> deleteModel(String modelId) async {
    try {
      // TODO: Implement actual model deletion via ModelManagerService
      await Future<void>.delayed(const Duration(milliseconds: 100));
      
      final downloaded = Set<String>.from(state.downloadedModels)
        ..remove(modelId);
      state = state.copyWith(downloadedModels: downloaded);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete model: $e');
    }
  }

  void setSelectedConfig(ModelConfig config) {
    state = state.copyWith(selectedConfig: config);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
