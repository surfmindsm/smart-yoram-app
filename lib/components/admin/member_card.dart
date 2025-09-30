import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/member.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import 'status_badge.dart';

/// 관리자용 교인 카드 컴포넌트
class MemberCard extends StatelessWidget {
  final Member member;
  final VoidCallback? onTap;

  const MemberCard({
    super.key,
    required this.member,
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
        child: Row(
          children: [
            // 프로필 사진
            _buildProfileImage(),
            SizedBox(width: 12.w),
            // 교인 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: const FigmaTextStyles().body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: NewAppColor.neutral900,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      StatusBadge(
                        status: member.memberStatus == 'active' ? 'active' : 'inactive',
                        label: member.memberStatus == 'active' ? '활성' : '비활성',
                      ),
                    ],
                  ),
                  if (member.phone.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14.sp,
                          color: NewAppColor.neutral600,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          member.phone,
                          style: const FigmaTextStyles().caption1.copyWith(
                            color: NewAppColor.neutral600,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (member.email != null && member.email!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14.sp,
                          color: NewAppColor.neutral600,
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Text(
                            member.email!,
                            style: const FigmaTextStyles().caption1.copyWith(
                              color: NewAppColor.neutral600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (member.district != null && member.district!.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      member.district!,
                      style: const FigmaTextStyles().caption2.copyWith(
                        color: NewAppColor.primary600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 화살표 아이콘
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

  Widget _buildProfileImage() {
    if (member.profilePhotoUrl != null && member.profilePhotoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100.r),
        child: Image.network(
          member.profilePhotoUrl!,
          width: 48.w,
          height: 48.h,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 48.w,
      height: 48.h,
      decoration: BoxDecoration(
        color: NewAppColor.primary200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          member.name.isNotEmpty ? member.name[0] : '?',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: NewAppColor.primary600,
          ),
        ),
      ),
    );
  }
}