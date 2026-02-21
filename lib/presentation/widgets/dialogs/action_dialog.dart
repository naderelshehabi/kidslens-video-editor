import 'package:flutter/material.dart';

import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// Dialog for selecting an action for a detection
class ActionDialog extends StatelessWidget {
  const ActionDialog({
    required this.detection,
    super.key,
  });

  final Detection detection;

  /// Show the dialog and return the selected modification
  static Future<Modification?> show({
    required BuildContext context,
    required Detection detection,
  }) => showModalBottomSheet<Modification>(
      context: context,
      builder: (context) => ActionDialog(detection: detection),
    );

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getDetectionColor(detection.type.name);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getIcon(detection.type), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${detection.type.name.toUpperCase()} Detection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_formatTime(detection.startTime)} - ${_formatTime(detection.endTime)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              detection.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            // Actions
            Text(
              'Choose Action',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            if (detection.type == ContentType.profanity) ...[
              _buildActionTile(
                context,
                'Mute',
                'Silence the audio during this segment',
                Icons.volume_off,
                const Modification.audioMute(),
              ),
              _buildActionTile(
                context,
                'Bleep',
                'Replace with a censorship tone',
                Icons.music_note,
                const Modification.audioBeep(),
              ),
            ] else ...[
              _buildActionTile(
                context,
                'Blur',
                'Apply a blur effect to hide the content',
                Icons.blur_on,
                const Modification.videoBlur(),
              ),
              _buildActionTile(
                context,
                'Black Box',
                'Cover this area with a black box',
                Icons.square,
                const Modification.videoBlackBox(),
              ),
            ],
            _buildActionTile(
              context,
              'Skip',
              'Skip this segment during playback',
              Icons.skip_next,
              const Modification.videoSkip(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Modification modification,
  ) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.of(context).pop(modification),
    );

  IconData _getIcon(ContentType type) => switch (type) {
      ContentType.profanity => Icons.mic_off,
      ContentType.nsfw => Icons.visibility_off,
      ContentType.violence => Icons.warning,
      ContentType.blood => Icons.water_drop,
      ContentType.weapons => Icons.gpp_bad,
      ContentType.nudity => Icons.visibility_off,
      ContentType.sexualContent => Icons.block,
      ContentType.kissing => Icons.favorite,
      ContentType.immodestDress => Icons.checkroom,
      ContentType.custom => Icons.category,
    };

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
