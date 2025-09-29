import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/index.dart';
import '../resource/color_style.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../models/bulletin.dart';
import '../models/file_type.dart';
import '../services/bulletin_service.dart';
import 'bulletin_fullscreen_viewer.dart';

class BulletinScreen extends StatefulWidget {
  const BulletinScreen({super.key});

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

  // 드롭다운 열림 상태
  bool isYearDropdownOpen = false;
  bool isMonthDropdownOpen = false;

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
      body: GestureDetector(
        onTap: () {
          // 드롭다운이 열려있으면 닫기
          if (isYearDropdownOpen || isMonthDropdownOpen) {
            setState(() {
              isYearDropdownOpen = false;
              isMonthDropdownOpen = false;
            });
          }
        },
        child: Stack(
          children: [
            // 메인 콘텐츠
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 10.h),

                // 검색 및 필터 헤더
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      // 검색 텍스트
                      Text(
                        '주보를 검색해 보세요',
                        style: const FigmaTextStyles().body1.copyWith(
                              color: NewAppColor.neutral900,
                            ),
                      ),
                      const Spacer(),
                      // 연도 드롭다운 (버튼만)
                      _buildDropdownButton(
                        value: selectedYear == 0 ? '전체' : '${selectedYear}년',
                        width: 80.w,
                        isOpen: isYearDropdownOpen,
                        onTap: () => _toggleYearDropdown(),
                      ),
                      SizedBox(width: 4.w),
                      // 월 드롭다운 (버튼만)
                      _buildDropdownButton(
                        value: selectedMonth == 0 ? '전체' : monthNames[selectedMonth],
                        width: 80.w,
                        isOpen: isMonthDropdownOpen,
                        onTap: () => _toggleMonthDropdown(),
                      ),
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(NewAppColor.primary500),
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

            // 드롭다운 오버레이들 (최상위 레이어)
            if (isYearDropdownOpen)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10.h + 32.h,
                right: 20.w + 80.w + 4.w,
                child: _buildDropdownList(
                  width: 80.w,
                  items: availableYears,
                  selectedValue: selectedYear,
                  onSelect: (year) => _selectYear(year),
                  isYear: true,
                ),
              ),
            if (isMonthDropdownOpen)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10.h + 32.h,
                right: 20.w,
                child: _buildDropdownList(
                  width: 80.w,
                  items: availableMonths,
                  selectedValue: selectedMonth,
                  onSelect: (month) => _selectMonth(month),
                  isYear: false,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletinCard(Bulletin bulletin) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        border: Border(
          bottom: BorderSide(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목만 표시
          Text(
            bulletin.title,
            style: const FigmaTextStyles().title3.copyWith(
                  color: Colors.black,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),

          // 미리보기 이미지
          GestureDetector(
            onTap: () => _navigateToFullscreen(bulletin),
            child: Container(
              height: 180.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // 미리보기 콘텐츠
                  Positioned.fill(
                    child: _buildPreviewWidget(bulletin),
                  ),
                  // 어두운 오버레이
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  // 페이지 수 표시
                  Positioned(
                    bottom: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 0.h,
                      ),
                      height: 20.h,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Center(
                        child: Text(
                          '+1',
                          style: const FigmaTextStyles().caption3.copyWith(
                                color: NewAppColor.neutral100,
                              ),
                        ),
                      ),
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          '주보 검색',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColor.secondary07,
          ),
        ),
        content: AppInput(
          controller: _searchController,
          placeholder: '검색어를 입력하세요',
          prefixIcon: Icons.search,
        ),
        actions: [
          AppButton(
            text: '취소',
            variant: ButtonVariant.ghost,
            size: ButtonSize.sm,
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
            },
          ),
          AppButton(
            text: '검색',
            size: ButtonSize.sm,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _navigateToFullscreen(Bulletin bulletin) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BulletinFullscreenViewer(
          bulletin: bulletin,
          localPath: null, // 초기에는 null로 설정
          fileType: _getFileType(bulletin.fileUrl),
        ),
      ),
    );
  }

  // FileType 반환
  FileType _getFileType(String? fileUrl) {
    final result = FileTypeHelper.getFileType(fileUrl);
    print('파일 타입 판단: $fileUrl -> $result');
    return result;
  }

  // 미리보기 위젯 빌드
  Widget _buildPreviewWidget(Bulletin bulletin) {
    print('미리보기 위젯 빌드 - fileUrl: ${bulletin.fileUrl}');

    if (bulletin.fileUrl == null || bulletin.fileUrl!.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8.h),
            Text(
              '미리보기 없음',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // 이미지 파일인 경우
    if (_isImageFile(bulletin.fileUrl!)) {
      print('이미지 파일로 인식됨: ${bulletin.fileUrl}');
      return CachedNetworkImage(
        imageUrl: bulletin.fileUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[400],
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          print('이미지 로드 오류: $error, URL: $url');
          return Container(
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 48.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8.h),
                Text(
                  '이미지 로드 실패',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '$error',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.red[400],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      );
    }

    // PDF 파일인 경우 - 첫 페이지 미리보기
    print('PDF 파일로 인식됨: ${bulletin.fileUrl}');
    return _buildPdfPreview(bulletin.fileUrl!);
  }

  // PDF 첫 페이지 미리보기 렌더링
  Widget _buildPdfPreview(String pdfUrl) {
    final cleanedUrl = FileTypeHelper.cleanUrl(pdfUrl);

    return Container(
      width: double.infinity,
      height: 260.h, // 미리보기 높이 제한
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SfPdfViewer.network(
          cleanedUrl,
          pageLayoutMode: PdfPageLayoutMode.single,
          scrollDirection: PdfScrollDirection.horizontal,
          enableDoubleTapZooming: false,
          enableTextSelection: false,
          canShowScrollHead: false,
          canShowScrollStatus: false,
          canShowPaginationDialog: false,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            print('PDF 로드 실패: ${details.error}');
          },
        ),
      ),
    );
  }

  // 파일 타입 확인
  bool _isImageFile(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.endsWith('.jpg') ||
        lowercaseUrl.endsWith('.jpeg') ||
        lowercaseUrl.endsWith('.png') ||
        lowercaseUrl.endsWith('.gif') ||
        lowercaseUrl.endsWith('.webp');
  }

  // 파일 타입 아이콘 반환
  IconData _getFileTypeIcon(String? fileUrl) {
    if (fileUrl == null) return Icons.description;

    if (_isImageFile(fileUrl)) {
      return Icons.image;
    } else {
      return Icons.description;
    }
  }

  // 파일 타입 텍스트 반환
  String _getFileTypeText(String? fileUrl) {
    if (fileUrl == null) return 'FILE';

    if (_isImageFile(fileUrl)) {
      return 'IMAGE';
    } else {
      return 'PDF';
    }
  }

  Future<void> _downloadBulletin(Bulletin bulletin) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${bulletin.title} 다운로드 중...'),
          action: SnackBarAction(
            label: '취소',
            onPressed: () {},
          ),
        ),
      );

      final response =
          await _bulletinService.downloadBulletin(bulletin.id);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${bulletin.title} 다운로드 완료')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('다운로드 실패: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('다운로드 실패: $e')),
        );
      }
    }
  }

  // 드롭다운 버튼만 (오버레이 없음)
  Widget _buildDropdownButton({
    required String value,
    required double width,
    required bool isOpen,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 32.h,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isOpen
            ? BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              )
            : BorderRadius.circular(8.r),
          border: Border.all(
            color: NewAppColor.neutral100,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: const FigmaTextStyles().caption1.copyWith(
                    color: NewAppColor.neutral800,
                  ),
            ),
            Icon(
              isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 12.sp,
              color: NewAppColor.neutral800,
            ),
          ],
        ),
      ),
    );
  }

  // 드롭다운 리스트만 (최상위 레이어용)
  Widget _buildDropdownList({
    required double width,
    required List<int> items,
    required int selectedValue,
    required Function(int) onSelect,
    required bool isYear,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(8.r),
        bottomRight: Radius.circular(8.r),
      ),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(8.r),
            bottomRight: Radius.circular(8.r),
          ),
          border: const Border(
            left: BorderSide(color: NewAppColor.neutral100, width: 1),
            right: BorderSide(color: NewAppColor.neutral100, width: 1),
            bottom: BorderSide(color: NewAppColor.neutral100, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: items.map((item) {
            final isSelected = isYear ? item == selectedValue : item == selectedValue;
            final isLast = item == items.last;

            return GestureDetector(
              onTap: () => onSelect(item),
              child: Container(
                width: double.infinity,
                height: 32.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: isSelected ? NewAppColor.primary500 : Colors.white,
                  borderRadius: isLast
                    ? BorderRadius.only(
                        bottomLeft: Radius.circular(8.r),
                        bottomRight: Radius.circular(8.r),
                      )
                    : BorderRadius.zero,
                  border: Border(
                    bottom: isLast ? BorderSide.none : const BorderSide(color: NewAppColor.neutral100, width: 1),
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isYear
                      ? (item == 0 ? '전체' : '$item년')
                      : (item < monthNames.length ? monthNames[item] : '오류($item)'),
                    style: const FigmaTextStyles().caption1.copyWith(
                      color: isSelected ? Colors.white : NewAppColor.neutral800,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 드롭다운 토글 메서드들
  void _toggleYearDropdown() {
    setState(() {
      isYearDropdownOpen = !isYearDropdownOpen;
      if (isYearDropdownOpen) {
        isMonthDropdownOpen = false; // 다른 드롭다운 닫기
      }
    });
    // print('Year dropdown open: $isYearDropdownOpen'); // 디버깅
  }

  void _toggleMonthDropdown() {
    setState(() {
      isMonthDropdownOpen = !isMonthDropdownOpen;
      if (isMonthDropdownOpen) {
        isYearDropdownOpen = false; // 다른 드롭다운 닫기
      }
    });
  }

  // 선택 메서드들
  void _selectYear(int year) {
    setState(() {
      selectedYear = year;
      isYearDropdownOpen = false;
    });
    _filterBulletins();
  }

  void _selectMonth(int month) {
    setState(() {
      selectedMonth = month;
      isMonthDropdownOpen = false;
    });
    _filterBulletins();
  }
}
