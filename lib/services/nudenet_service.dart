
import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';

/// NudeNet v3 class label constants.
///
/// Order matches the model output indices for NudeNet v3.3 (18 classes).
/// Pinned to model version v3.3 — must be updated if model version changes.
class NudeNetLabels {
  NudeNetLabels._();

  static const List<String> classNames = [
    'FEMALE_GENITALIA_COVERED', // 0
    'FACE_FEMALE', // 1
    'BUTTOCKS_EXPOSED', // 2
    'FEMALE_BREAST_EXPOSED', // 3
    'FEMALE_GENITALIA_EXPOSED', // 4
    'MALE_BREAST_EXPOSED', // 5
    'ANUS_EXPOSED', // 6
    'FEET_EXPOSED', // 7
    'BELLY_COVERED', // 8
    'FEET_COVERED', // 9
    'ARMPITS_COVERED', // 10
    'ARMPITS_EXPOSED', // 11
    'FACE_MALE', // 12
    'BELLY_EXPOSED', // 13
    'MALE_GENITALIA_EXPOSED', // 14
    'ANUS_COVERED', // 15
    'FEMALE_BREAST_COVERED', // 16
    'BUTTOCKS_COVERED', // 17
  ];

  /// Labels commonly associated with nudity detection
  static const Set<String> exposedLabels = {
    'FEMALE_BREAST_EXPOSED',
    'FEMALE_GENITALIA_EXPOSED',
    'MALE_GENITALIA_EXPOSED',
    'ANUS_EXPOSED',
    'BUTTOCKS_EXPOSED',
  };

  /// Labels for covered body parts
  static const Set<String> coveredLabels = {
    'FEMALE_GENITALIA_COVERED',
    'FEMALE_BREAST_COVERED',
    'ANUS_COVERED',
    'BUTTOCKS_COVERED',
    'BELLY_COVERED',
    'FEET_COVERED',
    'ARMPITS_COVERED',
  };

  /// Labels for non-sensitive body parts
  static const Set<String> nonSensitiveLabels = {
    'FACE_FEMALE',
    'FACE_MALE',
    'FEET_EXPOSED',
    'BELLY_EXPOSED',
    'ARMPITS_EXPOSED',
    'MALE_BREAST_EXPOSED',
  };
}

/// Service for running NudeNet v3 body part detection on video frames.
///
/// NudeNet v3 is a YOLOv8-based object detection model that detects 18 classes
/// of body parts with bounding boxes. This service wraps the detection inference
/// and maps results to [DetectedRegion] instances.
class NudeNetService {
  NudeNetService({
    required this.onnx,
    required this.modelManager,
  });

  final ONNXBindings onnx;
  final ModelManagerService modelManager;

  /// Default input size for NudeNet v3 medium (640x640)
  static const int defaultInputSize = 640;

  /// Default confidence threshold
  static const double defaultConfidenceThreshold = 0.25;

  /// Default IoU threshold for NMS
  static const double defaultIouThreshold = 0.45;

  /// Whether the service has been initialized
  bool _initialized = false;

  /// Initialize the service.
  Future<void> initialize() async {
    if (_initialized) return;
    await onnx.initialize();
    _initialized = true;
  }

  /// Detect body part regions in a video frame.
  ///
  /// [modelPath] - Path to the NudeNet ONNX model file
  /// [rgbData] - Raw RGB pixel data of the frame
  /// [width] - Frame width in pixels
  /// [height] - Frame height in pixels
  /// [categories] - Enabled visual content categories to filter results
  /// [confidenceThreshold] - Minimum confidence to accept a detection
  ///
  /// Returns a list of [DetectedRegion] with bounding box coordinates
  /// normalized to 0-1 in the original image space.
  Future<List<DetectedRegion>> detectRegions({
    required String modelPath,
    required Uint8List rgbData,
    required int width,
    required int height,
    List<VisualContentCategory>? categories,
    double confidenceThreshold = defaultConfidenceThreshold,
    int inputSize = defaultInputSize,
  }) async {
    // Validate frame data
    final expectedLength = width * height * 3;
    if (rgbData.length != expectedLength) {
      debugPrint(
        'NudeNetService: Invalid frame data length '
        '(expected $expectedLength, got ${rgbData.length})',
      );
      return [];
    }

    try {
      // Collect all detection labels from enabled NudeNet categories
      final relevantLabels = _collectRelevantLabels(categories);

      // Run detection inference
      final result = await onnx.runDetectionInference(
        modelPath,
        rgbData,
        width,
        height,
        classNames: NudeNetLabels.classNames,
        confidenceThreshold: confidenceThreshold,
        inputSize: inputSize,
      );

      // Convert DetectionBoxes to DetectedRegions, filtering by relevant labels
      final regions = <DetectedRegion>[];
      for (final box in result.boxes) {
        // If categories are specified, only include relevant labels
        if (relevantLabels != null && !relevantLabels.contains(box.className)) {
          continue;
        }

        regions.add(DetectedRegion(
          label: box.className,
          confidence: box.confidence,
          x: box.x,
          y: box.y,
          width: box.width,
          height: box.height,
        ),);
      }

      return regions;
    } catch (e) {
      debugPrint('NudeNetService: Detection failed: $e');
      return [];
    }
  }

  /// Get the path to the NudeNet model.
  ///
  /// [modelId] defaults to 'nudenet-v3-medium'.
  Future<String?> getModelPath([String modelId = 'nudenet-v3-medium']) async => modelManager.getModelPath(modelId);

  /// Collect all NudeNet detection labels from enabled categories.
  ///
  /// Returns null if no categories are provided (accept all labels).
  Set<String>? _collectRelevantLabels(
    List<VisualContentCategory>? categories,
  ) {
    if (categories == null || categories.isEmpty) return null;

    final labels = <String>{};
    for (final category in categories) {
      if (!category.enabled) continue;
      if (!category.usesNudeNet) continue;
      labels.addAll(category.detectionLabels);
    }

    return labels.isEmpty ? null : labels;
  }

  /// Collect NudeNet detection labels from [ContentCategory] model contributions.
  ///
  /// Extracts detection labels from enabled [ModelContribution]s with
  /// [HuggingFaceModelType.nudeNet].
  Set<String>? collectLabelsFromContentCategories(
    List<ContentCategory>? categories,
  ) {
    if (categories == null || categories.isEmpty) return null;

    final labels = <String>{};
    for (final category in categories) {
      if (!category.enabled) continue;
      for (final contribution in category.enabledModels) {
        if (contribution.modelType != HuggingFaceModelType.nudeNet) continue;
        labels.addAll(contribution.detectionLabels);
      }
    }

    return labels.isEmpty ? null : labels;
  }
}
