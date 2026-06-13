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

  // 1.2.0 C 방향: 연도 칩 row + 날짜 칩 카드
  // ⚠️ Scaffold를 쓰지 않는 이유: 부모(BulletinNoticesIntegratedScreen)가 이미 Scaffold라
  // 중첩되면 TabBarView 자식의 hit-test가 막힘. Container로 단순화한다.
  @override
  Widget build(BuildContext context) {
    final availableYears = _getAvailableYears();

    return Container(
      color: NewAppColor.canvasAlt,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // 직접 진입 시 상단 패딩만 적용 (통합 화면 안에서는 이미 흰 헤더가 있음)
          if (widget.showTopPadding)
            SizedBox(height: MediaQuery.of(context).padding.top + 10.h),
          // 연도 칩 row
          if (availableYears.isNotEmpty) _buildYearChipRow(availableYears),
          // 주보 목록
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              NewAppColor.skyPrimary),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '주보를 불러오는 중...',
                          style: FigmaTextStyles().body2.copyWith(
                                color: NewAppColor.textMuted,
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
                              Icons.menu_book_outlined,
                              size: 56.sp,
                              color: NewAppColor.iconFaint,
                            ),
                            SizedBox(height: 14.h),
                            Text(
                              '주보가 없습니다',
                              style: FigmaTextStyles().subtitle2.copyWith(
                                    color: NewAppColor.textSecondary,
                                  ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              '아직 등록된 주보가 없습니다',
                              style: FigmaTextStyles().caption1.copyWith(
                                    color: NewAppColor.textMuted,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBulletins,
                        color: NewAppColor.skyPrimary,
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 18.h),
                          itemCount: filteredBulletins.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final bulletin = filteredBulletins[index];
                            // 첫 번째(가장 최근) 주보에 '이번 주' 배지 — 단, 연도/검색 필터 미적용 상태에서만
                            final isThisWeek = index == 0 &&
                                selectedYear == null &&
                                _searchController.text.isEmpty;
                            return _buildBulletinCard(bulletin,
                                isThisWeek: isThisWeek);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // 1.2.0: 가로 스크롤 연도 칩 (전체/2025년/2024년)
  Widget _buildYearChipRow(List<String> years) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 2.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _yearChip(label: '전체', value: null),
            ...years.map((year) => _yearChip(label: '$year년', value: year)),
          ],
        ),
      ),
    );
  }

  Widget _yearChip({required String label, required String? value}) {
    final isSelected = selectedYear == value;
    return Padding(
      padding: EdgeInsets.only(right: 7.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedYear = value;
              _filterBullettinsWithoutSetState();
            });
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isSelected ? NewAppColor.skyPrimary : Colors.white,
              border: isSelected
                  ? null
                  : Border.all(color: NewAppColor.borderStrong, width: 1),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: FigmaTextStyles().caption2.copyWith(
                    color: isSelected
                        ? Colors.white
                        : NewAppColor.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5.sp,
                  ),
            ),
          ),
        ),
      ),
    );
  }

  // 1.2.0: 46×46 스카이 날짜 칩 + 절기/예배명 + '이번 주' 배지 + chevron
  Widget _buildBulletinCard(Bulletin bulletin, {required bool isThisWeek}) {
    final year = bulletin.date.year;
    return InkWell(
      onTap: () => _navigateToFullscreen(bulletin),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: NewAppColor.borderHair, width: 1),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 날짜 칩 — 46×46 라운드 13 skyTint
            Container(
              width: 46.w,
              height: 46.h,
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                borderRadius: BorderRadius.circular(13.r),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${bulletin.date.month}월',
                    style: TextStyle(
                      color: NewAppColor.skyDeep,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${bulletin.date.day}',
                    style: TextStyle(
                      color: NewAppColor.skyDeep,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 13.w),
            // 제목 + 부제
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bulletin.title,
                          style: FigmaTextStyles().cardTitleSm.copyWith(
                                color: NewAppColor.textStrong,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isThisWeek) ...[
                        SizedBox(width: 7.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 7.w, vertical: 1.h),
                          decoration: BoxDecoration(
                            color: NewAppColor.skyTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '이번 주',
                            style: FigmaTextStyles().badgeSm.copyWith(
                                  color: NewAppColor.skyDeep,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    // 설명(content) 있으면 우선, 없으면 기본 부제
                    (bulletin.description != null &&
                            bulletin.description!.isNotEmpty)
                        ? '${bulletin.description} · $year'
                        : '주보 · $year',
                    style: FigmaTextStyles().caption2.copyWith(
                          color: NewAppColor.textTertiary,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.chevron_right,
              size: 18.sp,
              color: NewAppColor.iconFaint,
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
