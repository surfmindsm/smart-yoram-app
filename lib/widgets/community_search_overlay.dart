import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';

/// 커뮤니티 검색 오버레이
/// 모든 커뮤니티 페이지에서 공통으로 사용하는 검색 UI
class CommunitySearchOverlay extends StatefulWidget {
  final String title; // 페이지 제목 (예: "무료 나눔")
  final Function(String) onSearch; // 검색어 제출 콜백
  final VoidCallback onClose; // 닫기 콜백

  const CommunitySearchOverlay({
    super.key,
    required this.title,
    required this.onSearch,
    required this.onClose,
  });

  @override
  State<CommunitySearchOverlay> createState() => _CommunitySearchOverlayState();
}

class _CommunitySearchOverlayState extends State<CommunitySearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    // 자동으로 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// 최근 검색어 로드
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('community_recent_searches') ?? [];
    setState(() {
      _recentSearches = searches;
    });
  }

  /// 최근 검색어 저장
  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('community_recent_searches') ?? [];

    // 중복 제거
    searches.remove(query);
    // 최상단에 추가
    searches.insert(0, query);
    // 최대 10개까지만 저장
    if (searches.length > 10) {
      searches.removeRange(10, searches.length);
    }

    await prefs.setStringList('community_recent_searches', searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  /// 최근 검색어 삭제
  Future<void> _deleteRecentSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('community_recent_searches') ?? [];
    searches.remove(query);
    await prefs.setStringList('community_recent_searches', searches);
    setState(() {
      _recentSearches = searches;
    });
  }

  /// 최근 검색어 전체 삭제
  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('community_recent_searches');
    setState(() {
      _recentSearches = [];
    });
  }

  /// 검색 실행
  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    _saveRecentSearch(query);
    widget.onSearch(query);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: NewAppColor.neutral100,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: widget.onClose,
        ),
        title: Text(
          widget.title,
          style: FigmaTextStyles().headline4.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
      ),
      body: Column(
        children: [
          // 검색 입력 영역
          _buildSearchHeader(),
          // 최근 검색어
          Expanded(
            child: _buildSearchContent(),
          ),
        ],
      ),
    );
  }

  /// 검색 바 헤더
  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: NewAppColor.neutral100,
      ),
      child: Column(
        children: [
          // 검색 입력 필드
          Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                hintStyle: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 20.sp,
                  color: NewAppColor.neutral500,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          LucideIcons.x,
                          size: 20.sp,
                          color: NewAppColor.neutral500,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral900,
                  ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) {
                setState(() {}); // X 버튼 표시 업데이트
              },
            ),
          ),
          SizedBox(height: 12.h),
          // 검색 버튼
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: _performSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: NewAppColor.primary600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
              ),
              child: Text(
                '검색',
                style: FigmaTextStyles().subtitle3.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 검색 내용 (최근 검색어)
  Widget _buildSearchContent() {
    return Container(
      color: NewAppColor.neutral100,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 최근 검색어 섹션
            if (_recentSearches.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최근 검색어',
                    style: FigmaTextStyles().subtitle2.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                  ),
                  GestureDetector(
                    onTap: _clearRecentSearches,
                    child: Text(
                      '전체 삭제',
                      style: FigmaTextStyles().caption2.copyWith(
                            color: NewAppColor.neutral500,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // 최근 검색어 목록
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: _recentSearches.map((query) {
                    return _buildRecentSearchItem(query);
                  }).toList(),
                ),
              ),
            ] else ...[
              // 최근 검색어 없음
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 48.sp,
                        color: NewAppColor.neutral300,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        '최근 검색어가 없습니다',
                        style: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral500,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }

  /// 최근 검색어 아이템
  Widget _buildRecentSearchItem(String query) {
    final isLast = _recentSearches.indexOf(query) == _recentSearches.length - 1;

    return InkWell(
      onTap: () {
        _searchController.text = query;
        _performSearch();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: NewAppColor.neutral200,
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 20.sp,
              color: NewAppColor.neutral400,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                query,
                style: FigmaTextStyles().body2.copyWith(
                      color: NewAppColor.neutral900,
                    ),
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.x,
                size: 20.sp,
                color: NewAppColor.neutral400,
              ),
              onPressed: () => _deleteRecentSearch(query),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
