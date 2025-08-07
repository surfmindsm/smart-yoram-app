import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum RadioSize {
  sm,
  md,
  lg,
}

class AppRadioOption<T> {
  final T value;
  final String label;
  final String? description;

  const AppRadioOption({
    required this.value,
    required this.label,
    this.description,
  });
}

class AppRadio<T> extends StatelessWidget {
  final T? groupValue;
  final T value;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? description;
  final RadioSize size;
  final bool disabled;

  const AppRadio({
    Key? key,
    required this.groupValue,
    required this.value,
    this.onChanged,
    this.label,
    this.description,
    this.size = RadioSize.md,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sizeConfig = _getSizeConfig(size);
    final isSelected = groupValue == value;
    final isDisabled = disabled || onChanged == null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: isDisabled ? null : () => onChanged?.call(value),
          child: Container(
            width: sizeConfig.radioSize,
            height: sizeConfig.radioSize,
            decoration: BoxDecoration(
              color: AppColor.white,
              border: Border.all(
                color: isSelected
                  ? (isDisabled ? AppColor.secondary02 : AppColor.primary600)
                  : (isDisabled ? AppColor.secondary02 : AppColor.border1),
                width: isSelected ? 2 : 1,
              ),
              shape: BoxShape.circle,
            ),
            child: isSelected
              ? Center(
                  child: Container(
                    width: sizeConfig.innerDotSize,
                    height: sizeConfig.innerDotSize,
                    decoration: BoxDecoration(
                      color: isDisabled ? AppColor.secondary02 : AppColor.primary600,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
          ),
        ),
        if (label != null || description != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  GestureDetector(
                    onTap: isDisabled ? null : () => onChanged?.call(value),
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontSize: sizeConfig.fontSize,
                        fontWeight: FontWeight.w500,
                        color: isDisabled
                          ? AppColor.secondary03
                          : AppColor.secondary06,
                      ),
                    ),
                  ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: sizeConfig.fontSize - 2,
                      color: isDisabled
                        ? AppColor.secondary03
                        : AppColor.secondary04,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  _RadioSizeConfig _getSizeConfig(RadioSize size) {
    switch (size) {
      case RadioSize.sm:
        return const _RadioSizeConfig(
          radioSize: 16,
          innerDotSize: 6,
          fontSize: 12,
        );
      case RadioSize.md:
        return const _RadioSizeConfig(
          radioSize: 20,
          innerDotSize: 8,
          fontSize: 14,
        );
      case RadioSize.lg:
        return const _RadioSizeConfig(
          radioSize: 24,
          innerDotSize: 10,
          fontSize: 16,
        );
    }
  }
}

class AppRadioGroup<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<AppRadioOption<T>> options;
  final ValueChanged<T?>? onChanged;
  final RadioSize size;
  final bool disabled;
  final String? errorText;
  final Axis direction;
  final double spacing;

  const AppRadioGroup({
    Key? key,
    this.label,
    this.value,
    required this.options,
    this.onChanged,
    this.size = RadioSize.md,
    this.disabled = false,
    this.errorText,
    this.direction = Axis.vertical,
    this.spacing = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColor.secondary06,
            ),
          ),
          const SizedBox(height: 8),
        ],
        direction == Axis.vertical
          ? Column(
              children: options
                  .map((option) => Padding(
                        padding: EdgeInsets.only(
                          bottom: option == options.last ? 0 : spacing,
                        ),
                        child: AppRadio<T>(
                          groupValue: value,
                          value: option.value,
                          onChanged: onChanged,
                          label: option.label,
                          description: option.description,
                          size: size,
                          disabled: disabled,
                        ),
                      ))
                  .toList(),
            )
          : Wrap(
              spacing: spacing,
              children: options
                  .map((option) => AppRadio<T>(
                        groupValue: value,
                        value: option.value,
                        onChanged: onChanged,
                        label: option.label,
                        description: option.description,
                        size: size,
                        disabled: disabled,
                      ))
                  .toList(),
            ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColor.error,
            ),
          ),
        ],
      ],
    );
  }

  // Named constructor for simple string options
  static AppRadioGroup<String> text({
    Key? key,
    String? label,
    String? value,
    required List<String> options,
    ValueChanged<String?>? onChanged,
    RadioSize size = RadioSize.md,
    bool disabled = false,
    String? errorText,
    Axis direction = Axis.vertical,
    double spacing = 12,
  }) {
    return AppRadioGroup<String>(
      key: key,
      label: label,
      value: value,
      options: options.map((option) => AppRadioOption(
        value: option,
        label: option,
      )).toList(),
      onChanged: onChanged,
      size: size,
      disabled: disabled,
      errorText: errorText,
      direction: direction,
      spacing: spacing,
    );
  }
}

class _RadioSizeConfig {
  final double radioSize;
  final double innerDotSize;
  final double fontSize;

  const _RadioSizeConfig({
    required this.radioSize,
    required this.innerDotSize,
    required this.fontSize,
  });
}
