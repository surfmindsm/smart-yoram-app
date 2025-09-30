import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/index.dart';
import '../../components/admin/status_badge.dart';
import '../../models/member.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/member_service.dart';

/// 관리자용 교인 상세 화면
class AdminMemberDetailScreen extends StatefulWidget {
  final Member member;

  const AdminMemberDetailScreen({
    super.key,
    required this.member,
  });

  @override
  State<AdminMemberDetailScreen> createState() =>
      _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState extends State<AdminMemberDetailScreen> {
  final MemberService _memberService = MemberService();
  late Member _member;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = _member.phone;
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

  Future<void> _sendEmail() async {
    final email = _member.email;
    if (email == null || email.isEmpty) return;

    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppToast.show(
          context,
          '이메일 앱을 열 수 없습니다',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _toggleMemberStatus() async {
    final newStatus = _member.memberStatus == 'active' ? 'inactive' : 'active';

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '상태 변경',
        content: Text(
            '${_member.name}님의 상태를 ${newStatus == 'active' ? '활성' : '비활성'}으로 변경하시겠습니까?'),
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
      final response = await _memberService.updateMemberStatus(
        memberId: _member.id,
        status: newStatus,
      );

      if (response.success && response.data != null) {
        setState(() {
          _member = response.data!;
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

  Future<void> _deleteMember() async {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '교인 삭제',
        content: Text('${_member.name}님의 정보를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete();
            },
            variant: ButtonVariant.destructive,
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    setState(() => _isLoading = true);

    try {
      final response = await _memberService.deleteMember(_member.id);

      if (response.success) {
        if (mounted) {
          AppToast.show(
            context,
            '교인이 삭제되었습니다',
            type: ToastType.success,
          );
          Navigator.pop(context); // 목록으로 돌아가기
        }
      } else {
        if (mounted) {
          AppToast.show(
            context,
            response.message.isNotEmpty
                ? response.message
                : '교인 삭제에 실패했습니다',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '교인 삭제 중 오류가 발생했습니다: $e',
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
          '교인 상세',
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
                  // 프로필 섹션
                  _buildProfileSection(),
                  SizedBox(height: 16.h),
                  // 기본 정보 섹션
                  _buildInfoSection(),
                  SizedBox(height: 16.h),
                  // 관리 액션 섹션
                  _buildActionSection(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      color: Colors.white,
      child: Column(
        children: [
          // 프로필 사진
          _buildProfileImage(),
          SizedBox(height: 16.h),
          // 이름
          Text(
            _member.name,
            style: const FigmaTextStyles().title1.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 8.h),
          // 상태 뱃지
          StatusBadge(
            status: _member.memberStatus == 'active' ? 'active' : 'inactive',
            label: _member.memberStatus == 'active' ? '활성' : '비활성',
          ),
          if (_member.district != null && _member.district!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              _member.district!,
              style: const FigmaTextStyles().body2.copyWith(
                color: NewAppColor.primary600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_member.profilePhotoUrl != null &&
        _member.profilePhotoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100.r),
        child: Image.network(
          _member.profilePhotoUrl!,
          width: 80.w,
          height: 80.h,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80.w,
      height: 80.h,
      decoration: BoxDecoration(
        color: NewAppColor.primary200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _member.name.isNotEmpty ? _member.name[0] : '?',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.w600,
            color: NewAppColor.primary600,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 정보',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: '전화번호',
            value: _member.phone,
            onTap: _member.phone.isNotEmpty ? _makePhoneCall : null,
          ),
          if (_member.email != null && _member.email!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: '이메일',
              value: _member.email!,
              onTap: _sendEmail,
            ),
          ],
          if (_member.address != null && _member.address!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: '주소',
              value: _member.address!,
            ),
          ],
          if (_member.position != null && _member.position!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.work_outline,
              label: '직분',
              value: _member.position!,
            ),
          ],
          if (_member.birthdate != null) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.cake_outlined,
              label: '생년월일',
              value:
                  '${_member.birthdate!.year}.${_member.birthdate!.month.toString().padLeft(2, '0')}.${_member.birthdate!.day.toString().padLeft(2, '0')}',
            ),
          ],
          SizedBox(height: 12.h),
          _buildInfoRow(
            icon: Icons.person_outline,
            label: '성별',
            value: _member.gender == 'M' ? '남성' : '여성',
          ),
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

  Widget _buildActionSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '관리 작업',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: _toggleMemberStatus,
              variant: ButtonVariant.secondary,
              child: Text(
                _member.memberStatus == 'active' ? '비활성화' : '활성화',
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: _deleteMember,
              variant: ButtonVariant.destructive,
              child: const Text('교인 삭제'),
            ),
          ),
        ],
      ),
    );
  }
}