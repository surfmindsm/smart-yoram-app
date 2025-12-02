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

/// 관리자용 공지사항 관리 화면
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
  bool _showImportantOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);

    try {
      // 현재 사용자의 church_id 가져오기
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
    List<Announcement> filtered = _notices;

    if (_showImportantOnly) {
      filtered = filtered.where((n) => n.isPinned).toList();
    }

    setState(() {
      _filteredNotices = filtered;
    });
  }

  void _toggleImportantFilter() {
    setState(() {
      _showImportantOnly = !_showImportantOnly;
      _applyFilters();
    });
  }

  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminNoticeEditorScreen(),
      ),
    );

    // 새 공지사항이 작성되었으면 목록 새로고침
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

    // 상세 화면에서 삭제 등의 작업이 있었으면 목록 새로고침
    if (result == true) {
      _loadNotices();
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
          icon: Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '공지사항 관리',
          style: const FigmaTextStyles().title2.copyWith(
            color: NewAppColor.neutral900,
          ),
        ),
        actions: [
          material.IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _navigateToAdd,
          ),
          material.IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadNotices,
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 섹션
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleImportantFilter,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _showImportantOnly ? NewAppColor.primary600 : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: _showImportantOnly ? NewAppColor.primary600 : NewAppColor.neutral300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16.sp,
                          color: _showImportantOnly ? Colors.white : NewAppColor.neutral700,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '중요 공지',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: _showImportantOnly ? FontWeight.w600 : FontWeight.w400,
                            color: _showImportantOnly ? Colors.white : NewAppColor.neutral700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 결과 카운트
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            color: NewAppColor.neutral100,
            child: Row(
              children: [
                Text(
                  '총 ${_filteredNotices.length}건',
                  style: const FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral700,
                  ),
                ),
              ],
            ),
          ),
          // 공지사항 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotices.isEmpty
                    ? Center(
                        child: Text(
                          '공지사항이 없습니다',
                          style: const FigmaTextStyles().body1.copyWith(
                            color: NewAppColor.neutral600,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotices,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          itemCount: _filteredNotices.length,
                          itemBuilder: (context, index) {
                            final notice = _filteredNotices[index];
                            return _buildNoticeCard(notice);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(Announcement notice) {
    return GestureDetector(
      onTap: () => _navigateToDetail(notice),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.isPinned) ...[
                  Icon(
                    Icons.star,
                    size: 16.sp,
                    color: const Color(0xFFFFA000),
                  ),
                  SizedBox(width: 4.w),
                ],
                Expanded(
                  child: Text(
                    notice.title,
                    style: const FigmaTextStyles().body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: NewAppColor.neutral900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              notice.content,
              style: const FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14.sp,
                  color: NewAppColor.neutral600,
                ),
                SizedBox(width: 4.w),
                Text(
                  _formatDate(notice.createdAt),
                  style: const FigmaTextStyles().caption1.copyWith(
                    color: NewAppColor.neutral600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}