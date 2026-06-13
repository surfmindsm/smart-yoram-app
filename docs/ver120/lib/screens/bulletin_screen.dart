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
  String? selectedYear; // 선택된 연도 (null이면 전체)

  @override
  void initState() {
    super.initState();
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
      bool matchesSearch = query.isEmpty ||
          bulletin.title.toLowerCase().contains(query) ||
          (bulletin.description?.toLowerCase().contains(query) ?? false);

      // 연도 필터링
      bool matchesYear = selectedYear == null ||
          bulletin.date.year.toString() == selectedYear;

      return matchesSearch && matchesYear;
    }).toList();
  }

  // 사용 가능한 연도 목록 가져오기
  List<String> _getAvailableYears() {
    if (allBulletins.isEmpty) return [];

    final years = allBulletins.map((b) => b.date.year.toString()).toSet().toList();
    years.sort((a, b) => b.compareTo(a)); // 최신 연도부터
    return years;
  }

  void _filterBulletins() {
    setState(() {
      _filterBullettinsWithoutSetState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final availableYears = _getAvailableYears();

    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 상단 패딩 - showTopPadding이 true일 때만 적용
          if (widget.showTopPadding)
            SizedBox(height: MediaQuery.of(context).padding.top + 10.h),

          SizedBox(height: 12.h),

          // 연도 필터
          if (availableYears.isNotEmpty) _buildYearFilter(availableYears),

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

  Widget _buildYearFilter(List<String> years) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedYear,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: NewAppColor.neutral700,
                ),
                isDense: true,
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      '전체',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: NewAppColor.neutral900,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ),
                  ...years.map((year) {
                    return DropdownMenuItem<String?>(
                      value: year,
                      child: Text(
                        '${year}년',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: NewAppColor.neutral900,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                    _filterBulletins();
                  });
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
}
