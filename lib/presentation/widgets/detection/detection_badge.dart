import 'package:flutter/material.dart';

import '../../themes/app_theme.dart';

/// Badge showing detection count by type
class DetectionBadge extends StatelessWidget {
  final String type;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  const DetectionBadge({
    super.key,
    required this.type,
    required this.count,
    this.isSelected = false,
    this.onTap,
  });

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
            color: isSelected ? color : color.withOpacity(0.1),
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
                      ? Colors.white.withOpacity(0.2)
                      : color.withOpacity(0.2),
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

  IconData _getIcon(String type) {
    return switch (type) {
      'profanity' => Icons.mic_off,
      'nudity' => Icons.visibility_off,
      'violence' => Icons.warning,
      'blood' => Icons.water_drop,
      'weapons' => Icons.gpp_bad,
      _ => Icons.error,
    };
  }

  String _formatType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }
}
