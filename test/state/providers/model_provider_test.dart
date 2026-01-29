import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';

void main() {
  group('ModelState', () {
    group('initial state', () {
      test('should have empty default values', () {
        const state = ModelState();

        expect(state.availableModels, isEmpty);
        expect(state.downloadedModels, isEmpty);
        expect(state.activeDownloads, isEmpty);
        expect(state.selectedModels, isEmpty);
        expect(state.loadedModels, isEmpty);
        expect(state.selectedConfig, isNull);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
      });
    });

    group('isDownloaded', () {
      test('should return true when model is in downloadedModels', () {
        const state = ModelState(
          downloadedModels: {'model-1', 'model-2'},
        );

        expect(state.isDownloaded('model-1'), isTrue);
        expect(state.isDownloaded('model-2'), isTrue);
      });

      test('should return false when model is not downloaded', () {
        const state = ModelState(
          downloadedModels: {'model-1'},
        );

        expect(state.isDownloaded('model-3'), isFalse);
      });

      test('should return false when downloadedModels is empty', () {
        const state = ModelState();

        expect(state.isDownloaded('any-model'), isFalse);
      });
    });

    group('isDownloading', () {
      test('should return true when model is in activeDownloads', () {
        const state = ModelState(
          activeDownloads: {
            'model-1': ModelDownloadProgress(
              modelId: 'model-1',
              percentage: 0.5,
              downloadedBytes: 50000000,
              totalBytes: 100000000,
            ),
          },
        );

        expect(state.isDownloading('model-1'), isTrue);
      });

      test('should return false when model is not downloading', () {
        const state = ModelState(
          activeDownloads: {
            'model-1': ModelDownloadProgress(
              modelId: 'model-1',
              percentage: 0.5,
              downloadedBytes: 50000000,
              totalBytes: 100000000,
            ),
          },
        );

        expect(state.isDownloading('model-2'), isFalse);
      });

      test('should return false when activeDownloads is empty', () {
        const state = ModelState();

        expect(state.isDownloading('any-model'), isFalse);
      });
    });

    group('isLoaded', () {
      test('should return true when model is in loadedModels', () {
        const state = ModelState(
          loadedModels: {'model-1', 'model-2'},
        );

        expect(state.isLoaded('model-1'), isTrue);
        expect(state.isLoaded('model-2'), isTrue);
      });

      test('should return false when model is not loaded', () {
        const state = ModelState(
          loadedModels: {'model-1'},
        );

        expect(state.isLoaded('model-3'), isFalse);
      });

      test('should return false when loadedModels is empty', () {
        const state = ModelState();

        expect(state.isLoaded('any-model'), isFalse);
      });
    });

    group('getDownloadProgress', () {
      test('should return correct progress for downloading model', () {
        const state = ModelState(
          activeDownloads: {
            'model-1': ModelDownloadProgress(
              modelId: 'model-1',
              percentage: 0.75,
              downloadedBytes: 75000000,
              totalBytes: 100000000,
            ),
          },
        );

        expect(state.getDownloadProgress('model-1'), equals(0.75));
      });

      test('should return 0.0 for model not in activeDownloads', () {
        const state = ModelState();

        expect(state.getDownloadProgress('model-1'), equals(0.0));
      });

      test('should return 0.0 for different model', () {
        const state = ModelState(
          activeDownloads: {
            'model-1': ModelDownloadProgress(
              modelId: 'model-1',
              percentage: 0.5,
              downloadedBytes: 50000000,
              totalBytes: 100000000,
            ),
          },
        );

        expect(state.getDownloadProgress('model-2'), equals(0.0));
      });
    });

    group('getSelectedModelId', () {
      test('should return model id for selected type', () {
        const state = ModelState(
          selectedModels: {
            HuggingFaceModelType.nsfw: 'nsfw-model-v1',
            HuggingFaceModelType.violence: 'violence-model-v2',
          },
        );

        expect(
          state.getSelectedModelId(HuggingFaceModelType.nsfw),
          equals('nsfw-model-v1'),
        );
        expect(
          state.getSelectedModelId(HuggingFaceModelType.violence),
          equals('violence-model-v2'),
        );
      });

      test('should return null when type not in selectedModels', () {
        const state = ModelState(
          selectedModels: {
            HuggingFaceModelType.nsfw: 'nsfw-model-v1',
          },
        );

        expect(
          state.getSelectedModelId(HuggingFaceModelType.violence),
          isNull,
        );
        expect(
          state.getSelectedModelId(HuggingFaceModelType.blood),
          isNull,
        );
      });

      test('should return null when selectedModels is empty', () {
        const state = ModelState();

        expect(
          state.getSelectedModelId(HuggingFaceModelType.nsfw),
          isNull,
        );
      });
    });

    group('copyWith', () {
      test('should copy with new downloadedModels', () {
        const state = ModelState();
        final newState = state.copyWith(
          downloadedModels: {'model-1', 'model-2'},
        );

        expect(newState.downloadedModels, contains('model-1'));
        expect(newState.downloadedModels, contains('model-2'));
        expect(newState.downloadedModels, hasLength(2));
      });

      test('should copy with new activeDownloads', () {
        const state = ModelState();
        final newState = state.copyWith(
          activeDownloads: {
            'model-1': const ModelDownloadProgress(
              modelId: 'model-1',
              percentage: 0.25,
              downloadedBytes: 25000000,
              totalBytes: 100000000,
            ),
          },
        );

        expect(newState.activeDownloads, contains('model-1'));
        expect(newState.activeDownloads['model-1']?.percentage, equals(0.25));
      });

      test('should copy with new selectedModels', () {
        const state = ModelState();
        final newState = state.copyWith(
          selectedModels: {
            HuggingFaceModelType.asr: 'whisper-large',
            HuggingFaceModelType.nsfw: 'nsfw-efficientnet',
          },
        );

        expect(
          newState.getSelectedModelId(HuggingFaceModelType.asr),
          equals('whisper-large'),
        );
        expect(
          newState.getSelectedModelId(HuggingFaceModelType.nsfw),
          equals('nsfw-efficientnet'),
        );
      });

      test('should copy with new loadedModels', () {
        const state = ModelState();
        final newState = state.copyWith(
          loadedModels: {'model-1', 'model-2', 'model-3'},
        );

        expect(newState.loadedModels, hasLength(3));
        expect(newState.isLoaded('model-1'), isTrue);
        expect(newState.isLoaded('model-2'), isTrue);
        expect(newState.isLoaded('model-3'), isTrue);
      });

      test('should copy with new selectedConfig', () {
        const state = ModelState();
        const config = ModelConfig(
          asrModelId: 'whisper-medium',
          visualModelId: 'nsfw-model',
        );
        final newState = state.copyWith(selectedConfig: config);

        expect(newState.selectedConfig, isNotNull);
        expect(newState.selectedConfig?.asrModelId, equals('whisper-medium'));
      });

      test('should copy with new isLoading', () {
        const state = ModelState();
        final newState = state.copyWith(isLoading: true);

        expect(newState.isLoading, isTrue);
        expect(state.isLoading, isFalse); // Original unchanged
      });

      test('should copy with new errorMessage', () {
        const state = ModelState();
        final newState = state.copyWith(errorMessage: 'Download failed');

        expect(newState.errorMessage, equals('Download failed'));
      });

      test('should clear errorMessage when copying with null', () {
        const state = ModelState(errorMessage: 'Previous error');
        final newState = state.copyWith();

        // copyWith without errorMessage should clear it (since it's nullable)
        expect(newState.errorMessage, isNull);
      });

      test('should preserve other fields when copying one field', () {
        const state = ModelState(
          downloadedModels: {'model-1'},
          loadedModels: {'model-1'},
        );
        final newState = state.copyWith(isLoading: true);

        expect(newState.isLoading, isTrue);
        expect(newState.downloadedModels, contains('model-1'));
        expect(newState.loadedModels, contains('model-1'));
      });
    });
  });

  group('ModelDownloadProgress', () {
    group('creation', () {
      test('should create with required fields', () {
        const progress = ModelDownloadProgress(
          modelId: 'test-model',
          percentage: 0.5,
          downloadedBytes: 50000000,
          totalBytes: 100000000,
        );

        expect(progress.modelId, equals('test-model'));
        expect(progress.percentage, equals(0.5));
        expect(progress.downloadedBytes, equals(50000000));
        expect(progress.totalBytes, equals(100000000));
      });

      test('should handle 0% progress', () {
        const progress = ModelDownloadProgress(
          modelId: 'test-model',
          percentage: 0,
          downloadedBytes: 0,
          totalBytes: 100000000,
        );

        expect(progress.percentage, equals(0.0));
        expect(progress.downloadedBytes, equals(0));
      });

      test('should handle 100% progress', () {
        const progress = ModelDownloadProgress(
          modelId: 'test-model',
          percentage: 1,
          downloadedBytes: 100000000,
          totalBytes: 100000000,
        );

        expect(progress.percentage, equals(1.0));
        expect(progress.downloadedBytes, equals(100000000));
      });

      test('should format percentage correctly', () {
        const progress = ModelDownloadProgress(
          modelId: 'test-model',
          percentage: 0.756,
          downloadedBytes: 75600000,
          totalBytes: 100000000,
        );

        expect(progress.percentageFormatted, equals('75.6%'));
      });

      test('should calculate bytes remaining', () {
        const progress = ModelDownloadProgress(
          modelId: 'test-model',
          percentage: 0.5,
          downloadedBytes: 50000000,
          totalBytes: 100000000,
        );

        expect(progress.bytesRemaining, equals(50000000));
      });

      test('should check if complete', () {
        const inProgress = ModelDownloadProgress(
          modelId: 'test-model',
          percentage: 0.5,
          downloadedBytes: 50000000,
          totalBytes: 100000000,
        );

        const complete = ModelDownloadProgress(
          modelId: 'test-model',
          percentage: 1,
          downloadedBytes: 100000000,
          totalBytes: 100000000,
          status: ModelDownloadStatus.complete,
        );

        expect(inProgress.isComplete, isFalse);
        expect(complete.isComplete, isTrue);
      });

      test('should check if failed', () {
        const failed = ModelDownloadProgress(
          modelId: 'test-model',
          percentage: 0.5,
          downloadedBytes: 50000000,
          totalBytes: 100000000,
          status: ModelDownloadStatus.failed,
        );

        expect(failed.isFailed, isTrue);
      });
    });
  });

  group('ModelNotifier', () {
    late ProviderContainer container;
    late ModelNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(modelNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('initialization', () {
      test('should start with empty state', () {
        expect(notifier.state.availableModels, isEmpty);
        expect(notifier.state.downloadedModels, isEmpty);
        expect(notifier.state.activeDownloads, isEmpty);
        expect(notifier.state.selectedModels, isEmpty);
        expect(notifier.state.loadedModels, isEmpty);
        expect(notifier.state.selectedConfig, isNull);
        expect(notifier.state.isLoading, isFalse);
        expect(notifier.state.errorMessage, isNull);
      });
    });

    group('selectModel', () {
      test('should set error for invalid model', () {
        // State should remain unchanged for invalid model (not in registry)
        notifier.selectModel('invalid-model', HuggingFaceModelType.nsfw);

        // Should have set an error message since model not in registry
        expect(notifier.state.errorMessage, isNotNull);

        // Reset error and test state management
        notifier.clearError();
        expect(notifier.state.errorMessage, isNull);
      });
    });

    group('updateDownloadProgress', () {
      test('should update download progress for model', () {
        const progress = ModelDownloadProgress(
          modelId: 'model-1',
          percentage: 0.5,
          downloadedBytes: 50000000,
          totalBytes: 100000000,
        );

        notifier.updateDownloadProgress('model-1', progress);

        expect(notifier.state.isDownloading('model-1'), isTrue);
        expect(notifier.state.getDownloadProgress('model-1'), equals(0.5));
      });

      test('should replace existing progress for same model', () {
        const progress1 = ModelDownloadProgress(
          modelId: 'model-1',
          percentage: 0.25,
          downloadedBytes: 25000000,
          totalBytes: 100000000,
        );
        const progress2 = ModelDownloadProgress(
          modelId: 'model-1',
          percentage: 0.75,
          downloadedBytes: 75000000,
          totalBytes: 100000000,
        );

        notifier
          ..updateDownloadProgress('model-1', progress1)
          ..updateDownloadProgress('model-1', progress2);

        expect(notifier.state.getDownloadProgress('model-1'), equals(0.75));
      });

      test('should handle multiple concurrent downloads', () {
        const progress1 = ModelDownloadProgress(
          modelId: 'model-1',
          percentage: 0.5,
          downloadedBytes: 50000000,
          totalBytes: 100000000,
        );
        const progress2 = ModelDownloadProgress(
          modelId: 'model-2',
          percentage: 0.25,
          downloadedBytes: 25000000,
          totalBytes: 100000000,
        );

        notifier
          ..updateDownloadProgress('model-1', progress1)
          ..updateDownloadProgress('model-2', progress2);

        expect(notifier.state.isDownloading('model-1'), isTrue);
        expect(notifier.state.isDownloading('model-2'), isTrue);
        expect(notifier.state.getDownloadProgress('model-1'), equals(0.5));
        expect(notifier.state.getDownloadProgress('model-2'), equals(0.25));
      });
    });

    group('setSelectedConfig', () {
      test('should update selected config', () {
        const config = ModelConfig(
          asrModelId: 'whisper-large',
          visualModelId: 'nsfw-efficientnet',
        );

        notifier.setSelectedConfig(config);

        expect(notifier.state.selectedConfig, isNotNull);
        expect(
          notifier.state.selectedConfig?.asrModelId,
          equals('whisper-large'),
        );
        expect(
          notifier.state.selectedConfig?.visualModelId,
          equals('nsfw-efficientnet'),
        );
      });

      test('should replace existing config', () {
        const config1 = ModelConfig(
          asrModelId: 'whisper-tiny',
          visualModelId: 'nsfw-mobilenet',
        );
        const config2 = ModelConfig(
          asrModelId: 'whisper-large',
          visualModelId: 'nsfw-efficientnet',
        );

        notifier
          ..setSelectedConfig(config1)
          ..setSelectedConfig(config2);

        expect(
          notifier.state.selectedConfig?.asrModelId,
          equals('whisper-large'),
        );
      });
    });

    group('clearError', () {
      test('should clear error message', () {
        // Set an error by trying to select an invalid model
        notifier.selectModel('invalid-model', HuggingFaceModelType.nsfw);
        expect(notifier.state.errorMessage, isNotNull);

        notifier.clearError();

        expect(notifier.state.errorMessage, isNull);
      });

      test('should not affect other state when clearing error', () {
        const progress = ModelDownloadProgress(
          modelId: 'model-1',
          percentage: 0.5,
          downloadedBytes: 50000000,
          totalBytes: 100000000,
        );
        notifier
          ..updateDownloadProgress('model-1', progress)
          ..clearError();

        expect(notifier.state.isDownloading('model-1'), isTrue);
        expect(notifier.state.getDownloadProgress('model-1'), equals(0.5));
      });
    });

    group('state transitions', () {
      test('should track loading state', () {
        expect(notifier.state.isLoading, isFalse);

        // Loading state is typically set internally during loadAvailableModels
        // We can verify the default state
        expect(notifier.state.isLoading, isFalse);
      });

      test('should maintain consistency across multiple operations', () {
        const progress = ModelDownloadProgress(
          modelId: 'model-1',
          percentage: 0.5,
          downloadedBytes: 50000000,
          totalBytes: 100000000,
        );

        notifier
          ..updateDownloadProgress('model-1', progress)
          ..setSelectedConfig(const ModelConfig(
            asrModelId: 'whisper-small',
            visualModelId: 'nsfw-model',
          ),);

        // All state should be maintained
        expect(notifier.state.isDownloading('model-1'), isTrue);
        expect(notifier.state.selectedConfig, isNotNull);
        expect(notifier.state.availableModels, isEmpty);
        expect(notifier.state.downloadedModels, isEmpty);
      });
    });
  });

  group('HuggingFaceModelType', () {
    test('should have all expected values', () {
      expect(HuggingFaceModelType.values, contains(HuggingFaceModelType.asr));
      expect(HuggingFaceModelType.values, contains(HuggingFaceModelType.nsfw));
      expect(
        HuggingFaceModelType.values,
        contains(HuggingFaceModelType.violence),
      );
      expect(HuggingFaceModelType.values, contains(HuggingFaceModelType.blood));
      expect(
        HuggingFaceModelType.values,
        contains(HuggingFaceModelType.weapons),
      );
    });

    test('should have 5 model types', () {
      expect(HuggingFaceModelType.values, hasLength(5));
    });
  });

  group('ModelConfig', () {
    test('should create with required fields', () {
      const config = ModelConfig(
        asrModelId: 'whisper-medium',
        visualModelId: 'nsfw-efficientnet',
      );

      expect(config.asrModelId, equals('whisper-medium'));
      expect(config.visualModelId, equals('nsfw-efficientnet'));
    });

    test('should support optional fields with defaults', () {
      const config = ModelConfig(
        asrModelId: 'whisper-tiny',
        visualModelId: 'nsfw-mobilenet',
      );

      // Default values for optional fields
      expect(config.asrLanguage, equals('en'));
      expect(config.useGpu, isTrue);
      expect(config.cpuThreads, equals(4));
    });

    test('should create with all fields specified', () {
      const config = ModelConfig(
        asrModelId: 'whisper-large',
        visualModelId: 'nsfw-vit',
        asrLanguage: 'es',
        useGpu: false,
        cpuThreads: 8,
      );

      expect(config.asrModelId, equals('whisper-large'));
      expect(config.visualModelId, equals('nsfw-vit'));
      expect(config.asrLanguage, equals('es'));
      expect(config.useGpu, isFalse);
      expect(config.cpuThreads, equals(8));
    });
  });

  group('HuggingFaceModel', () {
    test('should have isRecommended computed property', () {
      const modelWithRecommendedBadge = HuggingFaceModel(
        id: 'test-model',
        displayName: 'Test Model',
        huggingFaceId: 'org/test-model',
        fileName: 'model.onnx',
        parameters: '100M',
        parameterCount: 100000000,
        sizeBytes: 200000000,
        ramRequired: 500000000,
        speedMultiplier: 5,
        accuracyPercent: 95,
        modelType: HuggingFaceModelType.nsfw,
        badge: 'Recommended',
      );

      const modelWithoutBadge = HuggingFaceModel(
        id: 'test-model-2',
        displayName: 'Test Model 2',
        huggingFaceId: 'org/test-model-2',
        fileName: 'model2.onnx',
        parameters: '50M',
        parameterCount: 50000000,
        sizeBytes: 100000000,
        ramRequired: 250000000,
        speedMultiplier: 8,
        accuracyPercent: 90,
        modelType: HuggingFaceModelType.nsfw,
      );

      expect(modelWithRecommendedBadge.isRecommended, isTrue);
      expect(modelWithoutBadge.isRecommended, isFalse);
    });

    test('should have hasBadge computed property', () {
      const modelWithBadge = HuggingFaceModel(
        id: 'test-model',
        displayName: 'Test Model',
        huggingFaceId: 'org/test-model',
        fileName: 'model.onnx',
        parameters: '100M',
        parameterCount: 100000000,
        sizeBytes: 200000000,
        ramRequired: 500000000,
        speedMultiplier: 5,
        accuracyPercent: 95,
        modelType: HuggingFaceModelType.nsfw,
        badge: 'Best Value',
      );

      const modelWithoutBadge = HuggingFaceModel(
        id: 'test-model-2',
        displayName: 'Test Model 2',
        huggingFaceId: 'org/test-model-2',
        fileName: 'model2.onnx',
        parameters: '50M',
        parameterCount: 50000000,
        sizeBytes: 100000000,
        ramRequired: 250000000,
        speedMultiplier: 8,
        accuracyPercent: 90,
        modelType: HuggingFaceModelType.nsfw,
      );

      expect(modelWithBadge.hasBadge, isTrue);
      expect(modelWithoutBadge.hasBadge, isFalse);
    });

    test('should have sizeFormatted computed property', () {
      const model = HuggingFaceModel(
        id: 'test-model',
        displayName: 'Test Model',
        huggingFaceId: 'org/test-model',
        fileName: 'model.onnx',
        parameters: '100M',
        parameterCount: 100000000,
        sizeBytes: 500 * 1024 * 1024, // 500 MB
        ramRequired: 1024 * 1024 * 1024, // 1 GB
        speedMultiplier: 5,
        accuracyPercent: 95,
        modelType: HuggingFaceModelType.nsfw,
      );

      expect(model.sizeFormatted, equals('500 MB'));
    });

    test('should have isAsrModel computed property', () {
      const asrModel = HuggingFaceModel(
        id: 'whisper-small',
        displayName: 'Whisper Small',
        huggingFaceId: 'ggerganov/whisper.cpp',
        fileName: 'ggml-small.bin',
        parameters: '244M',
        parameterCount: 244000000,
        sizeBytes: 500000000,
        ramRequired: 1000000000,
        speedMultiplier: 5,
        accuracyPercent: 94,
        modelType: HuggingFaceModelType.asr,
      );

      const visualModel = HuggingFaceModel(
        id: 'nsfw-model',
        displayName: 'NSFW Model',
        huggingFaceId: 'org/nsfw',
        fileName: 'model.onnx',
        parameters: '100M',
        parameterCount: 100000000,
        sizeBytes: 200000000,
        ramRequired: 500000000,
        speedMultiplier: 8,
        accuracyPercent: 92,
        modelType: HuggingFaceModelType.nsfw,
      );

      expect(asrModel.isAsrModel, isTrue);
      expect(asrModel.isVisualModel, isFalse);
      expect(visualModel.isAsrModel, isFalse);
      expect(visualModel.isVisualModel, isTrue);
    });
  });
}
