import 'package:http/http.dart' as http;

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider.dart';

class VlmProviderFactory {
  VlmProviderFactory({
    http.Client Function()? httpClientFactory,
    this.parser = const VlmJsonParser(),
    this.overrideProvider,
  }) : httpClientFactory = httpClientFactory ?? http.Client.new;

  final http.Client Function() httpClientFactory;
  final VlmJsonParser parser;
  final VlmProvider Function({
    required LocalRuntimeProfile runtimeProfile,
    required Uri endpoint,
    required String modelAlias,
  })? overrideProvider;

  VlmProvider forRuntime({
    required LocalRuntimeProfile runtimeProfile,
    required Uri endpoint,
    required String modelAlias,
  }) {
    final override = overrideProvider;
    if (override != null) {
      return override(
        runtimeProfile: runtimeProfile,
        endpoint: endpoint,
        modelAlias: modelAlias,
      );
    }
    return switch (runtimeProfile.id) {
      LocalRuntimeId.cudaLlamaCpp ||
      LocalRuntimeId.vulkanLlamaCpp =>
        OpenAiCompatVlmProvider(
          endpoint: endpoint,
          runtimeProfile: runtimeProfile,
          modelAlias: modelAlias,
          client: httpClientFactory(),
          parser: parser,
        ),
      LocalRuntimeId.cudaTransformersHelper => TransformersHelperVlmProvider(
          endpoint: endpoint,
          client: httpClientFactory(),
        ),
      LocalRuntimeId.cudaVllm => VllmVlmProvider(
          endpoint: endpoint,
          client: httpClientFactory(),
        ),
      LocalRuntimeId.cudaTensorRt => NvidiaLocalVlmProvider(
          endpoint: endpoint,
          client: httpClientFactory(),
        ),
      LocalRuntimeId.directmlOnnx ||
      LocalRuntimeId.cpuLightweight =>
        throw VlmProviderException(
          'Runtime ${runtimeProfile.id.jsonValue} does not expose a local VLM HTTP provider.',
        ),
    };
  }
}
