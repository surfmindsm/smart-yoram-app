import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../components/index.dart';
import '../resource/color_style.dart';
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
      backgroundColor: AppColor.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10.h),

          // 필터 헤더
          AppCard(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary7,
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 연도 드롭다운
                      AppDropdown<int>(
                        placeholder: '연도',
                        value: selectedYear,
                        width: 80.w,
                        height: 36.h,
                        items: availableYears.map((year) {
                          return AppDropdownMenuItem<int>(
                            value: year,
                            text: year == 0 ? '전체' : '${year}년',
                          );
                        }).toList(),
                        onChanged: (int? newYear) {
                          if (newYear != null) {
                            setState(() {
                              selectedYear = newYear;
                            });
                            _filterBulletins();
                          }
                        },
                      ),
                      SizedBox(width: 4.w),
                      // 월 드롭다운
                      AppDropdown<int>(
                        placeholder: '월',
                        value: selectedMonth,
                        width: 80.w,
                        height: 36.h,
                        items: availableMonths.map((month) {
                          return AppDropdownMenuItem<int>(
                            value: month,
                            text: month < monthNames.length
                                ? monthNames[month]
                                : '오류(${month})',
                          );
                        }).toList(),
                        onChanged: (int? newMonth) {
                          if (newMonth != null) {
                            setState(() {
                              selectedMonth = newMonth;
                            });
                            _filterBulletins();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 주보 목록
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColor.primary7),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          '주보를 불러오는 중...',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: AppColor.secondary06,
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
                              Icons.description_outlined,
                              size: 64.sp,
                              color: AppColor.secondary04,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              '주보가 없습니다',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColor.secondary06,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '아직 등록된 주보가 없습니다',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColor.secondary05,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBulletins,
                        color: AppColor.primary7,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
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
    return AppCard(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      variant: CardVariant.elevated,
      onTap: () => _navigateToFullscreen(bulletin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 미리보기 영역
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              topRight: Radius.circular(12.r),
            ),
            child: Container(
              height: 200.h,
              width: double.infinity,
              color: AppColor.secondary00,
              child: Stack(
                children: [
                  // 미리보기 콘텐츠
                  Positioned.fill(
                    child: _buildPreviewWidget(bulletin),
                  ),
                  // 오버레이
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 전체화면 아이콘
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Icon(
                        Icons.fullscreen,
                        color: AppColor.secondary07,
                        size: 16.sp,
                      ),
                    ),
                  ),
                  // 파일 타입 배지
                  Positioned(
                    bottom: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getFileTypeIcon(bulletin.fileUrl),
                            size: 14.sp,
                            color: AppColor.secondary06,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _getFileTypeText(bulletin.fileUrl),
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColor.secondary06,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 콘텐츠 영역
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  bulletin.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.secondary07,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),

                // 날짜 정보
                Text(
                  _formatDate(bulletin.createdAt),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColor.secondary05,
                  ),
                ),

                // 파일 크기 정보
                if (bulletin.fileSize != null && bulletin.fileSize! > 0) ...[
                  SizedBox(height: 4.h),
                  Text(
                    '파일 크기: ${_formatFileSize(bulletin.fileSize!)}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColor.secondary04,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}.${date.day}';
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
              Icons.description_outlined,
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
                  Icons.broken_image_outlined,
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
    if (fileUrl == null) return Icons.description_outlined;

    if (_isImageFile(fileUrl)) {
      return Icons.image_outlined;
    } else {
      return Icons.picture_as_pdf_outlined;
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
          await _bulletinService.downloadBulletin(bulletin.id.toString());

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
}
