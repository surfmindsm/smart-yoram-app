import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/pastoral_care_request.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';

/// 1.2.0 C 방향: 관리자용 심방 신청 카드
///
/// 시안 §297-324 — 아바타+이름+상태칩 / 유형·희망일정 칩 / 본문 / 담당자 미지정 /
/// 담당자 지정 + 승인 버튼 2분할. 카드 사이 두꺼운 회색 구분선(8px borderSoft).
class PastoralCareCard extends StatelessWidget {
  final PastoralCareRequest request;
  final VoidCallback? onTap;
  final VoidCallback? onAssign;
  final VoidCallback? onApprove;

  const PastoralCareCard({
    super.key,
    required this.request,
    this.onTap,
    this.onAssign,
    this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final name = request.requesterName.isNotEmpty
        ? request.requesterName
        : (request.member?.name ?? '요청자');
    final initial = name.isNotEmpty ? name[0] : '?';
    final isPending = request.status == 'pending';
    final hasAssignedPastor = request.assignedPastorId != null;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 16.h),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 (아바타 + 이름·연락처 + 상태칩)
            Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: NewAppColor.skyTint,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: NewAppColor.skyDeep,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                SizedBox(width: 11.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$name ${_positionSuffix(request)}',
                        style: TextStyle(
                          color: NewAppColor.textStrong,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '연락처 ${request.requesterPhone}',
                        style: TextStyle(
                          color: NewAppColor.textTertiary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                _buildStatusChip(request.status),
              ],
            ),
            SizedBox(height: 13.h),
            // 유형 + 희망일정 칩
            Wrap(
              spacing: 7.w,
              runSpacing: 6.h,
              children: [
                _buildTypeChip(_getRequestTypeLabel(request.requestType)),
                if (request.preferredDate != null)
                  _buildInfoChip(
                    '희망 ${_formatPreferredDate(request.preferredDate!)}',
                  ),
              ],
            ),
            SizedBox(height: 11.h),
            // 본문 (최대 3줄)
            Text(
              request.description,
              style: TextStyle(
                color: NewAppColor.textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
                height: 1.55,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            // 담당 교역자 라인
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 15.sp,
                  color: NewAppColor.textTertiary,
                ),
                SizedBox(width: 5.w),
                Text(
                  '담당 교역자 ',
                  style: TextStyle(
                    color: NewAppColor.textTertiary,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                Text(
                  hasAssignedPastor ? '지정됨' : '미지정',
                  style: TextStyle(
                    color: hasAssignedPastor
                        ? NewAppColor.textBody
                        : NewAppColor.danger700,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
            // 액션 버튼 (대기 상태일 때만)
            if (isPending) ...[
              SizedBox(height: 14.h),
              Row(
                children: [
                  // 담당자 지정 (보조)
                  Expanded(
                    child: GestureDetector(
                      onTap: onAssign,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        decoration: BoxDecoration(
                          color: NewAppColor.borderSoft,
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '담당자 지정',
                          style: TextStyle(
                            color: NewAppColor.textSecondary,
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 9.w),
                  // 승인 (주)
                  Expanded(
                    child: GestureDetector(
                      onTap: onApprove,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 11.h),
                        decoration: BoxDecoration(
                          color: NewAppColor.skyPrimary,
                          borderRadius: BorderRadius.circular(11.r),
                          boxShadow: [
                            BoxShadow(
                              color: NewAppColor.skyPrimary.withOpacity(0.30),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '승인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 상태 칩 (대기=warning, 승인=sky, 완료=success, 취소=danger)
  Widget _buildStatusChip(String status) {
    final ({Color bg, Color fg, String label}) style;
    switch (status) {
      case 'pending':
        style = (
          bg: NewAppColor.warningBg,
          fg: NewAppColor.warning700,
          label: '대기',
        );
        break;
      case 'approved':
        style = (
          bg: NewAppColor.skyTint,
          fg: NewAppColor.skyDeep,
          label: '승인',
        );
        break;
      case 'in_progress':
        style = (
          bg: NewAppColor.skyTint,
          fg: NewAppColor.skyDeep,
          label: '진행중',
        );
        break;
      case 'completed':
        style = (
          bg: NewAppColor.successBg,
          fg: NewAppColor.success700,
          label: '완료',
        );
        break;
      case 'cancelled':
        style = (
          bg: NewAppColor.dangerBg,
          fg: NewAppColor.danger700,
          label: '취소',
        );
        break;
      case 'scheduled':
        style = (
          bg: NewAppColor.skyTint,
          fg: NewAppColor.skyDeep,
          label: '예정',
        );
        break;
      default:
        style = (
          bg: NewAppColor.borderSoft,
          fg: NewAppColor.textSecondary,
          label: status,
        );
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          color: style.fg,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  // 유형 칩 (skyTint + skyDeep)
  Widget _buildTypeChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: NewAppColor.skyTint,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: NewAppColor.skyDeep,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  // 정보 칩 (borderSoft + textSecondary) — 희망일정 등
  Widget _buildInfoChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: NewAppColor.borderSoft,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: NewAppColor.textSecondary,
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  String _positionSuffix(PastoralCareRequest request) {
    final p = request.member?.positionLabel;
    return (p != null && p.isNotEmpty) ? p : '';
  }

  String _getRequestTypeLabel(String type) {
    switch (type) {
      case 'general':
        return '일반 심방';
      case 'urgent':
        return '긴급 심방';
      case 'hospital':
        return '병원 심방';
      case 'counseling':
        return '상담';
      case 'visit':
        return '심방';
      case 'prayer':
        return '기도';
      case 'emergency':
        return '응급';
      default:
        return type;
    }
  }

  // 시안: "희망 6/18(목) 오후"
  String _formatPreferredDate(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    final period = date.hour < 12 ? '오전' : '오후';
    return '${date.month}/${date.day}($weekday) $period';
  }
}
