import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/services/detection/analysis_stage_host.dart';
import 'package:kidslens_video_editor/services/detection/chunk_planner.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/evidence_store.dart';
import 'package:kidslens_video_editor/services/detection/family_safety_prompt_templates.dart';
import 'package:kidslens_video_editor/services/detection/llama_server_manager.dart';
import 'package:kidslens_video_editor/services/detection/local_runtime_manager.dart';
import 'package:kidslens_video_editor/services/detection/local_search_index.dart';
import 'package:kidslens_video_editor/services/detection/policy_engine.dart';
import 'package:kidslens_video_editor/services/detection/runtime_binary_manager.dart';
import 'package:kidslens_video_editor/services/detection/temporal_fusion.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider_factory.dart';
import 'package:kidslens_video_editor/services/frame_sampling_service.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:path/path.dart' as p;

typedef VssCacheDirectoryFactory = Future<Directory> Function(String mediaId);
typedef VssSceneChangeDetector = Future<List<Duration>> Function(
  String mediaPath, {
  required CancellationToken? cancellationToken,
});
typedef VssFrameImageExtractor = Future<List<VlmFrameImage>> Function({
  required String videoPath,
  required VideoChunk chunk,
  required List<SampledFrameRef> frameRefs,
  required CancellationToken? cancellationToken,
});
typedef VssLlamaServerStarter = Future<VssLlamaServerLease> Function(
  LlamaServerStartRequest request,
);
typedef VssModelArtifactResolver = Future<VssModelArtifacts> Function(
  ModelBundleManifest bundle,
);
typedef VssModelBundleResolver = ModelBundleManifest Function(
  AnalysisSettings settings,
);

class VssFamilySafetyPipeline implements DetectionPipeline {
  VssFamilySafetyPipeline({
    required this.stageHost,
    required this.frameSamplingService,
    required this.modelManager,
    ChunkPlanner? chunkPlanner,
    RuntimeBinaryManager? runtimeBinaryManager,
    LlamaServerManager? llamaServerManager,
    LocalRuntimeManager? localRuntimeManager,
    VlmProviderFactory? vlmProviderFactory,
    PolicyEngine? policyEngine,
    PolicyDetectionBuilder? policyDetectionBuilder,
    FamilySafetySearchIndexer? searchIndexer,
    VssCacheDirectoryFactory? cacheDirectoryFactory,
    this.sceneChangeDetector,
    this.frameImageExtractor,
    this.llamaServerStarter,
    this.embeddingServerStarter,
    this.modelArtifactResolver,
    VssModelBundleResolver? modelBundleResolver,
    this.searchEmbeddingProvider,
    this.enableLegacyAuxiliarySignals = true,
    this.skipRuntimePreflight = false,
  })  : chunkPlanner = chunkPlanner ?? const ChunkPlanner(),
        runtimeBinaryManager = runtimeBinaryManager ?? RuntimeBinaryManager(),
        localRuntimeManager = localRuntimeManager ?? LocalRuntimeManager(),
        vlmProviderFactory = vlmProviderFactory ?? VlmProviderFactory(),
        policyEngine = policyEngine ??
            PolicyEngine.forPipeline(DetectionPipelineIds.vssFamilySafetyV1),
        policyDetectionBuilder =
            policyDetectionBuilder ?? const PolicyDetectionBuilder(),
        searchIndexer = searchIndexer ?? const FamilySafetySearchIndexer(),
        cacheDirectoryFactory =
            cacheDirectoryFactory ?? _defaultCacheDirectoryFactory,
        modelBundleResolver =
            modelBundleResolver ?? _defaultModelBundleResolver,
        _llamaServerManager = llamaServerManager;

  static const defaultModelBundleId = 'qwen3_vl_8b_instruct_gguf_q4km';
  static const embeddingModelBundleId = 'qwen3_embedding_0_6b_gguf_q8';
  static const _checkpointFileName = 'vss_checkpoint.json';
  static const _evidenceFileName = 'evidence.json';
  static const _manifestFileName = 'analysis_run_manifest.json';
  static const _searchIndexFileName = 'family_safety_search_index.json';
  static const _samplingHash =
      'vss_frames:max_per_chunk=8,max_long_side=768,jpeg_quality=85';
  static const _policyProfileHash = 'family_safety_policy_v1_vss_default';

  final AnalysisStageHost stageHost;
  final FrameSamplingService frameSamplingService;
  final ChunkPlanner chunkPlanner;
  final RuntimeBinaryManager runtimeBinaryManager;
  final ModelManagerService modelManager;
  final LocalRuntimeManager localRuntimeManager;
  final VlmProviderFactory vlmProviderFactory;
  final PolicyEngine policyEngine;
  final PolicyDetectionBuilder policyDetectionBuilder;
  final FamilySafetySearchIndexer searchIndexer;
  final VssCacheDirectoryFactory cacheDirectoryFactory;
  final VssSceneChangeDetector? sceneChangeDetector;
  final VssFrameImageExtractor? frameImageExtractor;
  final VssLlamaServerStarter? llamaServerStarter;
  final VssLlamaServerStarter? embeddingServerStarter;
  final VssModelArtifactResolver? modelArtifactResolver;
  final VssModelBundleResolver modelBundleResolver;
  final LocalEmbeddingProvider? searchEmbeddingProvider;
  final bool enableLegacyAuxiliarySignals;
  final bool skipRuntimePreflight;
  final LlamaServerManager? _llamaServerManager;

  @override
  DetectionPipelineProfile get profile =>
      DetectionPipelineProfile.vssFamilySafetyV1;

  @override
  Stream<AnalysisProgress> analyze(DetectionPipelineRequest request) async* {
    final mediaId = request.mediaId ?? request.mediaPath;
    final totalSteps = enableLegacyAuxiliarySignals ? 7 : 6;
    yield _progress(
      'VSS: preparing local VLM',
      currentStep: 1,
      totalSteps: totalSteps,
      stepProgress: 0,
    );

    final cacheDir = await cacheDirectoryFactory(mediaId);
    final evidenceStore = JsonEvidenceStore(
      File(p.join(cacheDir.path, _evidenceFileName)),
    );
    final checkpointFile = File(p.join(cacheDir.path, _checkpointFileName));
    final manifestFile = File(p.join(cacheDir.path, _manifestFileName));
    final searchIndexFile = File(p.join(cacheDir.path, _searchIndexFileName));

    late final ModelBundleManifest bundle;
    late final VssModelArtifacts artifacts;
    late final LocalRuntimeProfile runtimeProfile;
    late final VssLlamaServerLease serverHandle;
    late final VlmProvider provider;

    try {
      bundle = modelBundleResolver(request.settings);
      artifacts = await _resolveArtifacts(bundle);
      runtimeProfile = await _resolveRuntime(bundle);
      if (!skipRuntimePreflight) {
        final installState =
            await runtimeBinaryManager.getInstallState(runtimeProfile.id);
        if (!installState.isInstalled) {
          throw VssPipelineStartupException(
            'local runtime ${runtimeProfile.id.jsonValue} is not installed: '
            '${installState.missingFiles.join(', ')}',
          );
        }
      }
      serverHandle = await _startServer(
        bundle: bundle,
        artifacts: artifacts,
        runtimeProfile: runtimeProfile,
      );
      provider = vlmProviderFactory.forRuntime(
        runtimeProfile: runtimeProfile,
        endpoint: serverHandle.endpointUri,
        modelAlias: bundle.modelId,
      );
    } on Object catch (error) {
      yield _progress(
        'VSS unavailable: falling back to legacy (${_shortError(error)})',
        currentStep: 1,
        totalSteps: totalSteps,
        stepProgress: 1,
      );
      yield* stageHost.runLegacyAnalysis(request);
      return;
    }

    try {
      await stageHost.checkState(request.cancellationToken);
      final metadata = await stageHost.probeMedia(
        request.mediaPath,
        cancellationToken: request.cancellationToken,
      );
      final mediaDuration = metadata.duration <= Duration.zero
          ? const Duration(milliseconds: 1)
          : metadata.duration;
      final mediaDurationMs = mediaDuration.inMilliseconds;

      yield _progress(
        'VSS: planning video chunks',
        currentStep: 2,
        totalSteps: totalSteps,
        stepProgress: 0,
        processedDurationMs: 0,
        totalDurationMs: mediaDurationMs,
      );
      final sceneChanges = request.settings.useSceneDetection
          ? await _detectSceneChanges(
              request.mediaPath,
              cancellationToken: request.cancellationToken,
            )
          : const <Duration>[];
      final chunks = chunkPlanner.planChunks(
        mediaId: mediaId,
        mediaDuration: mediaDuration,
        sceneChanges: sceneChanges,
      );
      final framesByChunkId = _framesByChunkId(
        frameSamplingService.selectFrameRefsForChunks(
          chunks,
          config: ChunkFrameSelectionConfig(
            maxFramesPerChunk:
                bundle.maxFramesPerChunk < 8 ? bundle.maxFramesPerChunk : 8,
          ),
        ),
      );

      await _writeManifest(
        manifestFile,
        mediaId: mediaId,
        bundle: bundle,
        chunks: chunks,
      );
      yield _progress(
        'VSS: chunk plan ready (${chunks.length} chunks)',
        currentStep: 2,
        totalSteps: totalSteps,
        stepProgress: 1,
        processedDurationMs: 0,
        totalDurationMs: mediaDurationMs,
        itemsProcessed: chunks.length,
        totalItems: chunks.length,
      );

      var checkpoint = await _VssCheckpoint.read(checkpointFile);
      await _appendAudioEvidenceIfEnabled(
        request: request,
        evidenceStore: evidenceStore,
        mediaId: mediaId,
        currentStep: 3,
        totalSteps: totalSteps,
        mediaDurationMs: mediaDurationMs,
        emitProgress: (progress) {},
      );

      if (_hasProfanityCategory(request.settings)) {
        yield _progress(
          'VSS: audio evidence complete',
          currentStep: 3,
          totalSteps: totalSteps,
          stepProgress: 1,
          processedDurationMs: mediaDurationMs,
          totalDurationMs: mediaDurationMs,
        );
      } else {
        yield _progress(
          'VSS: audio evidence skipped',
          currentStep: 3,
          totalSteps: totalSteps,
          stepProgress: 1,
          processedDurationMs: 0,
          totalDurationMs: mediaDurationMs,
        );
      }

      final visualStep = enableLegacyAuxiliarySignals ? 4 : 0;
      if (enableLegacyAuxiliarySignals) {
        await for (final update in stageHost.runVisualAuxiliarySignals(
          request,
          mediaDuration: mediaDuration,
          currentStep: visualStep,
          totalSteps: totalSteps,
        )) {
          if (update.result != null) {
            await evidenceStore.appendAll(
              _visualAuxiliaryEvidence(
                mediaId: mediaId,
                result: update.result!,
                bundle: bundle,
              ),
            );
          }
          yield update.progress;
        }
      }

      final vlmStep = enableLegacyAuxiliarySignals ? 5 : 4;
      var processedChunks = 0;
      for (final chunk in chunks) {
        await stageHost.checkState(request.cancellationToken);
        final refs = framesByChunkId[chunk.id] ?? const <SampledFrameRef>[];
        if (checkpoint.completedChunkIds.contains(chunk.id) &&
            await _hasVlmEvidence(evidenceStore, mediaId, chunk.id)) {
          processedChunks++;
          yield _progress(
            'VSS: restored chunk ${chunk.index + 1}/${chunks.length}',
            currentStep: vlmStep,
            totalSteps: totalSteps,
            stepProgress: chunks.isEmpty ? 1 : processedChunks / chunks.length,
            processedDurationMs: chunk.endTime.inMilliseconds,
            totalDurationMs: mediaDurationMs,
            itemsProcessed: processedChunks,
            totalItems: chunks.length,
          );
          continue;
        }

        final frameImages = await _extractFrameImages(
          videoPath: request.mediaPath,
          chunk: chunk,
          frameRefs: refs,
          cancellationToken: request.cancellationToken,
        );
        final prompt = FamilySafetyPromptTemplates.policy(
          FamilySafetyPromptContext(
            mediaId: mediaId,
            chunk: chunk,
            frames: refs,
            modelBundle: bundle,
            enabledCategoryIds: _enabledPolicyCategoryIds(request.settings),
          ),
        );
        await provider.analyzeSegment(
          VideoSegmentRequest(
            mediaId: mediaId,
            chunk: chunk,
            frames: refs,
            frameImages: frameImages,
            modelBundle: bundle,
            runtimeProfile: runtimeProfile,
            prompt: prompt.text,
            cancellationToken: request.cancellationToken,
            evidenceStore: evidenceStore,
          ),
        );
        checkpoint = checkpoint.completeChunk(chunk.id);
        await checkpoint.write(checkpointFile);
        processedChunks++;
        yield _progress(
          'VSS: analyzed chunk ${chunk.index + 1}/${chunks.length}',
          currentStep: vlmStep,
          totalSteps: totalSteps,
          stepProgress: chunks.isEmpty ? 1 : processedChunks / chunks.length,
          processedDurationMs: chunk.endTime.inMilliseconds,
          totalDurationMs: mediaDurationMs,
          itemsProcessed: processedChunks,
          totalItems: chunks.length,
        );
      }

      final policyStep = enableLegacyAuxiliarySignals ? 6 : 5;
      yield _progress(
        'VSS: applying family-safety policy',
        currentStep: policyStep,
        totalSteps: totalSteps,
        stepProgress: 0,
        processedDurationMs: mediaDurationMs,
        totalDurationMs: mediaDurationMs,
      );
      final evidence = await evidenceStore.readAll(mediaId: mediaId);
      final policyResult = policyEngine.evaluate(
        mediaId: mediaId,
        records: evidence,
      );
      final buildResult = policyDetectionBuilder.build(
        mediaId: mediaId,
        findings: policyResult.findings,
        mediaDuration: mediaDuration,
        timelineId: 'timeline_$mediaId',
      );
      request.onDetectionsBuilt?.call(buildResult.detections);
      request.onTimelineBuilt?.call(buildResult.timeline);

      yield _progress(
        'VSS: indexing searchable evidence',
        currentStep: totalSteps,
        totalSteps: totalSteps,
        stepProgress: 0.5,
        processedDurationMs: mediaDurationMs,
        totalDurationMs: mediaDurationMs,
      );
      await _indexSearchDocuments(
        searchIndexFile: searchIndexFile,
        mediaId: mediaId,
        evidence: evidence,
        findings: policyResult.findings,
        detections: buildResult.detections,
        runtimeProfile: runtimeProfile,
      );

      yield _progress(
        'Analysis complete',
        currentStep: totalSteps,
        totalSteps: totalSteps,
        stepProgress: 1,
        processedDurationMs: mediaDurationMs,
        totalDurationMs: mediaDurationMs,
        itemsProcessed: buildResult.detections.length,
        totalItems: buildResult.detections.length,
      );
    } finally {
      await serverHandle.release();
    }
  }

  Future<VssModelArtifacts> _resolveArtifacts(
    ModelBundleManifest bundle,
  ) async {
    final override = modelArtifactResolver;
    if (override != null) {
      return override(bundle);
    }
    final primary = await modelManager.getModelPath(bundle.modelId);
    if (primary == null) {
      throw VssPipelineStartupException(
        'model bundle ${bundle.modelId} is not downloaded',
      );
    }
    final modelDir = File(primary).parent;
    if (bundle.artifactFiles.isEmpty) {
      return VssModelArtifacts(
        modelPath: primary,
        modelDirectory: modelDir.path,
      );
    }

    String? modelPath;
    String? mmprojPath;
    for (final artifact in bundle.artifactFiles) {
      final file = File(p.join(modelDir.path, artifact.path));
      if (!file.existsSync()) {
        throw VssPipelineStartupException(
          'model bundle ${bundle.modelId} is missing ${artifact.path}',
        );
      }
      final basename = p.basename(artifact.path).toLowerCase();
      if (basename.startsWith('mmproj') || basename.contains('mmproj')) {
        mmprojPath = file.path;
      } else {
        modelPath ??= file.path;
      }
    }
    return VssModelArtifacts(
      modelPath: modelPath ?? primary,
      mmprojPath: mmprojPath,
      modelDirectory: modelDir.path,
    );
  }

  Future<LocalRuntimeProfile> _resolveRuntime(
    ModelBundleManifest bundle,
  ) async {
    final preferred = LocalRuntimeProfile.byModelRuntime(bundle.runtime) ??
        LocalRuntimeProfile.byId(LocalRuntimeId.cudaLlamaCpp);
    if (skipRuntimePreflight) {
      return preferred;
    }
    final hardware = await localRuntimeManager.discoverHardware();
    final result = localRuntimeManager.selectRuntime(
      model: bundle,
      hardware: hardware,
      workload: LocalRuntimeWorkload(
        chunkSeconds: bundle.recommendedChunkSeconds,
        frameCount: bundle.maxFramesPerChunk < 8 ? bundle.maxFramesPerChunk : 8,
        frameWidth: 768,
        frameHeight: 768,
        maxOutputTokens: 2048,
        secondPass: false,
      ),
    );
    if (result.profile == null) {
      throw VssPipelineStartupException(
        result.rejectionReasons.isEmpty
            ? 'no local GPU runtime is available'
            : result.rejectionReasons.join('; '),
      );
    }
    return result.profile!;
  }

  Future<VssLlamaServerLease> _startServer({
    required ModelBundleManifest bundle,
    required VssModelArtifacts artifacts,
    required LocalRuntimeProfile runtimeProfile,
  }) {
    final request = LlamaServerStartRequest(
      runtimeId: runtimeProfile.id,
      modelBundleId: bundle.modelId,
      modelPath: artifacts.modelPath,
      mmprojPath: artifacts.mmprojPath,
      contextTokens:
          bundle.maxContextTokens < 16384 ? bundle.maxContextTokens : 16384,
    );
    final starter = llamaServerStarter;
    if (starter != null) {
      return starter(request);
    }
    final manager = _llamaServerManager ??
        LlamaServerManager(runtimeBinaryManager: runtimeBinaryManager);
    return manager.startVlm(request).then(VssLlamaServerLease.fromHandle);
  }

  Future<List<Duration>> _detectSceneChanges(
    String mediaPath, {
    required CancellationToken? cancellationToken,
  }) async {
    final detector = sceneChangeDetector;
    if (detector != null) {
      return detector(mediaPath, cancellationToken: cancellationToken);
    }
    await cancellationToken?.checkState();
    final changes = await frameSamplingService.detectSceneChanges(mediaPath);
    await cancellationToken?.checkState();
    return changes;
  }

  Future<List<VlmFrameImage>> _extractFrameImages({
    required String videoPath,
    required VideoChunk chunk,
    required List<SampledFrameRef> frameRefs,
    required CancellationToken? cancellationToken,
  }) {
    final extractor = frameImageExtractor;
    if (extractor != null) {
      return extractor(
        videoPath: videoPath,
        chunk: chunk,
        frameRefs: frameRefs,
        cancellationToken: cancellationToken,
      );
    }
    return frameSamplingService.extractChunkJpegFrames(
      videoPath: videoPath,
      chunk: chunk,
      frameRefs: frameRefs,
      cancellationToken: cancellationToken,
    );
  }

  Future<void> _appendAudioEvidenceIfEnabled({
    required DetectionPipelineRequest request,
    required EvidenceStore evidenceStore,
    required String mediaId,
    required int currentStep,
    required int totalSteps,
    required int mediaDurationMs,
    required void Function(AnalysisProgress progress) emitProgress,
  }) async {
    if (!_hasProfanityCategory(request.settings)) {
      return;
    }
    final transcript = request.existingTranscript ??
        request.checkpoint?.transcript ??
        await stageHost.transcribeAudio(
          request.mediaPath,
          request.settings,
          cancellationToken: request.cancellationToken,
        );
    final matches = request.checkpoint?.profanityMatches ??
        await stageHost.detectProfanity(
          transcript,
          request.settings,
          cancellationToken: request.cancellationToken,
        );
    final records = <EvidenceRecord>[
      for (final segment in transcript.segments)
        EvidenceRecord.transcriptSpan(
          mediaId: mediaId,
          segment: segment,
          provenance: EvidenceProvenance(
            providerId: 'legacy_audio_stage',
            providerVersion: '1',
            runtime: 'local',
            inputIds: [segment.id],
            startTime: segment.startTime,
            endTime: segment.endTime,
            modelBundleId: transcript.modelId,
          ),
        ),
      for (final match in matches)
        EvidenceRecord.profanityMatch(
          mediaId: mediaId,
          match: match,
          provenance: EvidenceProvenance(
            providerId: 'legacy_profanity_stage',
            providerVersion: '1',
            runtime: 'local',
            inputIds: [match.id],
            startTime: match.startTime,
            endTime: match.endTime,
          ),
        ),
    ];
    await evidenceStore.appendAll(records);
  }

  Iterable<EvidenceRecord> _visualAuxiliaryEvidence({
    required String mediaId,
    required AnalysisVisualAuxiliaryResult result,
    required ModelBundleManifest bundle,
  }) sync* {
    for (final frame in result.frameResults) {
      final provenance = EvidenceProvenance(
        providerId: 'legacy_visual_auxiliary',
        providerVersion: '1',
        modelBundleId: bundle.modelId,
        runtime: 'local_legacy_auxiliary',
        inputIds: ['frame:${frame.frameNumber}'],
        startTime: frame.timestamp,
        endTime: frame.timestamp + const Duration(milliseconds: 1),
      );
      yield EvidenceRecord.legacyNsfwScore(
        mediaId: mediaId,
        frame: frame,
        provenance: provenance,
      );
      for (final region
          in frame.visualContent?.detectedRegions ?? const <DetectedRegion>[]) {
        yield EvidenceRecord.legacyNudenetRegion(
          mediaId: mediaId,
          timestamp: frame.timestamp,
          frameNumber: frame.frameNumber,
          region: region,
          provenance: provenance,
        );
      }
    }
  }

  Future<void> _writeManifest(
    File manifestFile, {
    required String mediaId,
    required ModelBundleManifest bundle,
    required List<VideoChunk> chunks,
  }) async {
    manifestFile.parent.createSync(recursive: true);
    final manifest = AnalysisRunManifest(
      runId: _runId(mediaId),
      mediaId: mediaId,
      pipelineId: DetectionPipelineIds.vssFamilySafetyV1,
      pipelineVersion: AnalysisCheckpoint.defaultPipelineVersion,
      createdAt: DateTime.now().toUtc(),
      chunkPlannerHash: chunkPlanner.config.deterministicHash,
      samplingHash: _samplingHash,
      policyProfileHash: _policyProfileHash,
      modelBundleIds: {'vlm': bundle.modelId},
      chunks: chunks,
    );
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
  }

  Future<bool> _hasVlmEvidence(
    EvidenceStore evidenceStore,
    String mediaId,
    String chunkId,
  ) async {
    final records = await evidenceStore.readAll(
      mediaId: mediaId,
      type: EvidenceType.vlmPolicyJson,
    );
    return records.any((record) => record.chunkId == chunkId);
  }

  Future<void> _indexSearchDocuments({
    required File searchIndexFile,
    required String mediaId,
    required List<EvidenceRecord> evidence,
    required List<PolicyFinding> findings,
    required List<Detection> detections,
    required LocalRuntimeProfile runtimeProfile,
  }) async {
    VssLlamaServerLease? embeddingLease;
    try {
      final embeddingSelection = await _selectSearchEmbeddingProvider(
        runtimeProfile: runtimeProfile,
      );
      embeddingLease = embeddingSelection.lease;
      if (embeddingSelection.fallbackReason != null) {
        debugPrint(
          'VSS search embeddings: ${embeddingSelection.fallbackReason}; '
          'using hash fallback',
        );
      }
      final documents = searchIndexer.buildDocuments(
        mediaId: mediaId,
        evidenceRecords: evidence,
        policyFindings: findings,
        detections: detections,
      );
      final index = InMemoryLocalSearchIndex(
        store: JsonSearchIndexStore(searchIndexFile),
        embeddingProvider: embeddingSelection.provider,
      );
      await index.load();
      await index.clearMedia(mediaId);
      await index.indexDocuments(documents);
    } catch (_) {
      // Search indexing is non-fatal to detection results.
    } finally {
      await embeddingLease?.release();
    }
  }

  Future<_SearchEmbeddingSelection> _selectSearchEmbeddingProvider({
    required LocalRuntimeProfile runtimeProfile,
  }) async {
    final override = searchEmbeddingProvider;
    if (override != null) {
      return _SearchEmbeddingSelection(provider: override);
    }

    final bundle = ModelBundleCatalog.byModelId(embeddingModelBundleId);
    final downloadedPath = await modelManager.getModelPath(bundle.modelId);
    if (downloadedPath == null) {
      return const _SearchEmbeddingSelection(
        provider: HashLocalEmbeddingProvider(),
        fallbackReason: 'embedding bundle is not downloaded',
      );
    }

    try {
      final artifacts = await _resolveArtifacts(bundle);
      final lease = await _startEmbeddingServer(
        bundle: bundle,
        artifacts: artifacts,
        runtimeProfile: runtimeProfile,
      );
      return _SearchEmbeddingSelection(
        provider: LlamaServerEmbeddingProvider(
          endpointUri: lease.endpointUri,
          modelManifest: bundle,
        ),
        lease: lease,
      );
    } on Object catch (error) {
      return _SearchEmbeddingSelection(
        provider: const HashLocalEmbeddingProvider(),
        fallbackReason: 'embedding server unavailable: ${_shortError(error)}',
      );
    }
  }

  Future<VssLlamaServerLease> _startEmbeddingServer({
    required ModelBundleManifest bundle,
    required VssModelArtifacts artifacts,
    required LocalRuntimeProfile runtimeProfile,
  }) {
    final request = LlamaServerStartRequest(
      runtimeId: runtimeProfile.id,
      modelBundleId: bundle.modelId,
      modelPath: artifacts.modelPath,
      contextTokens: bundle.maxContextTokens,
      gpuLayers: 0,
      embedding: true,
    );
    final starter = embeddingServerStarter ?? llamaServerStarter;
    if (starter != null) {
      return starter(request);
    }
    final manager = _llamaServerManager ??
        LlamaServerManager(runtimeBinaryManager: runtimeBinaryManager);
    return manager.startEmbedding(request).then(VssLlamaServerLease.fromHandle);
  }

  Map<String, List<SampledFrameRef>> _framesByChunkId(
    Iterable<SampledFrameRef> refs,
  ) {
    final grouped = <String, List<SampledFrameRef>>{};
    for (final ref in refs) {
      grouped.putIfAbsent(ref.chunkId, () => <SampledFrameRef>[]).add(ref);
    }
    return grouped;
  }

  List<String> _enabledPolicyCategoryIds(AnalysisSettings settings) {
    final categories = settings.contentDetectionConfig.enabledVisualCategories
        .map((category) => category.id)
        .where((id) => id != 'nsfw')
        .toSet()
        .toList();
    if (_hasProfanityCategory(settings)) {
      categories.add(FamilySafetyPolicyCategory.profanity.id);
    }
    return categories.isEmpty ? const <String>[] : categories;
  }

  bool _hasProfanityCategory(AnalysisSettings settings) {
    final categoryEnabled = settings.contentDetectionConfig.enabledCategories
        .any((category) => category.id == 'profanity');
    return settings.enableProfanity || categoryEnabled;
  }

  AnalysisProgress _progress(
    String stepName, {
    required int currentStep,
    required int totalSteps,
    required double stepProgress,
    int? processedDurationMs,
    int? totalDurationMs,
    int? itemsProcessed,
    int? totalItems,
  }) =>
      AnalysisProgress(
        stepName: stepName,
        currentStep: currentStep,
        totalSteps: totalSteps,
        stepProgress: stepProgress.clamp(0.0, 1.0),
        processedDurationMs: processedDurationMs,
        totalDurationMs: totalDurationMs,
        itemsProcessed: itemsProcessed,
        totalItems: totalItems,
      );

  static ModelBundleManifest _defaultModelBundleResolver(
    AnalysisSettings settings,
  ) =>
      ModelBundleCatalog.byModelId(defaultModelBundleId);

  static Future<Directory> _defaultCacheDirectoryFactory(String mediaId) async {
    final hash =
        sha256.convert(utf8.encode(mediaId)).toString().substring(0, 16);
    final dir = Directory(
      p.join(Directory.systemTemp.path, 'kidslens_video_editor', 'vss', hash),
    );
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _runId(String mediaId) =>
      'vss_${sha256.convert(utf8.encode(mediaId)).toString().substring(0, 24)}';

  static String _shortError(Object error) {
    final text = error.toString().replaceAll('\n', ' ').trim();
    return text.length <= 140 ? text : '${text.substring(0, 137)}...';
  }
}

class VssModelArtifacts {
  const VssModelArtifacts({
    required this.modelPath,
    required this.modelDirectory,
    this.mmprojPath,
  });

  final String modelPath;
  final String? mmprojPath;
  final String modelDirectory;
}

class VssLlamaServerLease {
  const VssLlamaServerLease({
    required this.endpointUri,
    required this.release,
  });

  factory VssLlamaServerLease.fromHandle(LlamaServerHandle handle) =>
      VssLlamaServerLease(
        endpointUri: handle.endpointUri,
        release: handle.release,
      );

  final Uri endpointUri;
  final Future<void> Function() release;
}

class _SearchEmbeddingSelection {
  const _SearchEmbeddingSelection({
    required this.provider,
    this.lease,
    this.fallbackReason,
  });

  final LocalEmbeddingProvider provider;
  final VssLlamaServerLease? lease;
  final String? fallbackReason;
}

class VssPipelineStartupException implements Exception {
  const VssPipelineStartupException(this.message);

  final String message;

  @override
  String toString() => 'VssPipelineStartupException: $message';
}

class _VssCheckpoint {
  const _VssCheckpoint({
    this.completedChunkIds = const <String>{},
  });

  final Set<String> completedChunkIds;

  _VssCheckpoint completeChunk(String chunkId) => _VssCheckpoint(
        completedChunkIds: {...completedChunkIds, chunkId},
      );

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'completedChunkIds': completedChunkIds.toList()..sort(),
      };

  Future<void> write(File file) async {
    file.parent.createSync(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(toJson()),
    );
  }

  static Future<_VssCheckpoint> read(File file) async {
    if (!file.existsSync()) {
      return const _VssCheckpoint();
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) {
      return const _VssCheckpoint();
    }
    final ids = (decoded['completedChunkIds'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toSet();
    return _VssCheckpoint(completedChunkIds: ids);
  }
}
