import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';

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
          maxWidth: 400.w,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: NewAppColor.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: NewAppColor.neutral900.withOpacity(0.1),
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
                padding: EdgeInsets.all(24.w).copyWith(bottom: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title!,
                        style: FigmaTextStyles().subtitle1.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                      ),
                    ),
                    if (dismissible)
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: EdgeInsets.all(4.w),
                          child: Icon(
                            Icons.close,
                            size: 20.sp,
                            color: NewAppColor.neutral600,
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
                padding: EdgeInsets.symmetric(horizontal: 24.w)
                    .copyWith(bottom: 16.h),
                child: Text(
                  description!,
                  style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral700,
                  ),
                ),
              ),
            ],

            // Content
            if (content != null) ...[
              Flexible(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: content!,
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Actions
            if (actions != null && actions!.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.all(24.w).copyWith(top: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions!.length; i++) ...[
                      if (i > 0) SizedBox(width: 12.w),
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
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          ),
          child: Text(
            cancelText,
            style: FigmaTextStyles().subtitle3.copyWith(
              color: NewAppColor.neutral600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive ? NewAppColor.danger600 : NewAppColor.primary600,
            foregroundColor: NewAppColor.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            elevation: 0,
          ),
          child: Text(
            confirmText,
            style: FigmaTextStyles().subtitle3.copyWith(
              color: NewAppColor.white,
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
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: NewAppColor.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(NewAppColor.primary600),
            ),
            if (message != null) ...[
              SizedBox(height: 16.h),
              Text(
                message!,
                style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral700,
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

// Info Dialog - 단순 정보 표시
class AppInfoDialog extends StatelessWidget {
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback? onConfirm;

  const AppInfoDialog({
    Key? key,
    required this.title,
    required this.description,
    this.buttonText = '확인',
    this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      description: description,
      actions: [
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: NewAppColor.primary600,
            foregroundColor: NewAppColor.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            elevation: 0,
          ),
          child: Text(
            buttonText,
            style: FigmaTextStyles().subtitle3.copyWith(
              color: NewAppColor.white,
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String description,
    String buttonText = '확인',
    VoidCallback? onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AppInfoDialog(
        title: title,
        description: description,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    );
  }
}

// Error Dialog - 에러 표시
class AppErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback? onConfirm;

  const AppErrorDialog({
    Key? key,
    this.title = '오류',
    required this.message,
    this.buttonText = '확인',
    this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      content: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: NewAppColor.danger600,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral700,
              ),
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: NewAppColor.primary600,
            foregroundColor: NewAppColor.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            elevation: 0,
          ),
          child: Text(
            buttonText,
            style: FigmaTextStyles().subtitle3.copyWith(
              color: NewAppColor.white,
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    String title = '오류',
    required String message,
    String buttonText = '확인',
    VoidCallback? onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AppErrorDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    );
  }
}

// Input Dialog - 텍스트 입력
class AppInputDialog extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? initialValue;
  final String confirmText;
  final String cancelText;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AppInputDialog({
    Key? key,
    required this.title,
    this.hintText,
    this.initialValue,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  }) : super(key: key);

  @override
  State<AppInputDialog> createState() => _AppInputDialogState();

  static Future<String?> show({
    required BuildContext context,
    required String title,
    String? hintText,
    String? initialValue,
    String confirmText = '확인',
    String cancelText = '취소',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => AppInputDialog(
        title: title,
        hintText: hintText,
        initialValue: initialValue,
        confirmText: confirmText,
        cancelText: cancelText,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}

class _AppInputDialogState extends State<AppInputDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (widget.validator != null) {
      final error = widget.validator!(_controller.text);
      if (error != null) {
        setState(() {
          _errorText = error;
        });
        return;
      }
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: FigmaTextStyles().body2.copyWith(
            color: NewAppColor.neutral400,
          ),
          errorText: _errorText,
          filled: true,
          fillColor: NewAppColor.neutral100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
        style: FigmaTextStyles().body2.copyWith(
          color: NewAppColor.neutral900,
        ),
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        autofocus: true,
        onChanged: (_) {
          if (_errorText != null) {
            setState(() {
              _errorText = null;
            });
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          ),
          child: Text(
            widget.cancelText,
            style: FigmaTextStyles().subtitle3.copyWith(
              color: NewAppColor.neutral600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: NewAppColor.primary600,
            foregroundColor: NewAppColor.white,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            elevation: 0,
          ),
          child: Text(
            widget.confirmText,
            style: FigmaTextStyles().subtitle3.copyWith(
              color: NewAppColor.white,
            ),
          ),
        ),
      ],
    );
  }
}
