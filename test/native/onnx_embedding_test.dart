import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

// ============ Reimplemented private functions for testing ============

/// CLIP preprocessing constants (mirrors ONNXBindings._clipMean, _clipStd, _clipInputSize)
const clipMean = [0.48145466, 0.4578275, 0.40821073];
const clipStd = [0.26862954, 0.26130258, 0.27577711];
const clipInputSize = 224;

/// Embedding dimension for CLIP ViT-B/32
const embeddingDim = 512;

/// L2-normalize an embedding vector (mirrors ONNXBindings._l2Normalize)
List<double> l2Normalize(List<double> embedding) {
  var norm = 0.0;
  for (final v in embedding) {
    norm += v * v;
  }
  norm = sqrt(norm);
  if (norm < 1e-12) return embedding;
  return embedding.map((v) => v / norm).toList();
}

/// Compute CLIP preprocessing parameters without performing the actual resize.
/// Returns scale, resized dimensions, and crop offsets.
({double scale, int resizedW, int resizedH, int cropX, int cropY})
    clipPreprocessParams(int srcW, int srcH) {
  final scale = clipInputSize / min(srcW, srcH);
  final resizedW = (srcW * scale).round();
  final resizedH = (srcH * scale).round();
  final cropX = (resizedW - clipInputSize) ~/ 2;
  final cropY = (resizedH - clipInputSize) ~/ 2;
  return (
    scale: scale,
    resizedW: resizedW,
    resizedH: resizedH,
    cropX: cropX,
    cropY: cropY,
  );
}

/// Nearest-neighbor RGB resize (mirrors ONNXBindings._resizeRgb)
List<int> resizeRgb(
  List<int> data,
  int srcW,
  int srcH,
  int dstW,
  int dstH,
) {
  final output = List<int>.filled(dstW * dstH * 3, 0);
  final scaleX = srcW / dstW;
  final scaleY = srcH / dstH;

  for (var y = 0; y < dstH; y++) {
    for (var x = 0; x < dstW; x++) {
      final srcX = (x * scaleX).round().clamp(0, srcW - 1);
      final srcY = (y * scaleY).round().clamp(0, srcH - 1);
      final srcIdx = (srcY * srcW + srcX) * 3;
      final dstIdx = (y * dstW + x) * 3;

      if (srcIdx + 2 < data.length && dstIdx + 2 < output.length) {
        output[dstIdx] = data[srcIdx];
        output[dstIdx + 1] = data[srcIdx + 1];
        output[dstIdx + 2] = data[srcIdx + 2];
      }
    }
  }

  return output;
}

/// Full CLIP preprocessing (mirrors ONNXBindings._clipPreprocess)
Float32List clipPreprocess(List<int> rgbData, int srcW, int srcH) {
  const size = clipInputSize;

  final scale = size / min(srcW, srcH);
  final resizedW = (srcW * scale).round();
  final resizedH = (srcH * scale).round();

  final resized = resizeRgb(rgbData, srcW, srcH, resizedW, resizedH);

  final cropX = (resizedW - size) ~/ 2;
  final cropY = (resizedH - size) ~/ 2;

  final output = Float32List(3 * size * size);

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final sx = (cropX + x).clamp(0, resizedW - 1);
      final sy = (cropY + y).clamp(0, resizedH - 1);
      final srcIdx = (sy * resizedW + sx) * 3;

      final r = (resized[srcIdx] / 255.0 - clipMean[0]) / clipStd[0];
      final g = (resized[srcIdx + 1] / 255.0 - clipMean[1]) / clipStd[1];
      final b = (resized[srcIdx + 2] / 255.0 - clipMean[2]) / clipStd[2];

      output[0 * size * size + y * size + x] = r;
      output[1 * size * size + y * size + x] = g;
      output[2 * size * size + y * size + x] = b;
    }
  }

  return output;
}

// ============ Test helpers ============

/// Create a uniform color image (all pixels identical RGB)
List<int> makeUniformImage(int w, int h, int r, int g, int b) {
  final data = <int>[];
  for (var i = 0; i < w * h; i++) {
    data.addAll([r, g, b]);
  }
  return data;
}

/// Compute the L2 norm of a vector
double vectorNorm(List<double> v) {
  var sum = 0.0;
  for (final x in v) {
    sum += x * x;
  }
  return sqrt(sum);
}

void main() {
  // ================================================================
  // Group 1: L2 normalization
  // ================================================================
  group('L2 normalization', () {
    test('normalized vector has unit length', () {
      final input = [3.0, 4.0, 5.0, 6.0, 7.0];
      final result = l2Normalize(input);
      expect(vectorNorm(result), closeTo(1.0, 1e-10));
    });

    test('preserves direction (ratios between elements unchanged)', () {
      final input = [2.0, 4.0, 6.0];
      final result = l2Normalize(input);

      // ratio result[1]/result[0] should equal input[1]/input[0] = 2.0
      expect(result[1] / result[0], closeTo(2.0, 1e-10));
      // ratio result[2]/result[0] should equal input[2]/input[0] = 3.0
      expect(result[2] / result[0], closeTo(3.0, 1e-10));
    });

    test('zero vector returned as-is (norm < 1e-12)', () {
      final input = [0.0, 0.0, 0.0];
      final result = l2Normalize(input);
      // Should return the same list reference when norm < 1e-12
      expect(identical(result, input), isTrue);
      expect(result, equals([0.0, 0.0, 0.0]));
    });

    test('near-zero vector handled (very small values)', () {
      final input = [1e-15, 1e-15, 1e-15];
      final result = l2Normalize(input);
      // Norm of input ≈ 1.73e-15 which is < 1e-12, so returned as-is
      expect(identical(result, input), isTrue);
    });

    test('single element vector [5.0] normalizes to [1.0]', () {
      final result = l2Normalize([5.0]);
      expect(result.length, equals(1));
      expect(result[0], closeTo(1.0, 1e-10));
    });

    test('known input [3, 4] normalizes to [0.6, 0.8]', () {
      final result = l2Normalize([3.0, 4.0]);
      // norm = sqrt(9 + 16) = 5
      expect(result[0], closeTo(0.6, 1e-10));
      expect(result[1], closeTo(0.8, 1e-10));
    });
  });

  // ================================================================
  // Group 2: CLIP preprocessing scale and crop
  // ================================================================
  group('CLIP preprocessing scale and crop', () {
    test('square image 224x224: scale=1.0, no resize, no crop', () {
      final params = clipPreprocessParams(224, 224);
      expect(params.scale, closeTo(1.0, 1e-10));
      expect(params.resizedW, equals(224));
      expect(params.resizedH, equals(224));
      expect(params.cropX, equals(0));
      expect(params.cropY, equals(0));
    });

    test('landscape 640x480: shorter side scales to 224', () {
      final params = clipPreprocessParams(640, 480);
      // scale = 224 / min(640, 480) = 224 / 480
      expect(params.scale, closeTo(224.0 / 480.0, 1e-10));
      // resizedW = round(640 * 224/480) = round(298.666...) = 299
      expect(params.resizedW, equals(299));
      // resizedH = round(480 * 224/480) = 224
      expect(params.resizedH, equals(224));
      // cropX = (299 - 224) ~/ 2 = 37
      expect(params.cropX, equals(37));
      // cropY = 0
      expect(params.cropY, equals(0));
    });

    test('portrait 480x640: shorter side scales to 224', () {
      final params = clipPreprocessParams(480, 640);
      // scale = 224 / min(480, 640) = 224 / 480
      expect(params.scale, closeTo(224.0 / 480.0, 1e-10));
      // resizedW = round(480 * 224/480) = 224
      expect(params.resizedW, equals(224));
      // resizedH = round(640 * 224/480) = round(298.666...) = 299
      expect(params.resizedH, equals(299));
      // cropX = 0
      expect(params.cropX, equals(0));
      // cropY = (299 - 224) ~/ 2 = 37
      expect(params.cropY, equals(37));
    });

    test('very wide 1920x1080: shorter side scales to 224', () {
      final params = clipPreprocessParams(1920, 1080);
      // scale = 224 / min(1920, 1080) = 224 / 1080
      expect(params.scale, closeTo(224.0 / 1080.0, 1e-10));
      // resizedW = round(1920 * 224/1080) = round(398.222...) = 398
      expect(params.resizedW, equals(398));
      // resizedH = round(1080 * 224/1080) = 224
      expect(params.resizedH, equals(224));
      // cropX = (398 - 224) ~/ 2 = 87
      expect(params.cropX, equals(87));
      expect(params.cropY, equals(0));
    });

    test('already-at-224 shorter side: no crop on that axis', () {
      // 224x448 -- width is already 224 (the shorter side)
      final params = clipPreprocessParams(224, 448);
      // scale = 224 / 224 = 1.0
      expect(params.scale, closeTo(1.0, 1e-10));
      expect(params.resizedW, equals(224));
      expect(params.resizedH, equals(448));
      expect(params.cropX, equals(0));
      // cropY = (448 - 224) ~/ 2 = 112
      expect(params.cropY, equals(112));
    });
  });

  // ================================================================
  // Group 3: CLIP preprocessing normalization
  // ================================================================
  group('CLIP preprocessing normalization', () {
    test('pixel value 0 normalizes to -mean/std', () {
      // For a uniform black image, every pixel is 0
      final image = makeUniformImage(224, 224, 0, 0, 0);
      final output = clipPreprocess(image, 224, 224);

      // Channel R: (0/255 - mean[0]) / std[0] = -mean[0] / std[0]
      final expectedR = -clipMean[0] / clipStd[0];
      final expectedG = -clipMean[1] / clipStd[1];
      final expectedB = -clipMean[2] / clipStd[2];

      expect(output[0], closeTo(expectedR, 1e-5));
      expect(output[1 * 224 * 224], closeTo(expectedG, 1e-5));
      expect(output[2 * 224 * 224], closeTo(expectedB, 1e-5));
    });

    test('pixel value 255 normalizes to (1.0 - mean) / std', () {
      final image = makeUniformImage(224, 224, 255, 255, 255);
      final output = clipPreprocess(image, 224, 224);

      final expectedR = (1.0 - clipMean[0]) / clipStd[0];
      final expectedG = (1.0 - clipMean[1]) / clipStd[1];
      final expectedB = (1.0 - clipMean[2]) / clipStd[2];

      expect(output[0], closeTo(expectedR, 1e-5));
      expect(output[1 * 224 * 224], closeTo(expectedG, 1e-5));
      expect(output[2 * 224 * 224], closeTo(expectedB, 1e-5));
    });

    test('pixel value 128 normalizes to (128/255 - mean) / std', () {
      final image = makeUniformImage(224, 224, 128, 128, 128);
      final output = clipPreprocess(image, 224, 224);

      final expectedR = (128 / 255.0 - clipMean[0]) / clipStd[0];
      final expectedG = (128 / 255.0 - clipMean[1]) / clipStd[1];
      final expectedB = (128 / 255.0 - clipMean[2]) / clipStd[2];

      expect(output[0], closeTo(expectedR, 1e-5));
      expect(output[1 * 224 * 224], closeTo(expectedG, 1e-5));
      expect(output[2 * 224 * 224], closeTo(expectedB, 1e-5));
    });

    test('channel-specific normalization (R, G, B have different mean/std)',
        () {
      // Use an image with distinct R, G, B so we can verify each channel
      // independently: R=100, G=150, B=200
      final image = makeUniformImage(224, 224, 100, 150, 200);
      final output = clipPreprocess(image, 224, 224);

      final expectedR = (100 / 255.0 - clipMean[0]) / clipStd[0];
      final expectedG = (150 / 255.0 - clipMean[1]) / clipStd[1];
      final expectedB = (200 / 255.0 - clipMean[2]) / clipStd[2];

      // Check first pixel of each channel
      expect(output[0], closeTo(expectedR, 1e-5));
      expect(output[1 * 224 * 224], closeTo(expectedG, 1e-5));
      expect(output[2 * 224 * 224], closeTo(expectedB, 1e-5));

      // Verify the three channels produce different values
      expect(output[0], isNot(closeTo(output[1 * 224 * 224], 1e-5)));
      expect(
          output[1 * 224 * 224], isNot(closeTo(output[2 * 224 * 224], 1e-5)));
    });
  });

  // ================================================================
  // Group 4: CLIP preprocessing output format
  // ================================================================
  group('CLIP preprocessing output format', () {
    test('output has correct size: 3 * 224 * 224', () {
      final image = makeUniformImage(224, 224, 128, 128, 128);
      final output = clipPreprocess(image, 224, 224);
      expect(output.length, equals(3 * 224 * 224));
    });

    test('NCHW layout: channel 0 = R, channel 1 = G, channel 2 = B', () {
      // R=50, G=100, B=200 -- distinct values per channel
      final image = makeUniformImage(224, 224, 50, 100, 200);
      final output = clipPreprocess(image, 224, 224);

      final expectedR = (50 / 255.0 - clipMean[0]) / clipStd[0];
      final expectedG = (100 / 255.0 - clipMean[1]) / clipStd[1];
      final expectedB = (200 / 255.0 - clipMean[2]) / clipStd[2];

      const planeSize = 224 * 224;

      // Verify multiple pixels across each channel plane
      for (var i = 0; i < 10; i++) {
        final idx = i * 50; // sample at various positions
        if (idx < planeSize) {
          expect(
            output[0 * planeSize + idx],
            closeTo(expectedR, 1e-5),
            reason: 'R channel at index $idx',
          );
          expect(
            output[1 * planeSize + idx],
            closeTo(expectedG, 1e-5),
            reason: 'G channel at index $idx',
          );
          expect(
            output[2 * planeSize + idx],
            closeTo(expectedB, 1e-5),
            reason: 'B channel at index $idx',
          );
        }
      }
    });

    test('uniform color input produces identical values within each channel',
        () {
      final image = makeUniformImage(224, 224, 42, 84, 168);
      final output = clipPreprocess(image, 224, 224);

      const planeSize = 224 * 224;

      // All R-channel values should be the same
      final rVal = output[0];
      for (var i = 1; i < planeSize; i++) {
        expect(
          output[i],
          closeTo(rVal, 1e-6),
          reason: 'R channel pixel $i differs from pixel 0',
        );
      }

      // All G-channel values should be the same
      final gVal = output[planeSize];
      for (var i = 1; i < planeSize; i++) {
        expect(
          output[planeSize + i],
          closeTo(gVal, 1e-6),
          reason: 'G channel pixel $i differs from pixel 0',
        );
      }

      // All B-channel values should be the same
      final bVal = output[2 * planeSize];
      for (var i = 1; i < planeSize; i++) {
        expect(
          output[2 * planeSize + i],
          closeTo(bVal, 1e-6),
          reason: 'B channel pixel $i differs from pixel 0',
        );
      }
    });
  });

  // ================================================================
  // Group 5: CLIP preprocessing vs letterbox
  // ================================================================
  group('CLIP preprocessing vs letterbox', () {
    test('CLIP uses center crop, not letterbox (padding)', () {
      // For a 640x480 landscape image:
      // CLIP: scale shorter side to 224, then center crop the longer side
      // Letterbox: scale to fit inside target, then pad shorter side
      final clipParams = clipPreprocessParams(640, 480);

      // CLIP resizes so shorter side (480) becomes 224
      // resizedW > 224, resizedH = 224
      expect(clipParams.resizedH, equals(224));
      expect(clipParams.resizedW, greaterThan(224));
      // Crops the wider dimension (no padding, just cropping)
      expect(clipParams.cropX, greaterThan(0));
      expect(clipParams.cropY, equals(0));

      // Letterbox would do the opposite: scale = min(target/640, target/480)
      // which makes the image fit inside target, then pads.
      // We verify CLIP does NOT pad by checking that the crop offsets are
      // positive (meaning content is removed, not added).
      // For letterbox at 640x480 -> target 224:
      // letterbox scale = min(224/640, 224/480) = 224/640 = 0.35
      // letterbox newW = round(640 * 0.35) = 224, newH = round(480 * 0.35) = 168
      // That would pad height, NOT crop width.
      final letterboxScale = min(224 / 640, 224 / 480);
      final letterboxNewW = (640 * letterboxScale).round();
      final letterboxNewH = (480 * letterboxScale).round();

      // Letterbox fits within target, so at least one dimension < 224
      expect(letterboxNewH, lessThan(224));
      // CLIP never pads -- both dimensions >= 224 after resize
      expect(clipParams.resizedW, greaterThanOrEqualTo(224));
      expect(clipParams.resizedH, greaterThanOrEqualTo(224));
      // Confirm they use different approaches
      expect(letterboxNewW, isNot(equals(clipParams.resizedW)));
      expect(letterboxNewH, isNot(equals(clipParams.resizedH)));
    });

    test('CLIP output size is always 3*224*224', () {
      // Regardless of input dimensions, CLIP produces 3*224*224
      final image = makeUniformImage(640, 480, 128, 128, 128);
      final output = clipPreprocess(image, 640, 480);
      expect(output.length, equals(3 * 224 * 224));
    });

    test('letterbox and CLIP produce different output sizes for same target',
        () {
      // CLIP always outputs 224x224 (its fixed input size)
      // Letterbox outputs targetSize x targetSize (configurable, typically 640)
      // For the same image, the preprocessing approaches differ fundamentally:
      // - CLIP = resize shorter side to 224 + center crop
      // - letterbox = resize to fit in target + pad with gray

      // CLIP output: 3 * 224 * 224
      final clipOutput = clipPreprocess(
        makeUniformImage(640, 480, 128, 128, 128),
        640,
        480,
      );
      expect(clipOutput.length, equals(3 * clipInputSize * clipInputSize));

      // A letterbox for target=640 would produce 3 * 640 * 640
      // We can verify the size difference without running letterbox:
      const letterboxTarget = 640;
      const letterboxOutputSize = 3 * letterboxTarget * letterboxTarget;
      expect(clipOutput.length, isNot(equals(letterboxOutputSize)));
    });
  });

  // ================================================================
  // Group 6: Embedding dimension
  // ================================================================
  group('Embedding dimension', () {
    test('embedding dimension constant is 512', () {
      expect(embeddingDim, equals(512));
    });

    test('simulated embedding has length 512', () {
      // Simulate what ONNXBindings._simulateEmbedding does
      final random = Random(42);
      final embedding =
          List.generate(embeddingDim, (_) => random.nextDouble() * 2 - 1);
      final normalized = l2Normalize(embedding);

      expect(normalized.length, equals(512));
    });

    test('simulated embedding is L2-normalized (norm close to 1.0)', () {
      final random = Random(42);
      final embedding =
          List.generate(embeddingDim, (_) => random.nextDouble() * 2 - 1);
      final normalized = l2Normalize(embedding);

      expect(vectorNorm(normalized), closeTo(1.0, 1e-10));
    });
  });
}
