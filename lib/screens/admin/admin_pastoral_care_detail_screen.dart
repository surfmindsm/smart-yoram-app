import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/index.dart';
import '../../components/admin/status_badge.dart';
import '../../models/pastoral_care_request.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/pastoral_care_service.dart';

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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: material.IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
}