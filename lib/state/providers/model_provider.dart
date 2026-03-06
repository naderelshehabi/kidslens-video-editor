import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'model_provider.g.dart';

/// State for AI model management
class ModelState {
  const ModelState({
    this.availableModels = const [],
    this.downloadedModels = const {},
    this.activeDownloads = const {},
    this.selectedModels = const {},
    this.loadedModels = const {},
    this.selectedConfig,
    this.isLoading = false,
    this.errorMessage,
  });

  /// All available models from registry
  final List<HuggingFaceModel> availableModels;

  /// Set of downloaded model IDs
  final Set<String> downloadedModels;

  /// Active downloads with progress tracking (modelId -> progress)
  final Map<String, ModelDownloadProgress> activeDownloads;

  /// Selected model for each model type (HuggingFaceModelType -> modelId)
  final Map<HuggingFaceModelType, String> selectedModels;

  /// Models currently loaded into memory
  final Set<String> loadedModels;

  /// Current model configuration
  final ModelConfig? selectedConfig;

  /// Whether the provider is loading
  final bool isLoading;

  /// Error message if any
  final String? errorMessage;

  ModelState copyWith({
    List<HuggingFaceModel>? availableModels,
    Set<String>? downloadedModels,
    Map<String, ModelDownloadProgress>? activeDownloads,
    Map<HuggingFaceModelType, String>? selectedModels,
    Set<String>? loadedModels,
    ModelConfig? selectedConfig,
    bool? isLoading,
    String? errorMessage,
  }) =>
      ModelState(
        availableModels: availableModels ?? this.availableModels,
        downloadedModels: downloadedModels ?? this.downloadedModels,
        activeDownloads: activeDownloads ?? this.activeDownloads,
        selectedModels: selectedModels ?? this.selectedModels,
        loadedModels: loadedModels ?? this.loadedModels,
        selectedConfig: selectedConfig ?? this.selectedConfig,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );

  /// Check if a model is downloaded
  bool isDownloaded(String modelId) => downloadedModels.contains(modelId);

  /// Check if a model is currently downloading
  bool isDownloading(String modelId) => activeDownloads.containsKey(modelId);

  /// Check if a model is loaded into memory
  bool isLoaded(String modelId) => loadedModels.contains(modelId);

  /// Get download progress for a model (0.0 - 1.0)
  double getDownloadProgress(String modelId) =>
      activeDownloads[modelId]?.percentage ?? 0.0;

  /// Get selected model ID for a type
  String? getSelectedModelId(HuggingFaceModelType type) => selectedModels[type];
}

/// Provider for managing AI models
@Riverpod(keepAlive: true)
class ModelNotifier extends _$ModelNotifier {
  static final HuggingFaceModelRegistry _registry =
      HuggingFaceModelRegistry.instance;

  ModelManagerService get _modelManager =>
      ref.read(modelManagerServiceProvider);

  @override
  ModelState build() => const ModelState();

  /// Load available models from registry and check downloaded status
  Future<void> loadAvailableModels() async {
    state = state.copyWith(isLoading: true);
    try {
      // Get all models from HuggingFace registry
      final allModels = _registry.getAllModels();

      // Check which models are downloaded
      final downloadedIds = await _modelManager.getDownloadedModels();

      // Read persisted model selections from settings
      final settings = ref.read(settingsNotifierProvider);
      final persistedAsrModelId =
          settings.analysisSettings.modelConfig.asrModelId;
      final persistedNsfwModelId =
          settings.analysisSettings.modelConfig.nsfwModelId;
        final persistedParserModelId =
          settings.analysisSettings.modelConfig.parserModelId;
        final persistedGenderModelId =
          settings.analysisSettings.modelConfig.genderModelId;

      // Set selected models: prefer persisted settings, fall back to recommended
      final selectedModels = <HuggingFaceModelType, String>{};
      for (final type in HuggingFaceModelType.values) {
        final recommended = _registry.getRecommendedModel(type);
        if (recommended != null) {
          selectedModels[type] = recommended.id;
        }
      }

      // Override ASR selection with persisted value if available
      if (persistedAsrModelId.isNotEmpty) {
        selectedModels[HuggingFaceModelType.asr] = persistedAsrModelId;
      }
      if (persistedNsfwModelId.isNotEmpty) {
        selectedModels[HuggingFaceModelType.nsfw] = persistedNsfwModelId;
      }
      if (persistedParserModelId.isNotEmpty) {
        selectedModels[HuggingFaceModelType.parser] = persistedParserModelId;
      }
      if (persistedGenderModelId.isNotEmpty) {
        selectedModels[HuggingFaceModelType.genderHelper] =
            persistedGenderModelId;
      }

      state = state.copyWith(
        availableModels: allModels,
        downloadedModels: downloadedIds,
        selectedModels: selectedModels,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load models: $e',
      );
    }
  }

  /// Download a model with progress streaming
  Future<void> downloadModel(String modelId) async {
    // Get model info from registry
    final model = _registry.getModelById(modelId);
    if (model == null) {
      state = state.copyWith(
        errorMessage: 'Model not found: $modelId',
      );
      return;
    }

    try {
      // Initialize download progress
      state = state.copyWith(
        activeDownloads: {
          ...state.activeDownloads,
          modelId: ModelDownloadProgress(
            modelId: modelId,
            percentage: 0,
            downloadedBytes: 0,
            totalBytes: model.sizeBytes,
          ),
        },
      );

      // Stream download progress from ModelManagerService
      await for (final progress in _modelManager.downloadModel(modelId)) {
        state = state.copyWith(
          activeDownloads: {
            ...state.activeDownloads,
            modelId: progress,
          },
        );
      }

      // Mark as downloaded and remove from active downloads
      final downloads =
          Map<String, ModelDownloadProgress>.from(state.activeDownloads)
            ..remove(modelId);
      state = state.copyWith(
        activeDownloads: downloads,
        downloadedModels: {...state.downloadedModels, modelId},
      );
    } catch (e) {
      // Remove from active downloads on error
      final downloads =
          Map<String, ModelDownloadProgress>.from(state.activeDownloads)
            ..remove(modelId);
      state = state.copyWith(
        activeDownloads: downloads,
        errorMessage: 'Failed to download model: $e',
      );
    }
  }

  /// Update download progress (for external updates)
  void updateDownloadProgress(String modelId, ModelDownloadProgress progress) {
    state = state.copyWith(
      activeDownloads: {
        ...state.activeDownloads,
        modelId: progress,
      },
    );
  }

  /// Delete a downloaded model
  Future<void> deleteModel(String modelId) async {
    try {
      // Unload if loaded
      if (state.loadedModels.contains(modelId)) {
        await unloadModel(modelId);
      }

      // Delete via ModelManagerService
      await _modelManager.deleteModel(modelId);

      // Update state
      final downloaded = Set<String>.from(state.downloadedModels)
        ..remove(modelId);
      state = state.copyWith(
        downloadedModels: downloaded,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete model: $e');
    }
  }

  /// Select a model for a specific type
  void selectModel(String modelId, HuggingFaceModelType type) {
    final model = _registry.getModelById(modelId);
    if (model == null || model.modelType != type) {
      state = state.copyWith(
        errorMessage: 'Invalid model selection: $modelId for type $type',
      );
      return;
    }

    state = state.copyWith(
      selectedModels: {
        ...state.selectedModels,
        type: modelId,
      },
    );

    // Update the model config if applicable
    _updateModelConfig();
  }

  /// Get the selected model for a specific type
  HuggingFaceModel? getSelectedModel(HuggingFaceModelType type) {
    final modelId = state.selectedModels[type];
    if (modelId == null) return null;
    return _registry.getModelById(modelId);
  }

  /// Get all downloaded models with their info
  List<HuggingFaceModel> getDownloadedModels() => state.availableModels
      .where((m) => state.downloadedModels.contains(m.id))
      .toList();

  /// Get downloaded models by type
  List<HuggingFaceModel> getDownloadedModelsByType(HuggingFaceModelType type) =>
      state.availableModels
          .where(
            (m) => m.modelType == type && state.downloadedModels.contains(m.id),
          )
          .toList();

  /// Load a model into memory
  Future<void> loadModel(String modelId) async {
    if (state.loadedModels.contains(modelId)) {
      return; // Already loaded
    }

    if (!state.downloadedModels.contains(modelId)) {
      state = state.copyWith(
        errorMessage: 'Model not downloaded: $modelId',
      );
      return;
    }

    try {
      state = state.copyWith(isLoading: true);

      // Validate model before loading
      final isValid = await _modelManager.validateModel(modelId);
      if (!isValid) {
        throw Exception('Model validation failed: $modelId');
      }

      // Mark as loaded (actual loading happens in inference services)
      state = state.copyWith(
        loadedModels: {...state.loadedModels, modelId},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load model: $e',
      );
    }
  }

  /// Unload a model from memory
  Future<void> unloadModel(String modelId) async {
    if (!state.loadedModels.contains(modelId)) {
      return; // Not loaded
    }

    final loaded = Set<String>.from(state.loadedModels)..remove(modelId);
    state = state.copyWith(loadedModels: loaded);
  }

  /// Get the model path for a downloaded model
  Future<String?> getModelPath(String modelId) async =>
      _modelManager.getModelPath(modelId);

  /// Set the selected model configuration
  void setSelectedConfig(ModelConfig config) {
    state = state.copyWith(selectedConfig: config);
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith();
  }

  /// Update model config based on selected models
  void _updateModelConfig() {
    final asrModelId =
        state.selectedModels[HuggingFaceModelType.asr] ?? 'whisper-small';
    final nsfwModelId = state.selectedModels[HuggingFaceModelType.nsfw] ??
      'nsfw-onnx-community-vit-224';
    final parserModelId =
      state.selectedModels[HuggingFaceModelType.parser] ??
        'modesty-parser-birefnet-clothes';
    final genderModelId =
      state.selectedModels[HuggingFaceModelType.genderHelper] ??
        'gender-classification-onnx-community';

    final config = ModelConfig(
      asrModelId: asrModelId,
      nsfwModelId: nsfwModelId,
      parserModelId: parserModelId,
      genderModelId: genderModelId,
    );
    state = state.copyWith(selectedConfig: config);
  }

  /// Get models by type from registry
  List<HuggingFaceModel> getModelsByType(HuggingFaceModelType type) =>
      _registry.getModelsByType(type);

  /// Get ASR models
  List<HuggingFaceModel> getAsrModels() => _registry.getAsrModels();

  /// Get visual detection models
  List<HuggingFaceModel> getVisualModels() => _registry.getVisualModels();
}
