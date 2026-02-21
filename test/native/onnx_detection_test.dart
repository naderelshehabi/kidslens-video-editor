import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/region_temporal_aggregator.dart';

// =============================================================================
// Reimplemented algorithms from onnx_bindings.dart for direct testing.
// These mirror the private _letterbox and _unmapCoordinates methods.
// =============================================================================

/// Letterbox computation (matching onnx_bindings.dart logic).
///
/// Computes the scale factor, new dimensions, and padding needed to
/// fit [srcW] x [srcH] into a [targetSize] x [targetSize] square
/// while preserving the aspect ratio.
({double scale, double padX, double padY, int newW, int newH}) computeLetterbox(
  int srcW,
  int srcH,
  int targetSize,
) {
  final scale = min(targetSize / srcW, targetSize / srcH);
  final newW = (srcW * scale).round();
  final newH = (srcH * scale).round();
  final padX = (targetSize - newW) / 2.0;
  final padY = (targetSize - newH) / 2.0;
  return (scale: scale, padX: padX, padY: padY, newW: newW, newH: newH);
}

/// Coordinate un-mapping (matching onnx_bindings.dart logic).
///
/// Takes a [DetectionBox] whose x/y/width/height are normalized to [0,1]
/// in letterboxed input space, removes padding and scale, then normalizes
/// to [0,1] in the original image space.  Clamps to valid bounds.
DetectionBox unmapCoordinates(
  DetectionBox box,
  double padX,
  double padY,
  double scale,
  int origW,
  int origH,
  int inputSize,
) {
  // Convert from normalized-input-size space to original pixel space
  final cx = (box.x * inputSize - padX) / scale;
  final cy = (box.y * inputSize - padY) / scale;
  final w = box.width * inputSize / scale;
  final h = box.height * inputSize / scale;

  // Normalize to [0, 1] relative to original image size
  var nx = cx / origW;
  var ny = cy / origH;
  var nw = w / origW;
  var nh = h / origH;

  // Clamp to valid [0, 1] range
  nx = nx.clamp(0.0, 1.0);
  ny = ny.clamp(0.0, 1.0);
  nw = nw.clamp(0.0, 1.0 - nx);
  nh = nh.clamp(0.0, 1.0 - ny);

  return DetectionBox(
    classId: box.classId,
    className: box.className,
    confidence: box.confidence,
    x: nx,
    y: ny,
    width: nw,
    height: nh,
  );
}

// =============================================================================
// Tests
// =============================================================================

void main() {
  // ---------------------------------------------------------------------------
  // 1. Letterbox scale and padding calculations
  // ---------------------------------------------------------------------------
  group('Letterbox scale and padding calculations', () {
    test('square image (640x640) into 640 target produces no padding', () {
      final r = computeLetterbox(640, 640, 640);
      expect(r.scale, closeTo(1.0, 1e-6));
      expect(r.newW, 640);
      expect(r.newH, 640);
      expect(r.padX, closeTo(0.0, 1e-6));
      expect(r.padY, closeTo(0.0, 1e-6));
    });

    test('portrait video (1080x1920) into 640 target has horizontal padding', () {
      // scale = min(640/1080, 640/1920) = 640/1920 = 0.33333...
      final r = computeLetterbox(1080, 1920, 640);
      expect(r.scale, closeTo(640.0 / 1920.0, 1e-6));
      expect(r.newW, 360);
      expect(r.newH, 640);
      expect(r.padX, closeTo(140.0, 1e-6));
      expect(r.padY, closeTo(0.0, 1e-6));
    });

    test('ultra-wide (2560x1080) into 640 target has vertical padding', () {
      // scale = min(640/2560, 640/1080) = 640/2560 = 0.25
      final r = computeLetterbox(2560, 1080, 640);
      expect(r.scale, closeTo(0.25, 1e-6));
      expect(r.newW, 640);
      expect(r.newH, 270);
      expect(r.padX, closeTo(0.0, 1e-6));
      expect(r.padY, closeTo(185.0, 1e-6));
    });

    test('landscape (1920x1080) into 640 target has vertical padding', () {
      // scale = min(640/1920, 640/1080) = 640/1920 = 0.33333...
      final r = computeLetterbox(1920, 1080, 640);
      expect(r.scale, closeTo(640.0 / 1920.0, 1e-6));
      expect(r.newW, 640);
      expect(r.newH, 360);
      expect(r.padX, closeTo(0.0, 1e-6));
      expect(r.padY, closeTo(140.0, 1e-6));
    });

    test('small image (100x50) into 640 target upscales correctly', () {
      // scale = min(640/100, 640/50) = 640/100 = 6.4
      final r = computeLetterbox(100, 50, 640);
      expect(r.scale, closeTo(6.4, 1e-6));
      expect(r.newW, 640);
      expect(r.newH, 320);
      expect(r.padX, closeTo(0.0, 1e-6));
      expect(r.padY, closeTo(160.0, 1e-6));
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Coordinate un-mapping
  // ---------------------------------------------------------------------------
  group('Coordinate un-mapping', () {
    test('square image: box at center of input maps to center of output', () {
      // Square image (640x640) into 640 target -- no padding, scale=1.0
      const inputSize = 640;
      const origW = 640;
      const origH = 640;

      final lb = computeLetterbox(origW, origH, inputSize);

      // Box at center: normalized (0.25, 0.25, 0.5, 0.5) in input space
      const box = DetectionBox(
        classId: 0,
        className: 'person',
        confidence: 0.9,
        x: 0.25,
        y: 0.25,
        width: 0.5,
        height: 0.5,
      );

      final result = unmapCoordinates(
        box, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      expect(result.x, closeTo(0.25, 1e-6));
      expect(result.y, closeTo(0.25, 1e-6));
      expect(result.width, closeTo(0.5, 1e-6));
      expect(result.height, closeTo(0.5, 1e-6));
    });

    test('portrait video: correctly accounts for horizontal padding', () {
      // Portrait (1080x1920) into 640: scale=640/1920, padX=140, padY=0
      const inputSize = 640;
      const origW = 1080;
      const origH = 1920;

      final lb = computeLetterbox(origW, origH, inputSize);
      expect(lb.padX, closeTo(140.0, 1e-6));
      expect(lb.padY, closeTo(0.0, 1e-6));

      // A box centered in the letterboxed image at (0.5, 0.5) in normalized input coords
      // should map to the center of the original image
      const box = DetectionBox(
        classId: 0,
        className: 'person',
        confidence: 0.85,
        x: 0.5,
        y: 0.5,
        width: 0.1,
        height: 0.1,
      );

      final result = unmapCoordinates(
        box, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // cx = (0.5 * 640 - 140) / (640/1920) = (320 - 140) / 0.3333 = 540
      // ny = 540 / 1080 = 0.5
      // cy = (0.5 * 640 - 0) / (640/1920) = 320 / 0.3333 = 960
      // ny_y = 960 / 1920 = 0.5
      expect(result.x, closeTo(0.5, 1e-3));
      expect(result.y, closeTo(0.5, 1e-3));
    });

    test('landscape: correctly accounts for vertical padding', () {
      // Landscape (1920x1080) into 640: scale=640/1920, padX=0, padY=140
      const inputSize = 640;
      const origW = 1920;
      const origH = 1080;

      final lb = computeLetterbox(origW, origH, inputSize);
      expect(lb.padX, closeTo(0.0, 1e-6));
      expect(lb.padY, closeTo(140.0, 1e-6));

      // Box centered in letterbox space
      const box = DetectionBox(
        classId: 1,
        className: 'car',
        confidence: 0.7,
        x: 0.5,
        y: 0.5,
        width: 0.2,
        height: 0.2,
      );

      final result = unmapCoordinates(
        box, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // cx = (0.5 * 640 - 0) / scale = 320 / (640/1920) = 960
      // nx = 960 / 1920 = 0.5
      // cy = (0.5 * 640 - 140) / scale = 180 / (640/1920) = 540
      // ny = 540 / 1080 = 0.5
      expect(result.x, closeTo(0.5, 1e-3));
      expect(result.y, closeTo(0.5, 1e-3));
    });

    test('edge detection near image bounds is clamped correctly', () {
      // Landscape (1920x1080) into 640: padX=0, padY=140
      const inputSize = 640;
      const origW = 1920;
      const origH = 1080;

      final lb = computeLetterbox(origW, origH, inputSize);

      // Box at very bottom-right of the actual image area in letterbox space
      // The image area in letterbox is x=[0, 640], y=[140, 500]
      // Normalized: x ~ 1.0, y ~ 500/640 ~ 0.78125
      const box = DetectionBox(
        classId: 0,
        className: 'person',
        confidence: 0.6,
        x: 0.95,
        y: 0.75,
        width: 0.1,
        height: 0.1,
      );

      final result = unmapCoordinates(
        box, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // x and y should be in [0, 1]
      expect(result.x, greaterThanOrEqualTo(0.0));
      expect(result.x, lessThanOrEqualTo(1.0));
      expect(result.y, greaterThanOrEqualTo(0.0));
      expect(result.y, lessThanOrEqualTo(1.0));
      // width + x <= 1.0
      expect(result.x + result.width, lessThanOrEqualTo(1.0 + 1e-9));
      // height + y <= 1.0
      expect(result.y + result.height, lessThanOrEqualTo(1.0 + 1e-9));
    });

    test('box at (0, 0) is correctly un-mapped', () {
      // Portrait (1080x1920) into 640: padX=140, padY=0
      const inputSize = 640;
      const origW = 1080;
      const origH = 1920;

      final lb = computeLetterbox(origW, origH, inputSize);

      const box = DetectionBox(
        classId: 0,
        className: 'face',
        confidence: 0.95,
        x: 0,
        y: 0,
        width: 0.1,
        height: 0.1,
      );

      final result = unmapCoordinates(
        box, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // cx = (0.0 * 640 - 140) / scale = -140 / 0.3333 = -420
      // nx = -420 / 1080 < 0 => clamped to 0.0
      expect(result.x, closeTo(0.0, 1e-6));
      expect(result.y, closeTo(0.0, 1e-6));
      // Width should still be valid and > 0 (subject to clamping)
      expect(result.width, greaterThanOrEqualTo(0.0));
      expect(result.height, greaterThanOrEqualTo(0.0));
    });

    test('box partially in padding area is clamped to 0', () {
      // Portrait (1080x1920) into 640: padX=140, padY=0
      // The actual image spans x=[140, 500] out of [0, 640] in letterbox space
      const inputSize = 640;
      const origW = 1080;
      const origH = 1920;

      final lb = computeLetterbox(origW, origH, inputSize);

      // Box starts inside left padding at x = 100/640 ≈ 0.15625
      // padX is 140, so this is within the padding zone
      const box = DetectionBox(
        classId: 2,
        className: 'weapon',
        confidence: 0.4,
        x: 100.0 / 640.0,
        y: 0.3,
        width: 0.15,
        height: 0.15,
      );

      final result = unmapCoordinates(
        box, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // cx = (100 - 140) / scale = -40 / 0.3333 = -120 => negative => clamped to 0
      expect(result.x, closeTo(0.0, 1e-6));
      expect(result.y, greaterThanOrEqualTo(0.0));
      // The width should be reduced because x was clamped
      expect(result.width, greaterThanOrEqualTo(0.0));
      expect(result.x + result.width, lessThanOrEqualTo(1.0 + 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Edge detection + 10% padding with re-clamping
  //    Using TrackedRegion.padAndClamp from region_temporal_aggregator.dart
  // ---------------------------------------------------------------------------
  group('Edge detection + 10% padding with re-clamping', () {
    test('box at edge needs padding clamped to [0, 1]', () {
      // A box near the left edge: x=0.02, y=0.3, w=0.2, h=0.3
      // padX = 0.2 * 0.10 = 0.02 => new x = 0.02 - 0.02 = 0.0
      // padY = 0.3 * 0.10 = 0.03 => new y = 0.3 - 0.03 = 0.27
      final padded = TrackedRegion.padAndClamp(0.02, 0.3, 0.2, 0.3);

      expect(padded.x, greaterThanOrEqualTo(0.0));
      expect(padded.y, greaterThanOrEqualTo(0.0));
      expect(padded.x + padded.width, lessThanOrEqualTo(1.0 + 1e-9));
      expect(padded.y + padded.height, lessThanOrEqualTo(1.0 + 1e-9));
      // The width should be larger than original (or equal due to clamping)
      expect(padded.width, greaterThanOrEqualTo(0.2));
    });

    test('box near corner padded and clamped', () {
      // Box near top-left: x=0.0, y=0.0, w=0.1, h=0.1
      // padX = 0.1 * 0.1 = 0.01 => new x = -0.01 => clamped to 0
      // padY = 0.1 * 0.1 = 0.01 => new y = -0.01 => clamped to 0
      final padded = TrackedRegion.padAndClamp(0, 0, 0.1, 0.1);

      expect(padded.x, closeTo(0.0, 1e-9));
      expect(padded.y, closeTo(0.0, 1e-9));
      // Width should be expanded: 0.1 + 2*0.01 = 0.12
      // but x was clamped from -0.01 to 0.0, so width stays 0.12
      expect(padded.width, closeTo(0.12, 1e-9));
      expect(padded.height, closeTo(0.12, 1e-9));
    });

    test('box near bottom-right corner padded and clamped', () {
      // Box near bottom-right: x=0.85, y=0.85, w=0.15, h=0.15
      // padX = 0.15 * 0.1 = 0.015 => new x = 0.835, new w = 0.18
      // x + w = 0.835 + 0.18 = 1.015 => w clamped to 1.0 - 0.835 = 0.165
      final padded = TrackedRegion.padAndClamp(0.85, 0.85, 0.15, 0.15);

      expect(padded.x, greaterThanOrEqualTo(0.0));
      expect(padded.y, greaterThanOrEqualTo(0.0));
      expect(padded.x + padded.width, lessThanOrEqualTo(1.0 + 1e-9));
      expect(padded.y + padded.height, lessThanOrEqualTo(1.0 + 1e-9));
    });

    test('large box padding does not exceed 1.0', () {
      // Large box: x=0.0, y=0.0, w=0.95, h=0.95
      // padX = 0.95 * 0.1 = 0.095 => new x = -0.095 => 0.0
      // new w = 0.95 + 0.19 = 1.14 => clamped to min(1.14, 1.0 - 0.0) = 1.0
      final padded = TrackedRegion.padAndClamp(0, 0, 0.95, 0.95);

      expect(padded.x, closeTo(0.0, 1e-9));
      expect(padded.y, closeTo(0.0, 1e-9));
      expect(padded.width, lessThanOrEqualTo(1.0 + 1e-9));
      expect(padded.height, lessThanOrEqualTo(1.0 + 1e-9));
    });

    test('centered box expands symmetrically', () {
      // Box at center: x=0.4, y=0.4, w=0.2, h=0.2
      // padX = 0.2 * 0.1 = 0.02 => new x = 0.38, new w = 0.24
      // padY = 0.2 * 0.1 = 0.02 => new y = 0.38, new h = 0.24
      final padded = TrackedRegion.padAndClamp(0.4, 0.4, 0.2, 0.2);

      expect(padded.x, closeTo(0.38, 1e-9));
      expect(padded.y, closeTo(0.38, 1e-9));
      expect(padded.width, closeTo(0.24, 1e-9));
      expect(padded.height, closeTo(0.24, 1e-9));
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Full pipeline verification
  // ---------------------------------------------------------------------------
  group('Full pipeline verification', () {
    test('portrait video detection at letterbox coordinates un-maps correctly', () {
      // Portrait (1080x1920) -> 640 letterbox
      const inputSize = 640;
      const origW = 1080;
      const origH = 1920;

      final lb = computeLetterbox(origW, origH, inputSize);
      // scale = 640/1920 ≈ 0.33333, padX = 140, padY = 0

      // Detection in letterbox pixel space at center: pixel (320, 320)
      // Normalized in input: (320/640, 320/640) = (0.5, 0.5)
      // Size in letterbox: 64x128 pixels => normalized (64/640, 128/640) = (0.1, 0.2)
      const detectionBox = DetectionBox(
        classId: 0,
        className: 'person',
        confidence: 0.88,
        x: 0.5,
        y: 0.5,
        width: 0.1,
        height: 0.2,
      );

      final unmapped = unmapCoordinates(
        detectionBox, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // cx = (0.5*640 - 140) / (640/1920) = 180 / 0.33333 = 540
      // cy = (0.5*640 - 0) / (640/1920)   = 320 / 0.33333 = 960
      // w  = 0.1*640 / (640/1920)          = 64 / 0.33333  = 192
      // h  = 0.2*640 / (640/1920)          = 128 / 0.33333 = 384
      // nx = 540/1080 = 0.5, ny = 960/1920 = 0.5
      // nw = 192/1080 ≈ 0.1778, nh = 384/1920 = 0.2
      expect(unmapped.x, closeTo(0.5, 1e-3));
      expect(unmapped.y, closeTo(0.5, 1e-3));
      expect(unmapped.width, closeTo(192.0 / 1080.0, 1e-3));
      expect(unmapped.height, closeTo(0.2, 1e-3));
      expect(unmapped.confidence, 0.88);
      expect(unmapped.className, 'person');
    });

    test('ultra-wide video detection un-maps correctly', () {
      // Ultra-wide (2560x1080) -> 640: scale=0.25, padX=0, padY=185
      const inputSize = 640;
      const origW = 2560;
      const origH = 1080;

      final lb = computeLetterbox(origW, origH, inputSize);
      expect(lb.scale, closeTo(0.25, 1e-6));
      expect(lb.padX, closeTo(0.0, 1e-6));
      expect(lb.padY, closeTo(185.0, 1e-6));

      // Detection at normalized (0.5, 0.5) in input space, size (0.15, 0.1)
      const detectionBox = DetectionBox(
        classId: 1,
        className: 'knife',
        confidence: 0.72,
        x: 0.5,
        y: 0.5,
        width: 0.15,
        height: 0.1,
      );

      final unmapped = unmapCoordinates(
        detectionBox, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // cx = (0.5*640 - 0) / 0.25   = 320 / 0.25 = 1280
      // cy = (0.5*640 - 185) / 0.25  = 135 / 0.25 = 540
      // w  = 0.15*640 / 0.25         = 96 / 0.25  = 384
      // h  = 0.1*640 / 0.25          = 64 / 0.25  = 256
      // nx = 1280/2560 = 0.5, ny = 540/1080 = 0.5
      // nw = 384/2560 = 0.15, nh = 256/1080 ≈ 0.2370
      expect(unmapped.x, closeTo(0.5, 1e-3));
      expect(unmapped.y, closeTo(0.5, 1e-3));
      expect(unmapped.width, closeTo(0.15, 1e-3));
      expect(unmapped.height, closeTo(256.0 / 1080.0, 1e-3));
      expect(unmapped.className, 'knife');
    });

    test('detection at very edge of input is clamped properly', () {
      // Landscape (1920x1080) -> 640: scale=640/1920, padX=0, padY=140
      const inputSize = 640;
      const origW = 1920;
      const origH = 1080;

      final lb = computeLetterbox(origW, origH, inputSize);

      // Box that extends beyond the actual image area (into the gray padding)
      // Normalized (0.0, 0.0) in input space -- this is in the top padding
      const detectionBox = DetectionBox(
        classId: 0,
        className: 'gun',
        confidence: 0.55,
        x: 0,
        y: 0,
        width: 0.05,
        height: 0.05,
      );

      final unmapped = unmapCoordinates(
        detectionBox, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // cx = (0 - 0) / scale = 0 => nx = 0
      // cy = (0 - 140) / scale = negative => clamped to 0
      expect(unmapped.x, closeTo(0.0, 1e-6));
      expect(unmapped.y, closeTo(0.0, 1e-6));
      expect(unmapped.width, greaterThanOrEqualTo(0.0));
      expect(unmapped.height, greaterThanOrEqualTo(0.0));
      expect(unmapped.x + unmapped.width, lessThanOrEqualTo(1.0 + 1e-9));
      expect(unmapped.y + unmapped.height, lessThanOrEqualTo(1.0 + 1e-9));
    });

    test('full pipeline: letterbox -> detect -> unmap -> pad for portrait', () {
      // End-to-end: Portrait 1080x1920 -> letterbox -> detection -> unmap -> padAndClamp
      const inputSize = 640;
      const origW = 1080;
      const origH = 1920;

      final lb = computeLetterbox(origW, origH, inputSize);

      // Simulate a detection at letterbox pixel (250, 200) with size 80x100
      // Normalized: x = 250/640, y = 200/640, w = 80/640, h = 100/640
      const detectionBox = DetectionBox(
        classId: 0,
        className: 'person',
        confidence: 0.92,
        x: 250.0 / 640.0,
        y: 200.0 / 640.0,
        width: 80.0 / 640.0,
        height: 100.0 / 640.0,
      );

      // Step 1: Un-map from letterbox coords to original image coords
      final unmapped = unmapCoordinates(
        detectionBox, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // Verify un-mapped coordinates are in valid range
      expect(unmapped.x, greaterThanOrEqualTo(0.0));
      expect(unmapped.y, greaterThanOrEqualTo(0.0));
      expect(unmapped.x + unmapped.width, lessThanOrEqualTo(1.0 + 1e-9));
      expect(unmapped.y + unmapped.height, lessThanOrEqualTo(1.0 + 1e-9));

      // Step 2: Apply 10% padding
      final padded = TrackedRegion.padAndClamp(
        unmapped.x,
        unmapped.y,
        unmapped.width,
        unmapped.height,
      );

      // Verify padded coordinates are in valid range
      expect(padded.x, greaterThanOrEqualTo(0.0));
      expect(padded.y, greaterThanOrEqualTo(0.0));
      expect(padded.x + padded.width, lessThanOrEqualTo(1.0 + 1e-9));
      expect(padded.y + padded.height, lessThanOrEqualTo(1.0 + 1e-9));

      // Padded region should be larger than un-mapped (or equal if clamped)
      expect(padded.width, greaterThanOrEqualTo(unmapped.width - 1e-9));
      expect(padded.height, greaterThanOrEqualTo(unmapped.height - 1e-9));
    });

    test('full pipeline: ultra-wide -> detect at right edge -> clamp', () {
      // Ultra-wide (2560x1080) -> 640 target
      const inputSize = 640;
      const origW = 2560;
      const origH = 1080;

      final lb = computeLetterbox(origW, origH, inputSize);

      // Detection at extreme right of letterbox: pixel (620, 400)
      const detectionBox = DetectionBox(
        classId: 3,
        className: 'blood',
        confidence: 0.65,
        x: 620.0 / 640.0,
        y: 400.0 / 640.0,
        width: 30.0 / 640.0,
        height: 40.0 / 640.0,
      );

      final unmapped = unmapCoordinates(
        detectionBox, lb.padX, lb.padY, lb.scale, origW, origH, inputSize,
      );

      // x should be near the right edge of the original image
      expect(unmapped.x, greaterThan(0.9));
      expect(unmapped.x, lessThanOrEqualTo(1.0));
      // Width must not push past 1.0
      expect(unmapped.x + unmapped.width, lessThanOrEqualTo(1.0 + 1e-9));
      // y should be reasonable
      expect(unmapped.y, greaterThanOrEqualTo(0.0));
      expect(unmapped.y + unmapped.height, lessThanOrEqualTo(1.0 + 1e-9));
    });
  });
}
