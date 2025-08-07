import 'package:flutter/material.dart';
import '../resource/color_style.dart';

enum AlertType {
  info,
  warning,
  error,
  success,
}

class AppAlert extends StatelessWidget {
  final String title;
  final String? description;
  final AlertType type;
  final Widget? icon;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const AppAlert({
    Key? key,
    required this.title,
    this.description,
    this.type = AlertType.info,
    this.icon,
    this.onClose,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alertTheme = _getAlertTheme(type);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: alertTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alertTheme.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: icon ?? Icon(
              alertTheme.defaultIcon,
              color: alertTheme.iconColor,
              size: 20,
            ),
          ),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: alertTheme.titleColor,
                    height: 1.4,
                  ),
                ),
                
                // Description
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: alertTheme.descriptionColor,
                      height: 1.5,
                    ),
                  ),
                ],
                
                // Actions
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: actions!,
                  ),
                ],
              ],
            ),
          ),
          
          // Close button
          if (onClose != null)
            GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: alertTheme.titleColor.withOpacity(0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _AlertTheme _getAlertTheme(AlertType type) {
    switch (type) {
      case AlertType.info:
        return _AlertTheme(
          backgroundColor: AppColor.primary100,
          borderColor: AppColor.primary3.withOpacity(0.3),
          iconColor: AppColor.primary7,
          titleColor: AppColor.secondary07,
          descriptionColor: AppColor.secondary06,
          defaultIcon: Icons.info_outline,
        );
      case AlertType.warning:
        return _AlertTheme(
          backgroundColor: AppColor.orange100,
          borderColor: AppColor.orange400.withOpacity(0.3),
          iconColor: AppColor.orange500,
          titleColor: AppColor.secondary07,
          descriptionColor: AppColor.secondary06,
          defaultIcon: Icons.warning_amber_outlined,
        );
      case AlertType.error:
        return _AlertTheme(
          backgroundColor: const Color(0xffFEF2F2),
          borderColor: AppColor.error.withOpacity(0.3),
          iconColor: AppColor.error,
          titleColor: AppColor.secondary07,
          descriptionColor: AppColor.secondary06,
          defaultIcon: Icons.error_outline,
        );
      case AlertType.success:
        return _AlertTheme(
          backgroundColor: const Color(0xffF0FDF4),
          borderColor: const Color(0xff22C55E).withOpacity(0.3),
          iconColor: const Color(0xff22C55E),
          titleColor: AppColor.secondary07,
          descriptionColor: AppColor.secondary06,
          defaultIcon: Icons.check_circle_outline,
        );
    }
  }
}

class _AlertTheme {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color titleColor;
  final Color descriptionColor;
  final IconData defaultIcon;

  const _AlertTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.titleColor,
    required this.descriptionColor,
    required this.defaultIcon,
  });
}

// Pre-built Alert variants for convenience
class InfoAlert extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const InfoAlert({
    Key? key,
    required this.title,
    this.description,
    this.onClose,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppAlert(
      title: title,
      description: description,
      type: AlertType.info,
      onClose: onClose,
      actions: actions,
    );
  }
}

class WarningAlert extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const WarningAlert({
    Key? key,
    required this.title,
    this.description,
    this.onClose,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppAlert(
      title: title,
      description: description,
      type: AlertType.warning,
      onClose: onClose,
      actions: actions,
    );
  }
}

class ErrorAlert extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const ErrorAlert({
    Key? key,
    required this.title,
    this.description,
    this.onClose,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppAlert(
      title: title,
      description: description,
      type: AlertType.error,
      onClose: onClose,
      actions: actions,
    );
  }
}

class SuccessAlert extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  const SuccessAlert({
    Key? key,
    required this.title,
    this.description,
    this.onClose,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppAlert(
      title: title,
      description: description,
      type: AlertType.success,
      onClose: onClose,
      actions: actions,
    );
  }
}
