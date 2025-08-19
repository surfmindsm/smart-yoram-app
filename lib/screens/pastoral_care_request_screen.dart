import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart';
import '../models/pastoral_care_request.dart';
import '../services/pastoral_care_service.dart';
import '../resource/color_style.dart';

class PastoralCareRequestScreen extends StatefulWidget {
  const PastoralCareRequestScreen({super.key});

  @override
  State<PastoralCareRequestScreen> createState() =>
      _PastoralCareRequestScreenState();
}

class _PastoralCareRequestScreenState extends State<PastoralCareRequestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<PastoralCareRequest> _requests = [];

  // 신청 폼 컨트롤러들
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  final _preferredDateController = TextEditingController();
  final _preferredTimeController = TextEditingController();

  String _selectedRequestType = PastoralCareRequestType.visit;
  String _selectedPriority = PastoralCarePriority.medium;
  bool _isUrgent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadMyRequests() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await PastoralCareService.getMyRequests();
      if (response.success && response.data != null) {
        setState(() {
          _requests = response.data!;
        });
      } else {
        AppToast.show(
          context,
          '신청 목록을 불러올 수 없습니다: ${response.message}',
          type: ToastType.error,
        );
      }
    } catch (e) {
      AppToast.show(
        context,
        '네트워크 오류가 발생했습니다: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (_titleController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      AppToast.show(
        context,
        '제목과 내용을 입력해주세요.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = PastoralCareRequestCreate(
        requestType: _selectedRequestType,
        priority: _selectedPriority,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        preferredDate: _preferredDateController.text.trim().isEmpty
            ? null
            : _preferredDateController.text.trim(),
        preferredTime: _preferredTimeController.text.trim().isEmpty
            ? null
            : _preferredTimeController.text.trim(),
        contactInfo: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        isUrgent: _isUrgent,
      );

      final response = await PastoralCareService.createRequest(request);

      if (response.success) {
        AppToast.show(
          context,
          '심방 신청이 완료되었습니다.',
          type: ToastType.success,
        );

        _clearForm();
        _loadMyRequests();
        _tabController.animateTo(1); // 신청 목록 탭으로 이동
      } else {
        AppToast.show(
          context,
          '신청에 실패했습니다: ${response.message}',
          type: ToastType.error,
        );
      }
    } catch (e) {
      AppToast.show(
        context,
        '네트워크 오류가 발생했습니다: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _contactController.clear();
    _preferredDateController.clear();
    _preferredTimeController.clear();
    setState(() {
      _selectedRequestType = PastoralCareRequestType.visit;
      _selectedPriority = PastoralCarePriority.medium;
      _isUrgent = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _preferredDateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _preferredTimeController.text = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '심방 신청',
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
            Tab(text: '새 신청'),
            Tab(text: '신청 내역'),
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
          _buildRequestList(),
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
                  '신청 정보',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.secondary07,
                  ),
                ),
                SizedBox(height: 16.h),
                
                // 신청 유형
                Text(
                  '신청 유형 *',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColor.secondary07,
                  ),
                ),
                SizedBox(height: 8.h),
                AppDropdown<String>(
                  value: _selectedRequestType,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRequestType = value;
                      });
                    }
                  },
                  items: PastoralCareRequestType.all.map((type) {
                    return AppDropdownMenuItem<String>(
                      value: type,
                      text: PastoralCareRequestType.displayNames[type]!,
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),

                // 우선순위
                Text(
                  '우선순위',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColor.secondary07,
                  ),
                ),
                SizedBox(height: 8.h),
                AppDropdown<String>(
                  value: _selectedPriority,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPriority = value;
                      });
                    }
                  },
                  items: PastoralCarePriority.all.map((priority) {
                    return AppDropdownMenuItem<String>(
                      value: priority,
                      text: PastoralCarePriority.displayNames[priority]!,
                    );
                  }).toList(),
                ),
                SizedBox(height: 16.h),

                // 제목
                AppInput(
                  controller: _titleController,
                  label: '제목 *',
                  placeholder: '신청 제목을 입력해주세요',
                ),
                SizedBox(height: 16.h),

                // 내용
                AppInput(
                  controller: _descriptionController,
                  label: '상세 내용 *',
                  placeholder: '신청 내용을 자세히 입력해주세요',
                  maxLines: 4,
                ),
                SizedBox(height: 16.h),

                // 긴급 여부
                Row(
                  children: [
                    AppSwitch(
                      value: _isUrgent,
                      onChanged: (value) {
                        setState(() {
                          _isUrgent = value;
                        });
                      },
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '긴급 신청',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColor.secondary07,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '희망 일정 (선택사항)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.secondary07,
                  ),
                ),
                SizedBox(height: 16.h),

                // 희망 날짜
                AppInput(
                  controller: _preferredDateController,
                  label: '희망 날짜',
                  placeholder: '날짜를 선택해주세요',
                  disabled: true,
                  suffixIcon: Icons.calendar_today,
                  onTap: _selectDate,
                ),
                SizedBox(height: 16.h),

                // 희망 시간
                AppInput(
                  controller: _preferredTimeController,
                  label: '희망 시간',
                  placeholder: '시간을 선택해주세요',
                  disabled: true,
                  suffixIcon: Icons.access_time,
                  onTap: _selectTime,
                ),
                SizedBox(height: 16.h),

                // 연락처
                AppInput(
                  controller: _contactController,
                  label: '연락처',
                  placeholder: '연락 가능한 번호를 입력해주세요',
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: _isLoading ? null : _submitRequest,
              variant: ButtonVariant.primary,
              size: ButtonSize.lg,
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        const Text('신청 중...'),
                      ],
                    )
                  : const Text('신청하기'),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildRequestList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64.w,
              color: AppColor.secondary04,
            ),
            SizedBox(height: 16.h),
            Text(
              '신청 내역이 없습니다',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColor.secondary04,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '첫 번째 신청서를 작성해보세요',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColor.secondary04,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(PastoralCareRequest request) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: AppCard(
        variant: CardVariant.outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.secondary07,
                    ),
                  ),
                ),
                AppBadge(
                  text: request.statusDisplayName,
                  variant: _getStatusBadgeVariant(request.status),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              request.requestTypeDisplayName,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColor.secondary04,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '우선순위: ${request.priorityDisplayName}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColor.secondary04,
              ),
            ),
            if (request.isUrgent) ...[
              SizedBox(height: 4.h),
              Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 16.w,
                    color: Colors.red,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '긴급',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: 8.h),
            Text(
              '신청일: ${_formatDate(request.createdAt)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColor.secondary04,
              ),
            ),
            if (request.canEdit || request.canCancel) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  if (request.canEdit)
                    AppButton(
                      onPressed: () => _editRequest(request),
                      variant: ButtonVariant.outline,
                      size: ButtonSize.sm,
                      child: const Text('수정'),
                    ),
                  if (request.canEdit && request.canCancel)
                    SizedBox(width: 8.w),
                  if (request.canCancel)
                    AppButton(
                      onPressed: () => _cancelRequest(request),
                      variant: ButtonVariant.destructive,
                      size: ButtonSize.sm,
                      child: const Text('취소'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  BadgeVariant _getStatusBadgeVariant(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return BadgeVariant.secondary;
      case 'approved':
        return BadgeVariant.secondary;
      case 'in_progress':
        return BadgeVariant.secondary;
      case 'completed':
        return BadgeVariant.secondary;
      case 'cancelled':
        return BadgeVariant.error;
      default:
        return BadgeVariant.secondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  void _editRequest(PastoralCareRequest request) {
    // TODO: 수정 화면으로 이동하거나 다이얼로그 표시
    AppToast.show(
      context,
      '수정 기능은 곧 추가됩니다.',
      type: ToastType.info,
    );
  }

  Future<void> _cancelRequest(PastoralCareRequest request) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: '신청 취소',
        description: '정말로 이 신청을 취소하시겠습니까?\n취소된 신청은 복구할 수 없습니다.',
        actions: [
          AppButton(
            onPressed: () => Navigator.of(context).pop(false),
            variant: ButtonVariant.ghost,
            child: const Text('아니오'),
          ),
          AppButton(
            onPressed: () => Navigator.of(context).pop(true),
            variant: ButtonVariant.destructive,
            child: const Text('취소하기'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await PastoralCareService.cancelRequest(request.id);
        if (response.success) {
          AppToast.show(
            context,
            '신청이 취소되었습니다.',
            type: ToastType.success,
          );
          _loadMyRequests();
        } else {
          AppToast.show(
            context,
            '취소에 실패했습니다: ${response.message}',
            type: ToastType.error,
          );
        }
      } catch (e) {
        AppToast.show(
          context,
          '네트워크 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
