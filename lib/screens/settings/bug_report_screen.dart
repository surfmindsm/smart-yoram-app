import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/index.dart';
import '../../models/user.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/bug_report_service.dart';

/// 문제 신고 화면 — 1.2.0 C 방향
class BugReportScreen extends StatefulWidget {
  final User currentUser;

  const BugReportScreen({super.key, required this.currentUser});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final BugReportService _service = BugReportService();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final FocusNode _typeFocus = FocusNode();
  final FocusNode _descFocus = FocusNode();
  bool _submitting = false;

  static const _typeSuggestions = <String>[
    '로그인 오류',
    '화면 표시 문제',
    '알림 오작동',
    '데이터 동기화',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    _typeFocus.addListener(() => setState(() {}));
    _descFocus.addListener(() => setState(() {}));
    _typeController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descController.dispose();
    _typeFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _typeController.text.trim().isNotEmpty &&
      _descController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    try {
      final response = await _service.submitBugReport(
        userId: widget.currentUser.id,
        churchId: widget.currentUser.churchId,
        issueType: _typeController.text.trim(),
        description: _descController.text.trim(),
      );
      if (!mounted) return;
      if (response.success) {
        AppToast.success(context, '문제를 신고했습니다. 빠르게 확인하겠습니다.');
        Navigator.pop(context, true);
      } else {
        AppToast.error(
          context,
          response.message.isNotEmpty ? response.message : '문제 신고에 실패했습니다',
        );
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '문제 신고 중 오류가 발생했습니다');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      resizeToAvoidBottomInset: true,
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
          '문제 신고',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(),
                  SizedBox(height: 18.h),
                  _buildLabel('문제 유형'),
                  SizedBox(height: 8.h),
                  _buildTypeSuggestions(),
                  SizedBox(height: 10.h),
                  _buildTypeField(),
                  SizedBox(height: 18.h),
                  _buildLabel('문제 설명'),
                  SizedBox(height: 8.h),
                  _buildDescField(),
                  SizedBox(height: 10.h),
                  Text(
                    '재현 단계와 발생 시간을 함께 알려주시면 더 빠르게 확인할 수 있어요.',
                    style: TextStyle(
                      color: NewAppColor.textTertiary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      decoration: BoxDecoration(
        color: NewAppColor.skyTint,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bug_report_outlined,
              color: NewAppColor.skyDeep, size: 18.sp),
          SizedBox(width: 9.w),
          Expanded(
            child: Text(
              '불편한 점이나 버그를 알려주세요. 기기·앱 버전 정보는 자동으로 함께 전송됩니다.',
              style: TextStyle(
                color: NewAppColor.skyDeep,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
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

  Widget _buildTypeSuggestions() {
    return Wrap(
      spacing: 7.w,
      runSpacing: 7.h,
      children: _typeSuggestions.map((label) {
        final selected = _typeController.text.trim() == label;
        return GestureDetector(
          onTap: () {
            setState(() {
              _typeController.text = label;
              _typeController.selection = TextSelection.collapsed(
                offset: label.length,
              );
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 7.h),
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
              label,
              style: TextStyle(
                color: selected ? Colors.white : NewAppColor.textSecondary,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeField() {
    final focused = _typeFocus.hasFocus;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: focused ? NewAppColor.skyPrimary : NewAppColor.borderHair,
          width: focused ? 1.5 : 1,
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: TextField(
        controller: _typeController,
        focusNode: _typeFocus,
        style: TextStyle(
          color: NewAppColor.textStrong,
          fontSize: 14.5.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
        decoration: InputDecoration(
          hintText: '예: 로그인 오류',
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
      ),
    );
  }

  Widget _buildDescField() {
    final focused = _descFocus.hasFocus;
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
      child: TextField(
        controller: _descController,
        focusNode: _descFocus,
        maxLines: 8,
        minLines: 6,
        maxLength: 1000,
        style: TextStyle(
          color: NewAppColor.textBody,
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
          height: 1.6,
        ),
        buildCounter: (context,
            {required currentLength, required isFocused, maxLength}) {
          return Padding(
            padding: EdgeInsets.only(right: 2.w, bottom: 4.h),
            child: Text(
              '$currentLength / ${maxLength ?? 0}',
              style: TextStyle(
                color: NewAppColor.textTertiary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
          );
        },
        decoration: InputDecoration(
          hintText: '문제 설명을 자세히 입력해주세요',
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
      ),
    );
  }

  Widget _buildBottomBar() {
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
        child: GestureDetector(
          onTap: _canSubmit ? _submit : null,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: _canSubmit ? 1.0 : 0.4,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 15.h),
              decoration: BoxDecoration(
                color: NewAppColor.skyPrimary,
                borderRadius: BorderRadius.circular(13.r),
                boxShadow: _canSubmit
                    ? [
                        BoxShadow(
                          color: NewAppColor.skyPrimary.withOpacity(0.30),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: _submitting
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      '신고 보내기',
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
      ),
    );
  }
}
