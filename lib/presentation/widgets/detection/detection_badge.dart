import 'package:flutter/material.dart';

import 'package:kidslens_video_editor/presentation/themes/app_theme.dart';

/// Badge showing detection count by type
class DetectionBadge extends StatelessWidget {
  const DetectionBadge({
    required this.type,
    required this.count,
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  final String type;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getDetectionColor(type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIcon(type),
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                _formatType(type),
                style: TextStyle(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) => switch (type) {
        'profanity' => Icons.mic_off,
        'nudity' => Icons.visibility_off,
        'violence' => Icons.warning,
        'blood' => Icons.water_drop,
        'weapons' => Icons.gpp_bad,
        _ => Icons.error,
      };

  String _formatType(String type) => type[0].toUpperCase() + type.substring(1);
}
