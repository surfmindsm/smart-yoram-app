import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart';
import '../models/prayer_request.dart';
import '../services/prayer_request_service.dart';
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
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // 선택된 값들
  String _selectedCategory = PrayerCategory.personal;
  String _selectedPriority = PrayerPriority.normal;
  bool _isPrivate = false;
  bool _isSubmitting = false;
  
  // 데이터 목록들
  List<PrayerRequest> _myRequests = [];
  List<PrayerRequest> _publicRequests = [];
  bool _isLoadingMy = false;
  bool _isLoadingPublic = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMyRequests(),
      _loadPublicRequests(),
    ]);
  }

  Future<void> _loadMyRequests() async {
    setState(() => _isLoadingMy = true);
    
    try {
      final response = await PrayerRequestService.getMyRequests();
      if (response.success && response.data != null) {
        setState(() => _myRequests = response.data!);
      } else {
        _showErrorSnackBar('내 기도 목록을 불러오지 못했습니다: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('네트워크 오류: $e');
    } finally {
      setState(() => _isLoadingMy = false);
    }
  }

  Future<void> _loadPublicRequests() async {
    setState(() => _isLoadingPublic = true);
    
    try {
      final response = await PrayerRequestService.getPublicRequests();
      if (response.success && response.data != null) {
        setState(() => _publicRequests = response.data!);
      } else {
        _showErrorSnackBar('공동 기도 목록을 불러오지 못했습니다: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('네트워크 오류: $e');
    } finally {
      setState(() => _isLoadingPublic = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류: $message'),
          backgroundColor: AppColor.secondary04,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('성공: $message'),
          backgroundColor: AppColor.secondary02,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondary06,
      appBar: AppBar(
        title: Text(
          '중보 기도',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColor.primary600,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: '내 기도'),
            Tab(text: '공동 기도'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyRequestsTab(),
          _buildPublicRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRequestDialog,
        backgroundColor: AppColor.primary600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: _isLoadingMy
          ? _buildLoadingWidget()
          : _myRequests.isEmpty
              ? _buildEmptyWidget(
                  icon: Icons.favorite_outline,
                  title: '등록된 기도제목이 없습니다',
                  subtitle: '첫 기도제목을 등록해보세요',
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

  Widget _buildPublicRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadPublicRequests,
      child: _isLoadingPublic
          ? _buildLoadingWidget()
          : _publicRequests.isEmpty
              ? _buildEmptyWidget(
                  icon: Icons.people_outline,
                  title: '공동 기도제목이 없습니다',
                  subtitle: '공동체와 함께 기도해보세요',
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: _publicRequests.length,
                  itemBuilder: (context, index) {
                    final request = _publicRequests[index];
                    return _buildRequestCard(request, isMyRequest: false);
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
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 행
            Row(
              children: [
                AppBadge(
                  text: PrayerCategory.getCategoryName(request.category),
                  variant: _getCategoryBadgeVariant(request.category),
                ),
                SizedBox(width: 8.w),
                if (request.priority == PrayerPriority.urgent)
                  AppBadge(
                    text: '긴급',
                    variant: BadgeVariant.secondary,
                  ),
                if (request.isPrivate)
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: AppBadge(
                      text: '비공개',
                      variant: BadgeVariant.secondary,
                    ),
                  ),
                const Spacer(),
                AppBadge(
                  text: PrayerStatus.getStatusName(request.status),
                  variant: _getStatusBadgeVariant(request.status),
                ),
                if (isMyRequest)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, request),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('수정'),
                          ],
                        ),
                      ),
                      if (request.status == PrayerStatus.active)
                        const PopupMenuItem(
                          value: 'answered',
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 16, color: Colors.green),
                              SizedBox(width: 8),
                              Text('응답됨으로 표시'),
                            ],
                          ),
                        ),
                      if (request.status == PrayerStatus.active)
                        const PopupMenuItem(
                          value: 'pause',
                          child: Row(
                            children: [
                              Icon(Icons.pause, size: 16, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('일시정지'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('삭제 확인', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            
            // 제목
            Text(
              request.title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColor.secondary07,
              ),
            ),
            SizedBox(height: 8.h),
            
            // 내용
            Text(
              request.content,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColor.gray600,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            
            // 푸터
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
                if (request.memberName != null) ...[
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.person,
                    size: 14.w,
                    color: AppColor.secondary04,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    request.memberName!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColor.secondary04,
                    ),
                  ),
                ],
                const Spacer(),
                if (!isMyRequest)
                  AppButton(
                    variant: ButtonVariant.ghost,
                    onPressed: () => _prayForRequest(request),
                    child: const Text('기도해요'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BadgeVariant _getCategoryBadgeVariant(String category) {
    switch (category) {
      case PrayerCategory.personal:
        return BadgeVariant.primary;
      case PrayerCategory.family:
        return BadgeVariant.secondary;
      case PrayerCategory.church:
        return BadgeVariant.success;
      case PrayerCategory.mission:
        return BadgeVariant.warning;
      case PrayerCategory.healing:
        return BadgeVariant.error;
      case PrayerCategory.guidance:
        return BadgeVariant.secondary;
      default:
        return BadgeVariant.secondary;
    }
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
    return '${date.month}월 ${date.day}일';
  }

  void _handleMenuAction(String action, PrayerRequest request) {
    switch (action) {
      case 'edit':
        _showEditRequestDialog(request);
        break;
      case 'answered':
        _markAsAnswered(request);
        break;
      case 'pause':
        _markAsPaused(request);
        break;
      case 'delete':
        _showDeleteConfirmDialog(request);
        break;
    }
  }

  void _prayForRequest(PrayerRequest request) {
    _showSuccessSnackBar('${request.title}을 위해 기도합니다 ');
  }

  Future<void> _markAsAnswered(PrayerRequest request) async {
    try {
      final response = await PrayerRequestService.markAsAnswered(request.id!);
      if (response.success) {
        _showSuccessSnackBar('기도제목이 응답됨으로 표시되었습니다');
        _loadMyRequests();
      } else {
        _showErrorSnackBar('상태 변경에 실패했습니다: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('네트워크 오류: $e');
    }
  }

  Future<void> _markAsPaused(PrayerRequest request) async {
    try {
      final response = await PrayerRequestService.markAsPaused(request.id!);
      if (response.success) {
        _showSuccessSnackBar('기도제목이 일시정지되었습니다');
        _loadMyRequests();
      } else {
        _showErrorSnackBar('상태 변경에 실패했습니다: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('네트워크 오류: $e');
    }
  }

  void _showDeleteConfirmDialog(PrayerRequest request) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '기도제목 삭제',
        description: '${request.title}을(를) 삭제하시겠습니까?',
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
        _showSuccessSnackBar('기도제목이 삭제되었습니다');
        _loadMyRequests();
      } else {
        _showErrorSnackBar('기도제목 삭제에 실패했습니다: ${response.message}');
      }
    } catch (e) {
      _showErrorSnackBar('네트워크 오류: $e');
    }
  }

  void _showAddRequestDialog() {
    _resetForm();
    _showRequestDialog(isEdit: false);
  }

  void _showEditRequestDialog(PrayerRequest request) {
    _titleController.text = request.title;
    _contentController.text = request.content;
    _selectedCategory = request.category;
    _selectedPriority = request.priority;
    _isPrivate = request.isPrivate;
    _showRequestDialog(isEdit: true, request: request);
  }

  void _resetForm() {
    _titleController.clear();
    _contentController.clear();
    _selectedCategory = PrayerCategory.personal;
    _selectedPriority = PrayerPriority.normal;
    _isPrivate = false;
  }

  void _showRequestDialog({required bool isEdit, PrayerRequest? request}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: isEdit ? '기도제목 수정' : '기도제목 등록',
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppInput(
                  label: '제목',
                  placeholder: '기도 제목을 입력하세요',
                  controller: _titleController,
                ),
                SizedBox(height: 16.h),
                AppInput(
                  label: '내용',
                  placeholder: '기도 요청 내용을 입력하세요',
                  maxLines: 5,
                  controller: _contentController,
                ),
                SizedBox(height: 16.h),
                AppDropdown<String>(
                  value: _selectedCategory,
                  items: PrayerCategory.allCategories
                      .map((category) => AppDropdownMenuItem<String>(
                            value: category,
                            text: PrayerCategory.getCategoryName(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                  label: '분류',
                ),
                SizedBox(height: 16.h),
                AppDropdown<String>(
                  value: _selectedPriority,
                  items: PrayerPriority.allPriorities
                      .map((priority) => AppDropdownMenuItem<String>(
                            value: priority,
                            text: PrayerPriority.getPriorityName(priority),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPriority = value!);
                  },
                  label: '우선순위',
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            AppButton(
              onPressed: _isSubmitting ? null : () => _submitRequest(isEdit: isEdit, request: request),
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

  Future<void> _submitRequest({required bool isEdit, PrayerRequest? request}) async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    try {
      if (isEdit && request != null) {
        final updateRequest = PrayerRequestUpdate(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          priority: _selectedPriority,
          isPrivate: _isPrivate,
        );
        
        final response = await PrayerRequestService.updateRequest(
          request.id!,
          updateRequest,
        );
        
        if (response.success) {
          Navigator.pop(context);
          _showSuccessSnackBar('기도제목이 수정되었습니다');
          _loadMyRequests();
        } else {
          _showErrorSnackBar('기도제목 ${isEdit ? '수정' : '등록'}에 실패했습니다: ${response.message}');
        }
      } else {
        final createRequest = PrayerRequestCreate(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          category: _selectedCategory,
          priority: _selectedPriority,
          isPrivate: _isPrivate,
        );
        
        final response = await PrayerRequestService.createRequest(createRequest);
        
        if (response.success) {
          Navigator.pop(context);
          _showSuccessSnackBar('기도제목이 등록되었습니다');
          _loadData();
        } else {
          _showErrorSnackBar('상태 변경에 실패했습니다: ${response.message}');
        }
      }
    } catch (e) {
      _showErrorSnackBar('네트워크 오류: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
