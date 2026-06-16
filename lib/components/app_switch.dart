import 'package:flutter/material.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import '../resource/color_style_new.dart';

enum SwitchSize {
  sm,
  md,
  lg,
}

class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? description;
  final SwitchSize size;
  final bool disabled;

  const AppSwitch({
    Key? key,
    required this.value,
    this.onChanged,
    this.label,
    this.description,
    this.size = SwitchSize.md,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sizeConfig = _getSizeConfig(size);
    final isDisabled = disabled || onChanged == null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || description != null) ...[
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
                          ? NewAppColor.textTertiary
                          : NewAppColor.textStrong,
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
                        ? NewAppColor.textTertiary
                        : NewAppColor.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
        GestureDetector(
          onTap: isDisabled ? null : () => onChanged?.call(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: sizeConfig.trackWidth,
            height: sizeConfig.trackHeight,
            decoration: BoxDecoration(
              color: value
                ? (isDisabled ? NewAppColor.borderStrong : NewAppColor.skyPrimary)
                : (isDisabled ? NewAppColor.borderStrong : NewAppColor.textTertiary),
              borderRadius: BorderRadius.circular(sizeConfig.trackHeight / 2),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: value
                    ? sizeConfig.trackWidth - sizeConfig.thumbSize - 2
                    : 2,
                  top: 2,
                  child: Container(
                    width: sizeConfig.thumbSize,
                    height: sizeConfig.thumbSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  _SwitchSizeConfig _getSizeConfig(SwitchSize size) {
    switch (size) {
      case SwitchSize.sm:
        return const _SwitchSizeConfig(
          trackWidth: 32,
          trackHeight: 18,
          thumbSize: 14,
          fontSize: 12,
        );
      case SwitchSize.md:
        return const _SwitchSizeConfig(
          trackWidth: 40,
          trackHeight: 22,
          thumbSize: 18,
          fontSize: 14,
        );
      case SwitchSize.lg:
        return const _SwitchSizeConfig(
          trackWidth: 48,
          trackHeight: 26,
          thumbSize: 22,
          fontSize: 16,
        );
    }
  }

  // Named constructors for common use cases
  static AppSwitch simple({
    Key? key,
    required bool value,
    ValueChanged<bool>? onChanged,
    SwitchSize size = SwitchSize.md,
    bool disabled = false,
  }) {
    return AppSwitch(
      key: key,
      value: value,
      onChanged: onChanged,
      size: size,
      disabled: disabled,
    );
  }

  static AppSwitch labeled({
    Key? key,
    required bool value,
    ValueChanged<bool>? onChanged,
    required String label,
    String? description,
    SwitchSize size = SwitchSize.md,
    bool disabled = false,
  }) {
    return AppSwitch(
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

class _SwitchSizeConfig {
  final double trackWidth;
  final double trackHeight;
  final double thumbSize;
  final double fontSize;

  const _SwitchSizeConfig({
    required this.trackWidth,
    required this.trackHeight,
    required this.thumbSize,
    required this.fontSize,
  });
}
