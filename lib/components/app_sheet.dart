import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum SheetType {
  bottom,
  side,
}

class AppSheet {
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = false,
    double? height,
    EdgeInsetsGeometry? padding,
    Widget? leading,
    List<Widget>? actions,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppBottomSheet(
        title: title,
        height: height,
        padding: padding,
        leading: leading,
        actions: actions,
        onClose: onClose,
        child: child,
      ),
    );
  }

  static Future<T?> showSideSheet<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isDismissible = true,
    double? width,
    EdgeInsetsGeometry? padding,
    Widget? leading,
    List<Widget>? actions,
    VoidCallback? onClose,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      barrierLabel: 'Side Sheet',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _AppSideSheet(
          title: title,
          width: width,
          padding: padding,
          leading: leading,
          actions: actions,
          onClose: onClose,
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
    );
  }

  // Quick access methods for common use cases
  static Future<T?> showMenu<T>(
    BuildContext context, {
    required String title,
    required List<AppSheetMenuItem> items,
    Widget? leading,
    VoidCallback? onClose,
  }) {
    return showBottomSheet<T>(
      context,
      title: title,
      leading: leading,
      onClose: onClose,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return ListTile(
            leading: item.icon != null 
              ? Icon(item.icon, color: AppColor.secondary04) 
              : null,
            title: Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                color: AppColor.secondary06,
              ),
            ),
            subtitle: item.subtitle != null
              ? Text(
                  item.subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColor.secondary04,
                  ),
                )
              : null,
            trailing: item.trailing,
            onTap: () {
              Navigator.of(context).pop();
              item.onTap?.call();
            },
          );
        }).toList(),
      ),
    );
  }

  static Future<T?> showConfirm<T>(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '확인',
    String cancelText = '취소',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showBottomSheet<T>(
      context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppColor.secondary06,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.secondary06,
                    side: const BorderSide(color: AppColor.border1),
                  ),
                  child: Text(cancelText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary600,
                    foregroundColor: AppColor.white,
                  ),
                  child: Text(confirmText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<T?> showForm<T>(
    BuildContext context, {
    required String title,
    required Widget form,
    String submitText = '저장',
    String cancelText = '취소',
    VoidCallback? onSubmit,
    VoidCallback? onCancel,
  }) {
    return showSideSheet<T>(
      context,
      title: title,
      width: 400,
      child: Column(
        children: [
          Expanded(child: form),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCancel?.call();
                  },
                  child: Text(cancelText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    onSubmit?.call();
                  },
                  child: Text(submitText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppBottomSheet extends StatelessWidget {
  final String? title;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  final Widget child;

  const _AppBottomSheet({
    Key? key,
    this.title,
    this.height,
    this.padding,
    this.leading,
    this.actions,
    this.onClose,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColor.secondary02,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          if (title != null || actions != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: title != null
                      ? Text(
                          title!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColor.secondary06,
                          ),
                        )
                      : const SizedBox.shrink(),
                  ),
                  if (actions != null) ...actions!,
                  if (onClose != null)
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onClose?.call();
                      },
                      icon: const Icon(Icons.close),
                    ),
                ],
              ),
            ),

          // Content
          if (height != null)
            Expanded(
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            )
          else
            Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _AppSideSheet extends StatelessWidget {
  final String? title;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onClose;
  final Widget child;

  const _AppSideSheet({
    Key? key,
    this.title,
    this.width,
    this.padding,
    this.leading,
    this.actions,
    this.onClose,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        child: Container(
          width: width ?? 350,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppColor.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(-2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              if (title != null || actions != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColor.border1),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: title != null
                          ? Text(
                              title!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColor.secondary06,
                              ),
                            )
                          : const SizedBox.shrink(),
                      ),
                      if (actions != null) ...actions!,
                      if (onClose != null)
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onClose?.call();
                          },
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),

              // Content
              Expanded(
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppSheetMenuItem {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  const AppSheetMenuItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
  });
}
