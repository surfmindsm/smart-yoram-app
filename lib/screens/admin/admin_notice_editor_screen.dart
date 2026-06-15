import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/index.dart';
import '../../models/announcement.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/announcement_service.dart';
import '../../services/auth_service.dart';

/// 관리자용 공지사항 작성/수정 화면 — 1.2.0 C 방향
///
/// 시안: 좌측 ×닫기 / 가운데 타이틀 / 우측 "저장" 텍스트 액션 →
/// 카테고리 세그먼트 → 제목/내용 입력 → (수정 모드) 게시 옵션 토글 +
/// 하단 풀폭 "공지사항 삭제" 위험 버튼
class AdminNoticeEditorScreen extends StatefulWidget {
  final Announcement? announcement;

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
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  bool _isLoading = false;
  String _category = 'worship';
  bool _isPinned = false;
  bool _isActive = true;

  bool get isEditMode => widget.announcement != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.announcement?.title ?? '',
    );
    _contentController = TextEditingController(
      text: widget.announcement?.content ?? '',
    );
    _category = widget.announcement?.category ?? 'worship';
    _isPinned = widget.announcement?.isPinned ?? false;
    _isActive = widget.announcement?.isActive ?? true;
    _titleFocus.addListener(() => setState(() {}));
    _contentFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _saveAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

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

      final currentUser = currentUserResponse.data!;

      if (isEditMode) {
        final updateData = <String, dynamic>{
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'category': _category,
          'is_pinned': _isPinned,
          'is_active': _isActive,
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _announcementService.updateAnnouncement(
          widget.announcement!.id,
          updateData,
        );

        if (mounted) {
          AppToast.success(context, '공지사항이 수정되었습니다');
          Navigator.pop(context, true);
        }
      } else {
        final createData = <String, dynamic>{
          'church_id': currentUser.churchId,
          'title': _titleController.text.trim(),
          'content': _contentController.text.trim(),
          'author_id': currentUser.id,
          'author_name': currentUser.username,
          'is_pinned': _isPinned,
          'is_active': _isActive,
          'category': _category,
        };

        await _announcementService.createAnnouncement(createData);

        if (mounted) {
          AppToast.success(context, '공지사항이 작성되었습니다');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          isEditMode ? '공지사항 수정 중 오류가 발생했습니다' : '공지사항 작성 중 오류가 발생했습니다',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 시안: 하단 풀폭 위험 액션 — 미리보기 박스 포함 삭제 확인 시트
  void _confirmDelete() {
    final notice = widget.announcement!;
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
                    child: Icon(
                      Icons.delete_outline,
                      color: NewAppColor.danger700,
                      size: 26.sp,
                    ),
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
                  // 미리보기 박스
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
      final ok = await _announcementService
          .deleteAnnouncement(widget.announcement!.id);
      if (!mounted) return;
      if (ok) {
        AppToast.success(context, '공지를 삭제했습니다');
        Navigator.pop(context, true);
      } else {
        AppToast.error(context, '삭제에 실패했습니다');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '삭제 중 오류가 발생했습니다');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: NewAppColor.canvasAlt,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: material.IconButton(
          icon: Icon(Icons.close,
              color: NewAppColor.textStrong, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditMode ? '공지사항 수정' : '공지사항 작성',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAnnouncement,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
            ),
            child: Text(
              '저장',
              style: TextStyle(
                color: NewAppColor.skyPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: NewAppColor.skyPrimary),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 32.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategorySection(),
                    SizedBox(height: 18.h),
                    _buildFieldLabel('제목'),
                    SizedBox(height: 8.h),
                    _buildTitleField(),
                    SizedBox(height: 18.h),
                    _buildFieldLabel('내용'),
                    SizedBox(height: 8.h),
                    _buildContentField(),
                    SizedBox(height: 22.h),
                    _buildOptionsSection(),
                    if (isEditMode) ...[
                      SizedBox(height: 22.h),
                      _buildDeleteButton(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: NewAppColor.textTertiary,
        fontSize: 12.5.sp,
        fontWeight: FontWeight.w700,
        fontFamily: 'Pretendard',
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = const {
      'worship': '예배',
      'event': '행사',
      'member_news': '교우',
      'other': '일반',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('카테고리'),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: categories.entries.map((e) {
            final selected = _category == e.key;
            return GestureDetector(
              onTap: () => setState(() => _category = e.key),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: selected ? NewAppColor.skyPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: selected
                        ? NewAppColor.skyPrimary
                        : NewAppColor.borderStrong,
                    width: 1,
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    color: selected ? Colors.white : NewAppColor.textSecondary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    final focused = _titleFocus.hasFocus;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: focused ? NewAppColor.skyPrimary : NewAppColor.borderHair,
          width: focused ? 1.5 : 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      child: TextFormField(
        controller: _titleController,
        focusNode: _titleFocus,
        style: TextStyle(
          color: NewAppColor.textStrong,
          fontSize: 14.5.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
        decoration: InputDecoration(
          hintText: '공지사항 제목을 입력하세요',
          hintStyle: TextStyle(
            color: NewAppColor.textMuted,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '제목을 입력해주세요';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildContentField() {
    final focused = _contentFocus.hasFocus;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: focused ? NewAppColor.skyPrimary : NewAppColor.borderHair,
          width: focused ? 1.5 : 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      child: TextFormField(
        controller: _contentController,
        focusNode: _contentFocus,
        maxLines: 8,
        minLines: 6,
        style: TextStyle(
          color: NewAppColor.textBody,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
          height: 1.6,
        ),
        decoration: InputDecoration(
          hintText: '공지사항 내용을 입력하세요',
          hintStyle: TextStyle(
            color: NewAppColor.textMuted,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8.h),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '내용을 입력해주세요';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildFieldLabel('게시 옵션'),
            ),
          ),
          _buildToggleRow(
            icon: Icons.push_pin_outlined,
            label: '상단 고정',
            description: '목록 맨 위에 표시',
            value: _isPinned,
            onChanged: (v) => setState(() => _isPinned = v),
          ),
          Container(height: 1, color: NewAppColor.borderHair),
          _buildToggleRow(
            icon: Icons.visibility_outlined,
            label: '게시 상태',
            description: '교인에게 공개',
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: NewAppColor.textTertiary),
          SizedBox(width: 11.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  description,
                  style: TextStyle(
                    color: NewAppColor.textTertiary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: NewAppColor.skyPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      onTap: _confirmDelete,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
          color: NewAppColor.dangerBg,
          borderRadius: BorderRadius.circular(13.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline,
                size: 17.sp, color: NewAppColor.danger700),
            SizedBox(width: 7.w),
            Text(
              '공지사항 삭제',
              style: TextStyle(
                color: NewAppColor.danger700,
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
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
}
