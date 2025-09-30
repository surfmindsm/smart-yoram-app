import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/index.dart';
import '../../models/announcement.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';

/// 관리자용 공지사항 작성/수정 화면
class AdminNoticeEditorScreen extends StatefulWidget {
  final Announcement? announcement; // null이면 새 공지사항, 값이 있으면 수정

  const AdminNoticeEditorScreen({
    super.key,
    this.announcement,
  });

  @override
  State<AdminNoticeEditorScreen> createState() =>
      _AdminNoticeEditorScreenState();
}

class _AdminNoticeEditorScreenState extends State<AdminNoticeEditorScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isPinned = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.announcement?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.announcement?.content ?? '',
    );
    _isPinned = widget.announcement?.isPinned ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get isEditMode => widget.announcement != null;

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUserResponse = await _authService.getCurrentUser();
      if (!currentUserResponse.success || currentUserResponse.data == null) {
        if (mounted) {
          AppToast.show(
            context,
            '사용자 정보를 가져올 수 없습니다',
            type: ToastType.error,
          );
        }
        return;
      }

      if (isEditMode) {
        // 수정 모드
        await _announcementService.updateAnnouncement(
          widget.announcement!.id,
          {
            'title': _titleController.text.trim(),
            'content': _contentController.text.trim(),
            'is_pinned': _isPinned,
          },
        );

        if (mounted) {
          AppToast.show(
            context,
            '공지사항이 수정되었습니다',
            type: ToastType.success,
          );
          Navigator.pop(context, true);
        }
      } else {
        // 새 공지사항 작성
        await _announcementService.createAnnouncement({
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'is_pinned': _isPinned,
          'author_id': currentUserResponse.data!.id,
        });

        if (mounted) {
          AppToast.show(
            context,
            '공지사항이 작성되었습니다',
            type: ToastType.success,
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          isEditMode
              ? '공지사항 수정 중 오류가 발생했습니다: $e'
              : '공지사항 작성 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
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
          isEditMode ? '공지사항 수정' : '공지사항 작성',
          style: const FigmaTextStyles().title2.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
        actions: [
          material.IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: _isLoading ? null : _saveAnnouncement,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    // 제목 입력
                    _buildTitleSection(),
                    SizedBox(height: 16.h),
                    // 내용 입력
                    _buildContentSection(),
                    SizedBox(height: 16.h),
                    // 중요 공지 설정
                    _buildPinnedSection(),
                    SizedBox(height: 32.h),
                    // 저장 버튼
                    _buildSaveButton(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '제목',
            style: const FigmaTextStyles().title3.copyWith(
                  color: NewAppColor.neutral900,
                ),
          ),
          SizedBox(height: 12.h),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '공지사항 제목을 입력하세요',
              hintStyle: const FigmaTextStyles().body1.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: NewAppColor.neutral300,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: NewAppColor.primary600,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            style: const FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.neutral900,
                ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '제목을 입력해주세요';
              }
              return null;
            },
          ),
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
          SizedBox(height: 12.h),
          TextFormField(
            controller: _contentController,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: '공지사항 내용을 입력하세요',
              hintStyle: const FigmaTextStyles().body1.copyWith(
                    color: NewAppColor.neutral400,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: NewAppColor.neutral300,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: NewAppColor.primary600,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
            ),
            style: const FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.neutral900,
                  height: 1.6,
                ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '내용을 입력해주세요';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '중요 공지 설정',
            style: const FigmaTextStyles().title3.copyWith(
                  color: NewAppColor.neutral900,
                ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () {
              setState(() {
                _isPinned = !_isPinned;
              });
            },
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: _isPinned
                    ? const Color(0xFFFFF3E0)
                    : NewAppColor.neutral100,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: _isPinned
                      ? const Color(0xFFFFA000)
                      : NewAppColor.neutral200,
                  width: _isPinned ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPinned ? Icons.star : Icons.star_border,
                    color: _isPinned
                        ? const Color(0xFFFFA000)
                        : NewAppColor.neutral600,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '중요 공지로 설정',
                          style: const FigmaTextStyles().body1.copyWith(
                                color: _isPinned
                                    ? const Color(0xFFFFA000)
                                    : NewAppColor.neutral900,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '중요 공지는 목록 상단에 고정됩니다',
                          style: const FigmaTextStyles().body2.copyWith(
                                color: _isPinned
                                    ? const Color(0xFFFF8F00)
                                    : NewAppColor.neutral600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPinned,
                    onChanged: (value) {
                      setState(() {
                        _isPinned = value;
                      });
                    },
                    activeColor: const Color(0xFFFFA000),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        width: double.infinity,
        child: AppButton(
          onPressed: _isLoading ? null : _saveAnnouncement,
          child: Text(isEditMode ? '수정 완료' : '작성 완료'),
        ),
      ),
    );
  }
}