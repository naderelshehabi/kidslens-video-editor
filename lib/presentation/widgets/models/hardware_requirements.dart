import 'package:flutter/material.dart';
import 'package:kidslens_video_editor/data/models/gpu_info.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// Widget for displaying hardware requirements and comparing to available hardware
class HardwareRequirements extends StatelessWidget {
  const HardwareRequirements({
    super.key,
    this.systemCapabilities,
    this.requiredRamMB,
    this.requiredVramMB,
    this.requiresGpu = false,
    this.isLoading = false,
  });

  final SystemCapabilities? systemCapabilities;
  final int? requiredRamMB;
  final int? requiredVramMB;
  final bool requiresGpu;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final caps = systemCapabilities;
    if (caps == null) {
      return _buildNoHardwareInfo(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Requirements Check',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // RAM check
            _buildRequirementRow(
              context,
              icon: Icons.memory,
              label: 'RAM',
              available:
                  '${(caps.availableRamMB / 1024).toStringAsFixed(1)} GB available',
              required: requiredRamMB != null
                  ? '${(requiredRamMB! / 1024).toStringAsFixed(1)} GB required'
                  : null,
              isSatisfied: requiredRamMB == null ||
                  caps.availableRamMB >= requiredRamMB!,
            ),
            const SizedBox(height: 12),
            // VRAM check (if GPU required)
            if (requiresGpu || requiredVramMB != null) ...[
              _buildRequirementRow(
                context,
                icon: Icons.videogame_asset,
                label: 'GPU/VRAM',
                available: caps.accelerator != null
                    ? '${(caps.accelerator!.vramMB / 1024).toStringAsFixed(1)} GB available'
                    : 'No GPU detected',
                required: requiredVramMB != null
                    ? '${(requiredVramMB! / 1024).toStringAsFixed(1)} GB required'
                    : 'GPU recommended',
                isSatisfied: !requiresGpu ||
                    (caps.accelerator != null &&
                        (requiredVramMB == null ||
                            caps.accelerator!.vramMB >= requiredVramMB!)),
              ),
              const SizedBox(height: 12),
            ],
            // Disk space check
            _buildRequirementRow(
              context,
              icon: Icons.storage,
              label: 'Disk Space',
              available:
                  '${(caps.availableDiskSpaceMB / 1024).toStringAsFixed(1)} GB free',
              isSatisfied:
                  caps.availableDiskSpaceMB >= 1024, // At least 1GB free
            ),
            const SizedBox(height: 16),
            // Overall status
            _buildOverallStatus(context, caps),
          ],
        ),
      ),
    );
  }

  Widget _buildNoHardwareInfo(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hardware information unavailable. Requirements cannot be verified.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildRequirementRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String available,
    required bool isSatisfied,
    String? required,
  }) {
    final theme = Theme.of(context);
    final statusColor =
        isSatisfied ? AppTheme.successColor : AppTheme.errorColor;
    final statusIcon = isSatisfied ? Icons.check_circle : Icons.error;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                available,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (required != null)
          Expanded(
            flex: 2,
            child: Text(
              required,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Icon(
          statusIcon,
          size: 20,
          color: statusColor,
        ),
      ],
    );
  }

  Widget _buildOverallStatus(BuildContext context, SystemCapabilities caps) {
    final hasGpu = caps.accelerator != null;
    final hasEnoughRam = caps.availableRamMB >= 4096; // 4GB minimum
    final hasEnoughDisk = caps.availableDiskSpaceMB >= 1024; // 1GB minimum

    final allSatisfied = hasEnoughRam && hasEnoughDisk;
    final hasWarnings = !hasGpu;

    if (allSatisfied && !hasWarnings) {
      return _buildStatusBanner(
        context,
        icon: Icons.check_circle,
        color: AppTheme.successColor,
        title: 'System Ready',
        message: 'Your system meets all requirements for AI analysis.',
      );
    }

    if (allSatisfied && hasWarnings) {
      return _buildStatusBanner(
        context,
        icon: Icons.warning_amber,
        color: AppTheme.warningColor,
        title: 'System Ready (with warnings)',
        message:
            'Your system can run AI analysis, but a GPU is recommended for faster processing.',
      );
    }

    return _buildStatusBanner(
      context,
      icon: Icons.error,
      color: AppTheme.errorColor,
      title: 'Requirements Not Met',
      message: 'Your system may not have sufficient resources for AI analysis.',
    );
  }

  Widget _buildStatusBanner(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Compact widget showing hardware warning for a specific model
class HardwareWarningChip extends StatelessWidget {
  const HardwareWarningChip({
    required this.message,
    super.key,
  });

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border:
              Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber,
              size: 12,
              color: AppTheme.warningColor,
            ),
            const SizedBox(width: 4),
            Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.warningColor,
              ),
            ),
          ],
        ),
      );
}
