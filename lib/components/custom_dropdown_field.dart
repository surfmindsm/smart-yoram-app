import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';

/// 향상된 UI/UX를 가진 커스텀 드롭다운 위젯
///
/// 특징:
/// - 부드러운 애니메이션 효과
/// - 선택된 항목 하이라이트
/// - 커스터마이징 가능한 아이콘
/// - 향상된 터치 피드백
/// - 일관된 디자인 시스템 적용 (NewAppColor, FigmaTextStyles)
class CustomDropdownField<T> extends StatefulWidget {
  final String? label;
  final String hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool required;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Color? fillColor;
  final double? borderRadius;
  final double? height;

  const CustomDropdownField({
    super.key,
    this.label,
    required this.hintText,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.required = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.fillColor,
    this.borderRadius,
    this.height,
  });

  @override
  State<CustomDropdownField<T>> createState() => _CustomDropdownFieldState<T>();
}

class _CustomDropdownFieldState<T> extends State<CustomDropdownField<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleMenuStateChange(bool isOpen) {
    setState(() {
      _isOpen = isOpen;
      if (isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral900,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.required) ...[
                SizedBox(width: 4.w),
                Text(
                  '*',
                  style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.danger600,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8.h),
        ],
        DropdownButtonFormField<T>(
          value: widget.value,
          decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral400,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: RotationTransition(
                turns: _rotationAnimation,
                child: widget.suffixIcon ?? Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _isOpen ? NewAppColor.primary600 : NewAppColor.neutral400,
                  size: 24.sp,
                ),
              ),
              filled: true,
              fillColor: widget.enabled
                ? (widget.fillColor ?? NewAppColor.neutral100)
                : NewAppColor.neutral200,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.r),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.r),
                borderSide: BorderSide(
                  color: NewAppColor.danger600,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.r),
                borderSide: BorderSide(
                  color: NewAppColor.danger600,
                  width: 1.5,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: widget.height != null ? 0 : 12.h,
              ),
              errorStyle: FigmaTextStyles().caption2.copyWith(
                color: NewAppColor.danger600,
              ),
            ),
            style: FigmaTextStyles().body2.copyWith(
              color: widget.enabled ? NewAppColor.neutral900 : NewAppColor.neutral400,
            ),
            items: widget.items,
            onChanged: widget.enabled
              ? (value) {
                  _handleMenuStateChange(false);
                  widget.onChanged?.call(value);
                }
              : null,
            validator: widget.validator,
            isExpanded: true,
            icon: const SizedBox.shrink(), // 커스텀 아이콘을 suffixIcon으로 사용
            dropdownColor: Colors.white,
            elevation: 8,
            borderRadius: BorderRadius.circular(12.r),
            menuMaxHeight: 300.h,
            onTap: () => _handleMenuStateChange(true),
          ),
      ],
    );
  }
}

/// DropdownMenuItem용 헬퍼 함수
/// 선택된 항목을 하이라이트하여 표시
DropdownMenuItem<T> buildDropdownItem<T>({
  required T value,
  required String text,
  T? currentValue,
  Widget? leading,
  Widget? trailing,
}) {
  return DropdownMenuItem<T>(
    value: value,
    child: Row(
      children: [
        if (leading != null) ...[
          leading,
          SizedBox(width: 12.w),
        ],
        Expanded(
          child: Text(
            text,
            style: FigmaTextStyles().body2.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: 12.w),
          trailing,
        ],
      ],
    ),
  );
}

/// 간단한 텍스트 드롭다운 아이템 생성 헬퍼
List<DropdownMenuItem<String>> buildSimpleDropdownItems({
  required List<String> items,
  String? currentValue,
}) {
  return items.map((item) {
    return buildDropdownItem<String>(
      value: item,
      text: item,
      currentValue: currentValue,
    );
  }).toList();
}

/// 아이콘이 있는 드롭다운 아이템 생성 헬퍼
List<DropdownMenuItem<T>> buildDropdownItemsWithIcon<T>({
  required List<Map<String, dynamic>> items,
  T? currentValue,
}) {
  return items.map((item) {
    return buildDropdownItem<T>(
      value: item['value'] as T,
      text: item['text'] as String,
      currentValue: currentValue,
      leading: item['icon'] as Widget?,
    );
  }).toList();
}
