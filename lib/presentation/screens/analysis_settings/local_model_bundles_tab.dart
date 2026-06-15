import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/model_bundle_selection_policy.dart';
import 'package:kidslens_video_editor/services/detection/runtime_binary_manager.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/runtime_binary_provider.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

class LocalModelBundlesTab extends ConsumerStatefulWidget {
  const LocalModelBundlesTab({
    super.key,
    this.catalog = ModelBundleCatalog.initialCandidates,
    this.productionMode = false,
  });

  final List<ModelBundleManifest> catalog;
  final bool productionMode;

  @override
  ConsumerState<LocalModelBundlesTab> createState() =>
      _LocalModelBundlesTabState();
}

class _LocalModelBundlesTabState extends ConsumerState<LocalModelBundlesTab> {
  ModelBundleSelectionPolicy get _policy => ModelBundleSelectionPolicy(
        productionMode: widget.productionMode,
        catalog: widget.catalog,
      );

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(modelNotifierProvider.notifier).loadAvailableModels(),
    );
    Future<void>.microtask(
      () =>
          ref.read(runtimeBinaryNotifierProvider.notifier).loadInstallStates(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsState = ref.watch(settingsNotifierProvider);
    final modelState = ref.watch(modelNotifierProvider);
    final runtimeState = ref.watch(runtimeBinaryNotifierProvider);
    final settings = settingsState.analysisSettings;
    final acceptedTerms = settingsState.acceptedModelBundleTerms.toSet();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Local Model Bundles', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Configure the local-only family-safety pipeline and approved open-weight model bundles.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (modelState.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              modelState.errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _SelectionPanel(
            settings: settings,
            policy: _policy,
            acceptedTerms: acceptedTerms,
            localRuntimeId: settingsState.localRuntimeId,
            modelBundleIdsByRole: settingsState.modelBundleIdsByRole,
            onPipelineChanged: _setPipeline,
            onRuntimeChanged: _setRuntime,
            onBundleSelected: _selectBundle,
          ),
          const SizedBox(height: 20),
          _LocalRuntimeCard(
            runtimeState: runtimeState,
            selectedRuntimeId: settingsState.localRuntimeId,
            onRuntimeChanged: _setRuntime,
            onInstall: _installRuntime,
            onRefresh: _refreshRuntimeState,
          ),
          const SizedBox(height: 20),
          Text('Candidate Review', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          ...widget.catalog.map(
            (manifest) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ModelBundleCandidateTile(
                manifest: manifest,
                policy: _policy,
                localRuntimeId: settingsState.localRuntimeId,
                acceptedTerms: acceptedTerms,
                downloadProgress: modelState.activeDownloads[manifest.modelId],
                isDownloaded:
                    modelState.downloadedModels.contains(manifest.modelId),
                onAcceptTerms: manifest.acceptedTermsRequired
                    ? (accepted) => _setTermsAccepted(manifest, accepted)
                    : null,
                onInstallOfficial: _canInstall(manifest, acceptedTerms)
                    ? () => _downloadOfficial(manifest, acceptedTerms)
                    : null,
                onInstallConverted: _canInstallConverted(manifest)
                    ? () => _queueConvertedInstall(manifest.modelId)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canInstall(
    ModelBundleManifest manifest,
    Set<String> acceptedTerms,
  ) =>
      (manifest.artifactType == ModelBundleArtifactType.officialWeights ||
          manifest.artifactType == ModelBundleArtifactType.officialOnnx ||
          manifest.artifactType == ModelBundleArtifactType.officialGguf) &&
      manifest.artifactUri.startsWith('hf://') &&
      ModelSourceGovernance.isAcceptedOfficialOrganization(
        manifest.officialOrganization,
      ) &&
      manifest.commercialUse != CommercialUseStatus.blocked &&
      manifest.license != ModelBundleLicense.nonCommercial &&
      manifest.approvalStatus != ModelBundleApprovalStatus.blocked &&
      (!manifest.acceptedTermsRequired ||
          acceptedTerms.contains(manifest.modelId));

  bool _canInstallConverted(ModelBundleManifest manifest) =>
      manifest.artifactType ==
          ModelBundleArtifactType.internalQuantizedArtifact &&
      manifest.conversionRecipeId != null &&
      manifest.validateForProductionSelection().isEmpty;

  void _setPipeline(String pipelineId) {
    ref.read(settingsNotifierProvider.notifier).setAnalysisPipeline(pipelineId);
  }

  void _setRuntime(String runtimeId) {
    ref.read(settingsNotifierProvider.notifier).setLocalRuntime(runtimeId);
  }

  void _selectBundle(ModelBundleRole role, String? modelId) {
    ref.read(settingsNotifierProvider.notifier).selectModelBundleForRole(
          role: role.name,
          modelBundleId: modelId,
        );
  }

  void _setTermsAccepted(ModelBundleManifest manifest, bool accepted) {
    ref.read(settingsNotifierProvider.notifier).setModelBundleTermsAccepted(
          modelBundleId: manifest.modelId,
          accepted: accepted,
        );
  }

  void _downloadOfficial(
    ModelBundleManifest manifest,
    Set<String> acceptedTerms,
  ) {
    ref.read(modelNotifierProvider.notifier).downloadModelBundle(
          manifest,
          acceptedTerms: acceptedTerms,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${manifest.displayName} from official repo'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _queueConvertedInstall(String modelId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Converted artifact install requires KidsLens artifact'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _installRuntime(LocalRuntimeId runtimeId) {
    ref.read(settingsNotifierProvider.notifier).setLocalRuntime(
          runtimeId.jsonValue,
        );
    ref.read(runtimeBinaryNotifierProvider.notifier).ensureInstalled(runtimeId);
  }

  void _refreshRuntimeState() {
    ref.read(runtimeBinaryNotifierProvider.notifier).loadInstallStates();
  }
}

class _LocalRuntimeCard extends StatelessWidget {
  const _LocalRuntimeCard({
    required this.runtimeState,
    required this.selectedRuntimeId,
    required this.onRuntimeChanged,
    required this.onInstall,
    required this.onRefresh,
  });

  final RuntimeBinaryState runtimeState;
  final String selectedRuntimeId;
  final ValueChanged<String> onRuntimeChanged;
  final ValueChanged<LocalRuntimeId> onInstall;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('local_ai_runtime_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.developer_board, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Local AI Runtime',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: runtimeState.isLoading ? null : onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh local runtime status',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Install the verified llama.cpp server used by local VLM analysis.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (runtimeState.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                runtimeState.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _RuntimeInstallTile(
                  spec: RuntimeBinaryManager.pinnedCudaSpec,
                  installState:
                      runtimeState.installStates[LocalRuntimeId.cudaLlamaCpp],
                  progress:
                      runtimeState.activeInstalls[LocalRuntimeId.cudaLlamaCpp],
                  selectedRuntimeId: selectedRuntimeId,
                  onRuntimeChanged: onRuntimeChanged,
                  onInstall: onInstall,
                ),
                _RuntimeInstallTile(
                  spec: RuntimeBinaryManager.pinnedVulkanSpec,
                  installState:
                      runtimeState.installStates[LocalRuntimeId.vulkanLlamaCpp],
                  progress: runtimeState
                      .activeInstalls[LocalRuntimeId.vulkanLlamaCpp],
                  selectedRuntimeId: selectedRuntimeId,
                  onRuntimeChanged: onRuntimeChanged,
                  onInstall: onInstall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RuntimeInstallTile extends StatelessWidget {
  const _RuntimeInstallTile({
    required this.spec,
    required this.installState,
    required this.progress,
    required this.selectedRuntimeId,
    required this.onRuntimeChanged,
    required this.onInstall,
  });

  final RuntimeBinarySpec spec;
  final RuntimeBinaryInstallState? installState;
  final RuntimeBinaryInstallProgress? progress;
  final String selectedRuntimeId;
  final ValueChanged<String> onRuntimeChanged;
  final ValueChanged<LocalRuntimeId> onInstall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInstalled = installState?.isInstalled ?? false;
    final isInstalling = progress != null;
    final runtimeId = spec.runtimeId;
    final isSelected = selectedRuntimeId == runtimeId.jsonValue;
    final statusLabel = isInstalled
        ? 'Installed'
        : isInstalling
            ? _installProgressLabel(progress!)
            : 'Not installed';

    return SizedBox(
      width: 360,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      spec.displayName,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  _StatusChip(
                    label: statusLabel,
                    icon: isInstalled ? Icons.check_circle : Icons.download,
                    color: isInstalled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${spec.sourceRepo} · ${_formatBytes(spec.totalBytes)} · tag ${spec.tag}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (isInstalling) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress!.percentage),
                const SizedBox(height: 4),
                Text(
                  progress!.currentAsset ?? 'Installing runtime',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: Key('${runtimeId.jsonValue}_select_runtime_button'),
                    onPressed: isSelected
                        ? null
                        : () => onRuntimeChanged(runtimeId.jsonValue),
                    icon: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    label: Text(isSelected ? 'Selected' : 'Use Runtime'),
                  ),
                  FilledButton.icon(
                    key: Key('${runtimeId.jsonValue}_install_runtime_button'),
                    onPressed: isInstalled || isInstalling
                        ? null
                        : () => onInstall(runtimeId),
                    icon: Icon(isInstalled ? Icons.check : Icons.download),
                    label: Text(isInstalled ? 'Installed' : 'Install'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.settings,
    required this.policy,
    required this.acceptedTerms,
    required this.localRuntimeId,
    required this.modelBundleIdsByRole,
    required this.onPipelineChanged,
    required this.onRuntimeChanged,
    required this.onBundleSelected,
  });

  final AnalysisSettings settings;
  final ModelBundleSelectionPolicy policy;
  final Set<String> acceptedTerms;
  final String localRuntimeId;
  final Map<String, String> modelBundleIdsByRole;
  final ValueChanged<String> onPipelineChanged;
  final ValueChanged<String> onRuntimeChanged;
  final void Function(ModelBundleRole role, String? modelId) onBundleSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Selection', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _DropdownField<String>(
                  key: const Key('pipeline_selector'),
                  label: 'Pipeline',
                  width: 320,
                  value: settings.analysisPipelineId,
                  items: DetectionPipelineProfile.builtInProfiles
                      .map(
                        (profile) => DropdownMenuItem(
                          value: profile.id,
                          child: Text(_pipelineLabel(profile)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onPipelineChanged(value);
                    }
                  },
                ),
                _DropdownField<String>(
                  key: const Key('local_runtime_selector'),
                  label: 'Local Runtime',
                  width: 300,
                  value: localRuntimeId,
                  items: LocalRuntimeProfile.profiles
                      .map(
                        (profile) => DropdownMenuItem(
                          value: profile.id.jsonValue,
                          child: Text(profile.displayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      onRuntimeChanged(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final role in ModelBundleRole.values)
                  _RoleSelector(
                    role: role,
                    policy: policy,
                    selectedModelId: modelBundleIdsByRole[role.name],
                    localRuntimeId: localRuntimeId,
                    acceptedTerms: acceptedTerms,
                    onChanged: (modelId) => onBundleSelected(role, modelId),
                  ),
              ],
            ),
            if (modelBundleIdsByRole.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'No production-approved local model bundles are selected.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.role,
    required this.policy,
    required this.selectedModelId,
    required this.localRuntimeId,
    required this.acceptedTerms,
    required this.onChanged,
  });

  final ModelBundleRole role;
  final ModelBundleSelectionPolicy policy;
  final String? selectedModelId;
  final String localRuntimeId;
  final Set<String> acceptedTerms;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectable = policy.selectableForRole(
      role: role,
      localRuntimeId: localRuntimeId,
      acceptedTerms: acceptedTerms,
    );
    final value =
        selectable.any((manifest) => manifest.modelId == selectedModelId)
            ? selectedModelId
            : null;
    return _DropdownField<String?>(
      key: Key('${role.name}_bundle_selector'),
      label: '${_roleLabel(role)} Bundle',
      width: 300,
      value: value,
      items: [
        DropdownMenuItem<String?>(
          child: Text(
            selectable.isEmpty ? 'No compatible bundle' : 'None selected',
          ),
        ),
        for (final manifest in selectable)
          DropdownMenuItem<String?>(
            value: manifest.modelId,
            child: Text(_bundleSelectorLabel(manifest)),
          ),
      ],
      onChanged: selectable.isEmpty ? null : onChanged,
    );
  }
}

class _ModelBundleCandidateTile extends StatelessWidget {
  const _ModelBundleCandidateTile({
    required this.manifest,
    required this.policy,
    required this.localRuntimeId,
    required this.acceptedTerms,
    required this.downloadProgress,
    required this.isDownloaded,
    required this.onAcceptTerms,
    required this.onInstallOfficial,
    required this.onInstallConverted,
  });

  final ModelBundleManifest manifest;
  final ModelBundleSelectionPolicy policy;
  final String localRuntimeId;
  final Set<String> acceptedTerms;
  final ModelDownloadProgress? downloadProgress;
  final bool isDownloaded;
  final ValueChanged<bool>? onAcceptTerms;
  final VoidCallback? onInstallOfficial;
  final VoidCallback? onInstallConverted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockers = {
      for (final role in manifest.roles)
        ...policy.blockers(
          manifest: manifest,
          role: role,
          localRuntimeId: localRuntimeId,
          acceptedTerms: acceptedTerms,
        ),
    }.toList(growable: false);
    final statusColor = blockers.isEmpty
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final isDownloading = downloadProgress != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.memory, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manifest.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${manifest.vendor} · ${manifest.officialSourceRepo}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(
                  label: policy.approvalLabel(manifest),
                  icon: blockers.isEmpty ? Icons.verified : Icons.lock,
                  color: blockers.isEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: 'Official source',
                  icon: Icons.domain_verification,
                  color: theme.colorScheme.primary,
                ),
                _StatusChip(
                  label: manifest.license.name,
                  icon: Icons.policy,
                  color: theme.colorScheme.secondary,
                ),
                _StatusChip(
                  label: policy.commercialUseLabel(manifest),
                  icon: Icons.business_center,
                  color: theme.colorScheme.tertiary,
                ),
                _StatusChip(
                  label: policy.checksumLabel(manifest),
                  icon: manifest.sha256 == null
                      ? Icons.pending_actions
                      : Icons.fact_check,
                  color: manifest.sha256 == null
                      ? theme.colorScheme.outline
                      : theme.colorScheme.primary,
                ),
                _StatusChip(
                  label: policy.termsLabel(manifest, acceptedTerms),
                  icon: manifest.acceptedTermsRequired
                      ? Icons.assignment_turned_in
                      : Icons.assignment,
                  color: manifest.acceptedTermsRequired
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.outline,
                ),
                _StatusChip(
                  label: manifest.fitsRtx5070Validated
                      ? 'RTX 5070 validated'
                      : 'RTX 5070 pending',
                  icon: Icons.developer_board,
                  color: manifest.fitsRtx5070Validated
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                _StatusChip(
                  label:
                      '${manifest.minVramGb.toStringAsFixed(0)}-${manifest.recommendedVramGb.toStringAsFixed(0)} GB VRAM',
                  icon: Icons.speed,
                  color: theme.colorScheme.secondary,
                ),
                _StatusChip(
                  label: _runtimeLabel(manifest.runtime),
                  icon: Icons.settings_input_component,
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CapabilityChip(
                  label: 'Video input',
                  enabled: manifest.supportsVideoInput,
                ),
                _CapabilityChip(
                  label: 'Image input',
                  enabled: manifest.supportsImageInput,
                ),
                _CapabilityChip(
                  label: 'Bounding boxes',
                  enabled: manifest.supportsBoundingBoxes,
                ),
                _CapabilityChip(
                  label: 'Masks',
                  enabled: manifest.supportsMasks,
                ),
                _CapabilityChip(
                  label: 'Point localization',
                  enabled: manifest.supportsPointLocalization,
                ),
              ],
            ),
            if (blockers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                blockers.join(' '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (manifest.acceptedTermsRequired)
                  FilterChip(
                    selected: acceptedTerms.contains(manifest.modelId),
                    label: const Text('Accept Terms'),
                    onSelected: onAcceptTerms,
                    avatar: const Icon(Icons.gavel, size: 18),
                  ),
                OutlinedButton.icon(
                  onPressed:
                      isDownloaded || isDownloading ? null : onInstallOfficial,
                  icon: Icon(isDownloaded ? Icons.check : Icons.download),
                  label: Text(
                    isDownloaded
                        ? 'Official Artifact Downloaded'
                        : isDownloading
                            ? 'Downloading ${(downloadProgress!.percentage * 100).toStringAsFixed(0)}%'
                            : 'Download Official Artifact',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onInstallConverted,
                  icon: const Icon(Icons.inventory),
                  label: const Text('Install Converted Artifact'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double width;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(label),
      );
}

class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(
        enabled ? Icons.check_circle : Icons.remove_circle_outline,
        size: 16,
        color: enabled ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      label: Text(label),
    );
  }
}

String _roleLabel(ModelBundleRole role) {
  switch (role) {
    case ModelBundleRole.vlm:
      return 'VLM';
    case ModelBundleRole.grounding:
      return 'Grounding';
    case ModelBundleRole.embedding:
      return 'Embedding';
  }
}

String _pipelineLabel(DetectionPipelineProfile profile) {
  if (profile.isDefaultForNewProjects) {
    return '${profile.displayName} (Default)';
  }
  if (profile.isLegacy) {
    return '${profile.displayName} (Legacy option)';
  }
  return profile.displayName;
}

String _runtimeLabel(ModelBundleRuntime runtime) {
  switch (runtime) {
    case ModelBundleRuntime.llamaCppServer:
      return 'llama.cpp server';
    case ModelBundleRuntime.cudaVllm:
      return 'CUDA vLLM';
    case ModelBundleRuntime.cudaTransformersHelper:
      return 'CUDA Transformers';
    case ModelBundleRuntime.cudaTensorRt:
      return 'CUDA TensorRT';
    case ModelBundleRuntime.directmlOnnx:
      return 'DirectML ONNX';
    case ModelBundleRuntime.cpuLightweight:
      return 'CPU Lightweight';
    case ModelBundleRuntime.notYetValidated:
      return 'Runtime pending';
  }
}

String _bundleSelectorLabel(ModelBundleManifest manifest) {
  if (manifest.approvalStatus == ModelBundleApprovalStatus.evaluationOnly) {
    return '${manifest.displayName} (ready to validate)';
  }
  return manifest.displayName;
}

String _installProgressLabel(RuntimeBinaryInstallProgress progress) {
  switch (progress.status) {
    case RuntimeBinaryInstallStatus.pending:
      return 'Pending';
    case RuntimeBinaryInstallStatus.downloading:
      return 'Downloading ${(progress.percentage * 100).toStringAsFixed(0)}%';
    case RuntimeBinaryInstallStatus.verifying:
      return 'Verifying';
    case RuntimeBinaryInstallStatus.extracting:
      return 'Extracting';
    case RuntimeBinaryInstallStatus.complete:
      return 'Installed';
    case RuntimeBinaryInstallStatus.failed:
      return 'Failed';
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
