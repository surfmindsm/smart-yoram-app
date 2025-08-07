import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum ButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  link,
  destructive,
}

enum ButtonSize {
  sm,
  md,
  lg,
  icon,
}

class AppButton extends StatelessWidget {
  final String? text;
  final Widget? child;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool isLoading;
  final bool disabled;
  final IconData? icon;
  final IconData? trailingIcon;

  const AppButton({
    Key? key,
    this.text,
    this.child,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.isLoading = false,
    this.disabled = false,
    this.icon,
    this.trailingIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonTheme = _getButtonTheme(variant);
    final sizeTheme = _getSizeTheme(size);
    final isDisabled = disabled || isLoading;

    return SizedBox(
      height: sizeTheme.height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled 
              ? buttonTheme.backgroundColor.withOpacity(0.5) 
              : buttonTheme.backgroundColor,
          foregroundColor: isDisabled 
              ? buttonTheme.textColor.withOpacity(0.5) 
              : buttonTheme.textColor,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sizeTheme.borderRadius),
            side: BorderSide(
              color: isDisabled 
                  ? buttonTheme.borderColor.withOpacity(0.5) 
                  : buttonTheme.borderColor,
              width: buttonTheme.borderWidth,
            ),
          ),
          padding: sizeTheme.padding,
        ),
        child: isLoading
            ? SizedBox(
                width: sizeTheme.iconSize,
                height: sizeTheme.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    buttonTheme.textColor,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: sizeTheme.iconSize),
                    if (text != null || child != null) 
                      SizedBox(width: sizeTheme.iconSpacing),
                  ],
                  if (child != null)
                    child!
                  else if (text != null)
                    Text(
                      text!,
                      style: TextStyle(
                        fontSize: sizeTheme.fontSize,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  if (trailingIcon != null) ...[
                    if (text != null || child != null) 
                      SizedBox(width: sizeTheme.iconSpacing),
                    Icon(trailingIcon, size: sizeTheme.iconSize),
                  ],
                ],
              ),
      ),
    );
  }

  _ButtonTheme _getButtonTheme(ButtonVariant variant) {
    switch (variant) {
      case ButtonVariant.primary:
        return _ButtonTheme(
          backgroundColor: AppColor.primary7,
          textColor: AppColor.white,
          borderColor: AppColor.primary7,
          borderWidth: 1,
        );
      case ButtonVariant.secondary:
        return _ButtonTheme(
          backgroundColor: AppColor.secondary00,
          textColor: AppColor.secondary07,
          borderColor: AppColor.border1,
          borderWidth: 1,
        );
      case ButtonVariant.outline:
        return _ButtonTheme(
          backgroundColor: Colors.transparent,
          textColor: AppColor.secondary07,
          borderColor: AppColor.border1,
          borderWidth: 1,
        );
      case ButtonVariant.ghost:
        return _ButtonTheme(
          backgroundColor: Colors.transparent,
          textColor: AppColor.secondary07,
          borderColor: Colors.transparent,
          borderWidth: 0,
        );
      case ButtonVariant.link:
        return _ButtonTheme(
          backgroundColor: Colors.transparent,
          textColor: AppColor.primary7,
          borderColor: Colors.transparent,
          borderWidth: 0,
        );
      case ButtonVariant.destructive:
        return _ButtonTheme(
          backgroundColor: AppColor.error,
          textColor: AppColor.white,
          borderColor: AppColor.error,
          borderWidth: 1,
        );
    }
  }

  _SizeTheme _getSizeTheme(ButtonSize size) {
    switch (size) {
      case ButtonSize.sm:
        return _SizeTheme(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fontSize: 12,
          iconSize: 16,
          iconSpacing: 6,
          borderRadius: 6,
        );
      case ButtonSize.md:
        return _SizeTheme(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          fontSize: 14,
          iconSize: 18,
          iconSpacing: 8,
          borderRadius: 8,
        );
      case ButtonSize.lg:
        return _SizeTheme(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          fontSize: 16,
          iconSize: 20,
          iconSpacing: 8,
          borderRadius: 8,
        );
      case ButtonSize.icon:
        return _SizeTheme(
          height: 40,
          padding: const EdgeInsets.all(10),
          fontSize: 14,
          iconSize: 18,
          iconSpacing: 0,
          borderRadius: 8,
        );
    }
  }
}

class _ButtonTheme {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;

  const _ButtonTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.borderWidth,
  });
}

class _SizeTheme {
  final double height;
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double iconSpacing;
  final double borderRadius;

  const _SizeTheme({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.iconSpacing,
    required this.borderRadius,
  });
}

// Convenience constructors
class PrimaryButton extends AppButton {
  const PrimaryButton({
    Key? key,
    String? text,
    Widget? child,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.md,
    bool isLoading = false,
    bool disabled = false,
    IconData? icon,
    IconData? trailingIcon,
  }) : super(
    key: key,
    text: text,
    child: child,
    onPressed: onPressed,
    variant: ButtonVariant.primary,
    size: size,
    isLoading: isLoading,
    disabled: disabled,
    icon: icon,
    trailingIcon: trailingIcon,
  );
}

class SecondaryButton extends AppButton {
  const SecondaryButton({
    Key? key,
    String? text,
    Widget? child,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.md,
    bool isLoading = false,
    bool disabled = false,
    IconData? icon,
    IconData? trailingIcon,
  }) : super(
    key: key,
    text: text,
    child: child,
    onPressed: onPressed,
    variant: ButtonVariant.secondary,
    size: size,
    isLoading: isLoading,
    disabled: disabled,
    icon: icon,
    trailingIcon: trailingIcon,
  );
}

class OutlineButton extends AppButton {
  const OutlineButton({
    Key? key,
    String? text,
    Widget? child,
    VoidCallback? onPressed,
    ButtonSize size = ButtonSize.md,
    bool isLoading = false,
    bool disabled = false,
    IconData? icon,
    IconData? trailingIcon,
  }) : super(
    key: key,
    text: text,
    child: child,
    onPressed: onPressed,
    variant: ButtonVariant.outline,
    size: size,
    isLoading: isLoading,
    disabled: disabled,
    icon: icon,
    trailingIcon: trailingIcon,
  );
}

class IconButton extends AppButton {
  const IconButton({
    Key? key,
    required IconData icon,
    VoidCallback? onPressed,
    ButtonVariant variant = ButtonVariant.ghost,
    bool isLoading = false,
    bool disabled = false,
  }) : super(
    key: key,
    icon: icon,
    onPressed: onPressed,
    variant: variant,
    size: ButtonSize.icon,
    isLoading: isLoading,
    disabled: disabled,
  );
}
