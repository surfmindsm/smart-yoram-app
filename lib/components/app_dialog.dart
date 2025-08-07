import 'package:flutter/material.dart';
import '../resource/color_style.dart';

class AppDialog extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? content;
  final List<Widget>? actions;
  final bool dismissible;
  final double? width;
  final double? height;

  const AppDialog({
    Key? key,
    this.title,
    this.description,
    this.content,
    this.actions,
    this.dismissible = true,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: width ?? MediaQuery.of(context).size.width * 0.9,
        height: height,
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColor.secondary07.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.all(24).copyWith(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColor.secondary07,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (dismissible)
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            size: 20,
                            color: AppColor.secondary05,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Description
            if (description != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24)
                    .copyWith(bottom: 16),
                child: Text(
                  description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColor.secondary06,
                    height: 1.5,
                  ),
                ),
              ),
            ],

            // Content
            if (content != null) ...[
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: content!,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(24).copyWith(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      actions![i],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? description,
    Widget? content,
    List<Widget>? actions,
    bool dismissible = true,
    double? width,
    double? height,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: (context) => AppDialog(
        title: title,
        description: description,
        content: content,
        actions: actions,
        dismissible: dismissible,
        width: width,
        height: height,
      ),
    );
  }
}

// Alert Dialog - 간단한 확인/취소
class AppAlertDialog extends StatelessWidget {
  final String title;
  final String description;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool destructive;

  const AppAlertDialog({
    Key? key,
    required this.title,
    required this.description,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.onConfirm,
    this.onCancel,
    this.destructive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      description: description,
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(false),
          child: Text(
            cancelText,
            style: TextStyle(
              color: AppColor.secondary06,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? AppColor.error : AppColor.primary7,
            foregroundColor: AppColor.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String description,
    String confirmText = '확인',
    String cancelText = '취소',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    bool destructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AppAlertDialog(
        title: title,
        description: description,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        destructive: destructive,
      ),
    );
  }
}

// Loading Dialog
class AppLoadingDialog extends StatelessWidget {
  final String? message;

  const AppLoadingDialog({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary7),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.secondary06,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> show({
    required BuildContext context,
    String? message,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppLoadingDialog(message: message),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context).pop();
  }
}
