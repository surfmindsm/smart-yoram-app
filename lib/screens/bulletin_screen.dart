import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../models/bulletin.dart';
import '../models/file_type.dart';
import '../services/bulletin_service.dart';
import 'bulletin_fullscreen_viewer.dart';

class BulletinScreen extends StatefulWidget {
  final bool showTopPadding;

  const BulletinScreen({
    super.key,
    this.showTopPadding = true, // 기본값은 true (독립 화면일 때)
  });

  @override
  State<BulletinScreen> createState() => _BulletinScreenState();
}

class _BulletinScreenState extends State<BulletinScreen> {
  final BulletinService _bulletinService = BulletinService();
  final TextEditingController _searchController = TextEditingController();

  List<Bulletin> allBulletins = [];
  List<Bulletin> filteredBulletins = [];
  bool isLoading = true;

  // 필터링 변수 (0은 전체를 의미)
  int selectedYear = 0; // 전체로 초기화
  int selectedMonth = 0; // 전체로 초기화

  // PopupMenuButton을 위한 GlobalKey는 필요없음

  // 연도 목록 (과거 5년 + 현재년도, 미래 없음)
  late List<int> availableYears;

  // 월 목록 (0은 전체, 1-12는 실제 월)
  final List<int> availableMonths = [
    0,
    ...List.generate(12, (index) => index + 1)
  ];

  final List<String> monthNames = [
    '전체', // 0
    '1월', // 1
    '2월', // 2
    '3월', // 3
    '4월', // 4
    '5월', // 5
    '6월', // 6
    '7월', // 7
    '8월', // 8
    '9월', // 9
    '10월', // 10
    '11월', // 11
    '12월', // 12
  ];

  @override
  void initState() {
    super.initState();
    // 연도 목록 초기화 (전체 + 과거 5년 + 현재년도, 미래 없음)
    int currentYear = DateTime.now().year;
    availableYears = [
      0,
      ...List.generate(6, (index) => currentYear - 5 + index)
    ];

    // 디버깅: 배열 크기 확인
    print('📰 BULLETIN_SCREEN: availableMonths 배열: $availableMonths');
    print('📰 BULLETIN_SCREEN: monthNames 배열 크기: ${monthNames.length}');
    print('📰 BULLETIN_SCREEN: monthNames 배열: $monthNames');

    print('📰 BULLETIN_SCREEN: initState 시작 - 주보 화면 진입');
    print(
        '📰 BULLETIN_SCREEN: BulletinService 인스턴스: ${_bulletinService.toString()}');
    print('📰 BULLETIN_SCREEN: 검색 컨트롤러 설정');
    _searchController.addListener(_filterBulletins);
    print('📰 BULLETIN_SCREEN: _loadBulletins 호출 예정');
    _loadBulletins();
    print('📰 BULLETIN_SCREEN: initState 완료');
  }

  @override
  void dispose() {
    print('📰 BULLETIN_SCREEN: dispose 시작 - 주보 화면 종료');
    _searchController.dispose();
    super.dispose();
    print('📰 BULLETIN_SCREEN: dispose 완료');
  }

  Future<void> _loadBulletins() async {
    print('📰 BULLETIN_SCREEN: =================');
    print('📰 BULLETIN_SCREEN: _loadBulletins 시작');
    print('📰 BULLETIN_SCREEN: 현재 상태 - isLoading: $isLoading');
    print('📰 BULLETIN_SCREEN: 현재 주보 수 - allBulletins: ${allBulletins.length}');

    setState(() {
      isLoading = true;
      print('📰 BULLETIN_SCREEN: 로딩 상태를 true로 변경');
    });

    try {
      print('📰 BULLETIN_SCREEN: BulletinService.getBulletins 호출 시작');
      print('📰 BULLETIN_SCREEN: 요청 파라미터 - limit: 50');

      final response = await _bulletinService.getBulletins(limit: 50);

      print('📰 BULLETIN_SCREEN: BulletinService 응답 받음');
      print('📰 BULLETIN_SCREEN: 응답 success: ${response.success}');
      print('📰 BULLETIN_SCREEN: 응답 message: "${response.message}"');
      print('📰 BULLETIN_SCREEN: 응답 data null 여부: ${response.data == null}');

      if (response.success && response.data != null) {
        final dataLength = response.data!.length;
        print('📰 BULLETIN_SCREEN: 성공! 받은 주보 데이터 수: $dataLength');

        if (dataLength > 0) {
          print('📰 BULLETIN_SCREEN: 주보 상세 정보:');
          for (int i = 0; i < dataLength; i++) {
            final bulletin = response.data![i];
            print(
                '📰 BULLETIN_SCREEN: [$i] ID=${bulletin.id}, 제목="${bulletin.title}"');
            print(
                '📰 BULLETIN_SCREEN: [$i] 날짜=${bulletin.date}, 설명="${bulletin.description}"');
          }
        } else {
          print('📰 BULLETIN_SCREEN: 응답은 성공이지만 주보 데이터가 비어있음');
        }

        print(
            '📰 BULLETIN_SCREEN: allBulletins 업데이트 (${allBulletins.length} → $dataLength)');
        allBulletins = response.data!;
        print('📰 BULLETIN_SCREEN: filteredBulletins 업데이트 - 필터링 적용');
        // 초기 로딩 시에도 필터링 적용
        _filterBullettinsWithoutSetState();

        print(
            '📰 BULLETIN_SCREEN: 최종 상태 - allBulletins: ${allBulletins.length}, filtered: ${filteredBulletins.length}');
      } else {
        print('📰 BULLETIN_SCREEN: ❌ API 호출 실패 또는 null 데이터');
        print('📰 BULLETIN_SCREEN: 실패 세부사항:');
        print('📰 BULLETIN_SCREEN: - success: ${response.success}');
        print('📰 BULLETIN_SCREEN: - data == null: ${response.data == null}');
        print('📰 BULLETIN_SCREEN: - message: "${response.message}"');

        allBulletins = [];
        filteredBulletins = [];
        print('📰 BULLETIN_SCREEN: 빈 목록으로 초기화');

        if (mounted) {
          print('📰 BULLETIN_SCREEN: 사용자에게 오류 메시지 표시');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('주보 정보 로드 실패: ${response.message}')),
          );
        }
      }

      print('📰 BULLETIN_SCREEN: setState로 화면 갱신 준비');
      setState(() {
        isLoading = false;
        print('📰 BULLETIN_SCREEN: 로딩 상태를 false로 변경 완료');
      });
    } catch (e, stackTrace) {
      print('📰 BULLETIN_SCREEN: ❌ 예외 발생!');
      print('📰 BULLETIN_SCREEN: 예외 메시지: $e');
      print('📰 BULLETIN_SCREEN: 스택 트레이스: $stackTrace');

      setState(() => isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주보 정보 로드 실패: $e')),
        );
      }
    }

    print('📰 BULLETIN_SCREEN: _loadBulletins 완료');
    print('📰 BULLETIN_SCREEN: =================');
  }

  // setState 없이 필터링하는 메서드 (초기 로딩 시 사용)
  void _filterBullettinsWithoutSetState() {
    String query = _searchController.text.toLowerCase();

    filteredBulletins = allBulletins.where((bulletin) {
      // 검색어 필터링
      bool matchesQuery = query.isEmpty ||
          bulletin.title.toLowerCase().contains(query) ||
          (bulletin.description?.toLowerCase().contains(query) ?? false);

      // 날짜 필터링
      bool matchesDate = true;
      // 0은 전체를 의미하므로 필터링 제외
      if (selectedYear != 0) {
        matchesDate = matchesDate && (bulletin.date.year == selectedYear);
      }
      if (selectedMonth != 0) {
        matchesDate = matchesDate && (bulletin.date.month == selectedMonth);
      }

      return matchesQuery && matchesDate;
    }).toList();
  }

  void _filterBulletins() {
    setState(() {
      _filterBullettinsWithoutSetState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 상단 패딩 - showTopPadding이 true일 때만 적용
          if (widget.showTopPadding)
            SizedBox(height: MediaQuery.of(context).padding.top + 10.h),

          // 검색 및 필터 헤더
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                // 검색 텍스트
                // Text(
                //   '주보를 검색해 보세요',
                //   style: const FigmaTextStyles().body1.copyWith(
                //         color: NewAppColor.neutral900,
                //       ),
                // ),
                const Spacer(),
                // 연도 드롭다운
                _buildYearDropdown(),
                SizedBox(width: 4.w),
                // 월 드롭다운
                _buildMonthDropdown(),
              ],
            ),
          ),
          SizedBox(height: 24.h),

          // 주보 목록
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              NewAppColor.primary500),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '주보를 불러오는 중...',
                          style: const FigmaTextStyles().body1.copyWith(
                                color: NewAppColor.neutral600,
                              ),
                        ),
                      ],
                    ),
                  )
                : filteredBulletins.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description,
                              size: 64.sp,
                              color: NewAppColor.neutral400,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              '주보가 없습니다',
                              style: const FigmaTextStyles().title3.copyWith(
                                    color: NewAppColor.neutral600,
                                  ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '아직 등록된 주보가 없습니다',
                              style: const FigmaTextStyles().caption1.copyWith(
                                    color: NewAppColor.neutral600,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBulletins,
                        color: NewAppColor.primary500,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          itemCount: filteredBulletins.length,
                          itemBuilder: (context, index) {
                            final bulletin = filteredBulletins[index];
                            return _buildBulletinCard(bulletin);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletinCard(Bulletin bulletin) {
    return GestureDetector(
      onTap: () => _navigateToFullscreen(bulletin),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // 제목
            Expanded(
              child: Text(
                bulletin.title,
                style: const FigmaTextStyles().title3.copyWith(
                      color: NewAppColor.neutral900,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 12.w),
            // 오른쪽 화살표 아이콘
            Icon(
              Icons.chevron_right,
              size: 24.sp,
              color: NewAppColor.neutral400,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFullscreen(Bulletin bulletin) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulletinFullscreenViewer(
          bulletin: bulletin,
          localPath: null,
          fileType: FileTypeHelper.getFileType(bulletin.fileUrl),
        ),
      ),
    );
  }

  // 연도 드롭다운
  Widget _buildYearDropdown() {
    return PopupMenuButton<int>(
      offset: Offset(0, 8.h),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      onSelected: (year) {
        setState(() {
          selectedYear = year;
        });
        _filterBulletins();
      },
      itemBuilder: (context) {
        return availableYears.map((year) {
          final isSelected = year == selectedYear;
          return PopupMenuItem<int>(
            value: year,
            height: 32.h,
            child: Container(
              width: 64.w,
              child: Text(
                year == 0 ? '전체' : '$year년',
                style: const FigmaTextStyles().caption1.copyWith(
                      color: isSelected
                          ? NewAppColor.primary600
                          : NewAppColor.neutral800,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        width: 80.w,
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: NewAppColor.neutral100,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedYear == 0 ? '전체' : '$selectedYear년',
              style: const FigmaTextStyles().caption1.copyWith(
                    color: NewAppColor.neutral800,
                  ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 12.sp,
              color: NewAppColor.neutral800,
            ),
          ],
        ),
      ),
    );
  }

  // 월 드롭다운
  Widget _buildMonthDropdown() {
    return PopupMenuButton<int>(
      offset: Offset(0, 8.h),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      onSelected: (month) {
        setState(() {
          selectedMonth = month;
        });
        _filterBulletins();
      },
      itemBuilder: (context) {
        return availableMonths.map((month) {
          final isSelected = month == selectedMonth;
          return PopupMenuItem<int>(
            value: month,
            height: 32.h,
            child: Container(
              width: 64.w,
              child: Text(
                monthNames[month],
                style: const FigmaTextStyles().caption1.copyWith(
                      color: isSelected
                          ? NewAppColor.primary600
                          : NewAppColor.neutral800,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        width: 80.w,
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: NewAppColor.neutral100,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              monthNames[selectedMonth],
              style: const FigmaTextStyles().caption1.copyWith(
                    color: NewAppColor.neutral800,
                  ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 12.sp,
              color: NewAppColor.neutral800,
            ),
          ],
        ),
      ),
    );
  }
}
