import 'package:flutter/material.dart';
import 'package:smart_yoram_app/resource/color_style.dart';

/// 앱 전체에서 공통으로 사용되는 AppBar 위젯
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onLeadingPressed;
  final PreferredSizeWidget? bottom;
  final TextStyle? titleStyle;
  final double? scrolledUnderElevation;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onLeadingPressed,
    this.bottom,
    this.titleStyle,
    this.scrolledUnderElevation,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: titleStyle),
      backgroundColor: AppColor.background,
      foregroundColor: AppColor.secondary05,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      bottom: bottom,
      scrolledUnderElevation: scrolledUnderElevation,
      elevation: elevation,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
