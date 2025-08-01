import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/text_style.dart';
import 'package:smart_yoram_app/resource/color_style.dart';

/// 공통 폼 필드 위젯
class CustomFormField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool required;
  // InputDecoration 관련 속성들
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? enabledBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final bool filled;
  final Color? fillColor;
  final EdgeInsetsGeometry? contentPadding;
  final Color? prefixIconColor;
  final Color? suffixIconColor;

  const CustomFormField({
    super.key,
    required this.label,
    this.hintText,
    this.hintStyle,
    this.labelStyle,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.required = false,
    // InputDecoration 관련 속성들
    this.border,
    this.focusedBorder,
    this.enabledBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.filled = false,
    this.fillColor,
    this.contentPadding,
    this.prefixIconColor,
    this.suffixIconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: labelStyle ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              if (hintText != null) ...[
                const SizedBox(width: 4),
                Text(
                  hintText!,
                  style: hintStyle,
                ),
              ],
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          validator: validator,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: hintStyle,
            border: border ?? OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: focusedBorder ?? OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColor.primary900),
            ),
            enabledBorder: enabledBorder,
            errorBorder: errorBorder,
            focusedErrorBorder: focusedErrorBorder,
            suffixIcon: suffixIcon,
            prefixIcon: prefixIcon != null ? IconTheme(
              data: IconThemeData(color: prefixIconColor),
              child: prefixIcon!,
            ) : null,
            filled: filled || !enabled,
            fillColor: fillColor ?? (enabled ? null : Colors.grey[100]),
            contentPadding: contentPadding,
          ),
        ),
      ],
    );
  }
}

/// 드롭다운 폼 필드 위젯
class CustomDropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final bool enabled;
  final bool required;

  const CustomDropdownField({
    super.key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.hintText,
    this.hintStyle,
    this.labelStyle,
    this.enabled = true,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: labelStyle ??
                  const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: hintStyle,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColor.primary900),
            ),
            filled: !enabled,
            fillColor: enabled ? null : Colors.grey[100],
          ),
        ),
      ],
    );
  }
}
