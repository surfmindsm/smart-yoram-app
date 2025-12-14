import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/member.dart';
import '../resource/color_style.dart';
import '../resource/text_style.dart';
import '../services/member_service.dart';

class MemberDetailModal extends StatefulWidget {
  final Member member;

  const MemberDetailModal({
    super.key,
    required this.member,
  });

  @override
  State<MemberDetailModal> createState() => _MemberDetailModalState();
}

class _MemberDetailModalState extends State<MemberDetailModal> {
  final MemberService _memberService = MemberService();
  String? _organizationName;
  bool _isLoadingOrganization = false;

  @override
  void initState() {
    super.initState();
    print('🔍 Member 정보:');
    print('  - ID: ${widget.member.id}');
    print('  - 이름: ${widget.member.name}');
    print('  - organization_id: ${widget.member.organizationId}');
    print('  - department: ${widget.member.department}');
    _loadOrganizationName();
  }

  Future<void> _loadOrganizationName() async {
    if (widget.member.organizationId == null || widget.member.organizationId!.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingOrganization = true;
    });

    try {
      print('🔍 조직 정보 조회 시작 - ID: ${widget.member.organizationId}');

      // MemberService의 캐싱된 메서드 사용
      final organizationPath = await _memberService.getOrganizationPath(widget.member.organizationId!);

      if (mounted) {
        setState(() {
          _organizationName = organizationPath;
          _isLoadingOrganization = false;
        });
        print('✅ 조직 정보 로드 성공: $_organizationName');
      }
    } catch (e) {
      print('❌ 조직 정보 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoadingOrganization = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 800.h),
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '교인 정보',
                  style:
                      AppTextStyle(color: AppColor.secondary07).h2().copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                      color: AppColor.secondary03.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20.sp,
                      color: AppColor.secondary04,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 프로필 영역
            _buildProfileSection(),
            SizedBox(height: 24.h),

            // 상세 정보
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildInfoSection(),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // 프로필 이미지
        Container(
          width: 80.w,
          height: 80.h,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(40.r),
          ),
          child: widget.member.profilePhotoUrl != null &&
                  widget.member.profilePhotoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(40.r),
                  child: Image.network(
                    widget.member.profilePhotoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),
        SizedBox(height: 12.h),

        // 이름
        Text(
          widget.member.name,
          style: AppTextStyle(color: AppColor.secondary07).h1().copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        SizedBox(height: 4.h),

        // 직분
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _getPositionColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            widget.member.positionLabel,
            style: AppTextStyle(color: _getPositionColor()).b3().copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80.w,
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(40.r),
      ),
      child: Center(
        child: Text(
          widget.member.name.isNotEmpty ? widget.member.name[0] : '?',
          style: AppTextStyle(color: Colors.white).h1().copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildInfoItem('전화번호', widget.member.phone),
        if (widget.member.email != null && widget.member.email!.isNotEmpty)
          _buildInfoItem('이메일', widget.member.email!),
        _buildInfoItem('성별', _getGenderDisplay(widget.member.gender)),
        if (widget.member.birthdate != null)
          _buildInfoItem('생년월일', _formatDate(widget.member.birthdate!)),
        if (widget.member.address != null && widget.member.address!.isNotEmpty)
          _buildInfoItem('주소', widget.member.address!),
        if (widget.member.department != null && widget.member.department!.isNotEmpty)
          _buildInfoItem('부서', _getDepartmentDisplay(widget.member.department!)),
        // 조직 정보는 organizationId가 있고, 조직명을 성공적으로 로드한 경우에만 표시
        if (_organizationName != null && _organizationName!.isNotEmpty)
          _buildInfoItem('조직', _organizationName!),
        if (widget.member.district != null && widget.member.district!.isNotEmpty)
          _buildInfoItem('구역', widget.member.district!),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value,
      {bool isMultiline = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColor.secondary02,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            child: Text(
              label,
              style: AppTextStyle(color: AppColor.secondary04).b4().copyWith(
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle(color: AppColor.secondary07).b3().copyWith(
                fontSize: 13.sp,
              ),
              maxLines: isMultiline ? null : 1,
              overflow: isMultiline ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: () => _makePhoneCall(context, widget.member.phone),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(
                Icons.phone,
                color: Colors.green,
                size: 20.sp,
              ),
              label: Text(
                '전화',
                style: AppTextStyle(color: Colors.green).b2().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: () => _sendMessage(context, widget.member.phone),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(
                Icons.chat,
                color: Colors.white,
                size: 20.sp,
              ),
              label: Text(
                '메시지',
                style: AppTextStyle(color: Colors.white).b2().copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getPositionColor() {
    final positionLabel = widget.member.positionLabel.toLowerCase();

    // 교역자 계열
    if (positionLabel.contains('목사') || positionLabel.contains('전도사') || positionLabel == '교역자') {
      return Colors.purple;
    }
    // 장로 계열
    else if (positionLabel.contains('장로')) {
      return Colors.indigo;
    }
    // 권사 계열
    else if (positionLabel.contains('권사')) {
      return Colors.pink;
    }
    // 집사 계열
    else if (positionLabel.contains('집사')) {
      return Colors.orange;
    }
    // 기타 (교사, 학생, 성도)
    else {
      return Colors.blue;
    }
  }

  String _getMemberStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return '활동중';
      case 'inactive':
        return '비활동';
      case 'transferred':
        return '전출';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getGenderDisplay(String gender) {
    switch (gender.toLowerCase()) {
      case '남':
      case 'male':
      case 'm':
        return '남성';
      case '여':
      case 'female':
      case 'f':
        return '여성';
      default:
        return gender; // 원본 값 반환
    }
  }

  String _getDepartmentDisplay(String department) {
    const departmentMap = {
      'WORSHIP': '예배부',
      'EDUCATION': '교육부',
      'MISSION': '선교부',
      'YOUTH': '청년부',
      'CHILDREN': '아동부',
    };
    return departmentMap[department.toUpperCase()] ?? department;
  }

  Future<void> _makePhoneCall(BuildContext context, String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      // 전화번호에서 하이픈, 공백 등 제거
      String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

      if (cleanedPhone.isEmpty) {
        _showSnackBar(context, '유효하지 않은 전화번호입니다');
        return;
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedPhone);

      try {
        // 먼저 일반적인 방법 시도
        bool canLaunch = await canLaunchUrl(phoneUri);

        if (canLaunch) {
          await launchUrl(phoneUri);
        } else {
          // canLaunchUrl이 false라도 LaunchMode.externalApplication으로 시도
          await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        _showSnackBar(context, '전화 앱을 열 수 없습니다');
      }
    } else {
      _showSnackBar(context, '전화번호가 없습니다');
    }
  }

  Future<void> _sendMessage(BuildContext context, String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      // 전화번호에서 하이픈, 공백 등 제거
      String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

      if (cleanedPhone.isEmpty) {
        _showSnackBar(context, '유효하지 않은 전화번호입니다');
        return;
      }

      final Uri smsUri = Uri(scheme: 'sms', path: cleanedPhone);

      try {
        // 먼저 일반적인 방법 시도
        bool canLaunch = await canLaunchUrl(smsUri);

        if (canLaunch) {
          await launchUrl(smsUri);
        } else {
          // canLaunchUrl이 false라도 LaunchMode.externalApplication으로 시도
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        _showSnackBar(context, '메시지 앱을 열 수 없습니다');
      }
    } else {
      _showSnackBar(context, '전화번호가 없습니다');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
