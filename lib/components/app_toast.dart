import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import '../resource/color_style.dart';

enum ToastType {
  info,
  success,
  warning,
  error,
}

enum ToastPosition {
  top,
  center,
  bottom,
}

class AppToast {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    String? title,
    Widget? action,
  }) {
    hide();

    final toastConfig = _getToastConfig(type);

    _overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        title: title,
        type: type,
        position: position,
        duration: duration,
        action: action,
        config: toastConfig,
        onDismiss: hide,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    try {
      _overlayEntry?.remove();
    } catch (e) {
      // Overlay가 이미 제거된 경우 무시
    } finally {
      _overlayEntry = null;
    }
  }

  static _ToastConfig _getToastConfig(ToastType type) {
    switch (type) {
      case ToastType.info:
        return const _ToastConfig(
          backgroundColor: AppColor.primary600,
          iconColor: AppColor.white,
          textColor: AppColor.white,
          icon: Icons.info,
        );
      case ToastType.success:
        return const _ToastConfig(
          backgroundColor: Color(0xff10b981),
          iconColor: AppColor.white,
          textColor: AppColor.white,
          icon: Icons.check_circle,
        );
      case ToastType.warning:
        return const _ToastConfig(
          backgroundColor: AppColor.orange500,
          iconColor: AppColor.white,
          textColor: AppColor.white,
          icon: Icons.warning,
        );
      case ToastType.error:
        return const _ToastConfig(
          backgroundColor: AppColor.error,
          iconColor: AppColor.white,
          textColor: AppColor.white,
          icon: Icons.error,
        );
    }
  }

  // Named methods for common use cases
  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.bottom,
    Widget? action,
  }) {
    show(
      context,
      message,
      type: ToastType.info,
      title: title,
      duration: duration,
      position: position,
      action: action,
    );
  }

  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.bottom,
    Widget? action,
  }) {
    show(
      context,
      message,
      type: ToastType.success,
      title: title,
      duration: duration,
      position: position,
      action: action,
    );
  }

  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.bottom,
    Widget? action,
  }) {
    show(
      context,
      message,
      type: ToastType.warning,
      title: title,
      duration: duration,
      position: position,
      action: action,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    ToastPosition position = ToastPosition.bottom,
    Widget? action,
  }) {
    show(
      context,
      message,
      type: ToastType.error,
      title: title,
      duration: duration,
      position: position,
      action: action,
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final ToastPosition position;
  final Duration duration;
  final Widget? action;
  final _ToastConfig config;
  final VoidCallback onDismiss;

  const _ToastWidget({
    Key? key,
    required this.message,
    this.title,
    required this.type,
    required this.position,
    required this.duration,
    this.action,
    required this.config,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: _getSlideBegin(),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _animationController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Offset _getSlideBegin() {
    switch (widget.position) {
      case ToastPosition.top:
        return const Offset(0, -1);
      case ToastPosition.center:
        return const Offset(0, 0);
      case ToastPosition.bottom:
        return const Offset(0, 1);
    }
  }

  double _getTopPosition() {
    switch (widget.position) {
      case ToastPosition.top:
        return 60;
      case ToastPosition.center:
        return MediaQuery.of(context).size.height * 0.5 - 40;
      case ToastPosition.bottom:
        return MediaQuery.of(context).size.height - 140;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _getTopPosition(),
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.config.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.config.icon,
                    color: widget.config.iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.title != null)
                          Text(
                            widget.title!,
                            style: TextStyle(
                              color: widget.config.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(
                          widget.message,
                          style: TextStyle(
                            color: widget.config.textColor,
                            fontSize: 14,
                            fontWeight: widget.title != null 
                              ? FontWeight.w400 
                              : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.action != null) ...[
                    const SizedBox(width: 12),
                    widget.action!,
                  ],
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _animationController.reverse().then((_) {
                        widget.onDismiss();
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: widget.config.iconColor.withOpacity(0.8),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastConfig {
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  const _ToastConfig({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}
