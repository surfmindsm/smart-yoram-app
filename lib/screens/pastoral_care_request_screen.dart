import 'dart:async';
// import.*lucide_icons.*;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/index.dart';
import '../models/pastoral_care_request.dart';
import '../services/pastoral_care_service.dart';
import '../services/auth_service.dart';
import '../services/geocoding_service.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../widgets/datetime_picker_page.dart';

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
  int _currentTabIndex = 0;

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
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
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
      // print('지도 업데이트 실패: $e');
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

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DateTimePickerPage(
          initialDate: initialDate,
          initialTime: initialTime,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final DateTime date = result['date'];
      final String time = result['time'];

      setState(() {
        _preferredDateController.text =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} $time';
        // 이전 시간 컨트롤러도 업데이트 (백엔드 호환성)
        _preferredTimeController.text = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '심방 신청',
          style: const FigmaTextStyles().headline4.copyWith(
                color: Colors.white,
              ),
        ),
        backgroundColor: NewAppColor.success600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(52.h),
          child: Container(
            width: double.infinity,
            height: 52.h,
            color: Colors.white,
            child: Stack(
              children: [
                // 신청 내역 탭 (오른쪽)
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(1);
                      setState(() {
                        _currentTabIndex = 1;
                      });
                    },
                    child: Container(
                      width: 195.w,
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            width: _currentTabIndex == 1 ? 2.0 : 1,
                            color: _currentTabIndex == 1
                                ? NewAppColor.success600
                                : NewAppColor.neutral200,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '신청 내역',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentTabIndex == 1
                                ? NewAppColor.success600
                                : NewAppColor.neutral500,
                            fontSize: 16.sp,
                            fontFamily: 'Pretendard Variable',
                            fontWeight: _currentTabIndex == 1
                                ? FontWeight.w600
                                : FontWeight.w400,
                            height: 1.50,
                            letterSpacing: _currentTabIndex == 1 ? 0 : -0.40,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 새신청 탭 (왼쪽)
                Positioned(
                  left: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(0);
                      setState(() {
                        _currentTabIndex = 0;
                      });
                    },
                    child: Container(
                      width: 195.w,
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            width: _currentTabIndex == 0 ? 2.0 : 1,
                            color: _currentTabIndex == 0
                                ? NewAppColor.success600
                                : NewAppColor.neutral200,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '새신청',
                          textAlign: TextAlign.center,
                          style: FigmaTextStyles().title4.copyWith(
                                color: _currentTabIndex == 0
                                    ? NewAppColor.success600
                                    : NewAppColor.neutral500,
                                fontWeight: _currentTabIndex == 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                letterSpacing:
                                    _currentTabIndex == 0 ? 0 : -0.40,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: NewAppColor.neutral100,
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
    return Container(
      color: NewAppColor.neutral100,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '신청 상세정보',
                    style: const FigmaTextStyles().headline5.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                  ),
                  SizedBox(height: 16.h),

                  // 내용
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 커스텀 라벨
                      Text(
                        '상세 내용*',
                        style: const FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral900,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      // 커스텀 TextField with 글자 수 카운터
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: NewAppColor.neutral200,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Stack(
                          children: [
                            TextField(
                              controller: _descriptionController,
                              maxLines: 6,
                              maxLength: 200,
                              onChanged: (value) {
                                setState(() {}); // 글자 수 업데이트를 위해
                              },
                              decoration: InputDecoration(
                                hintText:
                                    '자녀가 군 입대를 앞두고 있습니다. 건강하게 갔다 올 수 있도록 심방 요청드립니다.',
                                hintStyle:
                                    const FigmaTextStyles().body2.copyWith(
                                          color: NewAppColor.neutral400,
                                        ),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
                                counterText: '', // 기본 카운터 숨기기
                              ),
                              style: const FigmaTextStyles().body2.copyWith(
                                    color: NewAppColor.neutral900,
                                  ),
                            ),
                            // 커스텀 글자 수 카운터
                            Positioned(
                              bottom: 12.h,
                              right: 16.w,
                              child: Text(
                                '${_descriptionController.text.length}/200',
                                style:
                                    const FigmaTextStyles().caption3.copyWith(
                                          color: NewAppColor.neutral400,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 긴급 여부
                  Container(
                    width: double.infinity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isUrgent = !_isUrgent;
                            });
                          },
                          child: Container(
                            width: 44.w,
                            height: 26.h,
                            padding: EdgeInsets.all(2.r),
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              color: _isUrgent
                                  ? NewAppColor.success600
                                  : NewAppColor.neutral300,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(1000.r),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: _isUrgent
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22.w,
                                  height: 22.h,
                                  padding: EdgeInsets.all(4.r),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(1000.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '긴급 신청',
                            style: FigmaTextStyles().body1.copyWith(
                                  color: NewAppColor.neutral600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '희망 일정(선택사항)',
                    style: const FigmaTextStyles().headline5.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                  ),
                  SizedBox(height: 16.h),

                  // 희망 날짜/시간
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '희망 날짜/시간',
                        style: const FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral900,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      AppInput(
                        controller: _preferredDateController,
                        placeholder: 'DD/MM/YYYY',
                        readOnly: true,
                        suffixIcon: Icons.calendar_today,
                        onTap: _selectDateTime,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 연락처
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '연락처',
                        style: const FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral900,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      AppInput(
                        controller: _contactController,
                        placeholder: '연락 가능한 번호를 입력해주세요',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 방문 위치 설정
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '방문 위치 (선택사항)',
                    style: FigmaTextStyles().headline5.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                  ),
                  SizedBox(height: 16.h),

                  // 주소 입력
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '주소',
                        style: const FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral900,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      AppInput(
                        controller: _addressController,
                        placeholder: '방문 주소를 입력하세요',
                        suffixIcon: Icons.search,
                        onSuffixIconTap: _onSearchAddress,
                        onSubmitted: (_) => _onSearchAddress(),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 상세주소 입력
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '상세주소(선택사항)',
                        style: const FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral900,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      AppInput(
                        controller: _detailAddressController,
                        placeholder: '동/호수, 건물명 등을 입력하세요',
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 지도 영역
                  if (_latitude != null && _longitude != null) ...[
                    Container(
                      height: 200.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: NewAppColor.neutral200),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: _buildMapWidget(),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24.h),

            GestureDetector(
              onTap: _isLoading ? null : _submitRequest,
              child: Container(
                width: double.infinity,
                height: 56.h,
                decoration: BoxDecoration(
                  color: _isLoading
                      ? NewAppColor.success300
                      : NewAppColor.success600,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '신청 중...',
                              style: const FigmaTextStyles().title4.copyWith(
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        )
                      : Text(
                          '신청하기',
                          style: const FigmaTextStyles().title4.copyWith(
                                color: Colors.white,
                              ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
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
                final cameraPosition =
                    await _mapController?.getCameraPosition();
                if (cameraPosition != null) {
                  final newLat = cameraPosition.target.latitude;
                  final newLng = cameraPosition.target.longitude;

                  // 위치가 실제로 변경된 경우만 업데이트
                  if ((_latitude == null ||
                          (_latitude! - newLat).abs() > 0.00001) ||
                      (_longitude == null ||
                          (_longitude! - newLng).abs() > 0.00001)) {
                    setState(() {
                      _latitude = newLat;
                      _longitude = newLng;
                    });

                    // 역지오코딩으로 주소 업데이트 (디바운싱 적용)
                    _debounceTimer?.cancel();
                    _debounceTimer =
                        Timer(const Duration(milliseconds: 500), () async {
                      final reverseResponse =
                          await GeocodingService.reverseGeocode(
                        latitude: newLat,
                        longitude: newLng,
                      );

                      if (reverseResponse.success &&
                          reverseResponse.data != null) {
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
        color: NewAppColor.neutral100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 48.w,
                color: NewAppColor.neutral400,
              ),
              SizedBox(height: 8.h),
              Text(
                '지도 로딩 중...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: NewAppColor.neutral500,
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
      // print('지도 링크 열기 실패: $e');
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
            Container(
              width: 80.w,
              height: 80.h,
              decoration: ShapeDecoration(
                color: NewAppColor.neutral100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              child: Icon(
                Icons.home_outlined,
                size: 40.sp,
                color: NewAppColor.neutral400,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              '신청 내역이 없습니다',
              style: const FigmaTextStyles().title3.copyWith(
                color: NewAppColor.neutral700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '첫 번째 심방 신청서를 작성해보세요',
              style: const FigmaTextStyles().body1.copyWith(
                color: NewAppColor.neutral500,
              ),
            ),
            SizedBox(height: 32.h),
            GestureDetector(
              onTap: () {
                _tabController.animateTo(0);
                setState(() {
                  _currentTabIndex = 0;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: ShapeDecoration(
                  color: NewAppColor.success600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 18.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '새 신청 작성하기',
                      style: const FigmaTextStyles().body1.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
    return GestureDetector(
      onTap: () => _showRequestDetailDialog(request),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더 영역
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
              child: Row(
                children: [
                  // 아이콘
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: ShapeDecoration(
                      color: NewAppColor.success200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      size: 20.sp,
                      color: NewAppColor.success600,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // 제목과 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                request.title,
                                style: const FigmaTextStyles().title4.copyWith(
                                  color: NewAppColor.neutral900,
                                ),
                              ),
                            ),
                            // 상태 배지
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: ShapeDecoration(
                                color: _getStatusColor(request.status),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                              ),
                              child: Text(
                                request.statusDisplayName,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(
                              request.requestTypeDisplayName,
                              style: const FigmaTextStyles().body2.copyWith(
                                color: NewAppColor.neutral600,
                              ),
                            ),
                            if (request.isUrgent) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: ShapeDecoration(
                                  color: NewAppColor.danger100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                                child: Text(
                                  '긴급',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w500,
                                    color: NewAppColor.danger600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 내용 영역
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 신청 내용 미리보기
                  if (request.description.isNotEmpty) ...[
                    Text(
                      request.description,
                      style: const FigmaTextStyles().body2.copyWith(
                        color: NewAppColor.neutral800,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12.h),
                  ],

                  // 부가 정보들
                  Row(
                    children: [
                      // 우선순위
                      Icon(
                        Icons.flag_outlined,
                        size: 14.sp,
                        color: NewAppColor.neutral500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        request.priorityDisplayName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: NewAppColor.neutral500,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      // 신청일
                      Icon(
                        Icons.access_time,
                        size: 14.sp,
                        color: NewAppColor.neutral500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _formatDate(request.createdAt),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: NewAppColor.neutral500,
                        ),
                      ),
                    ],
                  ),

                  // 위치 정보
                  if (request.address != null) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14.sp,
                          color: NewAppColor.neutral500,
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            request.address!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: NewAppColor.neutral500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 액션 버튼들
            if (request.canEdit || request.canCancel) ...[
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: NewAppColor.neutral200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    if (request.canEdit) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editRequest(request),
                          child: Container(
                            height: 36.h,
                            decoration: ShapeDecoration(
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                                side: const BorderSide(
                                  color: NewAppColor.neutral300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '수정',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: NewAppColor.neutral700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (request.canEdit && request.canCancel) SizedBox(width: 8.w),
                    if (request.canCancel) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _cancelRequest(request),
                          child: Container(
                            height: 36.h,
                            decoration: ShapeDecoration(
                              color: NewAppColor.danger100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6.r),
                                side: const BorderSide(
                                  color: NewAppColor.danger200,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '취소',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: NewAppColor.danger600,
                                ),
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
              SizedBox(height: 20.h),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return NewAppColor.warning600;
      case 'approved':
        return NewAppColor.primary600;
      case 'in_progress':
        return NewAppColor.success600;
      case 'completed':
        return NewAppColor.success700;
      case 'cancelled':
        return NewAppColor.neutral500;
      default:
        return NewAppColor.neutral500;
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
              if (request.isUrgent) _buildDetailSection('긴급 여부', '긴급 신청'),

              SizedBox(height: 16.h),

              // 신청 내용
              Text(
                '신청 내용',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: NewAppColor.neutral900,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: NewAppColor.neutral100,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: NewAppColor.neutral300),
                ),
                child: Text(
                  request.description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: NewAppColor.neutral600,
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
                _buildDetailSection('좌표',
                    '${request.latitude!.toStringAsFixed(6)}, ${request.longitude!.toStringAsFixed(6)}'),

              // 신청자 정보
              if (request.member != null)
                _buildDetailSection('신청자', request.member!.name),
              if (request.member?.phone != null)
                _buildDetailSection('신청자 연락처', request.member!.phone),

              // 일정 정보
              _buildDetailSection('신청일', _formatDetailDate(request.createdAt)),
              if (request.updatedAt != null &&
                  request.updatedAt != request.createdAt)
                _buildDetailSection(
                    '수정일', _formatDetailDate(request.updatedAt!)),

              // 처리 정보
              if (request.assignedTo != null)
                _buildDetailSection('담당자', request.assignedTo!),
              if (request.completedAt != null)
                _buildDetailSection(
                    '완료일', _formatDetailDate(request.completedAt!)),
              if (request.adminNotes != null && request.adminNotes!.isNotEmpty)
                _buildDetailSection('관리자 메모', request.adminNotes!),

              // 위치가 있으면 지도 보기 버튼 추가
              if (request.latitude != null && request.longitude != null) ...[
                SizedBox(height: 16.h),
                AppButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showLocationOnMap(
                        request.latitude!, request.longitude!, request.address);
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
            Text(
                '좌표: ${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}'),
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
                color: NewAppColor.neutral400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.sp,
                color: NewAppColor.neutral900,
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
