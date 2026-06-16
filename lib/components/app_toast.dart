import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 1.2.0 C 방향: 앱 전역 floating 다크 토스트
///
/// 디자인 정책 §3 바텀시트 톤 — `textStrong` 다크 배경 + 흰 글자.
/// 종류에 따라 아이콘과 색만 달라진다 (info/success=success300, error=danger300,
/// warning=warning300).
///
/// 사용:
///   AppToast.show(context, '저장되었습니다');         // info/success
///   AppToast.success(context, '복사되었습니다');
///   AppToast.error(context, '저장 실패');
///   AppToast.warning(context, '확인이 필요합니다');
///
/// 이 유틸은 Overlay 기반으로 구현돼 있어 Scaffold 외부에서도 호출 가능하다.
class AppToast {
  AppToast._();

  static OverlayEntry? _overlayEntry;

  /// 기본 (info) 토스트 — 체크 아이콘
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.bottom,
    Duration? duration,
    String? title, // 호환성 위해 유지 (현재 단일 라인 디자인이라 사용 안 함)
  }) {
    _show(context, message, type, position, duration);
  }

  static void info(BuildContext context, String message,
      {ToastPosition position = ToastPosition.bottom}) {
    _show(context, message, ToastType.info, position, null);
  }

  static void success(BuildContext context, String message,
      {ToastPosition position = ToastPosition.bottom}) {
    _show(context, message, ToastType.success, position, null);
  }

  static void warning(BuildContext context, String message,
      {ToastPosition position = ToastPosition.bottom}) {
    _show(context, message, ToastType.warning, position, null);
  }

  static void error(BuildContext context, String message,
      {ToastPosition position = ToastPosition.bottom}) {
    _show(context, message, ToastType.error, position, null);
  }

  static void hide() {
    try {
      _overlayEntry?.remove();
    } catch (_) {
      // 이미 제거된 경우 무시
    } finally {
      _overlayEntry = null;
    }
  }

  static void _show(
    BuildContext context,
    String message,
    ToastType type,
    ToastPosition position,
    Duration? duration,
  ) {
    hide();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // error는 노출 시간 약간 더 길게
    final effectiveDuration = duration ??
        Duration(milliseconds: type == ToastType.error ? 2800 : 2000);

    _overlayEntry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        position: position,
        duration: effectiveDuration,
        onDismiss: hide,
      ),
    );
    overlay.insert(_overlayEntry!);
  }
}

enum ToastType { info, success, warning, error }

enum ToastPosition { top, center, bottom }

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final ToastPosition position;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.position,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: _initialOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    Future.delayed(widget.duration, () {
      if (!mounted) return;
      _controller.reverse().then((_) => widget.onDismiss());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _initialOffset() {
    switch (widget.position) {
      case ToastPosition.top:
        return const Offset(0, -0.4);
      case ToastPosition.center:
        return Offset.zero;
      case ToastPosition.bottom:
        return const Offset(0, 0.4);
    }
  }

  ({IconData icon, Color iconColor}) _typeStyle() {
    switch (widget.type) {
      case ToastType.error:
        return (icon: LucideIcons.circleAlert, iconColor: NewAppColor.danger300);
      case ToastType.warning:
        return (
          icon: LucideIcons.triangleAlert,
          iconColor: NewAppColor.warning300,
        );
      case ToastType.success:
      case ToastType.info:
        return (
          icon: LucideIcons.circleCheck,
          iconColor: NewAppColor.success300,
        );
    }
  }

  EdgeInsets _positionPadding(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final size = MediaQuery.of(context).size;
    switch (widget.position) {
      case ToastPosition.top:
        return EdgeInsets.only(
          top: padding.top + 12.h,
          left: 16.w,
          right: 16.w,
        );
      case ToastPosition.center:
        return EdgeInsets.only(
          top: size.height / 2 - 30,
          left: 16.w,
          right: 16.w,
        );
      case ToastPosition.bottom:
        return EdgeInsets.only(
          bottom: padding.bottom + 24.h,
          left: 16.w,
          right: 16.w,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _typeStyle();
    final alignment = widget.position == ToastPosition.top
        ? Alignment.topCenter
        : widget.position == ToastPosition.center
            ? Alignment.center
            : Alignment.bottomCenter;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Padding(
          padding: _positionPadding(context),
          child: Align(
            alignment: alignment,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _fade,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: NewAppColor.textStrong,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF020817).withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          color: style.iconColor,
                          size: 18.sp,
                        ),
                        SizedBox(width: 10.w),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: FigmaTextStyles().body3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
