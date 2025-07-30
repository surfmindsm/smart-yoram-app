import 'package:flutter/material.dart';

/// 앱에서 공통으로 사용되는 버튼 위젯들
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.padding,
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
              Text(text),
            ],
          );

    Widget button;
    
    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: child,
        );
        break;
      case ButtonType.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.blue[700]!),
            foregroundColor: Colors.blue[700],
            padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: child,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue[700],
            padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          child: child,
        );
        break;
      case ButtonType.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
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
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.primary,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
    );
  }

  static CommonButton secondary({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
    EdgeInsetsGeometry? padding,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.secondary,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
    );
  }

  static CommonButton textButton({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
    EdgeInsetsGeometry? padding,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.text,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
    );
  }

  static CommonButton danger({
    required String text,
    VoidCallback? onPressed,
    IconData? icon,
    bool isLoading = false,
    double? width,
    EdgeInsetsGeometry? padding,
  }) {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      type: ButtonType.danger,
      icon: icon,
      isLoading: isLoading,
      width: width,
      padding: padding,
    );
  }
}

enum ButtonType {
  primary,
  secondary,
  text,
  danger,
}
