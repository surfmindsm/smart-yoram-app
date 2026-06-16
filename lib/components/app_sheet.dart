import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../resource/color_style_new.dart';
import 'app_select.dart' show AppSelectOption;

/// 1.2.0 C 방향 표준 바텀시트 컴포넌트
///
/// 세 가지 변형 제공:
/// - [AppConfirmSheet.show] : 위험·경고 확인 시트 (삭제, 로그아웃 등)
/// - [AppMenuSheet.show]    : 단순 아이콘+라벨 메뉴 행 묶음
/// - [AppInfoSheet.show]    : 헤더 + 본문 + 풀폭 확인 버튼 (상세 안내)
///
/// 모든 시트는 동일한 핸들바·라운드·암막 처리 사용.
class AppSheet {
  AppSheet._();

  /// 공통 핸들바 + 시트 컨테이너
  static Widget container({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      child: SafeArea(
        top: false,
        child: child,
      ),
    );
  }

  static Widget handle() {
    return Container(
      width: 44,
      height: 5,
      margin: EdgeInsets.only(top: 10.h, bottom: 14.h),
      decoration: BoxDecoration(
        color: NewAppColor.borderStrong,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

enum AppSheetTone { sky, danger, success, warning }

/// 확인/경고 시트 — 로그아웃·삭제·취소 등 결정 확인용
class AppConfirmSheet {
  AppConfirmSheet._();

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? description,
    Widget? preview,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    AppSheetTone tone = AppSheetTone.sky,
    IconData? icon,
  }) {
    final ({Color bg, Color fg}) toneColors = _toneColors(tone);
    final IconData iconData = icon ?? _defaultIcon(tone);

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) {
        return AppSheet.container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: AppSheet.handle()),
              Padding(
                padding: EdgeInsets.fromLTRB(22.w, 4.h, 22.w, 22.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54.w,
                      height: 54.w,
                      decoration: BoxDecoration(
                        color: toneColors.bg,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      alignment: Alignment.center,
                      child: Icon(iconData,
                          color: toneColors.fg, size: 26.sp),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: NewAppColor.textStrong,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    if (description != null) ...[
                      SizedBox(height: 8.h),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: NewAppColor.textMuted,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                          height: 1.55,
                        ),
                      ),
                    ],
                    if (preview != null) ...[
                      SizedBox(height: 16.h),
                      preview,
                    ],
                    SizedBox(height: 22.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCancelButton(
                            label: cancelLabel,
                            onTap: () => Navigator.pop(sheetContext, false),
                          ),
                        ),
                        SizedBox(width: 11.w),
                        Expanded(
                          child: _buildConfirmButton(
                            label: confirmLabel,
                            tone: tone,
                            onTap: () => Navigator.pop(sheetContext, true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildCancelButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
          color: NewAppColor.borderSoft,
          borderRadius: BorderRadius.circular(13.r),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: NewAppColor.textSecondary,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  static Widget _buildConfirmButton({
    required String label,
    required AppSheetTone tone,
    required VoidCallback onTap,
  }) {
    final Color background = _confirmButtonColor(tone);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(13.r),
          boxShadow: [
            BoxShadow(
              color: background.withOpacity(0.30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}

/// 단순 메뉴 시트 — 핸들바 + 아이콘+라벨 행 2~N개
class AppMenuSheet {
  AppMenuSheet._();

  static Future<void> show({
    required BuildContext context,
    required List<AppMenuItem> items,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) {
        return AppSheet.container(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: AppSheet.handle()),
              ...List.generate(items.length, (index) {
                final item = items[index];
                final isLast = index == items.length - 1;
                return Column(
                  children: [
                    _buildMenuRow(sheetContext, item),
                    if (!isLast)
                      Container(
                        height: 1,
                        color: NewAppColor.borderHair,
                        margin: EdgeInsets.symmetric(horizontal: 20.w),
                      ),
                  ],
                );
              }),
              SizedBox(height: 22.h),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildMenuRow(BuildContext context, AppMenuItem item) {
    final ({Color bg, Color fg}) toneColors = _toneColors(item.tone);
    final Color labelColor =
        item.danger ? NewAppColor.danger700 : NewAppColor.textStrong;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.enabled
            ? () {
                Navigator.pop(context);
                item.onTap();
              }
            : null,
        child: Opacity(
          opacity: item.enabled ? 1.0 : 0.4,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 22.sp,
                    color: item.danger ? NewAppColor.danger700 : toneColors.fg),
                SizedBox(width: 14.w),
                Text(
                  item.label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final AppSheetTone tone;
  final bool danger;
  final bool enabled;

  const AppMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone = AppSheetTone.sky,
    this.danger = false,
    this.enabled = true,
  });
}

/// 정보·안내 시트 — 헤더(아이콘+제목) + 스크롤 본문 + 풀폭 확인 버튼
class AppInfoSheet {
  AppInfoSheet._();

  static Future<void> show({
    required BuildContext context,
    required String title,
    required Widget body,
    IconData icon = LucideIcons.info,
    AppSheetTone tone = AppSheetTone.sky,
    String confirmLabel = '확인',
    double? maxHeightFraction,
  }) {
    final ({Color bg, Color fg}) toneColors = _toneColors(tone);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height *
                (maxHeightFraction ?? 0.8),
          ),
          child: AppSheet.container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: AppSheet.handle()),
                Padding(
                  padding: EdgeInsets.fromLTRB(22.w, 4.h, 22.w, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: toneColors.bg,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, color: toneColors.fg, size: 22.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: NewAppColor.textStrong,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14.h),
                Container(height: 1, color: NewAppColor.borderHair),
                Flexible(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.fromLTRB(22.w, 16.h, 22.w, 4.h),
                    child: body,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22.w, 14.h, 22.w, 18.h),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(sheetContext),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      decoration: BoxDecoration(
                        color: NewAppColor.skyPrimary,
                        borderRadius: BorderRadius.circular(13.r),
                        boxShadow: [
                          BoxShadow(
                            color: NewAppColor.skyPrimary.withOpacity(0.30),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        confirmLabel,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 톤별 아이콘 박스 컬러
({Color bg, Color fg}) _toneColors(AppSheetTone tone) {
  switch (tone) {
    case AppSheetTone.sky:
      return (bg: NewAppColor.skyTint, fg: NewAppColor.skyDeep);
    case AppSheetTone.danger:
      return (bg: NewAppColor.dangerBg, fg: NewAppColor.danger700);
    case AppSheetTone.success:
      return (bg: NewAppColor.successBg, fg: NewAppColor.success700);
    case AppSheetTone.warning:
      return (bg: NewAppColor.warningBg, fg: NewAppColor.warning700);
  }
}

Color _confirmButtonColor(AppSheetTone tone) {
  switch (tone) {
    case AppSheetTone.sky:
      return NewAppColor.skyPrimary;
    case AppSheetTone.danger:
      return NewAppColor.danger700;
    case AppSheetTone.success:
      return NewAppColor.success700;
    case AppSheetTone.warning:
      return NewAppColor.warning700;
  }
}

IconData _defaultIcon(AppSheetTone tone) {
  switch (tone) {
    case AppSheetTone.sky:
      return LucideIcons.circleHelp;
    case AppSheetTone.danger:
      return LucideIcons.trash2;
    case AppSheetTone.success:
      return LucideIcons.circleCheck;
    case AppSheetTone.warning:
      return LucideIcons.triangleAlert;
  }
}

/// 셀렉트 시트 — 옵션 목록에서 하나 선택 (Material Dropdown 대체)
class AppSelectSheet {
  AppSelectSheet._();

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<AppSelectOption<T>> options,
    T? selectedValue,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: AppSheet.container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: AppSheet.handle()),
                Padding(
                  padding: EdgeInsets.fromLTRB(22.w, 4.h, 22.w, 12.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: NewAppColor.textStrong,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(bottom: 14.h),
                    itemCount: options.length,
                    separatorBuilder: (_, __) => Container(
                      height: 1,
                      color: NewAppColor.borderHair,
                      margin: EdgeInsets.symmetric(horizontal: 22.w),
                    ),
                    itemBuilder: (_, index) {
                      final option = options[index];
                      final isSelected = option.value == selectedValue;
                      return InkWell(
                        onTap: () =>
                            Navigator.pop(sheetContext, option.value),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.w, vertical: 14.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? NewAppColor.skyDeep
                                        : NewAppColor.textStrong,
                                    fontSize: 15.sp,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontFamily: 'Pretendard',
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  LucideIcons.check,
                                  size: 18.sp,
                                  color: NewAppColor.skyPrimary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 셀렉터 박스 (Material Dropdown 대체용 위젯) —
/// 흰 fill + borderHair 1px + 좌측 라벨 + 우측 chevron-down
class AppSelectField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback onTap;
  final bool enabled;

  const AppSelectField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : NewAppColor.canvasAlt,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: NewAppColor.borderHair, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasValue ? value! : placeholder,
                style: TextStyle(
                  color: hasValue
                      ? NewAppColor.textStrong
                      : NewAppColor.textMuted,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronDown,
              size: 18.sp,
              color: NewAppColor.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
