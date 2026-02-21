import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';

// ============ Reimplemented NMS algorithm for testing ============

/// Compute Intersection over Union between two detection boxes.
///
/// Reimplemented from ONNXBindings._computeIoU for direct unit testing.
double computeIoU(DetectionBox a, DetectionBox b) {
  final x1 = max(a.x, b.x);
  final y1 = max(a.y, b.y);
  final x2 = min(a.x + a.width, b.x + b.width);
  final y2 = min(a.y + a.height, b.y + b.height);

  final intersectionW = max(0, x2 - x1);
  final intersectionH = max(0, y2 - y1);
  final intersection = intersectionW * intersectionH;

  final areaA = a.width * a.height;
  final areaB = b.width * b.height;
  final union = areaA + areaB - intersection;

  if (union <= 0) return 0;
  return intersection / union;
}

/// Per-class non-maximum suppression.
///
/// Reimplemented from ONNXBindings._nonMaxSuppression for direct unit testing.
List<DetectionBox> nonMaxSuppression(
  List<DetectionBox> boxes,
  double iouThreshold,
) {
  if (boxes.isEmpty) return [];

  // Group by class
  final byClass = <int, List<DetectionBox>>{};
  for (final box in boxes) {
    byClass.putIfAbsent(box.classId, () => []).add(box);
  }

  final result = <DetectionBox>[];

  for (final classBoxes in byClass.values) {
    // Sort by confidence descending
    classBoxes.sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <DetectionBox>[];
    final suppressed = List.filled(classBoxes.length, false);

    for (var i = 0; i < classBoxes.length; i++) {
      if (suppressed[i]) continue;
      kept.add(classBoxes[i]);

      for (var j = i + 1; j < classBoxes.length; j++) {
        if (suppressed[j]) continue;
        if (computeIoU(classBoxes[i], classBoxes[j]) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    result.addAll(kept);
  }

  return result;
}

// ============ Helper ============

/// Create a DetectionBox with sensible defaults for concise test code.
DetectionBox makeBox({
  int classId = 0,
  String className = 'class0',
  double confidence = 0.9,
  double x = 0.0,
  double y = 0.0,
  double width = 0.1,
  double height = 0.1,
}) =>
    DetectionBox(
      classId: classId,
      className: className,
      confidence: confidence,
      x: x,
      y: y,
      width: width,
      height: height,
    );

// ============ Tests ============

void main() {
  // ------------------------------------------------------------------
  // 1. IoU computation
  // ------------------------------------------------------------------
  group('IoU computation', () {
    test('identical boxes should return IoU = 1.0', () {
      final a = makeBox(x: 0.1, y: 0.1, width: 0.5, height: 0.5);
      final b = makeBox(x: 0.1, y: 0.1, width: 0.5, height: 0.5);
      expect(computeIoU(a, b), closeTo(1.0, 1e-9));
    });

    test('non-overlapping boxes should return IoU = 0.0', () {
      final a = makeBox();
      final b = makeBox(x: 0.5, y: 0.5);
      expect(computeIoU(a, b), 0.0);
    });

    test('partially overlapping boxes should return correct IoU', () {
      // Box A: (0, 0) to (0.4, 0.4), area = 0.16
      // Box B: (0.2, 0.2) to (0.6, 0.6), area = 0.16
      // Intersection: (0.2, 0.2) to (0.4, 0.4), area = 0.04
      // Union: 0.16 + 0.16 - 0.04 = 0.28
      // IoU: 0.04 / 0.28 = 1/7
      final a = makeBox(width: 0.4, height: 0.4);
      final b = makeBox(x: 0.2, y: 0.2, width: 0.4, height: 0.4);
      expect(computeIoU(a, b), closeTo(1.0 / 7.0, 1e-9));
    });

    test('box fully contained within another should return correct IoU', () {
      // Outer: (0.0, 0.0) to (1.0, 1.0), area = 1.0
      // Inner: (0.25, 0.25) to (0.75, 0.75), area = 0.25
      // Intersection = inner area = 0.25
      // Union = 1.0 + 0.25 - 0.25 = 1.0
      // IoU = 0.25 / 1.0 = 0.25
      final outer = makeBox(width: 1, height: 1);
      final inner = makeBox(x: 0.25, y: 0.25, width: 0.5, height: 0.5);
      expect(computeIoU(outer, inner), closeTo(0.25, 1e-9));
    });

    test('zero-size box should return IoU = 0.0', () {
      final a = makeBox(x: 0.5, y: 0.5, width: 0, height: 0);
      final b = makeBox(x: 0.5, y: 0.5, width: 0.3, height: 0.3);
      expect(computeIoU(a, b), 0.0);
    });

    test('adjacent boxes (touching edges, not overlapping) should return IoU = 0.0', () {
      // Box A ends at x = 0.5, Box B starts at x = 0.5
      final a = makeBox(width: 0.5, height: 0.5);
      final b = makeBox(x: 0.5, width: 0.5, height: 0.5);
      // Intersection width = max(0, min(0.5, 1.0) - max(0.0, 0.5)) = max(0, 0.0) = 0.0
      expect(computeIoU(a, b), 0.0);
    });

    test('symmetry: IoU(a, b) == IoU(b, a)', () {
      final a = makeBox(width: 0.3, height: 0.4);
      final b = makeBox(x: 0.1, y: 0.1, width: 0.5, height: 0.5);
      expect(computeIoU(a, b), closeTo(computeIoU(b, a), 1e-9));
    });
  });

  // ------------------------------------------------------------------
  // 2. Per-class NMS
  // ------------------------------------------------------------------
  group('Per-class NMS', () {
    test('empty input should return empty output', () {
      final result = nonMaxSuppression([], 0.45);
      expect(result, isEmpty);
    });

    test('single box should be returned as-is', () {
      final box = makeBox(confidence: 0.8);
      final result = nonMaxSuppression([box], 0.45);
      expect(result, hasLength(1));
      expect(result.first.confidence, 0.8);
    });

    test('two overlapping boxes of same class should keep higher confidence', () {
      // Nearly identical boxes, high overlap
      final highConf = makeBox(
        className: 'person',
        confidence: 0.95,
        x: 0.1,
        y: 0.1,
        width: 0.5,
        height: 0.5,
      );
      final lowConf = makeBox(
        className: 'person',
        confidence: 0.6,
        x: 0.12,
        y: 0.12,
        width: 0.5,
        height: 0.5,
      );

      final result = nonMaxSuppression([lowConf, highConf], 0.45);
      expect(result, hasLength(1));
      expect(result.first.confidence, 0.95);
    });

    test('two overlapping boxes of different classes should both be kept', () {
      final person = makeBox(
        className: 'person',
        x: 0.1,
        y: 0.1,
        width: 0.5,
        height: 0.5,
      );
      final cat = makeBox(
        classId: 1,
        className: 'cat',
        confidence: 0.85,
        x: 0.1,
        y: 0.1,
        width: 0.5,
        height: 0.5,
      );

      final result = nonMaxSuppression([person, cat], 0.45);
      expect(result, hasLength(2));
    });

    test('three boxes with two overlapping should suppress correct one', () {
      // Box A and Box B overlap heavily; Box C is separate
      final boxA = makeBox(
        x: 0.1,
        y: 0.1,
        width: 0.4,
        height: 0.4,
      );
      final boxB = makeBox(
        confidence: 0.7,
        x: 0.12,
        y: 0.12,
        width: 0.4,
        height: 0.4,
      );
      final boxC = makeBox(
        confidence: 0.8,
        x: 0.8,
        y: 0.8,
      );

      final result = nonMaxSuppression([boxB, boxC, boxA], 0.45);
      // Expect boxA (0.9) kept, boxB (0.7) suppressed by boxA, boxC (0.8) kept
      expect(result, hasLength(2));
      final confidences = result.map((b) => b.confidence).toSet();
      expect(confidences, contains(0.9));
      expect(confidences, contains(0.8));
      expect(confidences, isNot(contains(0.7)));
    });

    test('multiple classes each with overlaps should apply per-class suppression', () {
      // Class 0: two overlapping boxes
      final c0High = makeBox(
        className: 'person',
        confidence: 0.95,
        x: 0.1,
        y: 0.1,
        width: 0.4,
        height: 0.4,
      );
      final c0Low = makeBox(
        className: 'person',
        confidence: 0.5,
        x: 0.12,
        y: 0.12,
        width: 0.4,
        height: 0.4,
      );
      // Class 1: two overlapping boxes
      final c1High = makeBox(
        classId: 1,
        className: 'car',
        confidence: 0.88,
        x: 0.5,
        y: 0.5,
        width: 0.3,
        height: 0.3,
      );
      final c1Low = makeBox(
        classId: 1,
        className: 'car',
        confidence: 0.55,
        x: 0.52,
        y: 0.52,
        width: 0.3,
        height: 0.3,
      );

      final result =
          nonMaxSuppression([c0Low, c1Low, c0High, c1High], 0.45);
      // Each class should keep only the higher-confidence box
      expect(result, hasLength(2));
      final confidences = result.map((b) => b.confidence).toSet();
      expect(confidences, contains(0.95));
      expect(confidences, contains(0.88));
    });

    test('non-overlapping boxes of same class should all be kept', () {
      final boxA = makeBox(
        
      );
      final boxB = makeBox(
        confidence: 0.8,
        x: 0.5,
        y: 0.5,
      );
      final boxC = makeBox(
        confidence: 0.7,
        x: 0.9,
      );

      final result = nonMaxSuppression([boxA, boxB, boxC], 0.45);
      expect(result, hasLength(3));
    });
  });

  // ------------------------------------------------------------------
  // 3. NMS edge cases
  // ------------------------------------------------------------------
  group('NMS edge cases', () {
    test('all identical boxes should keep only the one with highest confidence', () {
      final boxes = List.generate(
        5,
        (i) => makeBox(
          confidence: 0.9 - i * 0.1, // 0.9, 0.8, 0.7, 0.6, 0.5
          x: 0.2,
          y: 0.2,
          width: 0.3,
          height: 0.3,
        ),
      );

      final result = nonMaxSuppression(boxes, 0.45);
      expect(result, hasLength(1));
      expect(result.first.confidence, 0.9);
    });

    test('IoU exactly at threshold should NOT be suppressed (strict >)', () {
      // We need two boxes whose IoU is exactly the threshold.
      // Two identical boxes have IoU = 1.0. Use threshold = 1.0:
      // IoU = 1.0 is NOT > 1.0, so both should be kept.
      final boxA = makeBox(
        width: 0.5,
        height: 0.5,
      );
      final boxB = makeBox(
        confidence: 0.8,
        width: 0.5,
        height: 0.5,
      );

      // At threshold 1.0, IoU = 1.0 is NOT > 1.0, so nothing is suppressed
      final result = nonMaxSuppression([boxA, boxB], 1);
      expect(result, hasLength(2));
    });

    test('IoU slightly above threshold should be suppressed', () {
      // Two identical boxes have IoU = 1.0
      // With threshold 0.45, IoU = 1.0 > 0.45, so lower confidence is suppressed
      final boxA = makeBox(
        width: 0.5,
        height: 0.5,
      );
      final boxB = makeBox(
        confidence: 0.8,
        width: 0.5,
        height: 0.5,
      );

      final result = nonMaxSuppression([boxA, boxB], 0.45);
      expect(result, hasLength(1));
      expect(result.first.confidence, 0.9);
    });

    test('boxes are sorted by confidence descending and highest is kept', () {
      // Feed boxes in reverse confidence order to verify sorting works
      final boxes = [
        makeBox(confidence: 0.3, x: 0.1, y: 0.1, width: 0.4, height: 0.4),
        makeBox(confidence: 0.5, x: 0.12, y: 0.12, width: 0.4, height: 0.4),
        makeBox(confidence: 0.95, x: 0.11, y: 0.11, width: 0.4, height: 0.4),
      ];

      final result = nonMaxSuppression(boxes, 0.45);
      expect(result, hasLength(1));
      expect(result.first.confidence, 0.95);
    });

    test('large number of boxes should be handled correctly', () {
      // 200 overlapping boxes of the same class at roughly the same position
      final boxes = List.generate(
        200,
        (i) => makeBox(
          confidence: 1.0 - i * 0.004, // 1.0 down to 0.204
          x: 0.3 + (i % 5) * 0.001,
          y: 0.3 + (i % 5) * 0.001,
          width: 0.4,
          height: 0.4,
        ),
      );

      final result = nonMaxSuppression(boxes, 0.45);
      // Many should be suppressed because they overlap heavily
      expect(result.length, lessThan(200));
      // The very first (highest confidence) must be present
      expect(result.first.confidence, closeTo(1.0, 1e-9));
    });

    test('threshold of 0.0 should suppress all overlapping boxes', () {
      // Any IoU > 0.0 gets suppressed
      final boxA = makeBox(
        width: 0.5,
        height: 0.5,
      );
      final boxB = makeBox(
        confidence: 0.8,
        x: 0.1,
        y: 0.1,
        width: 0.5,
        height: 0.5,
      );
      // These overlap, so IoU > 0. With threshold 0.0, B should be suppressed.
      final result = nonMaxSuppression([boxA, boxB], 0);
      expect(result, hasLength(1));
      expect(result.first.confidence, 0.9);
    });

    test('threshold of 1.0 should keep all boxes (nothing has IoU > 1.0)', () {
      final boxes = [
        makeBox(width: 0.5, height: 0.5),
        makeBox(confidence: 0.8, width: 0.5, height: 0.5),
        makeBox(confidence: 0.7, width: 0.5, height: 0.5),
      ];

      final result = nonMaxSuppression(boxes, 1);
      expect(result, hasLength(3));
    });
  });

  // ------------------------------------------------------------------
  // 4. DetectionResult helpers
  // ------------------------------------------------------------------
  group('DetectionResult helpers', () {
    late DetectionResult detectionResult;

    setUp(() {
      detectionResult = DetectionResult(
        boxes: [
          makeBox(className: 'person', confidence: 0.95),
          makeBox(className: 'person', confidence: 0.6),
          makeBox(classId: 1, className: 'car', confidence: 0.85),
          makeBox(classId: 1, className: 'car', confidence: 0.4),
          makeBox(classId: 2, className: 'dog', confidence: 0.75),
        ],
        inferenceTimeMs: 42,
      );
    });

    test('boxesAboveThreshold filters correctly', () {
      final above80 = detectionResult.boxesAboveThreshold(0.8);
      expect(above80, hasLength(2));
      expect(above80.every((b) => b.confidence >= 0.8), isTrue);

      final above50 = detectionResult.boxesAboveThreshold(0.5);
      expect(above50, hasLength(4));

      final above99 = detectionResult.boxesAboveThreshold(0.99);
      expect(above99, isEmpty);
    });

    test('boxesForClass filters correctly', () {
      final persons = detectionResult.boxesForClass('person');
      expect(persons, hasLength(2));
      expect(persons.every((b) => b.className == 'person'), isTrue);

      final cars = detectionResult.boxesForClass('car');
      expect(cars, hasLength(2));

      final dogs = detectionResult.boxesForClass('dog');
      expect(dogs, hasLength(1));

      final nonexistent = detectionResult.boxesForClass('airplane');
      expect(nonexistent, isEmpty);
    });

    test('detectedClasses returns unique set of class names', () {
      final classes = detectionResult.detectedClasses;
      expect(classes, hasLength(3));
      expect(classes, containsAll(['person', 'car', 'dog']));
    });

    test('count returns the number of boxes', () {
      expect(detectionResult.count, 5);
    });

    test('isEmpty returns false when boxes are present', () {
      expect(detectionResult.isEmpty, isFalse);
    });

    test('isEmpty returns true when no boxes are present', () {
      const empty = DetectionResult(boxes: []);
      expect(empty.isEmpty, isTrue);
      expect(empty.count, 0);
    });

    test('inferenceTimeMs is accessible', () {
      expect(detectionResult.inferenceTimeMs, 42);
    });

    test('inferenceTimeMs can be null', () {
      const noTime = DetectionResult(boxes: []);
      expect(noTime.inferenceTimeMs, isNull);
    });
  });
}
