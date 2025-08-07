import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum CardVariant {
  elevated,
  outlined,
  filled,
}

class AppCard extends StatelessWidget {
  final Widget child;
  final CardVariant variant;
  final double? elevation;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double? width;
  final double? height;

  const AppCard({
    Key? key,
    required this.child,
    this.variant = CardVariant.elevated,
    this.elevation,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 12,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardTheme = _getCardTheme(variant);
    
    Widget cardWidget = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? cardTheme.backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: cardTheme.borderWidth > 0
            ? Border.all(
                color: borderColor ?? cardTheme.borderColor,
                width: cardTheme.borderWidth,
              )
            : null,
        boxShadow: elevation != null || variant == CardVariant.elevated
            ? [
                BoxShadow(
                  color: AppColor.secondary07.withOpacity(0.1),
                  blurRadius: elevation ?? cardTheme.elevation,
                  offset: Offset(0, (elevation ?? cardTheme.elevation) / 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      cardWidget = GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  _CardTheme _getCardTheme(CardVariant variant) {
    switch (variant) {
      case CardVariant.elevated:
        return _CardTheme(
          backgroundColor: AppColor.white,
          borderColor: Colors.transparent,
          borderWidth: 0,
          elevation: 4,
        );
      case CardVariant.outlined:
        return _CardTheme(
          backgroundColor: AppColor.white,
          borderColor: AppColor.border1,
          borderWidth: 1,
          elevation: 0,
        );
      case CardVariant.filled:
        return _CardTheme(
          backgroundColor: AppColor.secondary00,
          borderColor: Colors.transparent,
          borderWidth: 0,
          elevation: 0,
        );
    }
  }
}

class _CardTheme {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double elevation;

  const _CardTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.elevation,
  });
}

// Card Header Component
class AppCardHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsets? padding;

  const AppCardHeader({
    Key? key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.secondary07,
                      height: 1.3,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.secondary05,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// Card Content Component
class AppCardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const AppCardContent({
    Key? key,
    required this.child,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: child,
    );
  }
}

// Card Footer Component
class AppCardFooter extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final EdgeInsets? padding;

  const AppCardFooter({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.end,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: children,
      ),
    );
  }
}

// Preset Card variants for common use cases
class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String description;
  final IconData? icon;
  final List<Widget>? actions;
  final VoidCallback? onTap;

  const InfoCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.description,
    this.icon,
    this.actions,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCardHeader(
            title: title,
            subtitle: subtitle,
            leading: icon != null
                ? Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColor.primary100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: AppColor.primary7,
                    ),
                  )
                : null,
          ),
          AppCardContent(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: AppColor.secondary06,
                height: 1.5,
              ),
            ),
          ),
          if (actions != null && actions!.isNotEmpty)
            AppCardFooter(
              children: actions!,
            ),
        ],
      ),
    );
  }
}

// Stats Card for displaying metrics
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trend;
  final VoidCallback? onTap;

  const StatsCard({
    Key? key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trend,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColor.secondary05,
                    height: 1.4,
                  ),
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? AppColor.secondary05,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColor.secondary07,
              height: 1.2,
            ),
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.secondary05,
                    ),
                  ),
                if (trend != null) ...[
                  const Spacer(),
                  trend!,
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
