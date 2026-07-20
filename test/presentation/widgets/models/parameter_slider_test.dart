import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/presentation/widgets/models/parameter_slider.dart';

void main() {
  group('ParameterSlider', () {
    Widget createParameterSlider({
      double value = 0.5,
      double min = 0.0,
      double max = 1.0,
      int? divisions,
      String? label,
      String? minLabel,
      String? maxLabel,
      ValueChanged<double>? onChanged,
      Color? activeColor,
      bool showValueIndicator = true,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: ParameterSlider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: label,
              minLabel: minLabel,
              maxLabel: maxLabel,
              onChanged: onChanged,
              activeColor: activeColor,
              showValueIndicator: showValueIndicator,
            ),
          ),
        );

    group('basic rendering', () {
      testWidgets('renders Slider widget', (tester) async {
        await tester.pumpWidget(createParameterSlider());

        expect(find.byType(Slider), findsOneWidget);
      });

      testWidgets('renders with correct initial value', (tester) async {
        await tester.pumpWidget(createParameterSlider(value: 0.75));

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, equals(0.75));
      });

      testWidgets('renders with correct min and max', (tester) async {
        await tester.pumpWidget(
          createParameterSlider(
            min: 10,
            max: 100,
            value: 50,
          ),
        );

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.min, equals(10.0));
        expect(slider.max, equals(100.0));
      });

      testWidgets('clamps value to valid range', (tester) async {
        await tester.pumpWidget(
          createParameterSlider(
            value: 2, // Out of range
          ),
        );

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.value, equals(1.0));
      });
    });

    group('labels', () {
      testWidgets('renders min label when provided', (tester) async {
        await tester.pumpWidget(
          createParameterSlider(
            minLabel: 'Low',
          ),
        );

        expect(find.text('Low'), findsOneWidget);
      });

      testWidgets('renders max label when provided', (tester) async {
        await tester.pumpWidget(
          createParameterSlider(
            maxLabel: 'High',
          ),
        );

        expect(find.text('High'), findsOneWidget);
      });

      testWidgets('renders both labels when provided', (tester) async {
        await tester.pumpWidget(
          createParameterSlider(
            minLabel: 'Min',
            maxLabel: 'Max',
          ),
        );

        expect(find.text('Min'), findsOneWidget);
        expect(find.text('Max'), findsOneWidget);
      });

      testWidgets('does not render labels when not provided', (tester) async {
        await tester.pumpWidget(createParameterSlider());

        // Only the slider should be present, no label texts
        expect(find.byType(Text), findsNothing);
      });
    });

    group('dragging', () {
      testWidgets('slider is draggable', (tester) async {
        await tester.pumpWidget(
          createParameterSlider(
            onChanged: (_) {},
          ),
        );

        final slider = find.byType(Slider);
        expect(slider, findsOneWidget);

        // Get slider bounds
        final sliderWidget = tester.widget<Slider>(slider);
        expect(sliderWidget.onChanged, isNotNull);
      });

      testWidgets('onChanged callback fires when dragged', (tester) async {
        double? changedValue;

        await tester.pumpWidget(
          createParameterSlider(
            onChanged: (value) => changedValue = value,
          ),
        );

        // Drag the slider
        await tester.drag(find.byType(Slider), const Offset(100, 0));
        await tester.pump();

        expect(changedValue, isNotNull);
      });

      testWidgets('slider is disabled when onChanged is null', (tester) async {
        await tester.pumpWidget(
          createParameterSlider(),
        );

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.onChanged, isNull);
      });
    });

    group('divisions', () {
      testWidgets('slider uses divisions when provided', (tester) async {
        await tester.pumpWidget(
          createParameterSlider(
            divisions: 10,
          ),
        );

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.divisions, equals(10));
      });

      testWidgets('slider is continuous when divisions is null',
          (tester) async {
        await tester.pumpWidget(
          createParameterSlider(),
        );

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.divisions, isNull);
      });
    });

    group('value indicator', () {
      testWidgets('shows label when showValueIndicator is true',
          (tester) async {
        await tester.pumpWidget(
          createParameterSlider(
            label: '50%',
          ),
        );

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.label, equals('50%'));
      });

      testWidgets('hides label when showValueIndicator is false',
          (tester) async {
        await tester.pumpWidget(
          createParameterSlider(
            label: '50%',
            showValueIndicator: false,
          ),
        );

        final slider = tester.widget<Slider>(find.byType(Slider));
        expect(slider.label, isNull);
      });
    });
  });

  group('LabeledParameterSlider', () {
    Widget createLabeledSlider({
      String label = 'Test Label',
      double value = 0.5,
      double min = 0.0,
      double max = 1.0,
      int? divisions,
      String? description,
      String? minLabel,
      String? maxLabel,
      String Function(double)? valueFormatter,
      ValueChanged<double>? onChanged,
      Color? activeColor,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: LabeledParameterSlider(
              label: label,
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              description: description,
              minLabel: minLabel,
              maxLabel: maxLabel,
              valueFormatter: valueFormatter ?? (v) => v.toStringAsFixed(2),
              onChanged: onChanged,
              activeColor: activeColor,
            ),
          ),
        );

    group('label rendering', () {
      testWidgets('renders label text', (tester) async {
        await tester.pumpWidget(
          createLabeledSlider(
            label: 'Confidence Threshold',
          ),
        );

        expect(find.text('Confidence Threshold'), findsOneWidget);
      });

      testWidgets('renders formatted value', (tester) async {
        await tester.pumpWidget(
          createLabeledSlider(
            value: 0.75,
            valueFormatter: (v) => '${(v * 100).round()}%',
          ),
        );

        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('renders description when provided', (tester) async {
        await tester.pumpWidget(
          createLabeledSlider(
            description: 'Adjust the sensitivity',
          ),
        );

        expect(find.text('Adjust the sensitivity'), findsOneWidget);
      });

      testWidgets('does not render description when null', (tester) async {
        await tester.pumpWidget(
          createLabeledSlider(),
        );

        expect(find.text('Adjust the sensitivity'), findsNothing);
      });
    });

    group('value display', () {
      testWidgets('value is displayed in container', (tester) async {
        await tester.pumpWidget(
          createLabeledSlider(
            value: 0.85,
            valueFormatter: (v) => '${(v * 100).round()}%',
          ),
        );

        expect(find.text('85%'), findsOneWidget);
      });

      testWidgets('updates displayed value when changed', (tester) async {
        var currentValue = 0.5;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) => MaterialApp(
              home: Scaffold(
                body: LabeledParameterSlider(
                  label: 'Test',
                  value: currentValue,
                  min: 0,
                  max: 1,
                  valueFormatter: (v) => '${(v * 100).round()}%',
                  onChanged: (v) {
                    setState(() => currentValue = v);
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('50%'), findsOneWidget);

        // Drag slider
        await tester.drag(find.byType(Slider), const Offset(100, 0));
        await tester.pump();

        // Value should have changed (not 50% anymore)
        expect(currentValue, isNot(0.5));
      });
    });

    group('nested ParameterSlider', () {
      testWidgets('contains ParameterSlider widget', (tester) async {
        await tester.pumpWidget(createLabeledSlider());

        expect(find.byType(ParameterSlider), findsOneWidget);
      });

      testWidgets('passes min/max labels to nested slider', (tester) async {
        await tester.pumpWidget(
          createLabeledSlider(
            minLabel: 'Slow',
            maxLabel: 'Fast',
          ),
        );

        expect(find.text('Slow'), findsOneWidget);
        expect(find.text('Fast'), findsOneWidget);
      });
    });
  });

  group('IntegerParameterSlider', () {
    Widget createIntegerSlider({
      String label = 'Test Label',
      int value = 5,
      int min = 0,
      int max = 10,
      String? description,
      String? minLabel,
      String? maxLabel,
      String? suffix,
      ValueChanged<int>? onChanged,
      Color? activeColor,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: IntegerParameterSlider(
              label: label,
              value: value,
              min: min,
              max: max,
              description: description,
              minLabel: minLabel,
              maxLabel: maxLabel,
              suffix: suffix,
              onChanged: onChanged,
              activeColor: activeColor,
            ),
          ),
        );

    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        createIntegerSlider(
          label: 'Frame Rate',
        ),
      );

      expect(find.text('Frame Rate'), findsOneWidget);
    });

    testWidgets('displays integer value', (tester) async {
      await tester.pumpWidget(
        createIntegerSlider(
          value: 30,
          min: 1,
          max: 60,
        ),
      );

      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('displays value with suffix', (tester) async {
      await tester.pumpWidget(
        createIntegerSlider(
          value: 30,
          min: 1,
          max: 60,
          suffix: ' fps',
        ),
      );

      expect(find.text('30 fps'), findsOneWidget);
    });

    testWidgets('uses default min/max labels', (tester) async {
      await tester.pumpWidget(
        createIntegerSlider(
          max: 100,
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('calls onChanged with integer value', (tester) async {
      int? changedValue;

      await tester.pumpWidget(
        createIntegerSlider(
          onChanged: (v) => changedValue = v,
        ),
      );

      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();

      expect(changedValue, isNotNull);
      expect(changedValue, isA<int>());
    });

    testWidgets('has correct number of divisions', (tester) async {
      await tester.pumpWidget(
        createIntegerSlider(),
      );

      // IntegerParameterSlider creates divisions = max - min
      final sliderFinder = find.byType(Slider);
      final slider = tester.widget<Slider>(sliderFinder);
      expect(slider.divisions, equals(10));
    });
  });

  group('PercentageSlider', () {
    Widget createPercentageSlider({
      String label = 'Test Label',
      double value = 0.5,
      String? description,
      ValueChanged<double>? onChanged,
      Color? activeColor,
      int divisions = 20,
    }) =>
        MaterialApp(
          home: Scaffold(
            body: PercentageSlider(
              label: label,
              value: value,
              description: description,
              onChanged: onChanged,
              activeColor: activeColor,
              divisions: divisions,
            ),
          ),
        );

    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        createPercentageSlider(
          label: 'Opacity',
        ),
      );

      expect(find.text('Opacity'), findsOneWidget);
    });

    testWidgets('displays value as percentage', (tester) async {
      await tester.pumpWidget(
        createPercentageSlider(
          value: 0.75,
        ),
      );

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('shows 0% and 100% labels', (tester) async {
      await tester.pumpWidget(createPercentageSlider());

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('has slider with 0 to 1 range', (tester) async {
      await tester.pumpWidget(
        createPercentageSlider(),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, equals(0));
      expect(slider.max, equals(1));
    });

    testWidgets('uses custom divisions', (tester) async {
      await tester.pumpWidget(
        createPercentageSlider(
          divisions: 10,
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, equals(10));
    });

    testWidgets('renders description when provided', (tester) async {
      await tester.pumpWidget(
        createPercentageSlider(
          description: 'Adjust transparency level',
        ),
      );

      expect(find.text('Adjust transparency level'), findsOneWidget);
    });
  });
}
