import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';

class AppDropdownMenuItem<T> {
  final T value;
  final String text;
  final Widget? leading;
  final Widget? trailing;

  const AppDropdownMenuItem({
    required this.value,
    required this.text,
    this.leading,
    this.trailing,
  });
}

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final T? value;
  final List<AppDropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? errorText;
  final bool disabled;
  final Widget? prefixIcon;
  final double? width;
  final double? height;

  const AppDropdown({
    Key? key,
    this.label,
    this.placeholder,
    this.value,
    required this.items,
    this.onChanged,
    this.errorText,
    this.disabled = false,
    this.prefixIcon,
    this.width,
    this.height,
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
              color: NewAppColor.textStrong,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          width: width,
          height: height ?? 44,
          decoration: BoxDecoration(
            border: Border.all(
              color: errorText != null 
                ? NewAppColor.danger700
                : disabled 
                  ? NewAppColor.borderStrong
                  : NewAppColor.borderHair,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: disabled ? NewAppColor.canvasAlt : Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Row(
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      placeholder ?? 'Select an option',
                      style: const TextStyle(
                        fontSize: 14,
                        color: NewAppColor.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item.value,
                  child: Row(
                    children: [
                      if (item.leading != null) ...[
                        item.leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          item.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: NewAppColor.textStrong,
                          ),
                        ),
                      ),
                      if (item.trailing != null) item.trailing!,
                    ],
                  ),
                );
              }).toList(),
              onChanged: disabled ? null : onChanged,
              isExpanded: true,
              icon: const Icon(
                LucideIcons.chevronDown,
                color: NewAppColor.textTertiary,
              ),
              dropdownColor: Colors.white,
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              menuMaxHeight: 200,
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: 12,
              color: NewAppColor.danger700,
            ),
          ),
        ],
      ],
    );
  }

  // Named constructors for common use cases
  static AppDropdown<String> text({
    Key? key,
    String? label,
    String? placeholder,
    String? value,
    required List<String> options,
    ValueChanged<String?>? onChanged,
    String? errorText,
    bool disabled = false,
    Widget? prefixIcon,
    double? width,
    double? height,
  }) {
    return AppDropdown<String>(
      key: key,
      label: label,
      placeholder: placeholder,
      value: value,
      items: options.map((option) => AppDropdownMenuItem(
        value: option,
        text: option,
      )).toList(),
      onChanged: onChanged,
      errorText: errorText,
      disabled: disabled,
      prefixIcon: prefixIcon,
      width: width,
      height: height,
    );
  }

  static AppDropdown<int> integer({
    Key? key,
    String? label,
    String? placeholder,
    int? value,
    required List<int> options,
    ValueChanged<int?>? onChanged,
    String? errorText,
    bool disabled = false,
    Widget? prefixIcon,
    double? width,
    double? height,
  }) {
    return AppDropdown<int>(
      key: key,
      label: label,
      placeholder: placeholder,
      value: value,
      items: options.map((option) => AppDropdownMenuItem(
        value: option,
        text: option.toString(),
      )).toList(),
      onChanged: onChanged,
      errorText: errorText,
      disabled: disabled,
      prefixIcon: prefixIcon,
      width: width,
      height: height,
    );
  }
}
