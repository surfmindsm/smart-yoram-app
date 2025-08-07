import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum BadgeVariant {
  primary,
  secondary,
  success,
  warning,
  error,
  outline,
}

enum BadgeSize {
  sm,
  md,
  lg,
}

class AppBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final BadgeSize size;
  final IconData? icon;
  final VoidCallback? onTap;

  const AppBadge({
    Key? key,
    required this.text,
    this.variant = BadgeVariant.primary,
    this.size = BadgeSize.md,
    this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badgeTheme = _getBadgeTheme(variant);
    final sizeTheme = _getSizeTheme(size);

    Widget badgeWidget = Container(
      padding: sizeTheme.padding,
      decoration: BoxDecoration(
        color: badgeTheme.backgroundColor,
        borderRadius: BorderRadius.circular(sizeTheme.borderRadius),
        border: badgeTheme.borderWidth > 0
            ? Border.all(
                color: badgeTheme.borderColor,
                width: badgeTheme.borderWidth,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: sizeTheme.iconSize,
              color: badgeTheme.textColor,
            ),
            SizedBox(width: sizeTheme.iconSpacing),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: sizeTheme.fontSize,
              fontWeight: FontWeight.w500,
              color: badgeTheme.textColor,
              height: 1,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      badgeWidget = GestureDetector(
        onTap: onTap,
        child: badgeWidget,
      );
    }

    return badgeWidget;
  }

  _BadgeTheme _getBadgeTheme(BadgeVariant variant) {
    switch (variant) {
      case BadgeVariant.primary:
        return _BadgeTheme(
          backgroundColor: AppColor.primary7,
          textColor: AppColor.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
        );
      case BadgeVariant.secondary:
        return _BadgeTheme(
          backgroundColor: AppColor.secondary00,
          textColor: AppColor.secondary07,
          borderColor: Colors.transparent,
          borderWidth: 0,
        );
      case BadgeVariant.success:
        return _BadgeTheme(
          backgroundColor: const Color(0xff22C55E),
          textColor: AppColor.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
        );
      case BadgeVariant.warning:
        return _BadgeTheme(
          backgroundColor: AppColor.orange500,
          textColor: AppColor.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
        );
      case BadgeVariant.error:
        return _BadgeTheme(
          backgroundColor: AppColor.error,
          textColor: AppColor.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
        );
      case BadgeVariant.outline:
        return _BadgeTheme(
          backgroundColor: Colors.transparent,
          textColor: AppColor.secondary07,
          borderColor: AppColor.border1,
          borderWidth: 1,
        );
    }
  }

  _SizeTheme _getSizeTheme(BadgeSize size) {
    switch (size) {
      case BadgeSize.sm:
        return _SizeTheme(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          fontSize: 10,
          iconSize: 10,
          iconSpacing: 3,
          borderRadius: 4,
        );
      case BadgeSize.md:
        return _SizeTheme(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          fontSize: 12,
          iconSize: 12,
          iconSpacing: 4,
          borderRadius: 6,
        );
      case BadgeSize.lg:
        return _SizeTheme(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          fontSize: 14,
          iconSize: 14,
          iconSpacing: 6,
          borderRadius: 8,
        );
    }
  }
}

class _BadgeTheme {
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final double borderWidth;

  const _BadgeTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.borderWidth,
  });
}

class _SizeTheme {
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double iconSpacing;
  final double borderRadius;

  const _SizeTheme({
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.iconSpacing,
    required this.borderRadius,
  });
}
