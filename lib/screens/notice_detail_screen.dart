import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/announcement.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../utils/announcement_categories.dart';

// 1.2.0 C 방향: 공지 상세 — 흰 탑바 + 흰 카드(라운드 18) + 칩/제목/메타/본문
class AnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({
    Key? key,
    required this.announcement,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _copyContent(BuildContext context) {
    final text = '''
${announcement.title}

${announcement.content}

작성일: ${_formatDate(announcement.createdAt)}
작성자: ${announcement.authorName ?? '관리자'}
    ''';

    Clipboard.setData(ClipboardData(text: text));
    _showAppToast(context, '내용이 복사되었습니다');
  }

  // 1.2.0 floating 다크 토스트 (home_screen의 _showAppToast와 동일 사양)
  void _showAppToast(BuildContext context, String message,
      {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 16.h),
        duration: Duration(milliseconds: isError ? 2800 : 2000),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: NewAppColor.textStrong,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF020817).withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError
                    ? NewAppColor.danger300
                    : NewAppColor.success300,
                size: 18.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  message,
                  style: FigmaTextStyles().body3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: NewAppColor.textStrong, size: 23.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '교회소식',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.content_copy_outlined,
                color: NewAppColor.textMuted, size: 21.sp),
            onPressed: () => _copyContent(context),
          ),
        ],
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 28.h),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 360.h),
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: NewAppColor.borderHair, width: 1),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 태그들
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    if (announcement.isPinned) _buildPinnedTag(),
                    _buildCategoryTag(
                      AnnouncementCategories.getCategoryLabel(
                        announcement.category,
                      ),
                    ),
                    if (announcement.subcategory != null &&
                        announcement.subcategory!.isNotEmpty)
                      _buildSubcategoryTag(
                        AnnouncementCategories.getSubcategoryLabel(
                          announcement.category,
                          announcement.subcategory,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 14.h),
                // 제목 — 21/800
                Text(
                  announcement.title,
                  style: FigmaTextStyles().pageTitle.copyWith(
                        color: NewAppColor.textStrong,
                        fontSize: 21.sp,
                        height: 1.35,
                      ),
                ),
                SizedBox(height: 16.h),
                Container(height: 1, color: NewAppColor.borderSoft),
                SizedBox(height: 12.h),
                // 메타: 작성자 · 작성일
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 15.sp, color: NewAppColor.textTertiary),
                    SizedBox(width: 5.w),
                    Text(
                      announcement.authorName ?? '관리자',
                      style: FigmaTextStyles().caption2.copyWith(
                            color: NewAppColor.textTertiary,
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      width: 1,
                      height: 11.h,
                      color: NewAppColor.borderStrong,
                    ),
                    SizedBox(width: 12.w),
                    Icon(Icons.access_time,
                        size: 15.sp, color: NewAppColor.textTertiary),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        _formatDate(announcement.createdAt),
                        style: FigmaTextStyles().caption2.copyWith(
                              color: NewAppColor.textTertiary,
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(height: 1, color: NewAppColor.borderSoft),
                SizedBox(height: 16.h),
                // 본문
                Text(
                  announcement.content,
                  style: FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral700,
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.7,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 1.2.0: 고정 배지 — danger 톤
  Widget _buildPinnedTag() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: NewAppColor.dangerBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.push_pin,
              size: 11.sp, color: NewAppColor.danger700),
          SizedBox(width: 4.w),
          Text(
            '고정',
            style: FigmaTextStyles().badgeSm.copyWith(
                  color: NewAppColor.danger700,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  // 1.2.0: 카테고리 칩 — skyTint + skyDeep + 라운드 999
  Widget _buildCategoryTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: NewAppColor.skyTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: FigmaTextStyles().badge.copyWith(
              color: NewAppColor.skyDeep,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  // 1.2.0: 보조 태그 — 회색 톤
  Widget _buildSubcategoryTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: NewAppColor.borderSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: FigmaTextStyles().badge.copyWith(
              color: NewAppColor.textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
