import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum TooltipPosition {
  top,
  bottom,
  left,
  right,
}

class AppTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final TooltipPosition position;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final double? maxWidth;
  final bool showArrow;

  const AppTooltip({
    Key? key,
    required this.child,
    required this.message,
    this.position = TooltipPosition.top,
    this.padding,
    this.textStyle,
    this.backgroundColor,
    this.maxWidth,
    this.showArrow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColor.secondary06,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: textStyle ?? const TextStyle(
        color: AppColor.white,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      preferBelow: position == TooltipPosition.bottom,
      verticalOffset: _getVerticalOffset(),
      child: child,
    );
  }

  double _getVerticalOffset() {
    switch (position) {
      case TooltipPosition.top:
        return -8;
      case TooltipPosition.bottom:
        return 8;
      case TooltipPosition.left:
      case TooltipPosition.right:
        return 0;
    }
  }

  // Named constructors for common use cases
  static AppTooltip info({
    Key? key,
    required Widget child,
    required String message,
    TooltipPosition position = TooltipPosition.top,
  }) {
    return AppTooltip(
      key: key,
      child: child,
      message: message,
      position: position,
      backgroundColor: AppColor.secondary06,
    );
  }

  static AppTooltip warning({
    Key? key,
    required Widget child,
    required String message,
    TooltipPosition position = TooltipPosition.top,
  }) {
    return AppTooltip(
      key: key,
      child: child,
      message: message,
      position: position,
      backgroundColor: AppColor.orange500,
    );
  }

  static AppTooltip error({
    Key? key,
    required Widget child,
    required String message,
    TooltipPosition position = TooltipPosition.top,
  }) {
    return AppTooltip(
      key: key,
      child: child,
      message: message,
      position: position,
      backgroundColor: AppColor.error,
    );
  }
}

class AppRichTooltip extends StatefulWidget {
  final Widget child;
  final Widget content;
  final TooltipPosition position;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double? maxWidth;
  final bool showArrow;
  final Duration? showDuration;
  final Duration? waitDuration;

  const AppRichTooltip({
    Key? key,
    required this.child,
    required this.content,
    this.position = TooltipPosition.top,
    this.padding,
    this.backgroundColor,
    this.maxWidth,
    this.showArrow = true,
    this.showDuration,
    this.waitDuration,
  }) : super(key: key);

  @override
  State<AppRichTooltip> createState() => _AppRichTooltipState();
}

class _AppRichTooltipState extends State<AppRichTooltip> 
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  Animation<double>? _animation;
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _hideTooltip();
    _animationController?.dispose();
    super.dispose();
  }

  void _showTooltip() {
    if (_isShowing) return;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController!.forward();
    _isShowing = true;
  }

  void _hideTooltip() {
    if (!_isShowing) return;
    
    _animationController!.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isShowing = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy - 60,
        child: FadeTransition(
          opacity: _animation!,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: widget.maxWidth ?? 200,
              ),
              padding: widget.padding ?? const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppColor.secondary06,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: widget.content,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isShowing ? _hideTooltip : _showTooltip,
      onLongPress: _showTooltip,
      child: MouseRegion(
        onEnter: (_) => _showTooltip(),
        onExit: (_) => _hideTooltip(),
        child: widget.child,
      ),
    );
  }
}
