import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/index.dart';
import '../../models/pastoral_care_request.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/pastoral_care_service.dart';
import '../../services/member_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 관리자용 심방 신청 상세 화면
class AdminPastoralCareDetailScreen extends StatefulWidget {
  final PastoralCareRequest request;

  const AdminPastoralCareDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<AdminPastoralCareDetailScreen> createState() =>
      _AdminPastoralCareDetailScreenState();
}

class _AdminPastoralCareDetailScreenState
    extends State<AdminPastoralCareDetailScreen> {
  final PastoralCareService _pastoralCareService = PastoralCareService();
  late PastoralCareRequest _request;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _request = widget.request;
  }

  Future<void> _changeStatus(String newStatus) async {
    final isCancel = newStatus == 'cancelled';
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '${_getStatusLabel(newStatus)}으로 변경할까요?',
      description: '심방 신청 상태를 변경합니다.',
      confirmLabel: _getStatusLabel(newStatus),
      tone: isCancel ? AppSheetTone.danger : AppSheetTone.sky,
      icon: isCancel ? LucideIcons.circleX : LucideIcons.circleCheck,
    );
    if (ok == true) await _performStatusUpdate(newStatus);
  }

  Future<void> _performStatusUpdate(String newStatus) async {
    setState(() => _isLoading = true);

    try {
      final response = await _pastoralCareService.updateRequestStatus(
        requestId: _request.id,
        status: newStatus,
      );

      if (response.success && response.data != null) {
        setState(() {
          _request = response.data!;
        });

        // 승인 시 요청자에게 알림 전송 (비동기, 실패해도 상태 변경은 성공)
        if (newStatus == 'approved') {
          _sendNotificationToRequester(response.data!).catchError((e) {
            print('❌ ADMIN_PASTORAL_CARE: 요청자 알림 전송 실패 - $e');
          });
        }

        if (mounted) {
          AppToast.show(
            context,
            '상태가 성공적으로 변경되었습니다',
            type: ToastType.success,
          );
        }
      } else {
        if (mounted) {
          AppToast.show(
            context,
            response.message.isNotEmpty
                ? response.message
                : '상태 변경에 실패했습니다',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '상태 변경 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  // 1.2.0 C 방향: 시안 — 헤더카드(아바타+이름+성도칩+부서·구역+상태칩+전화/문자 CTA) /
  // 신청 내용 카드 / 하단 고정 액션 푸터 (반려 + 승인하기)
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: NewAppColor.canvasAlt,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 26.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '심방 신청 상세',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: NewAppColor.skyPrimary,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRequesterSection(),
                        SizedBox(height: 12.h),
                        _buildRequestInfoSection(),
                      ],
                    ),
                  ),
                ),
                _buildBottomActionBar(),
              ],
            ),
    );
  }

  Widget _buildRequesterSection() {
    final name = _request.requesterName.isNotEmpty
        ? _request.requesterName
        : (_request.member?.name ?? '요청자');
    final initial = name.isNotEmpty ? name[0] : '?';
    final phone = _request.requesterPhone.isNotEmpty
        ? _request.requesterPhone
        : (_request.member?.phone ?? '');
    final position = _request.member?.positionLabel ?? '';
    final dept = _request.department ?? _request.member?.department ?? '';
    final district = _request.member?.district ?? '';
    final metaParts = [
      if (dept.isNotEmpty) dept,
      if (district.isNotEmpty) district,
      if (phone.isNotEmpty) phone,
    ];

    return _sectionCard(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  color: NewAppColor.skyDeep,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: NewAppColor.textStrong,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Pretendard',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (position.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        _buildPositionChip(position),
                      ],
                    ],
                  ),
                  if (metaParts.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      metaParts.join(' · '),
                      style: TextStyle(
                        color: NewAppColor.textTertiary,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            _buildStatusChip(_request.status),
          ],
        ),
      ],
    );
  }

  // 시안: 성도/직분 칩 (skyTint + skyDeep, 라운드 999)
  Widget _buildPositionChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: NewAppColor.skyTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: NewAppColor.skyDeep,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  // 1.2.0: 상태 칩 (목록 카드와 동일)
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

  // 시안: 신청 내용 카드 — 라벨/값 라인 정렬 + 종류 칩 + 요청 사항 본문 + 메타
  Widget _buildRequestInfoSection() {
    final preferredText = _formatPreferredSchedule();
    final body = _request.description;
    final metaParts = <String>[
      '신청일 ${_formatRequestDate(_request.createdAt)}',
      if (_request.requesterName.isNotEmpty || _request.member?.name != null)
        '신청자 ${_request.requesterName.isNotEmpty ? _request.requesterName : _request.member!.name}',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NewAppColor.borderHair, width: 1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 6.h),
            child: Text(
              '신청 내용',
              style: TextStyle(
                color: NewAppColor.textTertiary,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          // 라벨/값 라인업
          _buildLabelValueRow(
            icon: LucideIcons.stethoscope,
            label: '심방 종류',
            valueWidget: _buildTypeChip(
              _request.requestTypeDisplayName,
            ),
          ),
          if (preferredText.isNotEmpty)
            _buildLabelValueRow(
              icon: LucideIcons.calendar,
              label: '희망 일시',
              value: preferredText,
            ),
          if (_request.address != null && _request.address!.isNotEmpty)
            _buildLabelValueRow(
              icon: LucideIcons.mapPin,
              label: '장소',
              value: _request.address!,
            ),
          SizedBox(height: 8.h),
          // 요청 사항 본문
          if (body.isNotEmpty) ...[
            Container(height: 1, color: NewAppColor.borderHair),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 0.h),
              child: Text(
                '요청 사항',
                style: TextStyle(
                  color: NewAppColor.textTertiary,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 14.h),
              child: Text(
                body,
                style: TextStyle(
                  color: NewAppColor.textBody,
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                  height: 1.55,
                ),
              ),
            ),
          ] else
            SizedBox(height: 8.h),
          // 메타 (신청일·신청자)
          if (metaParts.isNotEmpty) ...[
            Container(height: 1, color: NewAppColor.borderHair),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 14.h),
              child: Text(
                metaParts.join(' · '),
                style: TextStyle(
                  color: NewAppColor.textTertiary,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 시안: 라벨(좌, 회색 아이콘+텍스트) / 값(우, 진한 텍스트 또는 칩)
  Widget _buildLabelValueRow({
    required IconData icon,
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 9.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16.sp, color: NewAppColor.textTertiary),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: NewAppColor.textTertiary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
          const Spacer(),
          if (valueWidget != null)
            valueWidget
          else
            Flexible(
              child: Text(
                value ?? '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: NewAppColor.textStrong,
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 시안: 신청 종류 칩 (skyPrimary fill + 흰 글씨)
  Widget _buildTypeChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: NewAppColor.skyPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w800,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  // 시안 하단 고정 액션 바 — 반려(연한 빨강 fill) + 승인하기(skyPrimary, 우측 확장)
  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: NewAppColor.canvasAlt,
        border: Border(
          top: BorderSide(color: NewAppColor.borderHair, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _buildStatusActions(),
      ),
    );
  }

  Widget _buildStatusActions() {
    switch (_request.status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildActionButton(
                label: '반려',
                onTap: () => _changeStatus('cancelled'),
                background: NewAppColor.dangerBg,
                foreground: NewAppColor.danger700,
              ),
            ),
            SizedBox(width: 9.w),
            Expanded(
              flex: 2,
              child: _buildActionButton(
                label: '승인하기',
                onTap: () => _changeStatus('approved'),
                background: NewAppColor.skyPrimary,
                foreground: Colors.white,
                shadow: true,
              ),
            ),
          ],
        );
      case 'approved':
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildActionButton(
                label: '취소',
                onTap: () => _changeStatus('cancelled'),
                background: NewAppColor.borderSoft,
                foreground: NewAppColor.textSecondary,
              ),
            ),
            SizedBox(width: 9.w),
            Expanded(
              flex: 2,
              child: _buildActionButton(
                label: '진행 시작',
                onTap: () => _changeStatus('in_progress'),
                background: NewAppColor.skyPrimary,
                foreground: Colors.white,
                shadow: true,
              ),
            ),
          ],
        );
      case 'in_progress':
        return _buildActionButton(
          label: '완료 처리',
          onTap: () => _changeStatus('completed'),
          background: NewAppColor.skyPrimary,
          foreground: Colors.white,
          shadow: true,
        );
      case 'completed':
        return _buildStatusBanner(
          icon: LucideIcons.circleCheck,
          label: '완료된 심방 신청입니다',
          bg: NewAppColor.successBg,
          fg: NewAppColor.success700,
        );
      case 'cancelled':
        return _buildStatusBanner(
          icon: LucideIcons.circleX,
          label: '취소/반려된 심방 신청입니다',
          bg: NewAppColor.dangerBg,
          fg: NewAppColor.danger700,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    required Color background,
    required Color foreground,
    bool shadow = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(13.r),
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: background.withOpacity(0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18.sp),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 희망 일시 포맷팅 — 시안: "6/18(목) 오후"
  String _formatPreferredSchedule() {
    final date = _request.preferredDate;
    if (date == null) return '';
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    final timeStart = _request.preferredTimeStart;
    String periodOrTime;
    if (timeStart != null && timeStart.isNotEmpty) {
      periodOrTime = timeStart;
    } else {
      periodOrTime = date.hour < 12 ? '오전' : '오후';
    }
    return '${date.month}/${date.day}($weekday) $periodOrTime';
  }

  // 신청일 메타 — 시안: "6월 14일"
  String _formatRequestDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }

  // 1.2.0 공용 카드 — 흰 배경 + borderHair 1px + 라운드 14
  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NewAppColor.borderHair, width: 1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
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

  /// 요청자에게 심방 승인 알림 전송
  Future<void> _sendNotificationToRequester(PastoralCareRequest request) async {
    try {
      print('🔔 ADMIN_PASTORAL_CARE: 요청자 알림 전송 시작');

      // 1. 요청자의 user_id 찾기
      int? requesterUserId = request.member?.userId;

      // member 정보가 없거나 userId가 없으면 member_id로 다시 조회
      if (requesterUserId == null && request.memberId != null) {
        print('🔔 ADMIN_PASTORAL_CARE: member에서 user_id를 찾을 수 없어 member_id로 재조회');
        final memberService = MemberService();
        final memberResponse = await memberService.getMember(request.memberId!);
        if (memberResponse.success && memberResponse.data != null) {
          requesterUserId = memberResponse.data!.userId;
          print('🔔 ADMIN_PASTORAL_CARE: member_id ${request.memberId}의 user_id: $requesterUserId');
        }
      }

      if (requesterUserId == null) {
        print('⚠️ ADMIN_PASTORAL_CARE: 요청자의 user_id를 찾을 수 없어 알림 전송 생략');
        return;
      }

      print('🔔 ADMIN_PASTORAL_CARE: 요청자 user_id: $requesterUserId');

      // 2. 알림 메시지 구성
      final title = '심방 요청 승인';
      final body = '심방 요청이 승인되었습니다. 담당자가 곧 연락드릴 예정입니다.';
      final notificationData = {
        'type': 'pastoral_care_approved',
        'request_id': request.id,
        'request_type': request.requestType,
        'status': 'approved',
      };

      // 3. notifications 테이블 삽입 + Edge Function으로 FCM 전송
      final now = DateTime.now().toUtc().toIso8601String();

      // 3-1. notifications 테이블에 삽입
      await Supabase.instance.client
          .from('notifications')
          .insert({
        'user_id': requesterUserId,
        'title': title,
        'body': body,
        'type': 'pastoral_care_approved',
        'is_read': false,
        'data': notificationData,
        'related_id': null,
        'related_type': 'pastoral_care_request',
        'created_at': now,
        'updated_at': now,
      });

      // 3-2. Edge Function 호출하여 FCM 전송
      final fcmResponse = await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'user_id': requesterUserId,
          'title': title,
          'body': body,
          'data': notificationData,
        },
      );

      print('✅ ADMIN_PASTORAL_CARE: Edge Function 응답: ${fcmResponse.data}');
    } catch (e, stackTrace) {
      print('❌ ADMIN_PASTORAL_CARE: 요청자 알림 전송 예외 - $e');
      print('❌ ADMIN_PASTORAL_CARE: 스택 트레이스 - $stackTrace');
      // 예외를 다시 던지지 않음 (알림 실패해도 상태 변경은 성공)
    }
  }
}