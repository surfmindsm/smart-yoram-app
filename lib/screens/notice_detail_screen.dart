import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/announcement.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../utils/announcement_categories.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({
    Key? key,
    required this.announcement,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyContent(BuildContext context) {
    final text = '''
${announcement.title}

${announcement.content}

작성일: ${_formatDate(announcement.createdAt)}
작성자: ${announcement.authorName ?? '관리자'}
    ''';

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('내용이 복사되었습니다'),
        duration: Duration(seconds: 2),
        backgroundColor: NewAppColor.success600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '교회 소식',
          style: FigmaTextStyles().headline4.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
        actions: [
          // 내용 복사 버튼
          IconButton(
            icon: Icon(Icons.content_copy, color: NewAppColor.neutral700),
            onPressed: () => _copyContent(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메인 컨텐츠 카드
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 태그들
                  Row(
                    children: [
                      // 고정 공지 배지
                      if (announcement.isPinned)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: NewAppColor.danger100,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.push_pin,
                                size: 12.sp,
                                color: NewAppColor.danger600,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '고정',
                                style: TextStyle(
                                  color: NewAppColor.danger600,
                                  fontSize: 11.sp,
                                  fontFamily: 'Pretendard Variable',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (announcement.isPinned) SizedBox(width: 6.w),

                      // 카테고리 배지
                      _buildCategoryTag(
                        AnnouncementCategories.getCategoryLabel(
                          announcement.category,
                        ),
                      ),

                      // 서브카테고리 배지
                      if (announcement.subcategory != null &&
                          announcement.subcategory!.isNotEmpty) ...[
                        SizedBox(width: 6.w),
                        _buildSubcategoryTag(
                          AnnouncementCategories.getSubcategoryLabel(
                            announcement.category,
                            announcement.subcategory,
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // 제목
                  Text(
                    announcement.title,
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 22.sp,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.5,
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // 작성자 & 날짜 정보
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: NewAppColor.neutral200,
                          width: 1,
                        ),
                        bottom: BorderSide(
                          color: NewAppColor.neutral200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 작성자 정보
                        Icon(
                          Icons.person_outline,
                          size: 16.sp,
                          color: NewAppColor.neutral500,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          announcement.authorName ?? '관리자',
                          style: TextStyle(
                            color: NewAppColor.neutral700,
                            fontSize: 13.sp,
                            fontFamily: 'Pretendard Variable',
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(width: 16.w),

                        // 구분선
                        Container(
                          width: 1,
                          height: 12.h,
                          color: NewAppColor.neutral300,
                        ),

                        SizedBox(width: 16.w),

                        // 작성일
                        Icon(
                          Icons.access_time,
                          size: 16.sp,
                          color: NewAppColor.neutral500,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _formatDate(announcement.createdAt),
                          style: TextStyle(
                            color: NewAppColor.neutral700,
                            fontSize: 13.sp,
                            fontFamily: 'Pretendard Variable',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // 내용
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 200.h, // 최소 높이 설정
                    ),
                    child: Text(
                      announcement.content,
                      style: TextStyle(
                        color: NewAppColor.neutral800,
                        fontSize: 15.sp,
                        fontFamily: 'Pretendard Variable',
                        fontWeight: FontWeight.w400,
                        height: 1.6,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: NewAppColor.primary600,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.sp,
          fontFamily: 'Pretendard Variable',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSubcategoryTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: NewAppColor.neutral200,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: NewAppColor.neutral700,
          fontSize: 11.sp,
          fontFamily: 'Pretendard Variable',
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
