import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';

/// 프로필 정보 다이얼로그
/// 상대방의 프로필을 클릭하거나 판매자 프로필을 선택하면 표시
class ProfileInfoDialog extends StatelessWidget {
  final String name;
  final String? churchName;
  final String? location;
  final String? churchAddress;
  final String? profileImageUrl;

  const ProfileInfoDialog({
    super.key,
    required this.name,
    this.churchName,
    this.location,
    this.churchAddress,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    print('🔍 ProfileInfoDialog: name=$name, churchName=$churchName, churchAddress=$churchAddress');
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 프로필 이미지
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: NewAppColor.neutral200,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: profileImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: NewAppColor.neutral100,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: NewAppColor.primary500,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: NewAppColor.neutral100,
                          child: Icon(
                            Icons.person,
                            size: 50.w,
                            color: NewAppColor.neutral400,
                          ),
                        ),
                      )
                    : Container(
                        color: NewAppColor.neutral100,
                        child: Icon(
                          Icons.person,
                          size: 50.w,
                          color: NewAppColor.neutral400,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 20.h),

            // 이름
            Text(
              name,
              style: FigmaTextStyles().headline5.copyWith(
                    color: NewAppColor.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
            ),

            SizedBox(height: 16.h),

            // 소속 교회
            if (churchName != null && churchName!.isNotEmpty) ...[
              // 교회명 라벨
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '소속 교회',
                  style: FigmaTextStyles().caption1.copyWith(
                        color: NewAppColor.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.church,
                      size: 18.sp,
                      color: NewAppColor.neutral600,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        churchName!,
                        style: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral800,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 교회 주소
            if (churchAddress != null && churchAddress!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              // 교회 주소 라벨
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '교회 주소',
                  style: FigmaTextStyles().caption1.copyWith(
                        color: NewAppColor.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Icon(
                        Icons.location_on,
                        size: 18.sp,
                        color: NewAppColor.neutral600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        churchAddress!,
                        style: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral800,
                              height: 1.4,
                            ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 24.h),

            // 닫기 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NewAppColor.primary500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '닫기',
                  style: FigmaTextStyles().button1.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 프로필 정보 다이얼로그 표시 헬퍼 함수
  static void show(
    BuildContext context, {
    required String name,
    String? churchName,
    String? location,
    String? churchAddress,
    String? profileImageUrl,
  }) {
    showDialog(
      context: context,
      builder: (context) => ProfileInfoDialog(
        name: name,
        churchName: churchName,
        location: location,
        churchAddress: churchAddress,
        profileImageUrl: profileImageUrl,
      ),
    );
  }
}
