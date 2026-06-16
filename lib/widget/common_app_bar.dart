import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';

/// 앱 전체에서 공통으로 사용되는 AppBar 위젯 (1.2.0 C 방향 표준)
///
/// - 흰 배경 + borderHair 1px 하단선
/// - chevron-left 24sp · textStrong
/// - 타이틀 17sp / 800 / Pretendard / textStrong (센터 정렬)
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onLeadingPressed;
  final PreferredSizeWidget? bottom;
  final TextStyle? titleStyle;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onLeadingPressed,
    this.bottom,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading ??
          (automaticallyImplyLeading && Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(LucideIcons.chevronLeft,
                      color: NewAppColor.textStrong, size: 24.sp),
                  onPressed:
                      onLeadingPressed ?? () => Navigator.pop(context),
                )
              : null),
      title: Text(
        title,
        style: titleStyle ??
            TextStyle(
              color: NewAppColor.textStrong,
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
            ),
      ),
      actions: actions,
      bottom: bottom,
      shape: Border(
        bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
