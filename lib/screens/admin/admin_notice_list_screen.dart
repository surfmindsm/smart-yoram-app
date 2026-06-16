import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/index.dart';
import '../../models/announcement.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';
import 'admin_notice_detail_screen.dart';
import 'admin_notice_editor_screen.dart';

/// 관리자용 공지사항 관리 화면 — 1.2.0 C 방향
///
/// 시안: 카드 사이 8px 회색 구분선 + 카테고리·고정·상태 칩 + 수정/삭제 액션 + 우하단 FAB
class AdminNoticeListScreen extends StatefulWidget {
  const AdminNoticeListScreen({super.key});

  @override
  State<AdminNoticeListScreen> createState() => _AdminNoticeListScreenState();
}

class _AdminNoticeListScreenState extends State<AdminNoticeListScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final AuthService _authService = AuthService();

  List<Announcement> _notices = [];
  List<Announcement> _filteredNotices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);

    try {
      final currentUserResponse = await _authService.getCurrentUser();
      if (!currentUserResponse.success || currentUserResponse.data == null) {
        throw Exception('사용자 정보를 가져올 수 없습니다');
      }

      final churchId = currentUserResponse.data!.churchId;

      final notices = await _announcementService.getAnnouncements(
        churchId: churchId,
      );

      setState(() {
        _notices = notices;
        _applyFilters();
      });
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '공지사항 조회 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    // 고정 우선 + 최신 정렬
    final sorted = List<Announcement>.from(_notices);
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    setState(() {
      _filteredNotices = sorted;
    });
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminNoticeEditorScreen(),
      ),
    );

    if (result == true) {
      _loadNotices();
    }
  }

  void _navigateToDetail(Announcement notice) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminNoticeDetailScreen(announcement: notice),
      ),
    );

    if (result == true) {
      _loadNotices();
    }
  }

  void _navigateToEdit(Announcement notice) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdminNoticeEditorScreen(announcement: notice),
      ),
    );
    if (result == true) {
      _loadNotices();
    }
  }

  // 공지 삭제 확인 — AppConfirmSheet 헬퍼 사용
  Future<void> _confirmDelete(Announcement notice) async {
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '공지사항을 삭제할까요?',
      description: '삭제하면 교인 화면에서도 사라지며,\n되돌릴 수 없어요.',
      confirmLabel: '삭제',
      tone: AppSheetTone.danger,
      preview: _buildDeletePreview(notice),
    );
    if (ok == true) await _performDelete(notice);
  }

  Widget _buildDeletePreview(Announcement notice) {
    return Container(
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
              _buildPreviewChip(_categoryLabel(notice.category)),
              if (notice.isPinned) _buildPreviewChip('고정'),
            ],
          ),
          SizedBox(height: 7.h),
          Text(
            notice.title,
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
    );
  }

  Future<void> _performDelete(Announcement notice) async {
    try {
      final ok = await _announcementService.deleteAnnouncement(notice.id);
      if (!mounted) return;
      if (ok) {
        AppToast.success(context, '공지를 삭제했습니다');
        _loadNotices();
      } else {
        AppToast.error(context, '삭제에 실패했습니다');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '삭제 중 오류가 발생했습니다');
      }
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
        centerTitle: false,
        titleSpacing: 0,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '공지사항 관리',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      floatingActionButton: _buildFab(),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: NewAppColor.skyPrimary),
            )
          : _filteredNotices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.megaphone,
                          size: 56.sp, color: NewAppColor.iconFaint),
                      SizedBox(height: 14.h),
                      Text(
                        '등록된 공지사항이 없습니다',
                        style: FigmaTextStyles().subtitle2.copyWith(
                              color: NewAppColor.textSecondary,
                            ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotices,
                  color: NewAppColor.skyPrimary,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredNotices.length,
                    separatorBuilder: (_, __) => Container(
                      height: 8,
                      color: NewAppColor.borderSoft,
                    ),
                    itemBuilder: (context, index) {
                      return _buildNoticeCard(_filteredNotices[index]);
                    },
                  ),
                ),
    );
  }

  // 시안: 공지 카드 — 칩 라인 + 제목 + 메타 + 수정/삭제 2분할
  Widget _buildNoticeCard(Announcement notice) {
    final categoryLabel = _categoryLabel(notice.category);
    final author = (notice.authorName?.isNotEmpty ?? false)
        ? notice.authorName!
        : '관리자';
    final meta = '$author · ${_formatDate(notice.createdAt)}';

    return InkWell(
      onTap: () => _navigateToDetail(notice),
      child: Container(
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 16.h),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 칩 라인 (고정 + 카테고리 + 상태)
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                if (notice.isPinned) _buildChip('고정', _ChipTone.sky),
                _buildChip(categoryLabel, _categoryTone(notice.category)),
                _buildChip(
                  notice.isActive ? '게시중' : '숨김',
                  notice.isActive ? _ChipTone.success : _ChipTone.neutral,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            // 제목
            Text(
              notice.title,
              style: TextStyle(
                color: NewAppColor.textStrong,
                fontSize: 15.5.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6.h),
            // 메타
            Text(
              meta,
              style: TextStyle(
                color: NewAppColor.textTertiary,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 14.h),
            // 수정 / 삭제 2분할
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: LucideIcons.pencil,
                    label: '수정',
                    background: NewAppColor.borderSoft,
                    foreground: NewAppColor.textSecondary,
                    onTap: () => _navigateToEdit(notice),
                  ),
                ),
                SizedBox(width: 9.w),
                Expanded(
                  child: _buildActionButton(
                    icon: LucideIcons.trash2,
                    label: '삭제',
                    background: NewAppColor.dangerBg,
                    foreground: NewAppColor.danger700,
                    onTap: () => _confirmDelete(notice),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 시안: 우하단 플로팅 "+ 공지 작성" 버튼
  Widget _buildFab() {
    return GestureDetector(
      onTap: _navigateToAdd,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: NewAppColor.skyPrimary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: NewAppColor.skyPrimary.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, color: Colors.white, size: 18.sp),
            SizedBox(width: 6.w),
            Text(
              '공지 작성',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(11.r),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.sp, color: foreground),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 삭제 시트 미리보기 칩 (흰 배경 + danger 보더/텍스트)
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

  // 톤별 칩
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

  // 시안 메타: "6월 12일"
  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일';
  }
}

enum _ChipTone { sky, success, warning, neutral }
