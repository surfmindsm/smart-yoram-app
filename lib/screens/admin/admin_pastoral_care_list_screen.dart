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
  String _selectedStatus = 'pending'; // pending(대기) / approved(+in_progress) / completed

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

    // 상태 필터 — '승인' 탭은 approved + in_progress 묶음
    if (_selectedStatus == 'approved') {
      filtered = filtered
          .where((r) => r.status == 'approved' || r.status == 'in_progress')
          .toList();
    } else if (_selectedStatus != 'all') {
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

  // 1.2.0 C 방향: AppBar + 탭바(대기/승인/완료) + 카드 + 카드 사이 8px 구분선
  int _countByStatus(String status) =>
      _requests.where((r) => r.status == status).length;

  @override
  Widget build(BuildContext context) {
    final pendingCount = _countByStatus('pending');
    final approvedCount = _countByStatus('approved') + _countByStatus('in_progress');
    final completedCount = _countByStatus('completed');

    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: material.IconButton(
          icon: Icon(Icons.chevron_left,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '심방 신청 관리',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
      ),
      body: Column(
        children: [
          // 탭바 — 대기 / 승인 / 완료 (밑줄 강조)
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('대기', pendingCount, 'pending'),
                _buildTab('승인', approvedCount, 'approved'),
                _buildTab('완료', completedCount, 'completed'),
              ],
            ),
          ),
          Container(height: 1, color: NewAppColor.borderSoft),
          // 심방 신청 목록
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: NewAppColor.skyPrimary,
                    ),
                  )
                : _filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 56.sp,
                              color: NewAppColor.iconFaint,
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              '심방 신청이 없습니다',
                              style: FigmaTextStyles().subtitle2.copyWith(
                                    color: NewAppColor.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        color: NewAppColor.skyPrimary,
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _filteredRequests.length,
                          separatorBuilder: (_, __) => Container(
                            height: 8,
                            color: NewAppColor.borderSoft,
                          ),
                          itemBuilder: (context, index) {
                            final request = _filteredRequests[index];
                            return PastoralCareCard(
                              request: request,
                              onTap: () => _navigateToDetail(request),
                              onAssign: () => _navigateToDetail(request),
                              onApprove: () => _approveRequest(request),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // 1.2.0: 탭바 항목 (활성 = skyPrimary 텍스트 + 2.5px 밑줄)
  Widget _buildTab(String label, int count, String status) {
    // '승인' 탭은 approved + in_progress 두 상태를 묶음
    final isSelected = status == 'approved'
        ? (_selectedStatus == 'approved' || _selectedStatus == 'in_progress')
        : _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onStatusFilterChanged(status),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 13.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? NewAppColor.skyPrimary
                    : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$label $count',
            style: TextStyle(
              color: isSelected
                  ? NewAppColor.skyPrimary
                  : NewAppColor.textTertiary,
              fontSize: 13.5.sp,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      ),
    );
  }

  // 카드 안 승인 버튼 — 상세 화면 거치지 않고 바로 승인
  Future<void> _approveRequest(PastoralCareRequest request) async {
    try {
      final response = await _pastoralCareService.updateRequestStatus(
        requestId: request.id,
        status: 'approved',
      );
      if (!mounted) return;
      if (response.success) {
        AppToast.success(context, '심방 신청을 승인했습니다');
        _loadRequests();
      } else {
        AppToast.error(
          context,
          response.message.isNotEmpty
              ? response.message
              : '승인에 실패했습니다',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, '오류가 발생했습니다: $e');
      }
    }
  }
}