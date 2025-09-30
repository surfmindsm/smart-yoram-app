import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/pastoral_care_request.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import 'status_badge.dart';

/// 관리자용 심방 신청 카드 컴포넌트
class PastoralCareCard extends StatelessWidget {
  final PastoralCareRequest request;
  final VoidCallback? onTap;

  const PastoralCareCard({
    super.key,
    required this.request,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (신청자 이름 + 상태 뱃지)
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.requesterName.isNotEmpty
                        ? request.requesterName
                        : (request.member?.name ?? '요청자'),
                    style: const FigmaTextStyles().body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: NewAppColor.neutral900,
                    ),
                  ),
                ),
                StatusBadge(
                  status: request.status,
                  label: _getStatusLabel(request.status),
                  isUrgent: request.isUrgent,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            // 신청 유형
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: NewAppColor.primary100,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    _getRequestTypeLabel(request.requestType),
                    style: const FigmaTextStyles().caption2.copyWith(
                      color: NewAppColor.primary600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (request.priority == 'high') ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '긴급',
                      style: const FigmaTextStyles().caption2.copyWith(
                        color: const Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 12.h),
            // 신청 내용 (요약)
            Text(
              _getContentPreview(request.description),
              style: const FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            // 하단 정보 (전화번호, 희망일)
            Row(
              children: [
                if (request.preferredDate != null) ...[
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14.sp,
                    color: NewAppColor.neutral600,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(request.preferredDate!),
                    style: const FigmaTextStyles().caption1.copyWith(
                      color: NewAppColor.neutral600,
                    ),
                  ),
                ],
                if (request.preferredDate != null &&
                    request.requesterPhone.isNotEmpty) ...[
                  SizedBox(width: 12.w),
                  Container(
                    width: 1,
                    height: 12.h,
                    color: NewAppColor.neutral300,
                  ),
                  SizedBox(width: 12.w),
                ],
                if (request.requesterPhone.isNotEmpty) ...[
                  Icon(
                    Icons.phone_outlined,
                    size: 14.sp,
                    color: NewAppColor.neutral600,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    request.requesterPhone,
                    style: const FigmaTextStyles().caption1.copyWith(
                      color: NewAppColor.neutral600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return '대기';
      case 'approved':
        return '승인';
      case 'in_progress':
        return '진행중';
      case 'completed':
        return '완료';
      case 'cancelled':
        return '취소';
      default:
        return status;
    }
  }

  String _getRequestTypeLabel(String type) {
    switch (type) {
      case 'visit':
        return '심방';
      case 'counseling':
        return '상담';
      case 'prayer':
        return '기도';
      case 'emergency':
        return '응급';
      case 'general':
        return '일반';
      default:
        return type;
    }
  }

  String _getContentPreview(String content) {
    if (content.length > 60) {
      return '${content.substring(0, 60)}...';
    }
    return content;
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}