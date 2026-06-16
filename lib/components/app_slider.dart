import 'package:flutter/material.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';

class AppSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? description;
  final bool disabled;
  final bool showValue;
  final String Function(double)? valueFormatter;

  const AppSlider({
    Key? key,
    required this.value,
    this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.description,
    this.disabled = false,
    this.showValue = false,
    this.valueFormatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: NewAppColor.textStrong,
                ),
              ),
              if (showValue)
                Text(
                  valueFormatter?.call(value) ?? value.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: NewAppColor.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: isDisabled ? NewAppColor.borderStrong : NewAppColor.skyPrimary,
            inactiveTrackColor: Colors.white,
            thumbColor: isDisabled ? NewAppColor.borderStrong : NewAppColor.skyPrimary,
            overlayColor: NewAppColor.skyPrimary.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            trackShape: const RectangularSliderTrackShape(),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: isDisabled ? null : onChanged,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              fontSize: 12,
              color: isDisabled ? NewAppColor.textTertiary : NewAppColor.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  // Named constructors for common use cases
  static AppSlider percentage({
    Key? key,
    required double value,
    ValueChanged<double>? onChanged,
    String? label,
    String? description,
    bool disabled = false,
    bool showValue = true,
  }) {
    return AppSlider(
      key: key,
      value: value,
      onChanged: onChanged,
      min: 0,
      max: 100,
      label: label,
      description: description,
      disabled: disabled,
      showValue: showValue,
      valueFormatter: (value) => '${value.round()}%',
    );
  }

  static AppSlider range({
    Key? key,
    required double value,
    ValueChanged<double>? onChanged,
    required double min,
    required double max,
    int? divisions,
    String? label,
    String? description,
    bool disabled = false,
    bool showValue = true,
    String Function(double)? valueFormatter,
  }) {
    return AppSlider(
      key: key,
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
      divisions: divisions,
      label: label,
      description: description,
      disabled: disabled,
      showValue: showValue,
      valueFormatter: valueFormatter,
    );
  }
}

class AppRangeSlider extends StatelessWidget {
  final RangeValues values;
  final ValueChanged<RangeValues>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final String? description;
  final bool disabled;
  final bool showValues;
  final String Function(double)? valueFormatter;

  const AppRangeSlider({
    Key? key,
    required this.values,
    this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
    this.description,
    this.disabled = false,
    this.showValues = false,
    this.valueFormatter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: NewAppColor.textStrong,
                ),
              ),
              if (showValues)
                Text(
                  '${valueFormatter?.call(values.start) ?? values.start.toStringAsFixed(1)} - ${valueFormatter?.call(values.end) ?? values.end.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: NewAppColor.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: isDisabled ? NewAppColor.borderStrong : NewAppColor.skyPrimary,
            inactiveTrackColor: Colors.white,
            thumbColor: isDisabled ? NewAppColor.borderStrong : NewAppColor.skyPrimary,
            overlayColor: NewAppColor.skyPrimary.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            tickMarkShape: SliderTickMarkShape.noTickMark,
            trackShape: const RectangularSliderTrackShape(),
          ),
          child: RangeSlider(
            values: RangeValues(
              values.start.clamp(min, max),
              values.end.clamp(min, max),
            ),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: isDisabled ? null : onChanged,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              fontSize: 12,
              color: isDisabled ? NewAppColor.textTertiary : NewAppColor.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  // Named constructors for common use cases
  static AppRangeSlider percentage({
    Key? key,
    required RangeValues values,
    ValueChanged<RangeValues>? onChanged,
    String? label,
    String? description,
    bool disabled = false,
    bool showValues = true,
  }) {
    return AppRangeSlider(
      key: key,
      values: values,
      onChanged: onChanged,
      min: 0,
      max: 100,
      label: label,
      description: description,
      disabled: disabled,
      showValues: showValues,
      valueFormatter: (value) => '${value.round()}%',
    );
  }
}
