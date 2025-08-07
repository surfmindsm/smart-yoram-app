import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum CheckboxSize {
  sm,
  md,
  lg,
}

class AppCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final String? description;
  final CheckboxSize size;
  final bool disabled;
  final String? errorText;

  const AppCheckbox({
    Key? key,
    required this.value,
    this.onChanged,
    this.label,
    this.description,
    this.size = CheckboxSize.md,
    this.disabled = false,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sizeConfig = _getSizeConfig(size);
    final isDisabled = disabled || onChanged == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: isDisabled ? null : () => onChanged?.call(!value),
              child: Container(
                width: sizeConfig.checkboxSize,
                height: sizeConfig.checkboxSize,
                decoration: BoxDecoration(
                  color: value 
                    ? (isDisabled ? AppColor.secondary02 : AppColor.primary600)
                    : AppColor.white,
                  border: Border.all(
                    color: errorText != null
                      ? AppColor.error
                      : value
                        ? (isDisabled ? AppColor.secondary02 : AppColor.primary600)
                        : (isDisabled ? AppColor.secondary02 : AppColor.border1),
                    width: value ? 0 : 1,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: value
                  ? Icon(
                      Icons.check,
                      size: sizeConfig.iconSize,
                      color: AppColor.white,
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
                        onTap: isDisabled ? null : () => onChanged?.call(!value),
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

  _CheckboxSizeConfig _getSizeConfig(CheckboxSize size) {
    switch (size) {
      case CheckboxSize.sm:
        return const _CheckboxSizeConfig(
          checkboxSize: 16,
          iconSize: 12,
          fontSize: 12,
        );
      case CheckboxSize.md:
        return const _CheckboxSizeConfig(
          checkboxSize: 20,
          iconSize: 16,
          fontSize: 14,
        );
      case CheckboxSize.lg:
        return const _CheckboxSizeConfig(
          checkboxSize: 24,
          iconSize: 18,
          fontSize: 16,
        );
    }
  }

  // Named constructors for common use cases
  static AppCheckbox simple({
    Key? key,
    required bool value,
    ValueChanged<bool?>? onChanged,
    required String label,
    CheckboxSize size = CheckboxSize.md,
    bool disabled = false,
  }) {
    return AppCheckbox(
      key: key,
      value: value,
      onChanged: onChanged,
      label: label,
      size: size,
      disabled: disabled,
    );
  }

  static AppCheckbox withDescription({
    Key? key,
    required bool value,
    ValueChanged<bool?>? onChanged,
    required String label,
    required String description,
    CheckboxSize size = CheckboxSize.md,
    bool disabled = false,
  }) {
    return AppCheckbox(
      key: key,
      value: value,
      onChanged: onChanged,
      label: label,
      description: description,
      size: size,
      disabled: disabled,
    );
  }
}

class _CheckboxSizeConfig {
  final double checkboxSize;
  final double iconSize;
  final double fontSize;

  const _CheckboxSizeConfig({
    required this.checkboxSize,
    required this.iconSize,
    required this.fontSize,
  });
}
