import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/member.dart';
import '../resource/color_style.dart';
import '../resource/text_style.dart';

class MemberDetailModal extends StatelessWidget {
  final Member member;

  const MemberDetailModal({
    super.key,
    required this.member,
  });

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
          child: member.profilePhotoUrl != null &&
                  member.profilePhotoUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(40.r),
                  child: Image.network(
                    member.profilePhotoUrl!,
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
          member.name,
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
            member.position ?? '성도',
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
          member.name.isNotEmpty ? member.name[0] : '?',
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
        _buildInfoItem('전화번호', member.phone),
        if (member.email != null && member.email!.isNotEmpty)
          _buildInfoItem('이메일', member.email!),
        _buildInfoItem('성별', member.gender == 'M' ? '남성' : '여성'),
        if (member.birthdate != null)
          _buildInfoItem('생년월일', _formatDate(member.birthdate!)),
        if (member.address != null && member.address!.isNotEmpty)
          _buildInfoItem('주소', member.address!),
        if (member.district != null && member.district!.isNotEmpty)
          _buildInfoItem('구역', member.district!),
        _buildInfoItem('상태', _getMemberStatusText(member.memberStatus)),
        if (member.registrationDate != null)
          _buildInfoItem('등록일', _formatDate(member.registrationDate!)),
        if (member.memo != null && member.memo!.isNotEmpty)
          _buildInfoItem('메모', member.memo!, isMultiline: true),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value,
      {bool isMultiline = false}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
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
            width: 70.w,
            child: Text(
              label,
              style: AppTextStyle(color: AppColor.secondary04).b3(),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              value,
              style: AppTextStyle(color: AppColor.secondary07).b2(),
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
              onPressed: () => _makePhoneCall(context, member.phone),
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
              onPressed: () => _sendMessage(context, member.phone),
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
    switch (member.position?.toLowerCase()) {
      case '목사':
      case '교역자':
        return Colors.purple;
      case '장로':
        return Colors.indigo;
      case '권사':
        return Colors.pink;
      case '집사':
        return Colors.orange;
      default:
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
