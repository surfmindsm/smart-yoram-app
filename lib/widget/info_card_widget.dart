import 'package:flutter/material.dart';

/// 정보를 표시하는 카드 위젯
class InfoCardWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<InfoItem> items;
  final VoidCallback? onTap;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? backgroundColor;

  const InfoCardWidget({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.items,
    this.onTap,
    this.iconColor,
    this.padding,
    this.elevation,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? 0,
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 섹션
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor ?? Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              if (items.isNotEmpty) ...[
                const SizedBox(height: 12),

                // 정보 아이템들
                ...items.map((item) => _buildInfoItem(item)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Row(
              children: [
                if (item.label != null) ...[
                  Text(
                    '${item.label}: ',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                Expanded(
                  child: Text(
                    item.value,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 정보 아이템 클래스
class InfoItem {
  final String? label;
  final String value;
  final IconData? icon;

  InfoItem({
    this.label,
    required this.value,
    this.icon,
  });
}
