import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../resource/color_style_new.dart';

/// 상태 뱃지 컴포넌트
class StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  final bool isUrgent;

  const StatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isUrgent) ...[
            Icon(
              Icons.error,
              size: 12.sp,
              color: Colors.red,
            ),
            SizedBox(width: 4.w),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: colors['text'],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getStatusColors() {
    switch (status) {
      case 'active':
        return {
          'background': const Color(0xFFE8F5E9),
          'text': const Color(0xFF2E7D32),
        };
      case 'inactive':
        return {
          'background': const Color(0xFFFFF3E0),
          'text': const Color(0xFFE65100),
        };
      case 'pending':
        return {
          'background': const Color(0xFFFFF9C4),
          'text': const Color(0xFFF57F17),
        };
      case 'approved':
        return {
          'background': const Color(0xFFE3F2FD),
          'text': const Color(0xFF1565C0),
        };
      case 'in_progress':
        return {
          'background': const Color(0xFFE1F5FE),
          'text': const Color(0xFF0277BD),
        };
      case 'completed':
        return {
          'background': const Color(0xFFE8F5E9),
          'text': const Color(0xFF2E7D32),
        };
      case 'cancelled':
        return {
          'background': const Color(0xFFFFEBEE),
          'text': const Color(0xFFC62828),
        };
      default:
        return {
          'background': NewAppColor.neutral200,
          'text': NewAppColor.neutral700,
        };
    }
  }
}