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
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style ??
              ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary900,
                foregroundColor: Colors.white,
                padding: padding ??
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 0.0,
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
          ),
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
          ),
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
          ),
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
