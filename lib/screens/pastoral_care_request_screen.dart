import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/index.dart';
import '../models/pastoral_care_request.dart';
import '../services/pastoral_care_service.dart';
import '../services/auth_service.dart';
import '../services/geocoding_service.dart';
import '../resource/color_style.dart';
import '../widgets/datetime_picker_bottom_sheet.dart';

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
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  final _preferredDateController = TextEditingController();
  final _preferredTimeController = TextEditingController();
  final _addressController = TextEditingController();
  final _detailAddressController = TextEditingController();

  bool _isUrgent = false;

  // 지도 관련 변수들
  double? _latitude;
  double? _longitude;
  NaverMapController? _mapController;
  NMarker? _marker;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _preferredDateController.dispose();
    _preferredTimeController.dispose();
    _addressController.dispose();
    _detailAddressController.dispose();
    _debounceTimer?.cancel();
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
        if (mounted) {
          AppToast.show(
            context,
            '신청 목록을 불러올 수 없습니다: ${response.message}',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '네트워크 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 주소 검색 및 지오코딩
  Future<void> _onSearchAddress() async {
    final query = _addressController.text.trim();
    if (query.isEmpty) return;

    final response = await GeocodingService.geocode(query);
    
    if (response.success && response.data != null) {
      final result = response.data!;
      
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });

      // 지도 위치 업데이트
      _updateMapLocation(result.latitude, result.longitude);
      
      if (mounted) {
        AppToast.show(
          context,
          '주소를 찾았습니다: ${result.address}',
          type: ToastType.success,
        );
      }
    } else {
      if (mounted) {
        AppToast.show(
          context,
          response.message ?? '주소를 찾을 수 없습니다.',
          type: ToastType.error,
        );
      }
    }
  }

  // 지도 위치 업데이트
  void _updateMapLocation(double lat, double lng) async {
    if (_mapController == null) return;

    try {
      // 카메라 이동
      await _mapController!.updateCamera(
        NCameraUpdate.scrollAndZoomTo(
          target: NLatLng(lat, lng),
          zoom: 16,
        ),
      );

      // 기존 마커 제거
      if (_marker != null) {
        await _mapController!.deleteOverlay(_marker!.info);
      }

      // 새 마커 추가
      _marker = NMarker(
        id: 'selected_location',
        position: NLatLng(lat, lng),
        caption: const NOverlayCaption(text: '선택 위치'),
      );

      await _mapController!.addOverlay(_marker!);
    } catch (e) {
      print('지도 업데이트 실패: $e');
    }
  }


  Future<void> _submitRequest() async {
    if (_descriptionController.text.trim().isEmpty) {
      AppToast.show(
        context,
        '내용을 입력해주세요.',
        type: ToastType.warning,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = AuthService().currentUser;
      final userName = currentUser?.fullName ?? '사용자';
      final userPhone = _contactController.text.trim().isNotEmpty 
                            ? _contactController.text.trim() 
                            : '010-0000-0000';
      
      final request = PastoralCareRequestCreate(
        requestType: PastoralCareRequestType.visit,
        priority: PastoralCarePriority.medium,
        title: '심방 신청',
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
        requesterName: userName,
        requesterPhone: userPhone,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        detailAddress: _detailAddressController.text.trim().isNotEmpty
            ? _detailAddressController.text.trim()
            : null,
        latitude: _latitude,
        longitude: _longitude,
      );

      final response = await PastoralCareService.createRequest(request);

      if (response.success) {
        if (mounted) {
          AppToast.show(
            context,
            '심방 신청이 완료되었습니다.',
            type: ToastType.success,
          );
        }

        _clearForm();
        _loadMyRequests();
        _tabController.animateTo(1);
      } else {
        if (mounted) {
          AppToast.show(
            context,
            '신청에 실패했습니다: ${response.message}',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '네트워크 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _descriptionController.clear();
    _contactController.clear();
    _preferredDateController.clear();
    _preferredTimeController.clear();
    _addressController.clear();
    _detailAddressController.clear();
    setState(() {
      _isUrgent = false;
      _latitude = null;
      _longitude = null;
    });
  }

  Future<void> _selectDateTime() async {
    // 기존 선택된 날짜와 시간 파싱
    DateTime? initialDate;
    String? initialTime;
    
    if (_preferredDateController.text.isNotEmpty) {
      final parts = _preferredDateController.text.split(' ');
      if (parts.isNotEmpty) {
        try {
          final dateParts = parts[0].split('-');
          if (dateParts.length == 3) {
            initialDate = DateTime(
              int.parse(dateParts[0]),
              int.parse(dateParts[1]),
              int.parse(dateParts[2]),
            );
          }
          if (parts.length > 1) {
            initialTime = parts[1];
          }
        } catch (e) {
          // 파싱 오류시 무시
        }
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateTimePickerBottomSheet(
        initialDate: initialDate,
        initialTime: initialTime,
        onConfirm: (date, time) {
          setState(() {
            _preferredDateController.text = 
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $time';
            // 이전 시간 컨트롤러도 업데이트 (백엔드 호환성)
            _preferredTimeController.text = time;
          });
        },
      ),
    );
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

                // 내용
                AppInput(
                  controller: _descriptionController,
                  label: '상세 내용 *',
                  placeholder: '심방이 필요한 사유를 자세히 입력해주세요',
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

                // 희망 날짜/시간
                AppInput(
                  controller: _preferredDateController,
                  label: '희망 날짜/시간',
                  placeholder: '날짜와 시간을 선택해주세요',
                  readOnly: true,
                  suffixIcon: Icons.event_available,
                  onTap: _selectDateTime,
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
          SizedBox(height: 16.h),

          // 방문 위치 설정
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '방문 위치 (선택사항)',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.secondary07,
                  ),
                ),
                SizedBox(height: 16.h),

                // 주소 입력
                AppInput(
                  controller: _addressController,
                  label: '주소',
                  placeholder: '방문 주소를 입력하세요',
                  suffixIcon: Icons.search,
                  onSuffixIconTap: _onSearchAddress,
                  onSubmitted: (_) => _onSearchAddress(),
                ),
                SizedBox(height: 16.h),

                // 상세주소 입력
                AppInput(
                  controller: _detailAddressController,
                  label: '상세주소 (선택사항)',
                  placeholder: '동/호수, 건물명 등을 입력하세요',
                ),
                SizedBox(height: 16.h),

                // 지도 영역
                if (_latitude != null && _longitude != null) ...[
                  Container(
                    height: 200.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColor.secondary02),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: _buildMapWidget(),
                  ),
                ],
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

  Widget _buildMapWidget() {
    try {
      return Stack(
        children: [
          NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(_latitude ?? 37.5665, _longitude ?? 126.9780),
                zoom: 16,
              ),
              locationButtonEnable: false,
              scaleBarEnable: false,
              logoClickEnable: false,
            ),
            onMapReady: (controller) async {
              _mapController = controller;
              if (_latitude != null && _longitude != null) {
                _updateMapLocation(_latitude!, _longitude!);
              }
            },
            onMapTapped: (point, latLng) async {
              setState(() {
                _latitude = latLng.latitude;
                _longitude = latLng.longitude;
              });
              _updateMapLocation(latLng.latitude, latLng.longitude);
              
              // 역지오코딩으로 주소 업데이트
              final reverseResponse = await GeocodingService.reverseGeocode(
                latitude: latLng.latitude,
                longitude: latLng.longitude,
              );
              
              if (reverseResponse.success && reverseResponse.data != null) {
                _addressController.text = reverseResponse.data!.address;
              }
            },
            onCameraChange: (NCameraUpdateReason reason, bool animated) async {
              // 지도가 제스처로 움직일 때만 위치 업데이트
              if (reason == NCameraUpdateReason.gesture) {
                // 현재 카메라 위치 가져오기
                final cameraPosition = await _mapController?.getCameraPosition();
                if (cameraPosition != null) {
                  final newLat = cameraPosition.target.latitude;
                  final newLng = cameraPosition.target.longitude;
                  
                  // 위치가 실제로 변경된 경우만 업데이트
                  if ((_latitude == null || (_latitude! - newLat).abs() > 0.00001) ||
                      (_longitude == null || (_longitude! - newLng).abs() > 0.00001)) {
                    
                    setState(() {
                      _latitude = newLat;
                      _longitude = newLng;
                    });
                    
                    // 역지오코딩으로 주소 업데이트 (디바운싱 적용)
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
                      final reverseResponse = await GeocodingService.reverseGeocode(
                        latitude: newLat,
                        longitude: newLng,
                      );
                      
                      if (reverseResponse.success && reverseResponse.data != null) {
                        _addressController.text = reverseResponse.data!.address;
                      }
                    });
                  }
                }
              }
            },
          ),
          // 지도 중앙에 고정 마커
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40.w,
                ),
                // 마커 아래쪽 점
                Container(
                  width: 4.w,
                  height: 4.w,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // 지도 사용 안내
          Positioned(
            top: 10.h,
            left: 10.w,
            right: 10.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '지도를 움직여서 위치를 선택하세요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return Container(
        color: AppColor.secondary01,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map_outlined,
                size: 48.w,
                color: AppColor.secondary04,
              ),
              SizedBox(height: 8.h),
              Text(
                '지도 로딩 중...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColor.secondary05,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }


  // 지도 링크 생성
  Map<String, String> _generateMapLinks(double lat, double lng) {
    return {
      'naver': 'nmap://place?lat=$lat&lng=$lng&name=심방위치',
      'google': 'https://maps.google.com/?q=$lat,$lng',
    };
  }

  // 지도 링크 열기
  Future<void> _openMapLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('지도 링크 열기 실패: $e');
    }
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
        child: InkWell(
          onTap: () => _showRequestDetailDialog(request),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
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
                if (request.address != null) ...[
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16.w,
                        color: AppColor.secondary04,
                      ),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          request.address!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColor.secondary04,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
          if (mounted) {
            AppToast.show(
              context,
              '신청이 취소되었습니다.',
              type: ToastType.success,
            );
          }
          _loadMyRequests();
        } else {
          if (mounted) {
            AppToast.show(
              context,
              '취소에 실패했습니다: ${response.message}',
              type: ToastType.error,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            '네트워크 오류가 발생했습니다: $e',
            type: ToastType.error,
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showRequestDetailDialog(PastoralCareRequest request) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '신청 상세보기',
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 기본 정보
              _buildDetailSection('신청 유형', request.requestTypeDisplayName),
              _buildDetailSection('상태', request.statusDisplayName),
              _buildDetailSection('우선순위', request.priorityDisplayName),
              if (request.isUrgent)
                _buildDetailSection('긴급 여부', '긴급 신청'),
              
              SizedBox(height: 16.h),
              
              // 신청 내용
              Text(
                '신청 내용',
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
                  request.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColor.gray600,
                    height: 1.4,
                  ),
                ),
              ),
              
              SizedBox(height: 16.h),
              
              // 희망 일정 정보
              if (request.preferredDate != null)
                _buildDetailSection('희망 날짜', request.preferredDate!),
              if (request.preferredTime != null)
                _buildDetailSection('희망 시간', request.preferredTime!),
              if (request.contactInfo != null)
                _buildDetailSection('연락처', request.contactInfo!),

              // 위치 정보
              if (request.address != null)
                _buildDetailSection('주소', request.address!),
              if (request.latitude != null && request.longitude != null)
                _buildDetailSection('좌표', '${request.latitude!.toStringAsFixed(6)}, ${request.longitude!.toStringAsFixed(6)}'),
              
              // 신청자 정보
              if (request.member != null)
                _buildDetailSection('신청자', request.member!.name),
              if (request.member?.phone != null)
                _buildDetailSection('신청자 연락처', request.member!.phone),
              
              // 일정 정보
              _buildDetailSection('신청일', _formatDetailDate(request.createdAt)),
              if (request.updatedAt != null && request.updatedAt != request.createdAt)
                _buildDetailSection('수정일', _formatDetailDate(request.updatedAt!)),
              
              // 처리 정보
              if (request.assignedTo != null)
                _buildDetailSection('담당자', request.assignedTo!),
              if (request.completedAt != null)
                _buildDetailSection('완료일', _formatDetailDate(request.completedAt!)),
              if (request.adminNotes != null && request.adminNotes!.isNotEmpty)
                _buildDetailSection('관리자 메모', request.adminNotes!),

              // 위치가 있으면 지도 보기 버튼 추가
              if (request.latitude != null && request.longitude != null) ...[
                SizedBox(height: 16.h),
                AppButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showLocationOnMap(request.latitude!, request.longitude!, request.address);
                  },
                  variant: ButtonVariant.outline,
                  size: ButtonSize.md,
                  child: const Text('지도에서 위치 보기'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          AppButton(
            variant: ButtonVariant.ghost,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('닫기'),
          ),
          if (request.canEdit)
            AppButton(
              onPressed: () {
                Navigator.of(context).pop();
                _editRequest(request);
              },
              child: const Text('수정'),
            ),
          if (request.canCancel)
            AppButton(
              variant: ButtonVariant.destructive,
              onPressed: () {
                Navigator.of(context).pop();
                _cancelRequest(request);
              },
              child: const Text('취소'),
            ),
        ],
      ),
    );
  }

  // 위치를 지도에서 보기
  void _showLocationOnMap(double latitude, double longitude, String? address) {
    final links = _generateMapLinks(latitude, longitude);
    
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '위치 보기',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (address != null) ...[
              Text('주소: $address'),
              SizedBox(height: 8.h),
            ],
            Text('좌표: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}'),
            SizedBox(height: 16.h),
            AppButton(
              onPressed: () => _openMapLink(links['naver']!),
              variant: ButtonVariant.primary,
              size: ButtonSize.md,
              child: const Text('네이버 지도에서 보기'),
            ),
            SizedBox(height: 8.h),
            AppButton(
              onPressed: () => _openMapLink(links['google']!),
              variant: ButtonVariant.outline,
              size: ButtonSize.md,
              child: const Text('구글 지도에서 보기'),
            ),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: const Text('닫기'),
          ),
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
}