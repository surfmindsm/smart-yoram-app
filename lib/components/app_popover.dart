import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum PopoverPosition {
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class AppPopover extends StatefulWidget {
  final Widget child;
  final Widget content;
  final PopoverPosition position;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool showArrow;
  final bool dismissOnTap;
  final Duration? showDuration;
  final VoidCallback? onShow;
  final VoidCallback? onHide;

  const AppPopover({
    Key? key,
    required this.child,
    required this.content,
    this.position = PopoverPosition.bottom,
    this.width,
    this.height,
    this.padding,
    this.backgroundColor,
    this.showArrow = true,
    this.dismissOnTap = true,
    this.showDuration,
    this.onShow,
    this.onHide,
  }) : super(key: key);

  @override
  State<AppPopover> createState() => _AppPopoverState();
}

class _AppPopoverState extends State<AppPopover>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _scaleAnimation;
  bool _isShowing = false;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _hidePopover();
    _animationController?.dispose();
    super.dispose();
  }

  void _showPopover() {
    if (_isShowing) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _animationController!.forward();
    _isShowing = true;
    widget.onShow?.call();

    if (widget.showDuration != null) {
      Future.delayed(widget.showDuration!, () {
        if (mounted && _isShowing) {
          _hidePopover();
        }
      });
    }
  }

  void _hidePopover() {
    if (!_isShowing) return;

    _animationController!.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      if (mounted) {
        setState(() => _isShowing = false);
        widget.onHide?.call();
      }
    });
  }

  void _togglePopover() {
    if (_isShowing) {
      _hidePopover();
    } else {
      _showPopover();
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: widget.dismissOnTap ? _hidePopover : null,
        child: Container(
          color: Colors.transparent,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: _getOffset(),
                child: FadeTransition(
                  opacity: _fadeAnimation!,
                  child: ScaleTransition(
                    scale: _scaleAnimation!,
                    alignment: _getAlignment(),
                    child: _buildPopoverContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopoverContent() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: widget.width,
        height: widget.height,
        constraints: widget.width == null || widget.height == null
            ? const BoxConstraints(
                minWidth: 100,
                maxWidth: 300,
                minHeight: 50,
                maxHeight: 400,
              )
            : null,
        padding: widget.padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? AppColor.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColor.border1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: widget.content,
      ),
    );
  }

  Offset _getOffset() {
    const margin = 8.0;
    switch (widget.position) {
      case PopoverPosition.top:
        return const Offset(0, -(margin + 8));
      case PopoverPosition.bottom:
        return const Offset(0, margin + 8);
      case PopoverPosition.left:
        return const Offset(-(margin + 8), 0);
      case PopoverPosition.right:
        return const Offset(margin + 8, 0);
      case PopoverPosition.topLeft:
        return const Offset(0, -(margin + 8));
      case PopoverPosition.topRight:
        return const Offset(0, -(margin + 8));
      case PopoverPosition.bottomLeft:
        return const Offset(0, margin + 8);
      case PopoverPosition.bottomRight:
        return const Offset(0, margin + 8);
    }
  }

  Alignment _getAlignment() {
    switch (widget.position) {
      case PopoverPosition.top:
      case PopoverPosition.topLeft:
      case PopoverPosition.topRight:
        return Alignment.bottomCenter;
      case PopoverPosition.bottom:
      case PopoverPosition.bottomLeft:
      case PopoverPosition.bottomRight:
        return Alignment.topCenter;
      case PopoverPosition.left:
        return Alignment.centerRight;
      case PopoverPosition.right:
        return Alignment.centerLeft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _togglePopover,
        child: widget.child,
      ),
    );
  }

  // Named constructors for common use cases
  static AppPopover menu({
    Key? key,
    required Widget child,
    required List<AppPopoverMenuItem> items,
    PopoverPosition position = PopoverPosition.bottom,
    double? width,
  }) {
    return AppPopover(
      key: key,
      child: child,
      position: position,
      width: width ?? 200,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return InkWell(
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 16, color: AppColor.secondary04),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColor.secondary06,
                      ),
                    ),
                  ),
                  if (item.trailing != null) item.trailing!,
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static AppPopover info({
    Key? key,
    required Widget child,
    required String title,
    String? description,
    PopoverPosition position = PopoverPosition.top,
    double? width,
  }) {
    return AppPopover(
      key: key,
      child: child,
      position: position,
      width: width ?? 250,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColor.secondary06,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColor.secondary04,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AppPopoverMenuItem {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppPopoverMenuItem({
    required this.title,
    this.icon,
    this.trailing,
    this.onTap,
  });
}
