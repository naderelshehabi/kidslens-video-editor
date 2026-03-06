import 'dart:math';

import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/frame_data.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/nsfw_onnx_service.dart';

/// Bounding box expressed in normalized frame coordinates.
class ModestyBoundingBox {
  const ModestyBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

/// Which backend produced a modesty-rule signal.
enum ModestySignalSource {
  explicitDetector,
  humanParser,
  genderHelper,
}

/// Normalized rule hit emitted by the modesty pipeline.
class ModestyRuleSignal {
  const ModestyRuleSignal({
    required this.categoryId,
    required this.confidence,
    required this.source,
    this.region,
    this.metadata = const <String, Object?>{},
  });

  final String categoryId;
  final double confidence;
  final ModestySignalSource source;
  final ModestyBoundingBox? region;
  final Map<String, Object?> metadata;
}

/// Batch result placeholder for the upcoming parser-backed modesty pipeline.
class ModestyAnalysisBatchResult {
  const ModestyAnalysisBatchResult({
    this.signalsByFrame = const <List<ModestyRuleSignal>>[],
    this.warningMessage,
  });

  final List<List<ModestyRuleSignal>> signalsByFrame;
  final String? warningMessage;
}

/// Scaffolding for a future parser-backed modesty analysis stage.
///
/// The current production pipeline can already route explicit detector outputs
/// through category-specific rules. This service will host the next phase:
/// person detection, human parsing, optional pose checks, and conservative
/// gender-aware policy evaluation.
class ModestyAnalysisService {
  ModestyAnalysisService({
    required this.nsfwOnnx,
  });

  final NsfwOnnxService nsfwOnnx;

  static const double _parserMaskThreshold = 0.5;
  static const double _minForegroundCoverage = 0.02;
  static const double _minFemaleConfidence = 0.78;
  static const double _minFemaleMargin = 0.12;
  static const String _armsExposureLabel = 'MODESTY_FEMALE_ARMS_EXPOSED';
  static const String _legsExposureLabel = 'MODESTY_FEMALE_LEGS_EXPOSED';

  static const Set<String> detectorBackedCategoryIds = <String>{
    'nudity',
    'female_chest_exposure',
    'female_abdomen_exposure',
    'male_buttocks_exposure',
    'male_genitals_exposure',
  };

  static const Set<String> plannedParserCategoryIds = <String>{
    'female_arms_exposure',
    'female_legs_exposure',
  };

  bool supportsCategory(ContentCategory category) =>
      detectorBackedCategoryIds.contains(category.id) ||
      plannedParserCategoryIds.contains(category.id);

  bool get supportsParserBackedCategories => true;

  Future<ModestyAnalysisBatchResult> analyzeBatch({
    required List<FrameData> frames,
    required List<ContentCategory> parserCategories,
    required String parserModelPath,
    String? genderModelPath,
    List<List<DetectedRegion>>? explicitRegionsByFrame,
    CancellationToken? cancellationToken,
  }) async {
    if (frames.isEmpty || parserCategories.isEmpty) {
      return ModestyAnalysisBatchResult(
        signalsByFrame: List<List<ModestyRuleSignal>>.generate(
          frames.length,
          (_) => const <ModestyRuleSignal>[],
          growable: false,
        ),
      );
    }

    final signalsByFrame = List<List<ModestyRuleSignal>>.generate(
      frames.length,
      (_) => <ModestyRuleSignal>[],
      growable: false,
    );
    final warnings = <String>[];
    var segmentationAvailable = true;
    var genderAvailable = genderModelPath != null && genderModelPath.isNotEmpty;

    for (var frameIndex = 0; frameIndex < frames.length; frameIndex++) {
      cancellationToken?.throwIfCancelled();
      if (!segmentationAvailable) {
        break;
      }

      final frame = frames[frameIndex];
      final explicitRegions = explicitRegionsByFrame != null &&
              frameIndex < explicitRegionsByFrame.length
          ? explicitRegionsByFrame[frameIndex]
          : const <DetectedRegion>[];

      BinarySegmentationMask segmentationMask;
      try {
        segmentationMask = await nsfwOnnx.runBinarySegmentationInference(
          modelPath: parserModelPath,
          rgbData: frame.data.toList(growable: false),
          width: frame.width,
          height: frame.height,
          threshold: _parserMaskThreshold,
          cancellationToken: cancellationToken,
        );
      } on NsfwOnnxException catch (e) {
        segmentationAvailable = false;
        warnings.add('Human parser disabled after inference failure: ${e.message}');
        break;
      }

      final silhouette = _extractSilhouetteBounds(segmentationMask);
      if (silhouette == null || silhouette.coverage < _minForegroundCoverage) {
        continue;
      }

      final genderScores = <String, double>{};
      if (genderAvailable && genderModelPath != null) {
        try {
          final crop = _cropRgb(
            rgbData: frame.data.toList(growable: false),
            width: frame.width,
            height: frame.height,
            bounds: silhouette,
          );
          if (crop != null) {
            genderScores.addAll(
              await nsfwOnnx.runLabeledClassificationInference(
                modelPath: genderModelPath,
                rgbData: crop.rgbData,
                width: crop.width,
                height: crop.height,
                labels: const <String>['female', 'male'],
                cancellationToken: cancellationToken,
              ),
            );
          }
        } on NsfwOnnxException catch (e) {
          genderAvailable = false;
          warnings.add('Gender helper disabled after inference failure: ${e.message}');
        }
      }

      final femaleExplicitEvidence = explicitRegions.any(
        (region) => region.label.startsWith('FEMALE_'),
      );
      final maleExplicitEvidence = explicitRegions.any(
        (region) => region.label.startsWith('MALE_'),
      );
      final femaleScore = max(
        genderScores['female'] ?? 0.0,
        femaleExplicitEvidence ? 0.98 : 0.0,
      );
      final maleScore = max(
        genderScores['male'] ?? 0.0,
        maleExplicitEvidence ? 0.98 : 0.0,
      );
      final confidentFemale = femaleScore >= _minFemaleConfidence &&
          (femaleScore - maleScore) >= _minFemaleMargin;

      if (!confidentFemale) {
        continue;
      }

      for (final category in parserCategories) {
        if (!plannedParserCategoryIds.contains(category.id)) {
          continue;
        }

        switch (category.id) {
          case 'female_arms_exposure':
            signalsByFrame[frameIndex].addAll(
              _analyzeArmExposure(
                frame: frame,
                mask: segmentationMask,
                silhouette: silhouette,
                category: category,
                femaleScore: femaleScore,
              ),
            );
            break;
          case 'female_legs_exposure':
            final legSignal = _analyzeLegExposure(
              frame: frame,
              mask: segmentationMask,
              silhouette: silhouette,
              category: category,
              femaleScore: femaleScore,
            );
            if (legSignal != null) {
              signalsByFrame[frameIndex].add(legSignal);
            }
            break;
          default:
            break;
        }
      }
    }

    return ModestyAnalysisBatchResult(
      signalsByFrame: List<List<ModestyRuleSignal>>.unmodifiable(
        signalsByFrame
            .map((signals) => List<ModestyRuleSignal>.unmodifiable(signals))
            .toList(growable: false),
      ),
      warningMessage: warnings.isEmpty ? null : warnings.join(' '),
    );
  }

  List<ModestyRuleSignal> _analyzeArmExposure({
    required FrameData frame,
    required BinarySegmentationMask mask,
    required _SilhouetteBounds silhouette,
    required ContentCategory category,
    required double femaleScore,
  }) {
    final signals = <ModestyRuleSignal>[];
    final leftArm = _ZoneRect(
      x: silhouette.x,
      y: silhouette.y + (silhouette.height * 0.18),
      width: silhouette.width * 0.24,
      height: silhouette.height * 0.34,
    );
    final rightArm = _ZoneRect(
      x: silhouette.x + (silhouette.width * 0.76),
      y: silhouette.y + (silhouette.height * 0.18),
      width: silhouette.width * 0.24,
      height: silhouette.height * 0.34,
    );

    for (final zone in <_ZoneRect>[leftArm, rightArm]) {
      final sample = _sampleSkinRatio(
        frame: frame,
        mask: mask,
        zone: zone,
      );
      final confidence = _combineConfidence(
        baseRatio: sample.skinRatio,
        helperConfidence: femaleScore,
      );
      if (sample.maskPixels >= 24 &&
          sample.skinRatio >= category.threshold &&
          confidence >= category.threshold) {
        signals.add(
          ModestyRuleSignal(
            categoryId: category.id,
            confidence: confidence,
            source: ModestySignalSource.humanParser,
            region: ModestyBoundingBox(
              x: zone.x,
              y: zone.y,
              width: zone.width,
              height: zone.height,
            ),
            metadata: <String, Object?>{
              'label': _armsExposureLabel,
              'skinRatio': sample.skinRatio,
              'femaleConfidence': femaleScore,
            },
          ),
        );
      }
    }

    return signals;
  }

  ModestyRuleSignal? _analyzeLegExposure({
    required FrameData frame,
    required BinarySegmentationMask mask,
    required _SilhouetteBounds silhouette,
    required ContentCategory category,
    required double femaleScore,
  }) {
    final zone = _ZoneRect(
      x: silhouette.x + (silhouette.width * 0.18),
      y: silhouette.y + (silhouette.height * 0.56),
      width: silhouette.width * 0.64,
      height: silhouette.height * 0.40,
    );
    final sample = _sampleSkinRatio(
      frame: frame,
      mask: mask,
      zone: zone,
    );
    final confidence = _combineConfidence(
      baseRatio: sample.skinRatio,
      helperConfidence: femaleScore,
    );
    if (sample.maskPixels < 32 ||
        sample.skinRatio < category.threshold ||
        confidence < category.threshold) {
      return null;
    }

    return ModestyRuleSignal(
      categoryId: category.id,
      confidence: confidence,
      source: ModestySignalSource.humanParser,
      region: ModestyBoundingBox(
        x: zone.x,
        y: zone.y,
        width: zone.width,
        height: zone.height,
      ),
      metadata: <String, Object?>{
        'label': _legsExposureLabel,
        'skinRatio': sample.skinRatio,
        'femaleConfidence': femaleScore,
      },
    );
  }

  _SilhouetteBounds? _extractSilhouetteBounds(BinarySegmentationMask mask) {
    if (mask.isEmpty) {
      return null;
    }

    var minX = mask.width;
    var minY = mask.height;
    var maxX = -1;
    var maxY = -1;
    var foregroundCount = 0;

    for (var y = 0; y < mask.height; y++) {
      for (var x = 0; x < mask.width; x++) {
        if (!mask.isForegroundAt(x, y)) {
          continue;
        }
        foregroundCount++;
        minX = min(minX, x);
        minY = min(minY, y);
        maxX = max(maxX, x);
        maxY = max(maxY, y);
      }
    }

    if (foregroundCount == 0 || maxX < minX || maxY < minY) {
      return null;
    }

    final x = minX / mask.width;
    final y = minY / mask.height;
    final width = ((maxX - minX) + 1) / mask.width;
    final height = ((maxY - minY) + 1) / mask.height;
    final coverage = foregroundCount / (mask.width * mask.height);

    return _SilhouetteBounds(
      x: x.clamp(0.0, 1.0).toDouble(),
      y: y.clamp(0.0, 1.0).toDouble(),
      width: width.clamp(0.0, 1.0 - x).toDouble(),
      height: height.clamp(0.0, 1.0 - y).toDouble(),
      coverage: coverage,
    );
  }

  _RgbCrop? _cropRgb({
    required List<int> rgbData,
    required int width,
    required int height,
    required _SilhouetteBounds bounds,
  }) {
    final padX = bounds.width * 0.08;
    final padY = bounds.height * 0.08;
    final startX = ((bounds.x - padX).clamp(0.0, 1.0) * width).floor();
    final startY = ((bounds.y - padY).clamp(0.0, 1.0) * height).floor();
    final endX = ((bounds.x + bounds.width + padX).clamp(0.0, 1.0) * width)
        .ceil();
    final endY = ((bounds.y + bounds.height + padY).clamp(0.0, 1.0) * height)
        .ceil();
    final cropWidth = max(1, endX - startX);
    final cropHeight = max(1, endY - startY);
    if (cropWidth < 8 || cropHeight < 8) {
      return null;
    }

    final cropped = List<int>.filled(cropWidth * cropHeight * 3, 0);
    for (var y = 0; y < cropHeight; y++) {
      final srcY = min(height - 1, startY + y);
      for (var x = 0; x < cropWidth; x++) {
        final srcX = min(width - 1, startX + x);
        final srcIndex = (srcY * width + srcX) * 3;
        final dstIndex = (y * cropWidth + x) * 3;
        cropped[dstIndex] = rgbData[srcIndex];
        cropped[dstIndex + 1] = rgbData[srcIndex + 1];
        cropped[dstIndex + 2] = rgbData[srcIndex + 2];
      }
    }

    return _RgbCrop(width: cropWidth, height: cropHeight, rgbData: cropped);
  }

  _ZoneSample _sampleSkinRatio({
    required FrameData frame,
    required BinarySegmentationMask mask,
    required _ZoneRect zone,
  }) {
    final frameWidth = frame.width;
    final frameHeight = frame.height;
    final rgbData = frame.data;
    final startX = (zone.x.clamp(0.0, 1.0) * frameWidth).floor();
    final startY = (zone.y.clamp(0.0, 1.0) * frameHeight).floor();
    final endX = ((zone.x + zone.width).clamp(0.0, 1.0) * frameWidth).ceil();
    final endY = ((zone.y + zone.height).clamp(0.0, 1.0) * frameHeight).ceil();
    final step = max(1, min(frameWidth, frameHeight) ~/ 180);
    var maskPixels = 0;
    var skinPixels = 0;

    for (var y = startY; y < endY; y += step) {
      final maskY = ((y / frameHeight) * mask.height).floor().clamp(0, mask.height - 1);
      for (var x = startX; x < endX; x += step) {
        final maskX = ((x / frameWidth) * mask.width).floor().clamp(0, mask.width - 1);
        if (!mask.isForegroundAt(maskX, maskY)) {
          continue;
        }

        maskPixels++;
        final pixelIndex = (y * frameWidth + x) * 3;
        if (_isLikelySkin(
          rgbData[pixelIndex],
          rgbData[pixelIndex + 1],
          rgbData[pixelIndex + 2],
        )) {
          skinPixels++;
        }
      }
    }

    return _ZoneSample(
      maskPixels: maskPixels,
      skinPixels: skinPixels,
      skinRatio: maskPixels == 0 ? 0.0 : skinPixels / maskPixels,
    );
  }

  bool _isLikelySkin(int r, int g, int b) {
    final maxChannel = max(r, max(g, b));
    final minChannel = min(r, min(g, b));
    if (r < 45 || g < 34 || b < 30) {
      return false;
    }
    if ((maxChannel - minChannel) < 15) {
      return false;
    }
    if (r <= g || r <= b) {
      return false;
    }

    final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
    return cb >= 77 && cb <= 127 && cr >= 133 && cr <= 173;
  }

  double _combineConfidence({
    required double baseRatio,
    required double helperConfidence,
  }) {
    return ((baseRatio * 0.7) + (helperConfidence * 0.3))
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

class _ZoneRect {
  const _ZoneRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

class _ZoneSample {
  const _ZoneSample({
    required this.maskPixels,
    required this.skinPixels,
    required this.skinRatio,
  });

  final int maskPixels;
  final int skinPixels;
  final double skinRatio;
}

class _SilhouetteBounds {
  const _SilhouetteBounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.coverage,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double coverage;
}

class _RgbCrop {
  const _RgbCrop({
    required this.width,
    required this.height,
    required this.rgbData,
  });

  final int width;
  final int height;
  final List<int> rgbData;
}
