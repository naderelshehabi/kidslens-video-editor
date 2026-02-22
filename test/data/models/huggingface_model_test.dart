import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

void main() {
  test('model type is ASR-only', () {
    expect(HuggingFaceModelType.values, [HuggingFaceModelType.asr]);
  });

  test('computed properties are valid', () {
    const model = HuggingFaceModel(
      id: 'whisper-small',
      displayName: 'Whisper Small',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-small.bin',
      parameters: '244M',
      parameterCount: 244000000,
      sizeBytes: 466 * 1024 * 1024,
      ramRequired: 2 * 1024 * 1024 * 1024,
      speedMultiplier: 4,
      accuracyPercent: 92,
      modelType: HuggingFaceModelType.asr,
      languages: ['en'],
      badge: 'Recommended',
    );

    expect(model.isAsrModel, isTrue);
    expect(model.isVisualModel, isFalse);
    expect(model.hasBadge, isTrue);
    expect(model.isRecommended, isTrue);
  });
}
