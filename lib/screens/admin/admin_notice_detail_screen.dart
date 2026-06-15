import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/index.dart';
import '../../models/announcement.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/announcement_service.dart';
import 'admin_notice_editor_screen.dart';

/// 관리자용 공지사항 상세 화면 — 1.2.0 C 방향
class AdminNoticeDetailScreen extends StatefulWidget {
  final Announcement announcement;

  const AdminNoticeDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<AdminNoticeDetailScreen> createState() =>
      _AdminNoticeDetailScreenState();
}

class _AdminNoticeDetailScreenState extends State<AdminNoticeDetailScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  late Announcement _announcement;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
  }

  Future<void> _performTogglePinned() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _announcementService.updateAnnouncement(
        _announcement.id,
        {'is_pinned': !_announcement.isPinned},
      );
      setState(() => _announcement = updated);
      if (mounted) {
        AppToast.success(
          context,
          updated.isPinned ? '상단 고정으로 설정했습니다' : '상단 고정을 해제했습니다',
        );
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '상태 변경 중 오류가 발생했습니다');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 1.2.0 삭제 확인 시트 (미리보기 박스 포함)
  void _confirmDelete() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 22.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 18.h),
                    decoration: BoxDecoration(
                      color: NewAppColor.borderStrong,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Container(
                    width: 54.w,
                    height: 54.w,
                    decoration: BoxDecoration(
                      color: NewAppColor.dangerBg,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.delete_outline,
                        color: NewAppColor.danger700, size: 26.sp),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '공지사항을 삭제할까요?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: NewAppColor.textStrong,
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '삭제하면 교인 화면에서도 사라지며,\n되돌릴 수 없어요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: NewAppColor.textMuted,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                      height: 1.55,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: NewAppColor.dangerBg,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: NewAppColor.danger700.withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 6.h,
                          children: [
                            _buildPreviewChip(_categoryLabel(_announcement.category)),
                            if (_announcement.isPinned) _buildPreviewChip('고정'),
                          ],
                        ),
                        SizedBox(height: 7.h),
                        Text(
                          _announcement.title,
                          style: TextStyle(
                            color: NewAppColor.textStrong,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Pretendard',
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(sheetContext),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            decoration: BoxDecoration(
                              color: NewAppColor.borderSoft,
                              borderRadius: BorderRadius.circular(13.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '취소',
                              style: TextStyle(
                                color: NewAppColor.textSecondary,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 11.w),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _performDelete();
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 15.h),
                            decoration: BoxDecoration(
                              color: NewAppColor.danger700,
                              borderRadius: BorderRadius.circular(13.r),
                              boxShadow: [
                                BoxShadow(
                                  color: NewAppColor.danger700.withOpacity(0.30),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '삭제',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _performDelete() async {
    setState(() => _isLoading = true);
    try {
      await _announcementService.deleteAnnouncement(_announcement.id);
      if (mounted) {
        AppToast.success(context, '공지를 삭제했습니다');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '삭제 중 오류가 발생했습니다');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminNoticeEditorScreen(
          announcement: _announcement,
        ),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
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
        leading: material.IconButton(
          icon: Icon(Icons.chevron_left,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '공지사항 상세',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: NewAppColor.skyPrimary),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 24.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        SizedBox(height: 12.h),
                        _buildBodyCard(),
                      ],
                    ),
                  ),
                ),
                _buildBottomActionBar(),
              ],
            ),
    );
  }

  // 헤더 카드: 칩 라인 + 제목 + 메타(작성자 · 작성일)
  Widget _buildHeaderCard() {
    final categoryLabel = _categoryLabel(_announcement.category);
    final author = (_announcement.authorName?.isNotEmpty ?? false)
        ? _announcement.authorName!
        : '관리자';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NewAppColor.borderHair, width: 1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              if (_announcement.isPinned) _buildChip('고정', _ChipTone.sky),
              _buildChip(categoryLabel, _categoryTone(_announcement.category)),
              _buildChip(
                _announcement.isActive ? '게시중' : '숨김',
                _announcement.isActive ? _ChipTone.success : _ChipTone.neutral,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _announcement.title,
            style: TextStyle(
              color: NewAppColor.textStrong,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
              height: 1.4,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '$author · ${_formatDate(_announcement.createdAt)}',
            style: TextStyle(
              color: NewAppColor.textTertiary,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }

  // 본문 카드
  Widget _buildBodyCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NewAppColor.borderHair, width: 1),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내용',
            style: TextStyle(
              color: NewAppColor.textTertiary,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            _announcement.content,
            style: TextStyle(
              color: NewAppColor.textBody,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  // 하단 액션 바: 고정 토글(보조) + 수정(주) + 삭제(아이콘 위험)
  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
      decoration: BoxDecoration(
        color: NewAppColor.canvasAlt,
        border: Border(
          top: BorderSide(color: NewAppColor.borderHair, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildIconAction(
              icon: _announcement.isPinned
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              tone: _announcement.isPinned
                  ? _IconActionTone.sky
                  : _IconActionTone.neutral,
              onTap: _performTogglePinned,
            ),
            SizedBox(width: 9.w),
            _buildIconAction(
              icon: Icons.delete_outline,
              tone: _IconActionTone.danger,
              onTap: _confirmDelete,
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: GestureDetector(
                onTap: _navigateToEdit,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    color: NewAppColor.skyPrimary,
                    borderRadius: BorderRadius.circular(13.r),
                    boxShadow: [
                      BoxShadow(
                        color: NewAppColor.skyPrimary.withOpacity(0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined,
                          color: Colors.white, size: 16.sp),
                      SizedBox(width: 7.w),
                      Text(
                        '수정',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconAction({
    required IconData icon,
    required _IconActionTone tone,
    required VoidCallback onTap,
  }) {
    final ({Color bg, Color fg}) c;
    switch (tone) {
      case _IconActionTone.sky:
        c = (bg: NewAppColor.skyTint, fg: NewAppColor.skyDeep);
        break;
      case _IconActionTone.danger:
        c = (bg: NewAppColor.dangerBg, fg: NewAppColor.danger700);
        break;
      case _IconActionTone.neutral:
        c = (bg: NewAppColor.borderSoft, fg: NewAppColor.textSecondary);
        break;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(13.r),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: c.fg, size: 19.sp),
      ),
    );
  }

  Widget _buildChip(String label, _ChipTone tone) {
    final ({Color bg, Color fg}) c;
    switch (tone) {
      case _ChipTone.sky:
        c = (bg: NewAppColor.skyTint, fg: NewAppColor.skyDeep);
        break;
      case _ChipTone.success:
        c = (bg: NewAppColor.successBg, fg: NewAppColor.success700);
        break;
      case _ChipTone.warning:
        c = (bg: NewAppColor.warningBg, fg: NewAppColor.warning700);
        break;
      case _ChipTone.neutral:
        c = (bg: NewAppColor.borderSoft, fg: NewAppColor.textSecondary);
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.fg,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildPreviewChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: NewAppColor.danger700.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: NewAppColor.danger700,
          fontSize: 10.5.sp,
          fontWeight: FontWeight.w800,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'worship':
        return '예배';
      case 'member_news':
        return '교우';
      case 'event':
        return '행사';
      default:
        return '일반';
    }
  }

  _ChipTone _categoryTone(String category) {
    switch (category) {
      case 'worship':
        return _ChipTone.sky;
      case 'event':
        return _ChipTone.warning;
      case 'member_news':
        return _ChipTone.sky;
      default:
        return _ChipTone.neutral;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일 '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

enum _ChipTone { sky, success, warning, neutral }

enum _IconActionTone { sky, danger, neutral }
