import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/index.dart';
import '../../models/announcement.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/announcement_service.dart';
import 'admin_notice_editor_screen.dart';

/// 관리자용 공지사항 상세 화면
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

  Future<void> _togglePinStatus() async {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '중요 공지 상태 변경',
        content: Text(_announcement.isPinned
            ? '중요 공지를 해제하시겠습니까?'
            : '중요 공지로 설정하시겠습니까?'),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performTogglePinned();
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  Future<void> _performTogglePinned() async {
    setState(() => _isLoading = true);

    try {
      final updatedAnnouncement = await _announcementService.updateAnnouncement(
        _announcement.id,
        {
          'is_pinned': !_announcement.isPinned,
        },
      );

      setState(() {
        _announcement = updatedAnnouncement;
      });

      if (mounted) {
        AppToast.show(
          context,
          '중요 공지 상태가 변경되었습니다',
          type: ToastType.success,
        );
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

  Future<void> _deleteAnnouncement() async {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '공지사항 삭제',
        content: const Text('이 공지사항을 삭제하시겠습니까?\n삭제된 공지사항은 복구할 수 없습니다.'),
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
      await _announcementService.deleteAnnouncement(_announcement.id);

      if (mounted) {
        AppToast.show(
          context,
          '공지사항이 삭제되었습니다',
          type: ToastType.success,
        );
        Navigator.pop(context, true); // true를 반환하여 목록 새로고침
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '삭제 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
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

    // 수정이 있었으면 공지사항 다시 로드
    if (result == true) {
      if (mounted) {
        // 상세 화면에서는 수정된 공지사항을 다시 로드할 방법이 없으므로
        // 목록 화면으로 돌아가서 새로고침하도록 함
        Navigator.pop(context, true);
      }
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
          '공지사항 상세',
          style: const FigmaTextStyles().title2.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
        actions: [
          material.IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: _navigateToEdit,
          ),
          material.IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteAnnouncement,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 및 상태 섹션
                  _buildHeaderSection(),
                  SizedBox(height: 16.h),
                  // 내용 섹션
                  _buildContentSection(),
                  SizedBox(height: 16.h),
                  // 작성자 및 날짜 섹션
                  _buildMetaSection(),
                  SizedBox(height: 16.h),
                  // 액션 버튼 섹션
                  _buildActionSection(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_announcement.isPinned) ...[
                Icon(
                  Icons.star,
                  size: 20.sp,
                  color: const Color(0xFFFFA000),
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text(
                  _announcement.title,
                  style: const FigmaTextStyles().title2.copyWith(
                        color: NewAppColor.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (_announcement.isPinned) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '중요 공지',
                style: const FigmaTextStyles().body2.copyWith(
                      color: const Color(0xFFFFA000),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내용',
            style: const FigmaTextStyles().title3.copyWith(
                  color: NewAppColor.neutral900,
                ),
          ),
          SizedBox(height: 16.h),
          Text(
            _announcement.content,
            style: const FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.neutral700,
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.person_outline,
            label: '작성자',
            value: _announcement.authorName ?? '관리자',
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: '작성일',
            value: _formatDate(_announcement.createdAt),
          ),
        ],
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
            '관리',
            style: const FigmaTextStyles().title3.copyWith(
                  color: NewAppColor.neutral900,
                ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: _togglePinStatus,
              variant: _announcement.isPinned
                  ? ButtonVariant.secondary
                  : ButtonVariant.primary,
              child: Text(_announcement.isPinned ? '중요 공지 해제' : '중요 공지로 설정'),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: _deleteAnnouncement,
              variant: ButtonVariant.destructive,
              child: const Text('공지사항 삭제'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
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
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}