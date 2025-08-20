import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart';
import '../models/prayer_request.dart';
import '../services/prayer_request_service.dart';
import '../services/auth_service.dart';
import '../resource/color_style.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      final response = await PrayerRequestService.getMyRequests();
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
      appBar: AppBar(
        title: Text(
          '중보 기도',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.secondary07,
          ),
        ),
        backgroundColor: AppColor.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '새 기도'),
            Tab(text: '내 기도'),
          ],
          labelColor: AppColor.primary600,
          unselectedLabelColor: AppColor.secondary04,
          indicatorColor: AppColor.primary600,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestForm(),
          _buildMyRequestsList(),
        ],
      ),
    );
  }

  Widget _buildRequestForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '기도 요청 정보',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.secondary07,
                  ),
                ),
                SizedBox(height: 16.h),

                // 내용
                Text(
                  '내용 *',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColor.secondary07,
                  ),
                ),
                SizedBox(height: 8.h),
                AppInput(
                  controller: _contentController,
                  placeholder: '기도 요청 내용을 입력하세요',
                  maxLines: 5,
                ),
                SizedBox(height: 16.h),

                // 비공개 설정
                AppCheckbox(
                  label: '비공개 요청',
                  description: '다른 사용자에게 보이지 않습니다',
                  value: _isPrivate,
                  onChanged: (value) {
                    setState(() {
                      _isPrivate = value!;
                    });
                  },
                ),
                SizedBox(height: 24.h),

                // 등록 버튼
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    onPressed: _isSubmitting ? null : _submitNewRequest,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('기도 요청 등록'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsList() {
    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: _isLoadingMy
          ? _buildLoadingWidget()
          : _myRequests.isEmpty
              ? _buildEmptyWidget(
                  icon: Icons.favorite_outline,
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
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColor.primary600),
          SizedBox(height: 16.h),
          Text(
            '기도 목록을 불러오는 중...',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColor.secondary04,
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
            color: AppColor.secondary04,
          ),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppColor.secondary04,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColor.secondary04,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(PrayerRequest request, {required bool isMyRequest}) {
    return AppCard(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () => _showRequestDetailDialog(request),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 - 비공개 표시만
              if (request.isPrivate)
                Row(
                  children: [
                    AppBadge(
                      text: '비공개',
                      variant: BadgeVariant.secondary,
                    ),
                  ],
                ),
              SizedBox(height: 12.h),

              // 내용 - 2줄까지만 표시
              Text(
                request.content,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColor.gray600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.h),

              // 푸터 - 날짜와 버튼들
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14.w,
                    color: AppColor.secondary04,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(request.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColor.secondary04,
                    ),
                  ),
                  const Spacer(),
                  if (isMyRequest) ...[
                    // 수정 버튼
                    InkWell(
                      onTap: () => _showEditRequestDialog(request),
                      borderRadius: BorderRadius.circular(6.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 16.w,
                              color: AppColor.primary600,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '수정',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColor.primary600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // 삭제 버튼
                    InkWell(
                      onTap: () => _showDeleteConfirmDialog(request),
                      borderRadius: BorderRadius.circular(6.r),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete,
                              size: 16.w,
                              color: Colors.red,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '삭제',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetailDialog(PrayerRequest request) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '기도 요청 상세보기',
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 기본 정보
              _buildDetailSection(
                  '카테고리', PrayerCategory.getCategoryName(request.category)),
              _buildDetailSection(
                  '상태', PrayerStatus.getStatusName(request.status)),
              if (request.priority == PrayerPriority.urgent)
                _buildDetailSection('우선순위', '긴급'),
              if (request.isPrivate) _buildDetailSection('공개 설정', '비공개'),

              SizedBox(height: 16.h),

              // 내용
              Text(
                '내용',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColor.secondary07,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColor.secondary01,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColor.secondary03),
                ),
                child: Text(
                  request.content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColor.gray600,
                    height: 1.4,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // 추가 정보
              if (request.memberName != null)
                _buildDetailSection('요청자', request.memberName!),
              _buildDetailSection('등록일', _formatDetailDate(request.createdAt)),
              if (request.updatedAt != null &&
                  request.updatedAt != request.createdAt)
                _buildDetailSection(
                    '수정일', _formatDetailDate(request.updatedAt!)),
            ],
          ),
        ),
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
            width: 70.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColor.secondary04,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColor.secondary07,
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

  BadgeVariant _getStatusBadgeVariant(String status) {
    switch (status) {
      case PrayerStatus.active:
        return BadgeVariant.primary;
      case PrayerStatus.answered:
        return BadgeVariant.success;
      case PrayerStatus.closed:
        return BadgeVariant.secondary;
      case PrayerStatus.paused:
        return BadgeVariant.warning;
      default:
        return BadgeVariant.secondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}월 ${date.day}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _prayForRequest(PrayerRequest request) {
    _showSuccessSnackBar('기도하겠습니다 ');
  }

  void _showEditRequestDialog(PrayerRequest request) {
    _contentController.text = request.content;
    _isPrivate = request.isPrivate;
    _showRequestDialog(isEdit: true, request: request);
  }

  void _showDeleteConfirmDialog(PrayerRequest request) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '기도 요청 삭제',
        description: '이 기도 요청을 삭제하시겠습니까?',
        actions: [
          AppButton(
            variant: ButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          AppButton(
            variant: ButtonVariant.destructive,
            onPressed: () async {
              Navigator.of(context).pop();
              _deleteRequest(request);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRequest(PrayerRequest request) async {
    try {
      final response = await PrayerRequestService.deleteRequest(request.id!);
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
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: isEdit ? '기도 요청 수정' : '기도 요청 등록',
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppInput(
                  label: '내용',
                  placeholder: '기도 요청 내용을 입력하세요',
                  maxLines: 5,
                  controller: _contentController,
                ),
                SizedBox(height: 16.h),
                AppCheckbox(
                  label: '비공개 요청',
                  description: '다른 사용자에게 보이지 않습니다',
                  value: _isPrivate,
                  onChanged: (value) {
                    setState(() => _isPrivate = value!);
                  },
                ),
              ],
            ),
          ),
          actions: [
            AppButton(
              variant: ButtonVariant.ghost,
              onPressed: () {
                Navigator.of(context).pop();
                _clearForm();
              },
              child: const Text('취소'),
            ),
            AppButton(
              onPressed: _isSubmitting
                  ? null
                  : () => _submitRequest(isEdit: isEdit, request: request),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? '수정' : '등록'),
            ),
          ],
        ),
      ),
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
          category: PrayerCategory.personal,
          priority: PrayerPriority.normal,
          isPrivate: _isPrivate,
        );

        final response = await PrayerRequestService.updateRequest(
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
          category: PrayerCategory.personal,
          priority: PrayerPriority.normal,
          isPrivate: _isPrivate,
          requesterName: userName,
        );

        final response =
            await PrayerRequestService.createRequest(createRequest);

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
        category: PrayerCategory.personal, // 기본 카테고리
        priority: PrayerPriority.normal, // 기본 우선순위
        isPrivate: _isPrivate,
        requesterName: userName, // 사용자 이름 전달
      );

      final response = await PrayerRequestService.createRequest(createRequest);

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
