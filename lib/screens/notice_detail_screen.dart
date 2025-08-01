import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/announcement.dart';
import '../resource/color_style.dart';
import '../resource/text_style.dart';
import '../widget/widgets.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({
    Key? key,
    required this.announcement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '공지사항',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 고정 여부 표시
            if (announcement.isPinned)
              Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4.r),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.push_pin,
                      size: 16.sp,
                      color: Colors.red,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '고정 공지',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // 제목
            Text(
              announcement.title,
              style: AppTextStyle(
                color: AppColor.secondary07,
              ).h2(),
            ),

            SizedBox(height: 12.h),

            // 작성일
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColor.secondary02,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16.sp,
                    color: AppColor.secondary04,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    announcement.formattedDate,
                    style: AppTextStyle(
                      color: AppColor.secondary04,
                    ).b3(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 내용
            Text(
              announcement.content,
              style: AppTextStyle(
                color: AppColor.secondary06,
              ).b2(),
              textAlign: TextAlign.left,
            ),

            SizedBox(height: 32.h),

            // 목록으로 돌아가기 버튼
            SizedBox(
              width: double.infinity,
              child: CommonButton(
                text: '목록으로 돌아가기',
                type: ButtonType.primary,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
