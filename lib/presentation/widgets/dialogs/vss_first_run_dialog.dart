import 'package:flutter/material.dart';

enum VssFirstRunAction {
  download,
  useLegacy,
  cancel,
}

class VssFirstRunDialog extends StatelessWidget {
  const VssFirstRunDialog({
    required this.modelName,
    required this.runtimeName,
    required this.modelMissing,
    required this.runtimeMissing,
    super.key,
  });

  final String modelName;
  final String runtimeName;
  final bool modelMissing;
  final bool runtimeMissing;

  static Future<VssFirstRunAction?> show({
    required BuildContext context,
    required String modelName,
    required String runtimeName,
    required bool modelMissing,
    required bool runtimeMissing,
  }) =>
      showDialog<VssFirstRunAction>(
        context: context,
        builder: (context) => VssFirstRunDialog(
          modelName: modelName,
          runtimeName: runtimeName,
          modelMissing: modelMissing,
          runtimeMissing: runtimeMissing,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('vss_first_run_dialog'),
      title: const Text('Download Local AI Runtime'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Family-safety AI analysis needs a one-time local download before it can run.',
            ),
            const SizedBox(height: 12),
            if (modelMissing)
              _RequirementRow(
                icon: Icons.memory,
                label: modelName,
                detail: 'Official VLM bundle, about 5.8 GB',
              ),
            if (runtimeMissing)
              _RequirementRow(
                icon: Icons.developer_board,
                label: runtimeName,
                detail: 'Verified llama.cpp runtime, about 0.5 GB for CUDA',
              ),
            const SizedBox(height: 12),
            Text(
              'Downloads come from official public repositories and analysis remains local after installation.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(VssFirstRunAction.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(VssFirstRunAction.useLegacy),
          child: const Text('Use Legacy Analysis Instead'),
        ),
        FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).pop(VssFirstRunAction.download),
          icon: const Icon(Icons.download),
          label: const Text('Download Now'),
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
