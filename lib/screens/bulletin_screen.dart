import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pdfx/pdfx.dart';
import 'package:smart_yoram_app/resource/text_style.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/bulletin.dart';
import '../services/bulletin_service.dart';
import '../widget/widgets.dart';
import 'bulletin_fullscreen_viewer.dart';
import 'bulletin_modal.dart' show FileType;

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
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 5.h),

          // 연도/월 필터 헤더
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppColor.transparent,
              border: Border(
                bottom: BorderSide(
                    color: AppColor.secondary02.withOpacity(0.3), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Row(
                  children: [
                    // 연도 드롭다운
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColor.secondary02),
                        borderRadius: BorderRadius.circular(8.r),
                        color: AppColor.white,
                      ),
                      child: DropdownButton2<int>(
                        value: selectedYear,
                        hint: Text('연도 선택'),
                        items: availableYears.map((year) {
                          return DropdownMenuItem<int>(
                            value: year,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0.w),
                              child: Text(
                                year == 0 ? '전체' : '${year}년',
                                style: AppTextStyle(
                                  color: AppColor.secondary06,
                                ).buttonLarge(),
                              ),
                            ),
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
                        iconStyleData: IconStyleData(
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20.sp,
                            color: AppColor.secondary06,
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            color: AppColor.white.withOpacity(0.8),
                            border: Border.all(
                              color: AppColor.secondary02,
                              width: 0,
                            ),
                            // boxShadow: [
                            //   BoxShadow(
                            //     color: AppColor.secondary02.withOpacity(0.1),
                            //     blurRadius: 4,
                            //     offset: Offset(0, 2),
                            //   ),
                            // ],
                          ),
                          elevation: 0,
                          maxHeight: 260.h,
                        ),
                        menuItemStyleData: MenuItemStyleData(
                          height: 40.h,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // 월 드롭다운
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColor.secondary02),
                        borderRadius: BorderRadius.circular(8.r),
                        color: AppColor.white,
                      ),
                      child: DropdownButton2<int>(
                        value: selectedMonth,
                        hint: Text('월 선택'),
                        style: AppTextStyle(
                          color: AppColor.secondary06,
                        ).buttonLarge(),
                        items: availableMonths.map((month) {
                          return DropdownMenuItem<int>(
                            value: month,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 0.w),
                              child: Text(
                                month < monthNames.length
                                    ? monthNames[month]
                                    : '오류(${month})',
                                style: AppTextStyle(
                                  color: AppColor.secondary06,
                                ).buttonLarge(),
                              ),
                            ),
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
                        iconStyleData: IconStyleData(
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20.sp,
                            color: AppColor.secondary06,
                          ),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            color: AppColor.white.withOpacity(0.8),
                            border: Border.all(
                              color: AppColor.secondary02,
                              width: 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColor.secondary02.withOpacity(0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          elevation: 0,
                          maxHeight: 260.h,
                        ),
                        menuItemStyleData: MenuItemStyleData(
                          height: 40.h,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 주보 목록
          Expanded(
            child: isLoading
                ? const LoadingWidget()
                : filteredBulletins.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.description_outlined,
                        title: '주보가 없습니다',
                        subtitle: '아직 등록된 주보가 없습니다',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBulletins,
                        child: ListView.builder(
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
      // floatingActionButton: FloatingActionButton(
      //   heroTag: "bulletin_fab",
      //   onPressed: _showAddBulletinDialog,
      //   backgroundColor: Colors.blue[700],
      //   child: const Icon(Icons.add, color: Colors.white),
      // ),
    );
  }

  Widget _buildBulletinCard(Bulletin bulletin) {
    return Card(
      color: AppColor.white,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _navigateToFullscreen(bulletin),
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 미리보기 영역
            Container(
              height: 250.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12.r),
                  topRight: Radius.circular(12.r),
                ),
                color: Colors.grey[100],
              ),
              child: Stack(
                children: [
                  // 미리보기 이미지/PDF
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12.r),
                      topRight: Radius.circular(12.r),
                    ),
                    child: _buildPreviewWidget(bulletin),
                  ),
                  // 그라디언트 오버레이 (가독성을 위해)
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
                            Colors.black.withOpacity(0.3)
                          ]
                        )
                      ),
                    ),
                  ),
                  // 전체화면 아이콘
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColor.secondary07.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 18.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 콘텐츠 영역
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목과 날짜
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          bulletin.title,
                          style: AppTextStyle(
                            color: AppColor.secondary06,
                          ).h2(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ],
        ),
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
        title: const Text('주보 검색'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '검색어를 입력하세요',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('검색'),
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
    return FutureBuilder<Widget>(
      future: _buildPdfPreview(bulletin.fileUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 8.h),
                Text(
                  'PDF 미리보기 로딩 중...',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print('PDF 미리보기 오류: ${snapshot.error}');
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 48.sp,
                  color: Colors.red[300],
                ),
                SizedBox(height: 8.h),
                Text(
                  'PDF 파일',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '터치하여 보기',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return snapshot.data ??
            Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 48.sp,
                  color: Colors.red[300],
                ),
              ),
            );
      },
    );
  }

  // PDF 첫 페이지 미리보기 빌드
  Future<Widget> _buildPdfPreview(String pdfUrl) async {
    try {
      print('PDF 미리보기 시작: $pdfUrl');

      // PDF 파일 다운로드
      final response = await HttpClient().getUrl(Uri.parse(pdfUrl));
      final request = await response.close();
      final bytes = await request
          .fold<List<int>>(<int>[], (prev, element) => prev..addAll(element));
      final pdfData = Uint8List.fromList(bytes);

      print('PDF 데이터 다운로드 완료: ${pdfData.length} bytes');

      // PDF 문서 열기
      final document = await PdfDocument.openData(pdfData);
      final page = await document.getPage(1); // 첫 번째 페이지

      print('PDF 첫 페이지 로드 완료');

      // 페이지를 이미지로 렌더링 (미리보기용 크기)
      final pageImage = await page.render(
        width: 300, // 미리보기용 작은 크기
        height: 400,
        format: PdfPageImageFormat.png,
      );

      print('PDF 페이지 렌더링 완료');

      // 리소스 정리
      page.close();
      document.close();

      // 이미진쇄 위젯 반환
      if (pageImage != null && pageImage.bytes.isNotEmpty) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Image.memory(
            pageImage.bytes,
            fit: BoxFit.cover,
          ),
        );
      } else {
        throw Exception('PDF 페이지 렌더링 실패: pageImage가 null이거나 비어있음');
      }
    } catch (e) {
      print('PDF 미리보기 오류: $e');
      // 오류 발생 시 기본 PDF 아이콘 표시
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 48.sp,
              color: Colors.red[300],
            ),
            SizedBox(height: 8.h),
            Text(
              'PDF 파일',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '터치하여 보기',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
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

  // FileType enum 반환
  FileType _getFileType(String? fileUrl) {
    if (fileUrl == null) return FileType.unknown;

    if (_isImageFile(fileUrl)) {
      return FileType.image;
    } else {
      return FileType.pdf;
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

  void _shareBulletin(Bulletin bulletin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주보 공유'),
        content: Text('${bulletin.title}을 공유하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('주보가 공유되었습니다')),
              );
            },
            child: const Text('공유'),
          ),
        ],
      ),
    );
  }

  void _showAddBulletinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('주보 추가'),
        content: const Text('주보 추가 기능은 관리자 권한이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
