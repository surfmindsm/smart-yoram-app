import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/index.dart';
import '../../components/admin/pastoral_care_card.dart';
import '../../models/pastoral_care_request.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/pastoral_care_service.dart';
import 'admin_pastoral_care_detail_screen.dart';

/// 관리자용 심방 신청 관리 화면
class AdminPastoralCareListScreen extends StatefulWidget {
  const AdminPastoralCareListScreen({super.key});

  @override
  State<AdminPastoralCareListScreen> createState() =>
      _AdminPastoralCareListScreenState();
}

class _AdminPastoralCareListScreenState
    extends State<AdminPastoralCareListScreen> {
  final PastoralCareService _pastoralCareService = PastoralCareService();

  List<PastoralCareRequest> _requests = [];
  List<PastoralCareRequest> _filteredRequests = [];
  bool _isLoading = false;
  String _selectedStatus = 'all'; // all, pending, approved, in_progress, completed, cancelled

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);

    try {
      final response =
          await _pastoralCareService.getAllRequests(limit: 1000);

      if (response.success && response.data != null) {
        setState(() {
          _requests = response.data!;
          _applyFilters();
        });
      } else {
        if (mounted) {
          AppToast.show(
            context,
            response.message.isNotEmpty
                ? response.message
                : '심방 신청 목록을 불러오는데 실패했습니다',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '심방 신청 목록 조회 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<PastoralCareRequest> filtered = _requests;

    // 상태 필터
    if (_selectedStatus != 'all') {
      filtered = filtered.where((r) => r.status == _selectedStatus).toList();
    }

    // 긴급 신청 우선 정렬
    filtered.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    setState(() {
      _filteredRequests = filtered;
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _applyFilters();
    });
  }

  void _navigateToDetail(PastoralCareRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdminPastoralCareDetailScreen(request: request),
      ),
    ).then((_) => _loadRequests()); // 돌아올 때 목록 새로고침
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
          '심방 신청 관리',
          style: const FigmaTextStyles().title2.copyWith(
            color: NewAppColor.neutral900,
          ),
        ),
        actions: [
          material.IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // 상태 필터 칩
          Container(
            padding: EdgeInsets.all(16.w),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('전체', 'all'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('대기', 'pending'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('승인', 'approved'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('진행중', 'in_progress'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('완료', 'completed'),
                  SizedBox(width: 8.w),
                  _buildFilterChip('취소', 'cancelled'),
                ],
              ),
            ),
          ),
          // 결과 카운트
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            color: NewAppColor.neutral100,
            child: Row(
              children: [
                Text(
                  '총 ${_filteredRequests.length}건',
                  style: const FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral700,
                  ),
                ),
                if (_filteredRequests
                    .where((r) => r.isUrgent)
                    .isNotEmpty) ...[
                  SizedBox(width: 12.w),
                  Container(
                    width: 1,
                    height: 12.h,
                    color: NewAppColor.neutral300,
                  ),
                  SizedBox(width: 12.w),
                  Icon(
                    Icons.error,
                    size: 16.sp,
                    color: Colors.red,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '긴급 ${_filteredRequests.where((r) => r.isUrgent).length}건',
                    style: const FigmaTextStyles().body2.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 심방 신청 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? Center(
                        child: Text(
                          '심방 신청이 없습니다',
                          style: const FigmaTextStyles().body1.copyWith(
                            color: NewAppColor.neutral600,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          itemCount: _filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = _filteredRequests[index];
                            return PastoralCareCard(
                              request: request,
                              onTap: () => _navigateToDetail(request),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;

    return GestureDetector(
      onTap: () => _onStatusFilterChanged(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.primary600 : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.white : NewAppColor.neutral700,
          ),
        ),
      ),
    );
  }
}