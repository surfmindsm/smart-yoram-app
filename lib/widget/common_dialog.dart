import 'package:flutter/material.dart';
import 'common_button.dart';

/// 공통 다이얼로그 위젯들
class CommonDialog {
  /// 확인 다이얼로그
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '확인',
    String cancelText = '취소',
    Color? confirmColor,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CommonButton(
            text: cancelText,
            type: ButtonType.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CommonButton(
            text: confirmText,
            type: isDangerous ? ButtonType.danger : ButtonType.primary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  /// 정보 다이얼로그
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String content,
    String buttonText = '확인',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CommonButton(
            text: buttonText,
            type: ButtonType.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 에러 다이얼로그
  static Future<void> showErrorDialog(
    BuildContext context, {
    String title = '오류',
    required String message,
    String buttonText = '확인',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          CommonButton(
            text: buttonText,
            type: ButtonType.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// 입력 다이얼로그
  static Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    String? hintText,
    String? initialValue,
    String confirmText = '확인',
    String cancelText = '취소',
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: initialValue);
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          maxLines: maxLines,
          keyboardType: keyboardType,
          autofocus: true,
        ),
        actions: [
          CommonButton(
            text: cancelText,
            type: ButtonType.text,
            onPressed: () => Navigator.of(context).pop(),
          ),
          CommonButton(
            text: confirmText,
            type: ButtonType.primary,
            onPressed: () => Navigator.of(context).pop(controller.text),
          ),
        ],
      ),
    );
  }
}
