import 'dart:math';

import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';

const List<String> kCanonicalNsfwLabels = <String>[
  'drawings',
  'hentai',
  'neutral',
  'porn',
  'sexy',
];

class NsfwModelSpec {
  const NsfwModelSpec({
    required this.modelId,
    required this.sourceUrl,
    required this.sha256,
    required this.license,
    required this.classOrder,
    required this.inputWidth,
    required this.inputHeight,
    required this.outputIsLogits,
    this.isFallback = false,
    this.isTensorflowJs = false,
  });

  final String modelId;
  final String sourceUrl;
  final String sha256;
  final String license;
  final List<String> classOrder;
  final int inputWidth;
  final int inputHeight;
  final bool outputIsLogits;
  final bool isFallback;
  final bool isTensorflowJs;

  bool get hasCanonicalClassOrder {
    if (classOrder.length != kCanonicalNsfwLabels.length) {
      return false;
    }
    for (var i = 0; i < kCanonicalNsfwLabels.length; i++) {
      if (classOrder[i] != kCanonicalNsfwLabels[i]) {
        return false;
      }
    }
    return true;
  }
}

class NsfwModelManifest {
  NsfwModelManifest._();

  // Production must replace these pinned entries with approved artifact sources
  // and exact SHA256 values for the shipped ONNX files.

  static const Set<String> _allowedLicenses = <String>{
    'mit',
  };

  static const Map<String, NsfwModelSpec> byModelId = <String, NsfwModelSpec>{
    'nsfw-gantman-mobilenet-v2-224': NsfwModelSpec(
      modelId: 'nsfw-gantman-mobilenet-v2-224',
      sourceUrl:
          'https://raw.githubusercontent.com/infinitered/nsfwjs/master/models/mobilenet_v2/model.json',
      sha256: '',
      license: 'MIT',
      classOrder: kCanonicalNsfwLabels,
      inputWidth: 224,
      inputHeight: 224,
      outputIsLogits: false,
      isTensorflowJs: true,
    ),
    'nsfw-gantman-inception-299': NsfwModelSpec(
      modelId: 'nsfw-gantman-inception-299',
      sourceUrl:
          'https://raw.githubusercontent.com/infinitered/nsfwjs/master/models/inception_v3/model.json',
      sha256: '',
      license: 'MIT',
      classOrder: kCanonicalNsfwLabels,
      inputWidth: 299,
      inputHeight: 299,
      outputIsLogits: false,
      isFallback: true,
      isTensorflowJs: true,
    ),
  };

  static NsfwModelSpec? findById(String id) => byModelId[id];

  static bool isLicenseAllowed(String license) =>
      _allowedLicenses.contains(license.toLowerCase());
}

class NsfwModelContractException implements Exception {
  NsfwModelContractException(this.message);

  final String message;

  @override
  String toString() => 'NsfwModelContractException: $message';
}

class NsfwModelAdapter {
  const NsfwModelAdapter(this.spec);

  final NsfwModelSpec spec;

  NsfwResult adapt(Map<String, double> rawOutput) {
    if (!spec.hasCanonicalClassOrder) {
      throw NsfwModelContractException(
        'Model ${spec.modelId} has invalid class order: ${spec.classOrder}',
      );
    }

    if (rawOutput.length != spec.classOrder.length) {
      throw NsfwModelContractException(
        'Expected ${spec.classOrder.length} output classes, got ${rawOutput.length}',
      );
    }

    final values = <double>[];
    for (final label in spec.classOrder) {
      final value = rawOutput[label];
      if (value == null) {
        throw NsfwModelContractException(
          'Missing NSFW class "$label" in output for model ${spec.modelId}',
        );
      }
      values.add(value);
    }

    final probs = spec.outputIsLogits ? _softmax(values) : values;
    final normalized = _normalize(probs);
    final scoreMap = <String, double>{};
    for (var i = 0; i < spec.classOrder.length; i++) {
      scoreMap[spec.classOrder[i]] = normalized[i];
    }

    return NsfwResult(
      drawings: scoreMap['drawings']!,
      hentai: scoreMap['hentai']!,
      neutral: scoreMap['neutral']!,
      porn: scoreMap['porn']!,
      sexy: scoreMap['sexy']!,
    );
  }

  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(max);
    final exps = logits.map((v) => exp(v - maxLogit)).toList(growable: false);
    final sumExp = exps.fold<double>(0, (a, b) => a + b);
    if (sumExp <= 0 || !sumExp.isFinite) {
      throw NsfwModelContractException(
        'Invalid logits: unable to apply softmax',
      );
    }
    return exps.map((v) => v / sumExp).toList(growable: false);
  }

  List<double> _normalize(List<double> values) {
    var sum = 0.0;
    final normalized = <double>[];
    for (final value in values) {
      if (!value.isFinite || value < 0) {
        throw NsfwModelContractException(
          'Model ${spec.modelId} produced invalid probability value: $value',
        );
      }
      sum += value;
      normalized.add(value);
    }

    if (sum <= 0 || !sum.isFinite) {
      throw NsfwModelContractException(
        'Model ${spec.modelId} produced non-normalizable scores',
      );
    }

    for (var i = 0; i < normalized.length; i++) {
      normalized[i] = normalized[i] / sum;
    }

    final sumAfter = normalized.fold<double>(0, (a, b) => a + b);
    if ((sumAfter - 1).abs() > 0.01) {
      throw NsfwModelContractException(
        'Model ${spec.modelId} probabilities failed sanity check: sum=$sumAfter',
      );
    }

    return normalized;
  }
}
