import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 설정 화면 등에서 사용되는 커스텀 리스트 타일
class CustomListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;
  final bool showArrow;

  const CustomListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.onTap,
    this.textColor,
    this.iconColor,
    this.trailing,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Colors.grey[600];
    
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? effectiveIconColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: trailing ?? (showArrow ? const Icon(LucideIcons.chevronRight) : null),
      onTap: onTap,
    );
  }
}
