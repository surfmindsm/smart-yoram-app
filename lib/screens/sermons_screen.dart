import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/models/sermon.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/services/sermon_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

enum FilterType { all, preacher, category, favorite }

class SermonsScreen extends StatefulWidget {
  const SermonsScreen({super.key});

  @override
  State<SermonsScreen> createState() => _SermonsScreenState();
}

class _SermonsScreenState extends State<SermonsScreen> {
  final SermonService _sermonService = SermonService();
  List<Sermon> _sermons = [];
  List<Sermon> _featuredSermons = [];
  List<String> _tags = [];
  List<String> _preachers = [];
  String? _selectedTag;
  String? _selectedPreacher;
  FilterType _currentFilter = FilterType.all;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 추천 설교와 전체 설교, 주제(태그), 설교자를 병렬로 로드
      final results = await Future.wait([
        _sermonService.getFeaturedSermons(),
        _sermonService.getSermons(),
        _sermonService.getTags(),
        _sermonService.getPreachers(),
      ]);

      setState(() {
        _featuredSermons = results[0] as List<Sermon>;
        _sermons = results[1] as List<Sermon>;
        _tags = results[2] as List<String>;
        _preachers = results[3] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSermonsByTag(String? tag) async {
    setState(() {
      _isLoading = true;
      _selectedTag = tag;
    });

    try {
      final sermons = tag == null
          ? await _sermonService.getSermons()
          : await _sermonService.getSermonsByTag(tag);

      setState(() {
        _sermons = sermons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSermonsByPreacher(String? preacherName) async {
    setState(() {
      _isLoading = true;
      _selectedPreacher = preacherName;
    });

    try {
      final sermons = preacherName == null
          ? await _sermonService.getSermons()
          : await _sermonService.getSermonsByPreacher(preacherName);

      setState(() {
        _sermons = sermons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavoriteSermons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = AuthService().currentUser?.id;
      if (userId == null) {
        setState(() {
          _sermons = [];
          _isLoading = false;
        });
        return;
      }

      final sermons = await _sermonService.getMyFavoriteSermons(userId);

      setState(() {
        _sermons = sermons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeFilter(FilterType filterType) {
    setState(() {
      _currentFilter = filterType;
      _selectedTag = null;
      _selectedPreacher = null;
    });

    switch (filterType) {
      case FilterType.all:
        _loadData();
        break;
      case FilterType.favorite:
        _loadFavoriteSermons();
        break;
      case FilterType.category:
      case FilterType.preacher:
        // 주제나 설교자 선택을 기다림
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '명설교',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
        centerTitle: false,
        actions: [
          // 즐겨찾기 버튼
          IconButton(
            icon: Icon(
              _currentFilter == FilterType.favorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: _currentFilter == FilterType.favorite
                  ? NewAppColor.danger600
                  : NewAppColor.neutral900,
            ),
            onPressed: () {
              if (_currentFilter == FilterType.favorite) {
                setState(() {
                  _currentFilter = FilterType.all;
                  _selectedTag = null;
                  _selectedPreacher = null;
                });
                _loadData();
              } else {
                _changeFilter(FilterType.favorite);
              }
            },
          ),
          // 설교자 필터 버튼
          IconButton(
            icon: Icon(
              Icons.person_outline,
              color: _selectedPreacher != null
                  ? NewAppColor.primary600
                  : NewAppColor.neutral900,
            ),
            onPressed: _showPreacherBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // 주제 탭바 (즐겨찾기가 아닐 때만 표시)
          if (_currentFilter != FilterType.favorite) _buildTagTabs(),
          // 설교자 필터 칩
          if (_selectedPreacher != null) _buildPreacherFilterChip(),
          // 컨텐츠
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: NewAppColor.primary600,
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorView()
                    : RefreshIndicator(
                        onRefresh: () {
                          if (_currentFilter == FilterType.favorite) {
                            return _loadFavoriteSermons();
                          } else if (_selectedPreacher != null) {
                            return _loadSermonsByPreacher(_selectedPreacher);
                          } else if (_selectedTag != null) {
                            return _loadSermonsByTag(_selectedTag);
                          } else {
                            return _loadData();
                          }
                        },
                        color: NewAppColor.primary600,
                        child: CustomScrollView(
                          slivers: _buildContent(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // 주제 탭바
  Widget _buildTagTabs() {
    return Container(
      color: Colors.white,
      height: 48.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _buildTagTab('전체', null),
          ..._tags.map((tag) => _buildTagTab(tag, tag)),
        ],
      ),
    );
  }

  Widget _buildTagTab(String label, String? tag) {
    final isSelected = _selectedTag == tag;
    return GestureDetector(
      onTap: () {
        if (_selectedPreacher != null) {
          // 설교자 필터가 있으면 해제
          setState(() {
            _selectedPreacher = null;
          });
        }
        _loadSermonsByTag(tag);
      },
      child: Container(
        margin: EdgeInsets.only(right: 8.w, top: 8.h, bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.primary600 : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: FigmaTextStyles().body2.copyWith(
                  color: isSelected ? Colors.white : NewAppColor.neutral700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
          ),
        ),
      ),
    );
  }

  // 설교자 필터 칩
  Widget _buildPreacherFilterChip() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: NewAppColor.primary100,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  size: 16.w,
                  color: NewAppColor.primary700,
                ),
                SizedBox(width: 4.w),
                Text(
                  _selectedPreacher!,
                  style: FigmaTextStyles().captionText1.copyWith(
                        color: NewAppColor.primary700,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedPreacher = null;
              });
              // 현재 선택된 주제로 다시 로드
              _loadSermonsByTag(_selectedTag);
            },
            child: Icon(
              Icons.close,
              size: 20.w,
              color: NewAppColor.neutral600,
            ),
          ),
        ],
      ),
    );
  }


  // 설교자 선택 바텀 시트
  void _showPreacherBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildPreacherBottomSheet(),
    );
  }

  Widget _buildPreacherBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 핸들
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: NewAppColor.neutral300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // 헤더
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    '설교자 선택',
                    style: FigmaTextStyles().subtitle2.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: NewAppColor.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: NewAppColor.neutral200),
            // 설교자 목록
            Expanded(
              child: _preachers.isEmpty
                  ? Center(
                      child: Text(
                        '등록된 설교자가 없습니다',
                        style: FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral500,
                            ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: _preachers.length,
                      itemBuilder: (context, index) {
                        final preacher = _preachers[index];
                        final isSelected = _selectedPreacher == preacher;
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _currentFilter = FilterType.preacher;
                            });
                            _loadSermonsByPreacher(preacher);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 20.w,
                                  color: isSelected
                                      ? NewAppColor.primary600
                                      : NewAppColor.neutral600,
                                ),
                                SizedBox(width: 12.w),
                                Text(
                                  preacher,
                                  style: FigmaTextStyles().body2.copyWith(
                                        color: isSelected
                                            ? NewAppColor.primary600
                                            : NewAppColor.neutral900,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 20.w,
                                    color: NewAppColor.primary600,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }


  List<Widget> _buildContent() {
    if (_currentFilter == FilterType.favorite) {
      return _buildFavoriteContent();
    } else {
      return _buildAllContent();
    }
  }

  List<Widget> _buildAllContent() {
    return [
      // 추천 설교 섹션
      if (_featuredSermons.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _buildSectionHeader('추천 설교'),
        ),
        SliverToBoxAdapter(
          child: _buildFeaturedSermons(),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 24.h)),
      ],

      // 전체 설교 리스트
      SliverToBoxAdapter(
        child: _buildSectionHeader('전체 설교'),
      ),

      if (_sermons.isEmpty)
        SliverFillRemaining(
          child: _buildEmptyView(),
        )
      else
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSermonCard(_sermons[index]),
              childCount: _sermons.length,
            ),
          ),
        ),
    ];
  }


  List<Widget> _buildFavoriteContent() {
    return [
      SliverToBoxAdapter(
        child: _buildSectionHeader('내 즐겨찾기'),
      ),
      if (_sermons.isEmpty)
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64.w,
                  color: NewAppColor.neutral300,
                ),
                SizedBox(height: 16.h),
                Text(
                  '즐겨찾기한 설교가 없습니다',
                  style: FigmaTextStyles().body1.copyWith(
                        color: NewAppColor.neutral500,
                      ),
                ),
              ],
            ),
          ),
        )
      else
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildSermonCard(_sermons[index]),
              childCount: _sermons.length,
            ),
          ),
        ),
    ];
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Text(
        title,
        style: FigmaTextStyles().subtitle2.copyWith(
              color: NewAppColor.neutral900,
            ),
      ),
    );
  }

  Widget _buildFeaturedSermons() {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _featuredSermons.length,
        itemBuilder: (context, index) {
          final sermon = _featuredSermons[index];
          return _buildFeaturedSermonCard(sermon);
        },
      ),
    );
  }

  Widget _buildFeaturedSermonCard(Sermon sermon) {
    return GestureDetector(
      onTap: () => _navigateToSermonDetail(sermon),
      child: Container(
        width: 300.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              child: Stack(
                children: [
                  Image.network(
                    sermon.getThumbnailUrl(quality: 'hqdefault'),
                    width: double.infinity,
                    height: 120.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 120.h,
                      color: NewAppColor.neutral200,
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 48.w,
                        color: NewAppColor.neutral400,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8.h,
                    right: 8.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: NewAppColor.primary600,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        '추천',
                        style: FigmaTextStyles().captionText2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 정보
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sermon.title,
                      style: FigmaTextStyles().body1.copyWith(
                            color: NewAppColor.neutral900,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      sermon.preacherName ?? '설교자 미상',
                      style: FigmaTextStyles().captionText1.copyWith(
                            color: NewAppColor.neutral600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSermonCard(Sermon sermon) {
    return GestureDetector(
      onTap: () => _navigateToSermonDetail(sermon),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                sermon.getThumbnailUrl(quality: 'default'),
                width: 120.w,
                height: 68.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120.w,
                  height: 68.h,
                  color: NewAppColor.neutral200,
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 32.w,
                    color: NewAppColor.neutral400,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sermon.category != null) ...[
                    Text(
                      sermon.category!,
                      style: FigmaTextStyles().captionText2.copyWith(
                            color: NewAppColor.primary600,
                          ),
                    ),
                    SizedBox(height: 4.h),
                  ],
                  Text(
                    sermon.title,
                    style: FigmaTextStyles().body2.copyWith(
                          color: NewAppColor.neutral900,
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      if (sermon.preacherName != null) ...[
                        Text(
                          sermon.preacherName!,
                          style: FigmaTextStyles().captionText2.copyWith(
                                color: NewAppColor.neutral600,
                              ),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      if (sermon.sermonDate != null)
                        Text(
                          sermon.getFormattedSermonDate(),
                          style: FigmaTextStyles().captionText2.copyWith(
                                color: NewAppColor.neutral500,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64.w,
            color: NewAppColor.neutral300,
          ),
          SizedBox(height: 16.h),
          Text(
            '등록된 설교가 없습니다',
            style: FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.neutral500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.w,
            color: NewAppColor.danger600,
          ),
          SizedBox(height: 16.h),
          Text(
            '설교를 불러올 수 없습니다',
            style: FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.neutral700,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            _errorMessage ?? '',
            style: FigmaTextStyles().captionText1.copyWith(
                  color: NewAppColor.neutral500,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: NewAppColor.primary600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              '다시 시도',
              style: FigmaTextStyles().body2.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSermonDetail(Sermon sermon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SermonDetailScreen(sermon: sermon),
      ),
    );
  }
}

// 설교 상세 화면 (유튜브 플레이어)
class SermonDetailScreen extends StatefulWidget {
  final Sermon sermon;

  const SermonDetailScreen({
    super.key,
    required this.sermon,
  });

  @override
  State<SermonDetailScreen> createState() => _SermonDetailScreenState();
}

class _SermonDetailScreenState extends State<SermonDetailScreen> {
  late YoutubePlayerController _controller;
  final SermonService _sermonService = SermonService();
  bool _isFavorited = false;
  bool _isLoadingFavorite = true;
  int? _currentUserId;
  List<Sermon> _relatedSermons = [];
  bool _isLoadingRelated = true;

  @override
  void initState() {
    super.initState();
    // YouTube 플레이어 화면에서 모든 방향 허용
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializePlayer();
    _incrementViewCount();
    _loadFavoriteStatus();
    _loadRelatedSermons();
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.sermon.youtubeVideoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        controlsVisibleAtStart: true,
      ),
    );
  }

  Future<void> _incrementViewCount() async {
    try {
      await _sermonService.incrementViewCount(widget.sermon.id);
    } catch (e) {
      // 조회수 증가 실패는 무시
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      // AuthService에서 현재 로그인한 사용자 ID 가져오기
      _currentUserId = AuthService().currentUser?.id;

      // 로그인하지 않은 사용자는 즐겨찾기 상태를 확인하지 않음
      if (_currentUserId == null) {
        setState(() {
          _isLoadingFavorite = false;
        });
        return;
      }

      final isFav = await _sermonService.isFavorited(
        widget.sermon.id,
        _currentUserId!,
      );

      setState(() {
        _isFavorited = isFav;
        _isLoadingFavorite = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  Future<void> _loadRelatedSermons() async {
    try {
      List<Sermon> related = [];

      // 1. 같은 설교자의 다른 설교들 (최대 5개)
      if (widget.sermon.preacherName != null && widget.sermon.preacherName!.isNotEmpty) {
        final bySamePreacher = await _sermonService.getSermonsByPreacher(
          widget.sermon.preacherName!,
          limit: 6, // 현재 설교 포함이므로 6개 가져오기
        );
        // 현재 설교 제외
        related.addAll(bySamePreacher.where((s) => s.id != widget.sermon.id).take(5));
      }

      // 2. 부족하면 추천 설교로 채우기
      if (related.length < 5) {
        final featured = await _sermonService.getFeaturedSermons(limit: 10);
        // 현재 설교와 이미 추가된 설교 제외
        final filteredFeatured = featured
            .where((s) => s.id != widget.sermon.id && !related.any((r) => r.id == s.id))
            .take(5 - related.length);
        related.addAll(filteredFeatured);
      }

      setState(() {
        _relatedSermons = related;
        _isLoadingRelated = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRelated = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    // 로그인하지 않은 사용자
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인이 필요한 기능입니다'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final success = await _sermonService.toggleFavorite(
        widget.sermon.id,
        _currentUserId!,
      );

      if (success) {
        setState(() {
          _isFavorited = !_isFavorited;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorited ? '즐겨찾기에 추가되었습니다' : '즐겨찾기에서 삭제되었습니다',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('즐겨찾기 처리에 실패했습니다'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isLoadingFavorite = false;
      });
    }
  }

  Widget _buildRelatedSermons() {
    if (_isLoadingRelated) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.h),
          child: CircularProgressIndicator(
            color: NewAppColor.primary600,
          ),
        ),
      );
    }

    if (_relatedSermons.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Text(
          '관련 영상이 없습니다',
          style: FigmaTextStyles().body2.copyWith(
                color: NewAppColor.neutral500,
              ),
        ),
      );
    }

    return Column(
      children: _relatedSermons
          .map((sermon) => _buildRelatedSermonItem(sermon))
          .toList(),
    );
  }

  Widget _buildRelatedSermonItem(Sermon sermon) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SermonDetailScreen(sermon: sermon),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: NewAppColor.neutral100,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.horizontal(left: Radius.circular(8.r)),
              child: Image.network(
                sermon.getThumbnailUrl(quality: 'default'),
                width: 120.w,
                height: 68.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120.w,
                  height: 68.h,
                  color: NewAppColor.neutral200,
                  child: Icon(
                    Icons.play_circle_outline,
                    size: 32.w,
                    color: NewAppColor.neutral400,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // 정보
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sermon.title,
                      style: FigmaTextStyles().body2.copyWith(
                            color: NewAppColor.neutral900,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    if (sermon.preacherName != null)
                      Text(
                        sermon.preacherName!,
                        style: FigmaTextStyles().captionText2.copyWith(
                              color: NewAppColor.neutral600,
                            ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 화면을 벗어날 때 다시 세로 모드로 고정
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: NewAppColor.primary600,
        progressColors: ProgressBarColors(
          playedColor: NewAppColor.primary600,
          handleColor: NewAppColor.primary700,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: NewAppColor.neutral100,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: NewAppColor.neutral900,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '명설교',
              style: FigmaTextStyles().subtitle2.copyWith(
                    color: NewAppColor.neutral900,
                  ),
            ),
            actions: [
              // 즐겨찾기 버튼
              IconButton(
                icon: _isLoadingFavorite
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: NewAppColor.neutral600,
                        ),
                      )
                    : Icon(
                        _isFavorited ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorited
                            ? NewAppColor.danger600
                            : NewAppColor.neutral600,
                      ),
                onPressed: _isLoadingFavorite ? null : _toggleFavorite,
              ),
            ],
          ),
          body: Column(
            children: [
              // 유튜브 플레이어
              player,
              // 설교 정보
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 카테고리
                        if (widget.sermon.category != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: NewAppColor.primary100,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              widget.sermon.category!,
                              style: FigmaTextStyles().captionText2.copyWith(
                                    color: NewAppColor.primary700,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                        ],
                        // 제목
                        Text(
                          widget.sermon.title,
                          style: FigmaTextStyles().subtitle1.copyWith(
                                color: NewAppColor.neutral900,
                              ),
                        ),
                        SizedBox(height: 12.h),
                        // 설교자 및 날짜
                        Row(
                          children: [
                            if (widget.sermon.preacherName != null) ...[
                              Icon(
                                Icons.person_outline,
                                size: 16.w,
                                color: NewAppColor.neutral600,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                widget.sermon.preacherName!,
                                style: FigmaTextStyles().body2.copyWith(
                                      color: NewAppColor.neutral700,
                                    ),
                              ),
                              SizedBox(width: 16.w),
                            ],
                            if (widget.sermon.sermonDate != null) ...[
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16.w,
                                color: NewAppColor.neutral600,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                widget.sermon.getFormattedSermonDate(),
                                style: FigmaTextStyles().body2.copyWith(
                                      color: NewAppColor.neutral700,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 8.h),
                        // 조회수
                        Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 16.w,
                              color: NewAppColor.neutral600,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '조회수 ${widget.sermon.viewCount}',
                              style: FigmaTextStyles().captionText1.copyWith(
                                    color: NewAppColor.neutral600,
                                  ),
                            ),
                          ],
                        ),
                        // 설명
                        if (widget.sermon.description != null &&
                            widget.sermon.description!.isNotEmpty) ...[
                          SizedBox(height: 24.h),
                          Divider(color: NewAppColor.neutral200),
                          SizedBox(height: 16.h),
                          Text(
                            '설교 소개',
                            style: FigmaTextStyles().body1.copyWith(
                                  color: NewAppColor.neutral900,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            widget.sermon.description!,
                            style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.neutral700,
                                  height: 1.6,
                                ),
                          ),
                        ],
                        // 관련 영상
                        SizedBox(height: 24.h),
                        Divider(color: NewAppColor.neutral200),
                        SizedBox(height: 16.h),
                        Text(
                          '관련 영상',
                          style: FigmaTextStyles().body1.copyWith(
                                color: NewAppColor.neutral900,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        SizedBox(height: 12.h),
                        _buildRelatedSermons(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
