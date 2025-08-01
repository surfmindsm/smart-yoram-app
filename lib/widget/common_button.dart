import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/text_style.dart';
import 'package:smart_yoram_app/resource/color_style.dart';

/// 앱에서 공통으로 사용되는 버튼 위젯들
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final TextStyle? fontStyle;
  final ButtonStyle? style;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.padding,
    this.fontStyle,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: fontStyle,
              ),
            ],
          );

    Widget button;

    switch (type) {
      case ButtonType.primary:
        // 사용자가 제공한 스타일 속성 추출
        final customBackgroundColor = style?.backgroundColor;
        final customForegroundColor = style?.foregroundColor;
        final customPadding = style?.padding?.resolve({});
        final customShape = style?.shape?.resolve({});
        final customElevation = style?.elevation?.resolve({});
        
        // 비활성화 상태에서도 배경색이 적용되도록 MaterialStateProperty 사용
        final backgroundColor = customBackgroundColor ?? 
            MaterialStateProperty.resolveWith<Color>((states) {
              return AppColor.primary900; // 항상 동일한 배경색 적용
            });
        
        final foregroundColor = customForegroundColor ?? 
            MaterialStateProperty.resolveWith<Color>((states) {
              return Colors.white; // 항상 동일한 텍스트 색상 적용
            });
        
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ButtonStyle(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            padding: MaterialStateProperty.all(customPadding ?? padding ?? 
                const EdgeInsets.symmetric(vertical: 12, horizontal: 24)),
            shape: MaterialStateProperty.all(customShape ?? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            )),
            elevation: MaterialStateProperty.all(customElevation ?? 0.0),
            // 비활성화 상태에서도 동일한 스타일 유지
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.white.withOpacity(0.1);
                }
                return null;
              },
            ),
          ),
          child: child,
        );
        break;
      case ButtonType.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColor.primary900),
            foregroundColor: AppColor.primary900,
            padding: padding ??
                const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0.0,
          ).merge(style),
          child: child,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColor.primary900,
            padding: padding ??
                const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 0.0,
          ).merge(style),
          child: child,
        );
        break;
      case ButtonType.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.error,
            foregroundColor: Colors.white,
            padding: padding ??
                const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0.0,
          ).merge(style),
          child: child,
        );
        break;
    }

    if (width != null) {
      return SizedBox(
        width: width,
        child: button,
      );
    }

    return button;
  }

  // Static helper methods for common button types
  static CommonButton primary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
    EdgeInsetsGeometry? padding,
    TextStyle? fontStyle,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.primary,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
      fontStyle: fontStyle,
    );
  }

  static CommonButton secondary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
    EdgeInsetsGeometry? padding,
    TextStyle? fontStyle,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.secondary,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
      fontStyle: fontStyle,
    );
  }

  static CommonButton textButton({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
    EdgeInsetsGeometry? padding,
    TextStyle? fontStyle,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.text,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
      fontStyle: fontStyle,
    );
  }

  static CommonButton danger({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
    EdgeInsetsGeometry? padding,
    TextStyle? fontStyle,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.danger,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
      fontStyle: fontStyle,
    );
  }
}

enum ButtonType {
  primary,
  secondary,
  text,
  danger,
}
