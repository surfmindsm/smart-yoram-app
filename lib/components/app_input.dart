import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 입력 필드 크기 — 작은(sm) / 보통(md, 기본) / 큰(lg)
enum InputSize { sm, md, lg }

/// 1.2.0 C 방향 표준 입력 컴포넌트
///
/// - 라벨: textSecondary 13sp/700 + 빨강 별표(필수)
/// - 박스: 흰 fill + borderHair 1px, 포커스 시 skyPrimary 1.5px
/// - 텍스트: textStrong 14sp/500
/// - placeholder: textTertiary 14sp/500
/// - 아이콘 색: textTertiary → 포커스 시 skyPrimary
class AppInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final bool disabled;
  final bool readOnly;
  final bool required;
  final InputSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const AppInput({
    Key? key,
    this.label,
    this.placeholder,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.disabled = false,
    this.readOnly = false,
    this.required = false,
    this.size = InputSize.md,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
  }) : super(key: key);

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final config = _sizeConfig(widget.size);
    final hasError = widget.errorText != null;
    final borderColor = hasError
        ? NewAppColor.danger700
        : _isFocused
            ? NewAppColor.skyPrimary
            : NewAppColor.borderHair;
    final iconColor =
        _isFocused ? NewAppColor.skyPrimary : NewAppColor.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  color: NewAppColor.textSecondary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
              if (widget.required) ...[
                SizedBox(width: 3.w),
                Text(
                  '*',
                  style: TextStyle(
                    color: NewAppColor.danger700,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 6.h),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: widget.disabled ? NewAppColor.canvasAlt : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: borderColor,
              width: _isFocused || hasError ? 1.5 : 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            initialValue: widget.initialValue,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            enabled: !widget.disabled,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            style: TextStyle(
              color: widget.disabled
                  ? NewAppColor.textTertiary
                  : NewAppColor.textStrong,
              fontSize: config.fontSize,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
              height: 1.45,
            ),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: TextStyle(
                color: NewAppColor.textTertiary,
                fontSize: config.fontSize,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Padding(
                      padding: EdgeInsets.only(left: 12.w, right: 6.w),
                      child: Icon(
                        widget.prefixIcon,
                        color: iconColor,
                        size: config.iconSize,
                      ),
                    )
                  : null,
              prefixIconConstraints: BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              suffixIcon: widget.suffixIcon != null
                  ? GestureDetector(
                      onTap: widget.onSuffixIconTap,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.only(right: 12.w, left: 6.w),
                        child: Icon(
                          widget.suffixIcon,
                          color: iconColor,
                          size: config.iconSize,
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints: BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.prefixIcon != null ? 4.w : 14.w,
                vertical: config.verticalPadding,
              ),
              border: InputBorder.none,
              counterText: '',
              isDense: true,
            ),
          ),
        ),
        if (widget.helperText != null || widget.errorText != null) ...[
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.only(left: 2.w),
            child: Text(
              widget.errorText ?? widget.helperText!,
              style: TextStyle(
                color: hasError
                    ? NewAppColor.danger700
                    : NewAppColor.textTertiary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ],
    );
  }

  _InputConfig _sizeConfig(InputSize size) {
    switch (size) {
      case InputSize.sm:
        return _InputConfig(
          fontSize: 13.sp,
          iconSize: 16.sp,
          verticalPadding: 10.h,
        );
      case InputSize.md:
        return _InputConfig(
          fontSize: 14.sp,
          iconSize: 18.sp,
          verticalPadding: 13.h,
        );
      case InputSize.lg:
        return _InputConfig(
          fontSize: 15.sp,
          iconSize: 20.sp,
          verticalPadding: 15.h,
        );
    }
  }
}

class _InputConfig {
  final double fontSize;
  final double iconSize;
  final double verticalPadding;
  const _InputConfig({
    required this.fontSize,
    required this.iconSize,
    required this.verticalPadding,
  });
}

// 비밀번호 입력 (visibility 토글)
class AppPasswordInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final bool required;
  final InputSize size;
  final ValueChanged<String>? onChanged;

  const AppPasswordInput({
    Key? key,
    this.label,
    this.placeholder = '비밀번호를 입력하세요',
    this.helperText,
    this.errorText,
    this.controller,
    this.required = false,
    this.size = InputSize.md,
    this.onChanged,
  }) : super(key: key);

  @override
  State<AppPasswordInput> createState() => _AppPasswordInputState();
}

class _AppPasswordInputState extends State<AppPasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppInput(
      label: widget.label,
      placeholder: widget.placeholder,
      helperText: widget.helperText,
      errorText: widget.errorText,
      controller: widget.controller,
      required: widget.required,
      size: widget.size,
      obscureText: _obscureText,
      onChanged: widget.onChanged,
      prefixIcon: LucideIcons.lock,
      suffixIcon: _obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
      onSuffixIconTap: () {
        setState(() => _obscureText = !_obscureText);
      },
      keyboardType: TextInputType.visiblePassword,
    );
  }
}
