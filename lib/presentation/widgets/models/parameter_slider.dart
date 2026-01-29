import 'package:flutter/material.dart';

/// Reusable slider widget with labels and optional step snapping
class ParameterSlider extends StatelessWidget {
  const ParameterSlider({
    required this.value,
    required this.min,
    required this.max,
    super.key,
    this.divisions,
    this.label,
    this.minLabel,
    this.maxLabel,
    this.onChanged,
    this.activeColor,
    this.showValueIndicator = true,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? minLabel;
  final String? maxLabel;
  final ValueChanged<double>? onChanged;
  final Color? activeColor;
  final bool showValueIndicator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sliderTheme = theme.sliderTheme.copyWith(
      activeTrackColor: activeColor,
      thumbColor: activeColor,
      overlayColor: activeColor?.withValues(alpha: 0.12),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SliderTheme(
          data: sliderTheme,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: showValueIndicator ? label : null,
            onChanged: onChanged,
          ),
        ),
        if (minLabel != null || maxLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (minLabel != null)
                  Text(
                    minLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (maxLabel != null)
                  Text(
                    maxLabel!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
      ],
    );
  }
}

/// Slider with a label showing the current value
class LabeledParameterSlider extends StatelessWidget {
  const LabeledParameterSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.valueFormatter,
    super.key,
    this.divisions,
    this.description,
    this.minLabel,
    this.maxLabel,
    this.onChanged,
    this.activeColor,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? description;
  final String? minLabel;
  final String? maxLabel;
  final String Function(double value) valueFormatter;
  final ValueChanged<double>? onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: (activeColor ?? theme.colorScheme.primary)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                valueFormatter(value),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: activeColor ?? theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        ParameterSlider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: valueFormatter(value),
          minLabel: minLabel,
          maxLabel: maxLabel,
          onChanged: onChanged,
          activeColor: activeColor,
        ),
      ],
    );
  }
}

/// Slider for integer values
class IntegerParameterSlider extends StatelessWidget {
  const IntegerParameterSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    super.key,
    this.description,
    this.minLabel,
    this.maxLabel,
    this.suffix,
    this.onChanged,
    this.activeColor,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String? description;
  final String? minLabel;
  final String? maxLabel;
  final String? suffix;
  final ValueChanged<int>? onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) => LabeledParameterSlider(
      label: label,
      value: value.toDouble(),
      min: min.toDouble(),
      max: max.toDouble(),
      divisions: max - min,
      description: description,
      minLabel: minLabel ?? '$min',
      maxLabel: maxLabel ?? '$max',
      valueFormatter: (v) =>
          suffix != null ? '${v.round()}$suffix' : '${v.round()}',
      onChanged: onChanged != null ? (v) => onChanged!(v.round()) : null,
      activeColor: activeColor,
    );
}

/// Slider for percentage values (0-100)
class PercentageSlider extends StatelessWidget {
  const PercentageSlider({
    required this.label,
    required this.value,
    super.key,
    this.description,
    this.onChanged,
    this.activeColor,
    this.divisions = 20,
  });

  final String label;
  final double value; // 0.0 to 1.0
  final String? description;
  final ValueChanged<double>? onChanged;
  final Color? activeColor;
  final int divisions;

  @override
  Widget build(BuildContext context) => LabeledParameterSlider(
      label: label,
      value: value,
      min: 0,
      max: 1,
      divisions: divisions,
      description: description,
      minLabel: '0%',
      maxLabel: '100%',
      valueFormatter: (v) => '${(v * 100).round()}%',
      onChanged: onChanged,
      activeColor: activeColor,
    );
}
