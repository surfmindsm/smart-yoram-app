import 'dart:async';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/index.dart';
import '../models/pastoral_care_request.dart';
import '../services/pastoral_care_service.dart';
import '../services/auth_service.dart';
import '../services/geocoding_service.dart';
import '../services/member_service.dart';
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
      final response = await PastoralCareService().getMyRequests();
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
        requestType: PastoralCareRequestType.general, // 기본 유형으로 고정
        priority: PastoralCarePriority.normal, // 기본 우선순위로 고정
        title: '심방 신청',
        description: _descriptionController.text.trim(),
        preferredDate: _preferredDateController.text.trim().isEmpty
            ? null
            : _preferredDateController.text.trim().split(' ')[0], // 날짜만 추출
        preferredTimeStart: _preferredTimeController.text.trim().isEmpty
            ? null
            : _preferredTimeController.text.trim(),
        preferredTimeEnd: null, // 종료시간은 항상 null
        contactInfo: _contactController.text.trim().isEmpty
            ? null
            : _contactController.text.trim(),
        isUrgent: false, // 항상 일반 신청으로 고정
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

      final response = await PastoralCareService().createRequest(request);

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
      _latitude = null;
      _longitude = null;
    });
  }

  Future<void> _selectDateTime() async {
    // 기존 선택된 날짜와 시간 파싱
    DateTime? initialDate;
    String? initialTime;

    if (_preferredDateController.text.isNotEmpty) {
      try {
        final dateParts = _preferredDateController.text.split('-');
        if (dateParts.length == 3) {
          initialDate = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
        }
      } catch (e) {
        // 파싱 오류시 무시
      }
    }

    if (_preferredTimeController.text.isNotEmpty) {
      initialTime = _preferredTimeController.text;
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
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        _preferredTimeController.text = time;
      });
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
        centerTitle: true,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 26.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '심방 신청',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
      ),
      body: Column(
        children: [
          // 1.2.0 탭바 — 새신청 / 신청 내역 (밑줄 강조)
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _buildTab('새신청', 0),
                _buildTab('신청 내역', 1),
              ],
            ),
          ),
          Container(height: 1, color: NewAppColor.borderSoft),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestForm(),
                _buildRequestList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 시안: 필드 라벨 (textStrong 13sp/700)
  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: NewAppColor.textStrong,
        fontSize: 13.sp,
        fontWeight: FontWeight.w700,
        fontFamily: 'Pretendard',
      ),
    );
  }

  // 시안: 희망 일시 통합 필드 — event 아이콘 + "M월 D일(요) 오전/오후 H시" + chevron
  Widget _buildScheduleField() {
    final display = _composeScheduleDisplay();
    final hasValue = display != null;
    return GestureDetector(
      onTap: _selectDateTime,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: NewAppColor.borderHair, width: 1),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar,
                size: 18.sp, color: NewAppColor.textTertiary),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                display ?? '날짜·시간 선택',
                style: TextStyle(
                  color: hasValue
                      ? NewAppColor.textStrong
                      : NewAppColor.textMuted,
                  fontSize: 14.sp,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
            Icon(LucideIcons.chevronDown,
                size: 20.sp, color: NewAppColor.iconFaint),
          ],
        ),
      ),
    );
  }

  // 통합 표시 텍스트 — "6월 18일(목) 오후 2시" 시안과 동일
  String? _composeScheduleDisplay() {
    final dateText = _preferredDateController.text.trim();
    final timeText = _preferredTimeController.text.trim();
    if (dateText.isEmpty && timeText.isEmpty) return null;

    String datePart = '';
    if (dateText.isNotEmpty) {
      try {
        final parts = dateText.split('-');
        if (parts.length == 3) {
          final d = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
          final w = weekdays[d.weekday - 1];
          datePart = '${d.month}월 ${d.day}일($w)';
        }
      } catch (_) {
        datePart = dateText;
      }
    }

    String timePart = '';
    if (timeText.isNotEmpty) {
      try {
        final hm = timeText.split(':');
        if (hm.length >= 1) {
          final h = int.parse(hm[0]);
          final m = hm.length >= 2 ? int.parse(hm[1]) : 0;
          final period = h < 12 ? '오전' : '오후';
          final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
          timePart =
              m == 0 ? '$period $h12시' : '$period $h12시 ${m.toString().padLeft(2, '0')}분';
        }
      } catch (_) {
        timePart = timeText;
      }
    }

    if (datePart.isEmpty) return timePart;
    if (timePart.isEmpty) return datePart;
    return '$datePart $timePart';
  }

  // 1.2.0 탭바 항목 — 활성 = skyPrimary 텍스트 + 2.5px 밑줄
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
    return Container(
      color: NewAppColor.canvasAlt,
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
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: NewAppColor.borderHair, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '신청 상세정보',
                    style: TextStyle(fontFamily: 'Pretendard', fontSize: 15.5.sp, fontWeight: FontWeight.w800,
                          color: NewAppColor.textStrong,
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
                              color: NewAppColor.textStrong,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      // 커스텀 TextField with 글자 수 카운터
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: NewAppColor.borderHair,
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
                                          color: NewAppColor.textMuted,
                                        ),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
                                counterText: '', // 기본 카운터 숨기기
                              ),
                              style: const FigmaTextStyles().body2.copyWith(
                                    color: NewAppColor.textStrong,
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
                                          color: NewAppColor.textMuted,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: NewAppColor.borderHair, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '희망 일정(선택사항)',
                    style: TextStyle(fontFamily: 'Pretendard', fontSize: 15.5.sp, fontWeight: FontWeight.w800,
                          color: NewAppColor.textStrong,
                        ),
                  ),
                  SizedBox(height: 16.h),

                  // 시안: 희망 일시 — 통합 박스 (날짜 + 시간 한 줄, event 아이콘 prefix + chevron suffix)
                  _buildFieldLabel('희망 일시'),
                  SizedBox(height: 8.h),
                  _buildScheduleField(),
                  SizedBox(height: 16.h),

                  // 연락처 (phone 아이콘 prefix)
                  _buildFieldLabel('연락처'),
                  SizedBox(height: 8.h),
                  AppInput(
                    controller: _contactController,
                    placeholder: '연락 가능한 번호를 입력해주세요',
                    prefixIcon: LucideIcons.phone,
                    keyboardType: TextInputType.phone,
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
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: NewAppColor.borderHair, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '방문 위치 (선택사항)',
                    style: TextStyle(fontFamily: 'Pretendard', fontSize: 15.5.sp, fontWeight: FontWeight.w800,
                          color: NewAppColor.textStrong,
                        ),
                  ),
                  SizedBox(height: 16.h),

                  // 장소 (location 아이콘 prefix)
                  _buildFieldLabel('장소'),
                  SizedBox(height: 8.h),
                  AppInput(
                    controller: _addressController,
                    placeholder: '방문 주소를 입력하세요',
                    prefixIcon: LucideIcons.mapPin,
                    suffixIcon: LucideIcons.search,
                    onSuffixIconTap: _onSearchAddress,
                    onSubmitted: (_) => _onSearchAddress(),
                  ),
                  SizedBox(height: 16.h),

                  _buildFieldLabel('상세주소(선택사항)'),
                  SizedBox(height: 8.h),
                  AppInput(
                    controller: _detailAddressController,
                    placeholder: '동/호수, 건물명 등을 입력하세요',
                  ),
                  SizedBox(height: 16.h),

                  // 지도 영역
                  if (_latitude != null && _longitude != null) ...[
                    Container(
                      height: 200.h,
                      decoration: BoxDecoration(
                        border: Border.all(color: NewAppColor.borderHair),
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
              behavior: HitTestBehavior.opaque,
              child: Opacity(
                opacity: _isLoading ? 0.6 : 1.0,
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
                  child: _isLoading
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
                            SizedBox(width: 9.w),
                            Text(
                              '신청 중…',
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
                          '신청하기',
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
      ),
    );
  }

  Widget _buildMapWidget() {
    print(
        '🗺️ PASTORAL_CARE: _buildMapWidget 호출됨 - lat: $_latitude, lng: $_longitude');
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: 200.h,
              child: Builder(
                builder: (context) {
                  print('🗺️ PASTORAL_CARE: NaverMap 위젯 빌드 중');
                  return NaverMap(
                    options: NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: NLatLng(
                            _latitude ?? 37.5665, _longitude ?? 126.9780),
                        zoom: 16,
                      ),
                      locationButtonEnable: false,
                      scaleBarEnable: false,
                      logoClickEnable: false,
                      indoorEnable: false,
                      nightModeEnable: false,
                    ),
                    onMapReady: (controller) async {
                      print('🗺️ PASTORAL_CARE: 지도 초기화 완료');
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
                      final reverseResponse =
                          await GeocodingService.reverseGeocode(
                        latitude: latLng.latitude,
                        longitude: latLng.longitude,
                      );

                      if (reverseResponse.success &&
                          reverseResponse.data != null) {
                        _addressController.text = reverseResponse.data!.address;
                      }
                    },
                    onCameraChange:
                        (NCameraUpdateReason reason, bool animated) async {
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
                            _debounceTimer = Timer(
                                const Duration(milliseconds: 500), () async {
                              final reverseResponse =
                                  await GeocodingService.reverseGeocode(
                                latitude: newLat,
                                longitude: newLng,
                              );

                              if (reverseResponse.success &&
                                  reverseResponse.data != null) {
                                _addressController.text =
                                    reverseResponse.data!.address;
                              }
                            });
                          }
                        }
                      }
                    },
                  );
                },
              ),
            ),
            // 지도 중앙에 고정 마커
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.mapPin,
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
        ),
      );
    } catch (e) {
      return Container(
        color: NewAppColor.canvasAlt,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.map,
                size: 48.w,
                color: NewAppColor.textMuted,
              ),
              SizedBox(height: 8.h),
              Text(
                '지도 로딩 중...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: NewAppColor.textTertiary,
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
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                LucideIcons.house,
                size: 36.sp,
                color: NewAppColor.skyDeep,
              ),
            ),
            SizedBox(height: 22.h),
            Text(
              '신청 내역이 없습니다',
              style: TextStyle(
                color: NewAppColor.textStrong,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              '첫 번째 심방 신청서를 작성해보세요',
              style: TextStyle(
                color: NewAppColor.textTertiary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: () {
                _tabController.animateTo(0);
                setState(() {
                  _currentTabIndex = 0;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 13.h),
                decoration: BoxDecoration(
                  color: NewAppColor.skyPrimary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: NewAppColor.skyPrimary.withOpacity(0.30),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus, size: 17.sp, color: Colors.white),
                    SizedBox(width: 7.w),
                    Text(
                      '새 신청 작성하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
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
    final statusTone = _getStatusTone(request.status);
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
            // 상단 헤더 영역
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
                      LucideIcons.house,
                      size: 18.sp,
                      color: NewAppColor.skyDeep,
                    ),
                  ),
                  SizedBox(width: 11.w),
                  Expanded(
                    child: Text(
                      request.title.isNotEmpty
                          ? request.title
                          : request.requestTypeDisplayName,
                      style: TextStyle(
                        color: NewAppColor.textStrong,
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Pretendard',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 9.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: statusTone.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      request.statusDisplayName,
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
                  if (request.description.isNotEmpty) ...[
                    Text(
                      request.description,
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
                  if (request.address != null) ...[
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(LucideIcons.mapPin,
                            size: 13.sp, color: NewAppColor.textTertiary),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            request.address!,
                            style: TextStyle(
                              color: NewAppColor.textTertiary,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
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

            if (request.canEdit || request.canCancel) ...[
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
                    if (request.canEdit) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _editRequest(request),
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
                    if (request.canEdit && request.canCancel)
                      SizedBox(width: 8.w),
                    if (request.canCancel) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _cancelRequest(request),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: NewAppColor.dangerBg,
                              borderRadius: BorderRadius.circular(11.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '취소',
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

  // 1.2.0: 상태별 톤 (bg + fg) — 관리자 화면과 동일 매핑
  ({Color bg, Color fg}) _getStatusTone(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return (bg: NewAppColor.warningBg, fg: NewAppColor.warning700);
      case 'approved':
      case 'scheduled':
      case 'in_progress':
        return (bg: NewAppColor.skyTint, fg: NewAppColor.skyDeep);
      case 'completed':
        return (bg: NewAppColor.successBg, fg: NewAppColor.success700);
      case 'cancelled':
        return (bg: NewAppColor.dangerBg, fg: NewAppColor.danger700);
      default:
        return (bg: NewAppColor.borderSoft, fg: NewAppColor.textSecondary);
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
    final result = await AppConfirmSheet.show(
      context: context,
      title: '신청을 취소할까요?',
      description: '취소된 신청은 복구할 수 없어요.',
      confirmLabel: '취소하기',
      cancelLabel: '아니요',
      tone: AppSheetTone.danger,
      icon: LucideIcons.circleX,
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await PastoralCareService().cancelRequest(request.id);
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

  Future<void> _showRequestDetailDialog(PastoralCareRequest request) async {
    // 담당자 이름 조회
    String? assignedPastorName;
    if (request.assignedPastorId != null) {
      try {
        final memberResponse = await MemberService().getMember(request.assignedPastorId!);
        if (memberResponse.success && memberResponse.data != null) {
          assignedPastorName = memberResponse.data!.name;
        }
      } catch (e) {
        print('담당자 정보 조회 실패: $e');
      }
    }

    if (!mounted) return;

    AppInfoSheet.show(
      context: context,
      title: '신청 상세보기',
      icon: LucideIcons.calendarDays,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('상태', request.statusDisplayName),
          SizedBox(height: 14.h),
          Text(
            '신청 내용',
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
              request.description,
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
          if (request.preferredDate != null)
            _buildDetailSection(
                '희망 날짜',
                '${request.preferredDate!.year}.${request.preferredDate!.month.toString().padLeft(2, '0')}.${request.preferredDate!.day.toString().padLeft(2, '0')}'),
          if (request.preferredTime != null)
            _buildDetailSection('희망 시간', request.preferredTime!),
          if (request.contactInfo != null)
            _buildDetailSection('연락처', request.contactInfo!),
          if (request.address != null)
            _buildDetailSection('주소', request.address!),
          if (request.latitude != null && request.longitude != null)
            _buildDetailSection(
                '좌표',
                '${request.latitude!.toStringAsFixed(6)}, ${request.longitude!.toStringAsFixed(6)}'),
          if (request.member != null)
            _buildDetailSection('신청자', request.member!.name),
          if (request.member?.phone != null)
            _buildDetailSection('신청자 연락처', request.member!.phone),
          _buildDetailSection('신청일', _formatDetailDate(request.createdAt)),
          if (request.updatedAt != null &&
              request.updatedAt != request.createdAt)
            _buildDetailSection('수정일', _formatDetailDate(request.updatedAt!)),
          _buildDetailSection('담당자', assignedPastorName ?? '미지정'),
          if (request.completedAt != null)
            _buildDetailSection('완료일', _formatDetailDate(request.completedAt!)),
          if (request.adminNotes != null && request.adminNotes!.isNotEmpty)
            _buildDetailSection('관리자 메모', request.adminNotes!),
          if (request.latitude != null && request.longitude != null) ...[
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                _showLocationOnMap(
                    request.latitude!, request.longitude!, request.address);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 13.h),
                decoration: BoxDecoration(
                  color: NewAppColor.skyTint,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.map,
                        size: 16.sp, color: NewAppColor.skyDeep),
                    SizedBox(width: 7.w),
                    Text(
                      '지도에서 위치 보기',
                      style: TextStyle(
                        color: NewAppColor.skyDeep,
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 위치를 지도에서 보기 — AppMenuSheet 헬퍼 사용
  void _showLocationOnMap(double latitude, double longitude, String? address) {
    final links = _generateMapLinks(latitude, longitude);
    AppMenuSheet.show(
      context: context,
      items: [
        AppMenuItem(
          icon: LucideIcons.map,
          label: '네이버 지도에서 보기',
          onTap: () => _openMapLink(links['naver']!),
        ),
        AppMenuItem(
          icon: LucideIcons.globe,
          label: '구글 지도에서 보기',
          onTap: () => _openMapLink(links['google']!),
        ),
      ],
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
}
