import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/member.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../services/member_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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

    try {
      print('🔍 조직 정보 조회 시작 - ID: ${widget.member.organizationId}');

      // MemberService의 캐싱된 메서드 사용
      final organizationPath = await _memberService.getOrganizationPath(widget.member.organizationId!);

      if (mounted) {
        setState(() {
          _organizationName = organizationPath;
        });
        print('✅ 조직 정보 로드 성공: $_organizationName');
      }
    } catch (e) {
      print('❌ 조직 정보 로드 실패: $e');
    }
  }

  // 1.2.0 C 방향: 큰 아바타 + 직분 칩 + 라벨/값 리스트 + 전화 보조 / 메시지 주 버튼
  @override
  Widget build(BuildContext context) {
    final isPlainPosition = widget.member.positionLabel == '성도' ||
        widget.member.positionLabel == '교인' ||
        widget.member.positionLabel.isEmpty;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22.r),
      ),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 720.h),
        padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22.r),
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
                  style: FigmaTextStyles().subtitle1.copyWith(
                        color: NewAppColor.textStrong,
                      ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 34.w,
                    height: 34.h,
                    decoration: BoxDecoration(
                      color: NewAppColor.borderSoft,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.x,
                      size: 19.sp,
                      color: NewAppColor.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18.h),

            // 프로필 영역
            _buildProfileSection(isPlainPosition: isPlainPosition),
            SizedBox(height: 22.h),

            // 상세 정보
            Expanded(
              child: SingleChildScrollView(
                child: _buildInfoSection(),
              ),
            ),

            SizedBox(height: 24.h),
            // 하단 버튼
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({required bool isPlainPosition}) {
    final hasPhoto = widget.member.profilePhotoUrl != null &&
        widget.member.profilePhotoUrl!.isNotEmpty;
    return Column(
      children: [
        // 큰 원형 아바타 — skyTint 배경 + skyDeep 글자 (목업 §144)
        Container(
          width: 104.w,
          height: 104.h,
          decoration: BoxDecoration(
            color: NewAppColor.skyTint,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: hasPhoto
              ? ClipOval(
                  child: Image.network(
                    widget.member.profilePhotoUrl!,
                    width: 104.w,
                    height: 104.h,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),
        SizedBox(height: 14.h),

        // 이름 — 23/800
        Text(
          widget.member.name,
          style: FigmaTextStyles().pageTitle.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 23.sp,
              ),
        ),
        SizedBox(height: 10.h),

        // 직분 칩 — '성도'는 회색, 그 외는 skyTint
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isPlainPosition
                ? NewAppColor.borderSoft
                : NewAppColor.skyTint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.member.positionLabel.isEmpty
                ? '성도'
                : widget.member.positionLabel,
            style: FigmaTextStyles().badge.copyWith(
                  color: isPlainPosition
                      ? NewAppColor.textSecondary
                      : NewAppColor.skyDeep,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      widget.member.name.isNotEmpty ? widget.member.name[0] : '?',
      style: TextStyle(
        color: NewAppColor.skyDeep,
        fontSize: 42.sp,
        fontWeight: FontWeight.w800,
        fontFamily: 'Pretendard',
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
          _buildInfoItem(
              '생년월일',
              '${_formatDate(widget.member.birthdate!)} (${widget.member.birthdateType ?? '양력'})'),
        if (widget.member.department != null &&
            widget.member.department!.isNotEmpty)
          _buildInfoItem('부서', _getDepartmentDisplay(widget.member.department!)),
        if (_organizationName != null && _organizationName!.isNotEmpty)
          _buildInfoItem('조직', _organizationName!, isLast: true),
        if ((_organizationName == null || _organizationName!.isEmpty) &&
            widget.member.district != null &&
            widget.member.district!.isNotEmpty)
          _buildInfoItem('구역', widget.member.district!, isLast: true),
      ],
    );
  }

  // 라벨/값 행 — 라벨 88px 폭, 행 사이 1px borderSoft 구분선
  Widget _buildInfoItem(String label, String value, {bool isLast = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 13.h),
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: NewAppColor.borderSoft,
                  width: 1,
                ),
              ),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 88.w,
            child: Text(
              label,
              style: FigmaTextStyles().caption1.copyWith(
                    color: NewAppColor.textTertiary,
                    fontSize: 13.5.sp,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.textBody,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5.sp,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 전화(보조) / 메시지(주) — 단일 스카이 톤
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // 전화 — 보조 버튼 (흰배경 + 1.5px #BAE6FD 테두리 + skyDeep 텍스트)
        Expanded(
          child: InkWell(
            onTap: () => _makePhoneCall(context, widget.member.phone),
            borderRadius: BorderRadius.circular(13.r),
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: NewAppColor.primary300, width: 1.5),
                borderRadius: BorderRadius.circular(13.r),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.phone, color: NewAppColor.skyDeep, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    '전화',
                    style: FigmaTextStyles().button2.copyWith(
                          color: NewAppColor.skyDeep,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 11.w),
        // 메시지 — 주 버튼 (skyPrimary + 흰글자 + 섀도)
        Expanded(
          child: InkWell(
            onTap: () => _sendMessage(context, widget.member.phone),
            borderRadius: BorderRadius.circular(13.r),
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: NewAppColor.skyPrimary,
                borderRadius: BorderRadius.circular(13.r),
                boxShadow: [
                  BoxShadow(
                    color: NewAppColor.skyPrimary.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.messageCircle,
                      color: Colors.white, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    '메시지',
                    style: FigmaTextStyles().button2.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
