import 'package:flutter/material.dart';

/// 빠른 메뉴 아이템 위젯
class QuickMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? borderColor;
  final double? iconSize;

  const QuickMenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.borderColor,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? Colors.blue[700];
    final effectiveBorderColor = borderColor ?? Colors.grey[300];
    final effectiveIconSize = iconSize ?? 32.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: effectiveBorderColor!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: effectiveIconSize, color: effectiveIconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
