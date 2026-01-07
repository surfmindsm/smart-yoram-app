import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/index.dart';
import '../../components/admin/status_badge.dart';
import '../../models/pastoral_care_request.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/pastoral_care_service.dart';
import '../../services/member_service.dart';

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

  Future<void> _makePhoneCall() async {
    final phoneNumber = _request.requesterPhone.isNotEmpty
        ? _request.requesterPhone
        : (_request.member?.phone ?? '');
    if (phoneNumber.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppToast.show(
          context,
          '전화를 걸 수 없습니다',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '상태 변경',
        content: Text('심방 신청 상태를 "${_getStatusLabel(newStatus)}"으로 변경하시겠습니까?'),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performStatusUpdate(newStatus);
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: NewAppColor.neutral100,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '심방 신청 상세',
          style: const FigmaTextStyles().title2.copyWith(
            color: NewAppColor.neutral900,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 신청자 정보 섹션
                  _buildRequesterSection(),
                  SizedBox(height: 16.h),
                  // 신청 내용 섹션
                  _buildRequestInfoSection(),
                  SizedBox(height: 16.h),
                  // 위치 정보 섹션
                  if (_request.address != null &&
                      _request.address!.isNotEmpty)
                    _buildLocationSection(),
                  if (_request.address != null && _request.address!.isNotEmpty)
                    SizedBox(height: 16.h),
                  // 상태 관리 섹션
                  _buildStatusManagementSection(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
    );
  }

  Widget _buildRequesterSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '신청자 정보',
                  style: const FigmaTextStyles().title3.copyWith(
                    color: NewAppColor.neutral900,
                  ),
                ),
              ),
              StatusBadge(
                status: _request.status,
                label: _getStatusLabel(_request.status),
                isUrgent: _request.isUrgent,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: '이름',
            value: _request.requesterName.isNotEmpty
                ? _request.requesterName
                : (_request.member?.name ?? '알 수 없음'),
          ),
          if (_request.requesterPhone.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: '전화번호',
              value: _request.requesterPhone,
              onTap: _makePhoneCall,
            ),
          ] else if (_request.member?.phone.isNotEmpty ?? false) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: '전화번호',
              value: _request.member!.phone,
              onTap: _makePhoneCall,
            ),
          ],
          if (_request.contactInfo != null &&
              _request.contactInfo!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.contact_phone_outlined,
              label: '연락처 정보',
              value: _request.contactInfo!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '신청 내용',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          // 신청 유형
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: NewAppColor.primary100,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _request.requestType,
                  style: const FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.primary600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _getPriorityColor(_request.priority),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _getPriorityLabel(_request.priority),
                  style: const FigmaTextStyles().body2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // 제목
          if (_request.title.isNotEmpty) ...[
            Text(
              _request.title,
              style: const FigmaTextStyles().title3.copyWith(
                color: NewAppColor.neutral900,
              ),
            ),
            SizedBox(height: 12.h),
          ],
          // 내용
          Text(
            _request.description,
            style: const FigmaTextStyles().body1.copyWith(
              color: NewAppColor.neutral700,
              height: 1.5,
            ),
          ),
          if (_request.preferredDate != null) ...[
            SizedBox(height: 16.h),
            Divider(color: NewAppColor.neutral200),
            SizedBox(height: 16.h),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: '희망 날짜',
              value: _formatDate(_request.preferredDate!),
            ),
          ],
          if (_request.preferredTime != null &&
              _request.preferredTime!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.access_time_outlined,
              label: '희망 시간',
              value: _request.preferredTime!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '방문 위치',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: '주소',
            value: _request.address!,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusManagementSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '상태 관리',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          // 상태별 액션 버튼들
          if (_request.status == 'pending') ...[
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: () => _changeStatus('approved'),
                child: const Text('승인'),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: () => _changeStatus('cancelled'),
                variant: ButtonVariant.destructive,
                child: const Text('거절'),
              ),
            ),
          ],
          if (_request.status == 'approved') ...[
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: () => _changeStatus('in_progress'),
                child: const Text('진행 시작'),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: () => _changeStatus('cancelled'),
                variant: ButtonVariant.secondary,
                child: const Text('취소'),
              ),
            ),
          ],
          if (_request.status == 'in_progress') ...[
            SizedBox(
              width: double.infinity,
              child: AppButton(
                onPressed: () => _changeStatus('completed'),
                child: const Text('완료 처리'),
              ),
            ),
          ],
          if (_request.status == 'completed') ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF2E7D32),
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '완료된 심방 신청입니다',
                      style: const FigmaTextStyles().body1.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_request.status == 'cancelled') ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel,
                    color: const Color(0xFFC62828),
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      '취소된 심방 신청입니다',
                      style: const FigmaTextStyles().body1.copyWith(
                        color: const Color(0xFFC62828),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: NewAppColor.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18.sp,
                color: NewAppColor.neutral700,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const FigmaTextStyles().caption1.copyWith(
                      color: NewAppColor.neutral600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    value,
                    style: const FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: NewAppColor.neutral400,
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return '높음';
      case 'medium':
        return '보통';
      case 'low':
        return '낮음';
      default:
        return priority;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return const Color(0xFFC62828);
      case 'medium':
        return const Color(0xFFF57F17);
      case 'low':
        return const Color(0xFF2E7D32);
      default:
        return NewAppColor.neutral600;
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