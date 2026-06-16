import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart';
import '../models/prayer_request.dart';
import '../services/prayer_request_service.dart';
import '../services/auth_service.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PrayerRequestScreen extends StatefulWidget {
  const PrayerRequestScreen({Key? key}) : super(key: key);

  @override
  State<PrayerRequestScreen> createState() => _PrayerRequestScreenState();
}

class _PrayerRequestScreenState extends State<PrayerRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 폼 컨트롤러들
  final _contentController = TextEditingController();

  // 선택된 값들
  bool _isPrivate = false;
  bool _isSubmitting = false;

  // 데이터 목록들
  List<PrayerRequest> _myRequests = [];
  bool _isLoadingMy = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadMyRequests();
  }

  Future<void> _loadMyRequests() async {
    if (!mounted) return;

    setState(() => _isLoadingMy = true);

    try {
      final response = await PrayerRequestService().getMyRequests();
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() => _myRequests = response.data!);
      } else {
        AppToast.show(
          context,
          '내 기도 목록을 불러오지 못했습니다: ${response.message}',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        '네트워크 오류가 발생했습니다: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingMy = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      AppToast.show(
        context,
        message,
        type: ToastType.error,
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      AppToast.show(
        context,
        message,
        type: ToastType.success,
      );
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
              color: NewAppColor.textStrong, size: 26.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '중보 기도',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
      ),
      body: Column(
        children: [
          // 1.2.0 탭바 — 새 기도 / 내 기도 (밑줄 강조)
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('새 기도', 0),
                _buildTab('내 기도', 1),
              ],
            ),
          ),
          Container(height: 1, color: NewAppColor.borderSoft),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestForm(),
                _buildMyRequestsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() => _currentTabIndex = index);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 13.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? NewAppColor.skyPrimary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected ? NewAppColor.skyPrimary : NewAppColor.textTertiary,
              fontSize: 14.sp,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 폼 카드 (1.2.0)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: NewAppColor.borderHair, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '기도 요청 정보',
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 16.h),
                // 라벨
                Row(
                  children: [
                    Text(
                      '기도 내용',
                      style: TextStyle(
                        color: NewAppColor.textSecondary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '*',
                      style: TextStyle(
                        color: NewAppColor.danger700,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                // 입력 박스 + 카운터
                Stack(
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: 6,
                      maxLength: 200,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        color: NewAppColor.textStrong,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: '건강 회복을 위해 기도 부탁드립니다.',
                        hintStyle: TextStyle(
                          color: NewAppColor.textTertiary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                              color: NewAppColor.borderHair, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                              color: NewAppColor.borderHair, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                              color: NewAppColor.skyPrimary, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.fromLTRB(
                            14.w, 13.h, 14.w, 32.h),
                        counterText: '',
                      ),
                    ),
                    Positioned(
                      bottom: 10.h,
                      right: 14.w,
                      child: Text(
                        '${_contentController.text.length}/200',
                        style: TextStyle(
                          color: NewAppColor.textTertiary,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // 비공개 토글 행
                Row(
                  children: [
                    Icon(LucideIcons.lock,
                        size: 18.sp, color: NewAppColor.textTertiary),
                    SizedBox(width: 9.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '비공개 요청',
                            style: TextStyle(
                              color: NewAppColor.textStrong,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '담당 사역자에게만 공유돼요.',
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
                    AppSwitch(
                      value: _isPrivate,
                      onChanged: (value) =>
                          setState(() => _isPrivate = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          // 등록 버튼 — sky primary + 그림자
          GestureDetector(
            onTap: _isSubmitting ? null : _submitNewRequest,
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: _isSubmitting ? 0.5 : 1.0,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  color: NewAppColor.skyPrimary,
                  borderRadius: BorderRadius.circular(13.r),
                  boxShadow: [
                    BoxShadow(
                      color: NewAppColor.skyPrimary.withOpacity(0.30),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '등록 중…',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '기도 요청 등록',
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
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildMyRequestsList() {
    return Container(
      color: NewAppColor.canvasAlt,
      child: RefreshIndicator(
        onRefresh: _loadMyRequests,
        child: _isLoadingMy
            ? _buildLoadingWidget()
            : _myRequests.isEmpty
                ? _buildEmptyWidget(
                    icon: LucideIcons.heart,
                    title: '등록된 기도 요청이 없습니다',
                    subtitle: '첫 기도 요청을 등록해보세요',
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _myRequests.length,
                    itemBuilder: (context, index) {
                      final request = _myRequests[index];
                      return _buildRequestCard(request, isMyRequest: true);
                    },
                  ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: NewAppColor.skyPrimary),
          SizedBox(height: 16.h),
          Text(
            '기도 목록을 불러오는 중...',
            style: const FigmaTextStyles().body2.copyWith(
              color: NewAppColor.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64.w,
            color: NewAppColor.textMuted,
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.textMuted,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: const FigmaTextStyles().body2.copyWith(
              color: NewAppColor.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(PrayerRequest request, {required bool isMyRequest}) {
    final statusTone = _getStatusTone(request.status);
    final canEdit = isMyRequest && request.status == PrayerStatus.active;
    final canDelete = isMyRequest;
    return GestureDetector(
      onTap: () => _showRequestDetailDialog(request),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: NewAppColor.borderHair, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 영역 — 아이콘 + 제목 + 상태 칩
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
              child: Row(
                children: [
                  Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: NewAppColor.skyTint,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.heart,
                      size: 18.sp,
                      color: NewAppColor.skyDeep,
                    ),
                  ),
                  SizedBox(width: 11.w),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          PrayerCategory.getCategoryName(request.category),
                          style: TextStyle(
                            color: NewAppColor.textStrong,
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Pretendard',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (request.isPrivate) ...[
                          SizedBox(width: 6.w),
                          Icon(LucideIcons.lock,
                              size: 13.sp,
                              color: NewAppColor.textTertiary),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: statusTone.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      PrayerStatus.getStatusName(request.status),
                      style: TextStyle(
                        color: statusTone.fg,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 내용 영역
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (request.content.isNotEmpty) ...[
                    Text(
                      request.content,
                      style: TextStyle(
                        color: NewAppColor.textBody,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10.h),
                  ],
                  Row(
                    children: [
                      Icon(LucideIcons.clock,
                          size: 13.sp, color: NewAppColor.textTertiary),
                      SizedBox(width: 4.w),
                      Text(
                        _formatDate(request.createdAt),
                        style: TextStyle(
                          color: NewAppColor.textTertiary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 하단 액션 영역 — 수정/삭제 풀폭 분할
            if (canEdit || canDelete) ...[
              SizedBox(height: 14.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: NewAppColor.borderHair,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (canEdit) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showEditRequestDialog(request),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: NewAppColor.borderSoft,
                              borderRadius: BorderRadius.circular(11.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '수정',
                              style: TextStyle(
                                color: NewAppColor.textSecondary,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (canEdit && canDelete) SizedBox(width: 8.w),
                    if (canDelete) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showDeleteConfirmDialog(request),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: NewAppColor.dangerBg,
                              borderRadius: BorderRadius.circular(11.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '삭제',
                              style: TextStyle(
                                color: NewAppColor.danger700,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: 16.h),
            ],
          ],
        ),
      ),
    );
  }

  // 1.2.0 상태별 톤 — 심방 신청 카드와 동일 패턴
  ({Color bg, Color fg}) _getStatusTone(String status) {
    switch (status) {
      case PrayerStatus.active:
        return (bg: NewAppColor.skyTint, fg: NewAppColor.skyDeep);
      case PrayerStatus.answered:
        return (bg: NewAppColor.successBg, fg: NewAppColor.success700);
      case PrayerStatus.paused:
        return (bg: NewAppColor.warningBg, fg: NewAppColor.warning700);
      case PrayerStatus.closed:
        return (bg: NewAppColor.borderSoft, fg: NewAppColor.textSecondary);
      default:
        return (bg: NewAppColor.borderSoft, fg: NewAppColor.textSecondary);
    }
  }

  void _showRequestDetailDialog(PrayerRequest request) {
    AppInfoSheet.show(
      context: context,
      title: '기도 요청 상세보기',
      icon: LucideIcons.heart,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection(
              '카테고리', PrayerCategory.getCategoryName(request.category)),
          _buildDetailSection(
              '상태', PrayerStatus.getStatusName(request.status)),
          if (request.priority == PrayerPriority.urgent)
            _buildDetailSection('우선순위', '긴급'),
          if (request.isPrivate) _buildDetailSection('공개 설정', '비공개'),
          SizedBox(height: 14.h),
          Text(
            '내용',
            style: TextStyle(
              color: NewAppColor.textStrong,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: NewAppColor.canvasAlt,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: NewAppColor.borderHair),
            ),
            child: Text(
              request.content,
              style: TextStyle(
                color: NewAppColor.textBody,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
                height: 1.55,
              ),
            ),
          ),
          SizedBox(height: 14.h),
          if (request.memberName != null)
            _buildDetailSection('요청자', request.memberName!),
          _buildDetailSection('등록일', _formatDetailDate(request.createdAt)),
          if (request.updatedAt != null &&
              request.updatedAt != request.createdAt)
            _buildDetailSection('수정일', _formatDetailDate(request.updatedAt!)),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                color: NewAppColor.textTertiary,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: NewAppColor.textStrong,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetailDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showEditRequestDialog(PrayerRequest request) {
    _contentController.text = request.content;
    _isPrivate = request.isPrivate;
    _showRequestDialog(isEdit: true, request: request);
  }

  Future<void> _showDeleteConfirmDialog(PrayerRequest request) async {
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '기도 요청을 삭제할까요?',
      description: '삭제한 기도 요청은 되돌릴 수 없어요.',
      confirmLabel: '삭제',
      tone: AppSheetTone.danger,
    );
    if (ok == true) _deleteRequest(request);
  }

  Future<void> _deleteRequest(PrayerRequest request) async {
    try {
      final response = await PrayerRequestService().deleteRequest(request.id!);
      if (response.success) {
        _showSuccessSnackBar('기도 요청이 삭제되었습니다');
        _loadMyRequests();
      } else {
        _showErrorSnackBar('기도 요청 삭제에 실패했습니다: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('네트워크 오류: $e');
    }
  }

  void _showRequestDialog({required bool isEdit, PrayerRequest? request}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(26.r)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 22.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 핸들바
                        Container(
                          width: 44,
                          height: 5,
                          margin: EdgeInsets.only(bottom: 18.h),
                          decoration: BoxDecoration(
                            color: NewAppColor.borderStrong,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        // 아이콘 박스
                        Container(
                          width: 54.w,
                          height: 54.w,
                          decoration: BoxDecoration(
                            color: NewAppColor.skyTint,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.heart,
                              color: NewAppColor.skyDeep, size: 26.sp),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          isEdit ? '기도 요청 수정' : '기도 요청 등록',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: NewAppColor.textStrong,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        SizedBox(height: 22.h),
                        // 내용 라벨
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Text(
                                '기도 내용',
                                style: TextStyle(
                                  color: NewAppColor.textSecondary,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                '*',
                                style: TextStyle(
                                  color: NewAppColor.danger700,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: _contentController,
                          maxLines: 5,
                          style: TextStyle(
                            color: NewAppColor.textStrong,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Pretendard',
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: '기도 요청 내용을 입력하세요',
                            hintStyle: TextStyle(
                              color: NewAppColor.textTertiary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                  color: NewAppColor.borderHair, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                  color: NewAppColor.borderHair, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                  color: NewAppColor.skyPrimary, width: 1.5),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 13.h),
                          ),
                        ),
                        SizedBox(height: 14.h),
                        // 비공개 토글
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: NewAppColor.canvasAlt,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(LucideIcons.lock,
                                  size: 18.sp,
                                  color: NewAppColor.textTertiary),
                              SizedBox(width: 9.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '비공개 요청',
                                      style: TextStyle(
                                        color: NewAppColor.textStrong,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Pretendard',
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '담당 사역자에게만 공유돼요.',
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
                              AppSwitch(
                                value: _isPrivate,
                                onChanged: (value) =>
                                    setSheetState(() => _isPrivate = value),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 22.h),
                        // 액션 버튼
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _isSubmitting
                                    ? null
                                    : () {
                                        Navigator.pop(sheetContext);
                                        _clearForm();
                                      },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding:
                                      EdgeInsets.symmetric(vertical: 15.h),
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
                                onTap: _isSubmitting
                                    ? null
                                    : () => _submitRequest(
                                          isEdit: isEdit,
                                          request: request,
                                        ),
                                behavior: HitTestBehavior.opaque,
                                child: Opacity(
                                  opacity: _isSubmitting ? 0.5 : 1.0,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 15.h),
                                    decoration: BoxDecoration(
                                      color: NewAppColor.skyPrimary,
                                      borderRadius:
                                          BorderRadius.circular(13.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: NewAppColor.skyPrimary
                                              .withOpacity(0.30),
                                          blurRadius: 22,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: _isSubmitting
                                        ? SizedBox(
                                            width: 18.w,
                                            height: 18.w,
                                            child:
                                                const CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            isEdit ? '수정' : '등록',
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitRequest(
      {required bool isEdit, PrayerRequest? request}) async {
    if (_contentController.text.trim().isEmpty) {
      AppToast.show(
        context,
        '내용을 입력해주세요.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (isEdit && request != null) {
        final updateRequest = PrayerRequestUpdate(
          content: _contentController.text.trim(),
          category: PrayerCategory.general,
          priority: PrayerPriority.normal,
          isPrivate: _isPrivate,
        );

        final response = await PrayerRequestService().updateRequest(
          request.id!,
          updateRequest,
        );

        if (response.success) {
          Navigator.pop(context);
          _showSuccessSnackBar('기도 요청이 수정되었습니다');
          _loadMyRequests();
        } else {
          _showErrorSnackBar('기도 요청 수정에 실패했습니다: ${response.message}');
        }
      } else {
        final currentUser = AuthService().currentUser;
        final userName = currentUser?.fullName ?? '사용자';

        final createRequest = PrayerRequestCreate(
          title: '기도 요청',
          content: _contentController.text.trim(),
          category: PrayerCategory.general,
          priority: PrayerPriority.normal,
          isPrivate: _isPrivate,
          requesterName: userName,
        );

        final response =
            await PrayerRequestService().createRequest(createRequest);

        if (response.success) {
          Navigator.pop(context);
          _showSuccessSnackBar('기도 요청이 등록되었습니다');
          _loadMyRequests();
        } else {
          _showErrorSnackBar('기도 요청 등록에 실패했습니다: ${response.message}');
        }
      }
    } catch (e) {
      _showErrorSnackBar('네트워크 오류: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitNewRequest() async {
    if (_contentController.text.trim().isEmpty) {
      AppToast.show(
        context,
        '내용을 입력해주세요.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUser = AuthService().currentUser;
      final userName = currentUser?.fullName ?? '사용자';

      final createRequest = PrayerRequestCreate(
        title: '기도 요청', // 기본 제목
        content: _contentController.text.trim(),
        category: PrayerCategory.general, // 기본 카테고리
        priority: PrayerPriority.normal, // 기본 우선순위
        isPrivate: _isPrivate,
        requesterName: userName, // 사용자 이름 전달
      );

      final response = await PrayerRequestService().createRequest(createRequest);

      if (response.success) {
        _clearForm();
        _showSuccessSnackBar('기도 요청이 등록되었습니다');
        _loadMyRequests();
      } else {
        _showErrorSnackBar('기도 요청 등록에 실패했습니다: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('네트워크 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    _contentController.clear();
    _isPrivate = false;
  }
}
