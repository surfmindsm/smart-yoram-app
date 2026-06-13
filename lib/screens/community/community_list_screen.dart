import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/screens/community/community_detail_screen.dart';
import 'package:smart_yoram_app/screens/community/community_create_screen.dart';
import 'package:smart_yoram_app/utils/location_data.dart';
import 'package:smart_yoram_app/widgets/community_search_overlay.dart';

/// 커뮤니티 목록 화면 (공통)
/// 모든 카테고리에서 재사용 가능한 목록 화면
class CommunityListScreen extends StatefulWidget {
  final String categoryId;
  final String title;
  final CommunityListType type;

  const CommunityListScreen({
    super.key,
    required this.categoryId,
    required this.title,
    required this.type,
  });

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

enum CommunityListType {
  freeSharing,
  itemSale,
  itemRequest,
  jobPosting,
  musicTeamRecruit,
  musicTeamSeeking,
  churchNews,
  myPosts,
  myFavorites,
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  final CommunityService _communityService = CommunityService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  List<dynamic> _items = [];
  List<dynamic> _filteredItemsCache = []; // 캐시된 필터링 결과
  User? _currentUser;
  bool _isSearchMode = false; // 검색 모드 여부

  // 검색 및 필터
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory; // 카테고리 필터 (가구, 전자제품 등)
  String? _selectedCity; // 도/시 필터
  String? _selectedDistrict; // 시/군/구 필터
  bool? _deliveryAvailableFilter; // 택배가능 필터
  String _priceFilter = 'all'; // 가격 필터: all(전체), free(무료), paid(판매)
  bool _hideCompleted = false; // 판매/나눔/요청 완료 제거 필터
  String _employmentTypeFilter =
      'all'; // 고용형태 필터: all(전체), full-time(정규직), part-time(시간제), volunteer(자원봉사)
  String _teamTypeFilter =
      'all'; // 팀형태 필터: all(전체), praise-team(찬양팀), worship-team(워십팀), band(밴드)
  String _instrumentFilter =
      'all'; // 악기/파트 필터 (행사팀 지원): all(전체), solo(솔로), praise-team(찬양팀), etc.
  String? _selectedDayFilter; // 활동 가능 요일 필터 (행사팀 지원)

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadItems();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadCurrentUser() async {
    final userResponse = await _authService.getCurrentUser();
    setState(() {
      _currentUser = userResponse.data;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);

    try {
      List<dynamic> items = [];

      switch (widget.type) {
        case CommunityListType.freeSharing:
          // 이제 무료나눔과 물품판매를 통합했으므로 전체 아이템 가져오기
          items = await _communityService.getSharingItems();
          break;
        case CommunityListType.itemSale:
          items = await _communityService.getSharingItems();
          break;
        case CommunityListType.itemRequest:
          items = await _communityService.getRequestItems();
          break;
        case CommunityListType.jobPosting:
          items = await _communityService.getJobPosts();
          break;
        case CommunityListType.musicTeamRecruit:
          items = await _communityService.getMusicTeamRecruitments();
          break;
        case CommunityListType.musicTeamSeeking:
          items = await _communityService.getMusicTeamSeekers();
          break;
        case CommunityListType.churchNews:
          items = await _communityService.getChurchNews();
          break;
        case CommunityListType.myPosts:
          final myPosts = await _communityService.getMyPosts();
          items = myPosts;
          break;
        case CommunityListType.myFavorites:
          // 찜한 글은 별도 서비스 사용
          items = [];
          break;
      }

      print('📋 COMMUNITY_LIST: 로드된 아이템 수 - ${items.length}');
      if (items.isNotEmpty && items.first is SharingItem) {
        final statusCounts = <String, int>{};
        for (var item in items) {
          if (item is SharingItem) {
            final status = item.status.toLowerCase();
            statusCounts[status] = (statusCounts[status] ?? 0) + 1;
          }
        }
        print('📋 COMMUNITY_LIST: 상태별 개수 - $statusCounts');
      }

      setState(() {
        _items = items;
        _isLoading = false;
        _updateFilteredItems();
      });
    } catch (e) {
      print('❌ COMMUNITY_LIST: 목록 로드 실패 - $e');
      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  /// 검색어 변경 핸들러
  void _onSearchChanged() {
    setState(() {
      _updateFilteredItems();
    });
  }

  /// 검색 페이지 열기
  void _openSearchOverlay() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunitySearchOverlay(
          title: widget.title,
          onSearch: (query) {
            // 검색어를 컨트롤러에 설정하고 필터링
            setState(() {
              _searchController.text = query;
              _updateFilteredItems();
            });
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  /// 필터링된 아이템 목록 재계산
  void _updateFilteredItems() {
    List<dynamic> filtered = _items;

    // 검색어 필터링
    final searchQuery = _searchController.text.trim().toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        String title = '';
        String? churchName;
        String? churchLocation;

        if (item is SharingItem) {
          title = item.title.toLowerCase();
          churchName = item.churchName?.toLowerCase();
          churchLocation = item.displayLocation?.toLowerCase();
        } else if (item is RequestItem) {
          title = item.title.toLowerCase();
          churchName = item.churchName?.toLowerCase();
          churchLocation = item.displayLocation?.toLowerCase();
        } else if (item is JobPost) {
          title = item.title.toLowerCase();
          churchName = item.churchName?.toLowerCase();
          churchLocation = item.location?.toLowerCase();
        } else if (item is MusicTeamRecruitment) {
          title = item.title.toLowerCase();
          churchName = item.churchName?.toLowerCase();
          churchLocation = [item.province, item.district]
              .where((e) => e != null && e.isNotEmpty)
              .join(' ')
              .toLowerCase();
        } else if (item is MusicTeamSeeker) {
          title = item.title.toLowerCase();
          churchName = item.churchName?.toLowerCase();
        } else if (item is ChurchNews) {
          title = item.title.toLowerCase();
          churchName = item.churchName?.toLowerCase();
          churchLocation = item.location?.toLowerCase();
        } else if (item is Map<String, dynamic>) {
          title = (item['title'] ?? '').toString().toLowerCase();
          churchName = (item['church_name'] ?? '').toString().toLowerCase();
          churchLocation =
              (item['church_location'] ?? '').toString().toLowerCase();
        }

        return title.contains(searchQuery) ||
            (churchName?.contains(searchQuery) ?? false) ||
            (churchLocation?.contains(searchQuery) ?? false);
      }).toList();
    }

    // 가격 필터 (무료나눔/물품판매)
    if ((widget.type == CommunityListType.freeSharing ||
            widget.type == CommunityListType.itemSale) &&
        _priceFilter != 'all') {
      filtered = filtered.where((item) {
        if (item is SharingItem) {
          if (_priceFilter == 'free') {
            return item.isFree;
          } else if (_priceFilter == 'paid') {
            return !item.isFree;
          }
        }
        return false;
      }).toList();
    }

    // 판매/나눔/요청/사역자 모집 완료 제거 필터
    if (_hideCompleted) {
      filtered = filtered.where((item) {
        if (item is SharingItem) {
          final status = item.status.toLowerCase();
          return status != 'completed' &&
              status != 'closed' &&
              status != 'sold';
        } else if (item is RequestItem) {
          final status = item.status.toLowerCase();
          return status != 'completed' && status != 'closed';
        } else if (item is JobPost) {
          final status = item.status.toLowerCase();
          return status != 'completed' && status != 'closed';
        }
        return true;
      }).toList();
    }

    // 고용형태 필터 (사역자 모집)
    if (_employmentTypeFilter != 'all' &&
        widget.type == CommunityListType.jobPosting) {
      filtered = filtered.where((item) {
        if (item is JobPost) {
          return item.employmentType == _employmentTypeFilter;
        }
        return false;
      }).toList();
    }

    // 팀형태 필터 (행사팀 모집)
    if (_teamTypeFilter != 'all' &&
        widget.type == CommunityListType.musicTeamRecruit) {
      filtered = filtered.where((item) {
        if (item is MusicTeamRecruitment) {
          // teamTypes는 배열이므로 contains로 확인
          return item.teamTypes.contains(_teamTypeFilter);
        }
        return false;
      }).toList();
    }

    // 행사팀 모집 완료 제거 필터
    if (_hideCompleted && widget.type == CommunityListType.musicTeamRecruit) {
      filtered = filtered.where((item) {
        if (item is MusicTeamRecruitment) {
          final status = item.status.toLowerCase();
          return status != 'completed' && status != 'closed';
        }
        return true;
      }).toList();
    }

    // 카테고리 필터 (무료나눔/물품판매/물품요청)
    if (_selectedCategory != null &&
        (widget.type == CommunityListType.freeSharing ||
            widget.type == CommunityListType.itemSale ||
            widget.type == CommunityListType.itemRequest)) {
      filtered = filtered.where((item) {
        if (item is SharingItem) {
          return item.category == _selectedCategory;
        } else if (item is RequestItem) {
          return item.category == _selectedCategory;
        }
        return false;
      }).toList();
    }

    // 직종 필터 (사역자 모집)
    if (_selectedCategory != null &&
        widget.type == CommunityListType.jobPosting) {
      filtered = filtered.where((item) {
        if (item is JobPost) {
          return item.jobType == _selectedCategory;
        }
        return false;
      }).toList();
    }

    // 예배 형태 필터 (행사팀 모집)
    if (_selectedCategory != null &&
        widget.type == CommunityListType.musicTeamRecruit) {
      filtered = filtered.where((item) {
        if (item is MusicTeamRecruitment) {
          return item.worshipType == _selectedCategory;
        }
        return false;
      }).toList();
    }

    // 위치 필터 (도/시)
    if (_selectedCity != null) {
      filtered = filtered.where((item) {
        String? province;
        String? location;
        if (item is SharingItem) {
          province = item.province;
          location = item.location; // 레거시 필드
        } else if (item is RequestItem) {
          location = item.location;
        } else if (item is JobPost) {
          location = item.location;
        } else if (item is MusicTeamRecruitment) {
          province = item.province;
          location = item.location;
        } else if (item is ChurchNews) {
          location = item.location;
        }

        // SharingItem과 MusicTeamRecruitment는 province 우선, 없으면 location
        if (province != null && province.isNotEmpty) {
          return province == _selectedCity;
        } else if (location != null && location.isNotEmpty) {
          return location.startsWith(_selectedCity!);
        }
        return false;
      }).toList();
    }

    // 위치 필터 (시/군/구)
    if (_selectedDistrict != null) {
      filtered = filtered.where((item) {
        String? district;
        String? location;
        if (item is SharingItem) {
          district = item.district;
          location = item.location; // 레거시 필드
        } else if (item is RequestItem) {
          location = item.location;
        } else if (item is JobPost) {
          location = item.location;
        } else if (item is MusicTeamRecruitment) {
          district = item.district;
          location = item.location;
        } else if (item is ChurchNews) {
          location = item.location;
        }

        // SharingItem과 MusicTeamRecruitment는 district 우선, 없으면 location
        if (district != null && district.isNotEmpty) {
          return district == _selectedDistrict;
        } else if (location != null && location.isNotEmpty) {
          return location.contains(_selectedDistrict!);
        }
        return false;
      }).toList();
    }

    // 택배가능 필터 (무료나눔/물품판매)
    if (_deliveryAvailableFilter != null &&
        (widget.type == CommunityListType.freeSharing ||
            widget.type == CommunityListType.itemSale)) {
      filtered = filtered.where((item) {
        if (item is SharingItem) {
          return item.deliveryAvailable == _deliveryAvailableFilter;
        }
        return false;
      }).toList();
    }

    // 악기/파트 필터 (행사팀 지원)
    if (_instrumentFilter != 'all' &&
        widget.type == CommunityListType.musicTeamSeeking) {
      filtered = filtered.where((item) {
        if (item is MusicTeamSeeker) {
          return item.instrument == _instrumentFilter;
        }
        return false;
      }).toList();
    }

    // 활동 가능 요일 필터 (행사팀 지원)
    if (_selectedDayFilter != null &&
        widget.type == CommunityListType.musicTeamSeeking) {
      filtered = filtered.where((item) {
        if (item is MusicTeamSeeker) {
          return item.availableDays.contains(_selectedDayFilter);
        }
        return false;
      }).toList();
    }

    // 행사팀 지원 완료 제거 필터
    if (_hideCompleted && widget.type == CommunityListType.musicTeamSeeking) {
      filtered = filtered.where((item) {
        if (item is MusicTeamSeeker) {
          final status = item.status.toLowerCase();
          return status != 'completed' && status != 'closed';
        }
        return true;
      }).toList();
    }

    // 행사팀 지원 지역 필터 (활동 가능 지역 배열에서 확인)
    if (_selectedCity != null &&
        widget.type == CommunityListType.musicTeamSeeking) {
      filtered = filtered.where((item) {
        if (item is MusicTeamSeeker) {
          // preferredLocation 배열에 선택된 도시가 포함되어 있는지 확인
          return item.preferredLocation
              .any((loc) => loc.contains(_selectedCity!));
        }
        return false;
      }).toList();
    }

    // 카테고리 필터 (교회 소식)
    if (_selectedCategory != null &&
        widget.type == CommunityListType.churchNews) {
      filtered = filtered.where((item) {
        if (item is ChurchNews) {
          return item.category == _selectedCategory;
        }
        return false;
      }).toList();
    }

    // 종료 제거 필터 (교회 소식)
    if (_hideCompleted && widget.type == CommunityListType.churchNews) {
      filtered = filtered.where((item) {
        if (item is ChurchNews) {
          final status = item.status.toLowerCase();
          return status != 'completed' && status != 'closed';
        }
        return true;
      }).toList();
    }

    _filteredItemsCache = filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1.2.0 C 방향: 캔버스 배경 + 흰 AppBar
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        actions: [
          if (widget.type == CommunityListType.freeSharing ||
              widget.type == CommunityListType.itemSale ||
              widget.type == CommunityListType.itemRequest ||
              widget.type == CommunityListType.jobPosting ||
              widget.type == CommunityListType.musicTeamRecruit ||
              widget.type == CommunityListType.musicTeamSeeking ||
              widget.type == CommunityListType.churchNews)
            IconButton(
              icon: Icon(Icons.tune,
                  color: NewAppColor.textMuted, size: 22.sp),
              onPressed: _showAdvancedFilterBottomSheet,
            ),
          IconButton(
            icon: Icon(Icons.search,
                color: NewAppColor.textMuted, size: 22.sp),
            onPressed: _openSearchOverlay,
          ),
        ],
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      body: Column(
        children: [
          // 검색 중일 때 검색어 표시
          if (_searchController.text.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                border: Border(
                  bottom: BorderSide(color: NewAppColor.skyTint, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16.sp,
                    color: NewAppColor.skyDeep,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      '검색: ${_searchController.text}',
                      style: FigmaTextStyles().body3.copyWith(
                            color: NewAppColor.skyDeep,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _updateFilteredItems();
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.all(4.w),
                      child: Icon(
                        Icons.close,
                        size: 16.sp,
                        color: NewAppColor.skyDeep,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 빠른 필터 (무료나눔/물품판매)
          if (widget.type == CommunityListType.freeSharing ||
              widget.type == CommunityListType.itemSale)
            _buildQuickFilters(),
          // 빠른 필터 (물품 요청)
          if (widget.type == CommunityListType.itemRequest)
            _buildQuickRequestFilters(),
          // 빠른 필터 (사역자 모집)
          if (widget.type == CommunityListType.jobPosting)
            _buildQuickJobFilters(),
          // 빠른 필터 (행사팀 모집)
          if (widget.type == CommunityListType.musicTeamRecruit)
            _buildQuickMusicTeamFilters(),
          // 빠른 필터 (행사팀 지원)
          if (widget.type == CommunityListType.musicTeamSeeking)
            _buildQuickMusicTeamSeekingFilters(),
          // 빠른 필터 (교회 소식)
          if (widget.type == CommunityListType.churchNews)
            _buildQuickChurchNewsFilters(),
          // 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItemsCache.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadItems,
                        child: widget.type == CommunityListType.churchNews
                            ? ListView.builder(
                                itemCount: _filteredItemsCache.length,
                                itemBuilder: (context, index) {
                                  return _buildItemCard(
                                      _filteredItemsCache[index]);
                                },
                              )
                            : ListView.separated(
                                itemCount: _filteredItemsCache.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: NewAppColor.borderHair,
                                ),
                                itemBuilder: (context, index) {
                                  return _buildItemCard(
                                      _filteredItemsCache[index]);
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _canCreatePost()
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreate,
              backgroundColor: NewAppColor.skyPrimary,
              elevation: 6,
              icon: Icon(Icons.add, color: Colors.white, size: 20.sp),
              label: Text(
                '글쓰기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 56.sp,
            color: NewAppColor.iconFaint,
          ),
          SizedBox(height: 14.h),
          Text(
            '게시글이 없습니다',
            style: FigmaTextStyles().body3.copyWith(
                  color: NewAppColor.textMuted,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    // 교회 소식인 경우 연락처 스타일 카드 사용
    if (widget.type == CommunityListType.churchNews) {
      return _buildChurchNewsCard(item);
    }

    // 공통 필드 추출
    String title = '';
    String? imageUrl;
    String date = '';
    int viewCount = 0;
    int likes = 0;
    int? authorId; // 작성자 ID
    String? authorName;
    String? authorProfilePhotoUrl; // 프로필 사진
    String? churchName;
    String? churchLocation; // 교회 지역 (도시 + 구/동)
    String? priceText; // 가격 정보
    String? status; // 상태
    String? statusLabel; // 상태 표시 텍스트
    bool deliveryAvailable = false; // 택배 가능 여부

    if (item is SharingItem) {
      title = item.title;
      imageUrl = item.images.isNotEmpty ? item.images.first : null;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorId = item.authorId;
      authorName = item.authorName;
      authorProfilePhotoUrl = item.authorProfilePhotoUrl;
      churchName = item.churchName;
      churchLocation = item.displayLocation; // province + district
      deliveryAvailable = item.deliveryAvailable;
      status = item.status;
      statusLabel = item.statusDisplayName;
      // 가격 표시: 무료나눔이면 "무료 나눔", 아니면 가격
      if (item.isFree) {
        priceText = '무료 나눔';
      } else {
        priceText = item.formattedPrice;
      }
    } else if (item is RequestItem) {
      title = item.title;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorId = item.authorId;
      authorName = item.authorName;
      authorProfilePhotoUrl = null; // 프로필 이미지 제거
      churchName = item.churchName;
      churchLocation = item.displayLocation;
      status = item.status;
      statusLabel = item.statusDisplayName;
      // 보상 정보 표시
      if (item.rewardType == 'free') {
        priceText = '무료나눔';
      } else if (item.rewardType == 'exchange') {
        priceText = '교환';
      } else if (item.rewardType == 'payment' && item.rewardAmount != null) {
        priceText = '${item.rewardAmount!.toStringAsFixed(0)}원';
      }
    } else if (item is JobPost) {
      title = item.title;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorId = item.authorId;
      authorName = item.authorName;
      churchName = item.churchName;
      churchLocation = item.location;
      status = item.status;
      statusLabel = item.statusDisplayName;
    } else if (item is MusicTeamRecruitment) {
      title = item.title;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorId = item.authorId;
      authorName = item.authorName;
      churchName = item.churchName;
      // 리스트에는 province + district만 표시 (상세주소 제외)
      churchLocation = [item.province, item.district]
          .where((e) => e != null && e.isNotEmpty)
          .join(' ');
      status = item.status;
      statusLabel = item.statusDisplayName;
    } else if (item is MusicTeamSeeker) {
      title = item.title;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorId = item.authorId;
      authorName = item.authorName;
      churchName = item.churchName;
      status = item.status;
      statusLabel = item.statusDisplayName;
    } else if (item is Map<String, dynamic>) {
      // myPosts의 경우
      title = item['title'] ?? '';
      date = _formatDate(item['created_at']);
      viewCount = item['view_count'] ?? 0;
      likes = item['likes'] ?? 0;
      authorId = item['author_id'];
      authorName = item['author_name'];
      churchName = item['church_name'];
      churchLocation = item['church_location'];
      status = item['status'];
      // 테이블 이름과 isFree 정보 전달
      final tableName = item['tableName'] ?? item['table'];
      final isFree = item['is_free'] == true;
      statusLabel =
          _getStatusLabel(item['status'], tableName: tableName, isFree: isFree);

      // 이미지 추출 (images 필드가 있는 경우)
      if (item['images'] != null) {
        if (item['images'] is List && (item['images'] as List).isNotEmpty) {
          imageUrl = (item['images'] as List).first.toString();
        } else if (item['images'] is String &&
            (item['images'] as String).isNotEmpty) {
          // JSON 문자열인 경우 파싱 시도
          try {
            final parsed = item['images'] as String;
            if (parsed.startsWith('[') && parsed.endsWith(']')) {
              // 간단한 JSON 배열 파싱
              final urls = parsed.substring(1, parsed.length - 1).split(',');
              if (urls.isNotEmpty) {
                imageUrl =
                    urls.first.trim().replaceAll('"', '').replaceAll("'", '');
              }
            } else {
              imageUrl = parsed;
            }
          } catch (e) {
            print('이미지 URL 파싱 실패: $e');
          }
        }
      }
    }

    final hasImage = imageUrl != null;
    final isCompleted = status != null &&
        (status.toLowerCase() == 'completed' ||
            status.toLowerCase() == 'closed' ||
            status.toLowerCase() == 'sold' ||
            status.toLowerCase() == 'ing');

    return InkWell(
      onTap: () => _navigateToDetail(item),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일 이미지 (왼쪽)
            if (hasImage) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Opacity(
                      opacity: isCompleted ? 0.5 : 1.0,
                      child: Image.network(
                        imageUrl,
                        width: 120.w,
                        height: 120.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120.w,
                            height: 120.w,
                            color: NewAppColor.neutral200,
                            child: Icon(
                              LucideIcons.image,
                              size: 48.sp,
                              color: NewAppColor.neutral400,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // 택배가능 배지 (우측 상단)
                  if (deliveryAvailable)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: NewAppColor.skyPrimary,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: [
                            BoxShadow(
                              color: NewAppColor.skyPrimary.withOpacity(0.32),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.truck,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16.w),
            ],
            // 게시글 정보 (오른쪽)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    title,
                    style: TextStyle(
                      color: isCompleted
                          ? NewAppColor.neutral500
                          : NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  // 작성자 프로필 사진 + 작성자 · 교회명 · 지역 · 시간
                  Row(
                    children: [
                      // 프로필 사진
                      if (authorProfilePhotoUrl != null &&
                          authorProfilePhotoUrl.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(right: 8.w),
                          child: ClipOval(
                            child: Image.network(
                              authorProfilePhotoUrl,
                              width: 20.w,
                              height: 20.w,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 20.w,
                                  height: 20.w,
                                  decoration: const BoxDecoration(
                                    color: NewAppColor.neutral300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.user,
                                    size: 12.sp,
                                    color: NewAppColor.neutral500,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      // 텍스트 정보
                      Expanded(
                        child: Text(
                          [
                            // if (authorName != null && authorName.isNotEmpty)
                            //   authorName,
                            // if (churchName != null && churchName.isNotEmpty)
                            //   churchName,
                            if (churchLocation != null &&
                                churchLocation.isNotEmpty)
                              churchLocation,
                            date,
                          ].join(' · '),
                          style: TextStyle(
                            color: isCompleted
                                ? NewAppColor.neutral400
                                : NewAppColor.neutral600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 가격 (물품 판매/나눔인 경우)
                  if (priceText != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      priceText,
                      style: TextStyle(
                        color: isCompleted
                            ? NewAppColor.neutral500
                            : NewAppColor.neutral900,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard Variable',
                        height: 1.4,
                      ),
                    ),
                  ],
                  // 상태 칩 + 조회수
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 상태 칩 (예약중, 완료만 표시) — 라운드 999 통일
                      if (statusLabel != null &&
                          status != null &&
                          _shouldShowStatus(status))
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 9.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        )
                      else
                        SizedBox.shrink(),
                      // 조회수
                      Row(
                        children: [
                          Icon(
                            LucideIcons.eye,
                            size: 14.sp,
                            color: NewAppColor.neutral600,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '$viewCount',
                            style: TextStyle(
                              color: NewAppColor.neutral600,
                              fontSize: 12.sp,
                              fontFamily: 'Pretendard Variable',
                            ),
                          ),
                        ],
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

  /// 교회 소식 카드 (연락처 스타일)
  Widget _buildChurchNewsCard(dynamic item) {
    String title = '';
    String? imageUrl;
    String date = '';
    int viewCount = 0;
    String? churchName;
    String? churchLocation;
    String? status;
    String? statusLabel;

    if (item is ChurchNews) {
      title = item.title;
      imageUrl = item.images?.isNotEmpty == true ? item.images!.first : null;
      date = item.formattedDate;
      viewCount = item.viewCount;
      churchName = item.churchName;
      churchLocation = item.location;
      status = item.status;
      statusLabel = item.statusDisplayName;
    } else if (item is Map<String, dynamic>) {
      title = item['title'] ?? '';
      date = _formatDate(item['created_at']);
      viewCount = item['view_count'] ?? 0;
      churchName = item['church_name'];
      churchLocation = item['church_location'];
      status = item['status'];
      statusLabel = _getStatusLabel(item['status'], tableName: 'church_news');

      // 이미지 추출
      if (item['images'] != null) {
        if (item['images'] is List && (item['images'] as List).isNotEmpty) {
          imageUrl = (item['images'] as List).first.toString();
        }
      }
    }

    final isCompleted = status != null &&
        (status.toLowerCase() == 'completed' ||
            status.toLowerCase() == 'closed');

    return GestureDetector(
      onTap: () => _navigateToDetail(item),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(width: 1, color: NewAppColor.borderHair),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 썸네일 — 라운드 11 skyTint
            Container(
              width: 44.w,
              height: 44.h,
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                borderRadius: BorderRadius.circular(11.r),
                image: imageUrl != null && imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: imageUrl == null || imageUrl.isEmpty
                  ? Icon(
                      LucideIcons.newspaper,
                      color: NewAppColor.skyDeep,
                      size: 20.sp,
                    )
                  : null,
            ),
            SizedBox(width: 13.w),
            // 텍스트 정보
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FigmaTextStyles().cardTitleSm.copyWith(
                          color: isCompleted
                              ? NewAppColor.textTertiary
                              : NewAppColor.textStrong,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    [
                      if (churchLocation != null &&
                          churchLocation.isNotEmpty)
                        churchLocation,
                      date,
                    ].join(' · '),
                    style: FigmaTextStyles().caption2.copyWith(
                          color: NewAppColor.textTertiary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (statusLabel != null &&
                      status != null &&
                      isCompleted) ...[
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: NewAppColor.borderSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: FigmaTextStyles().badgeSm.copyWith(
                              color: NewAppColor.textSecondary,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // 조회수
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.eye,
                  size: 13.sp,
                  color: NewAppColor.textTertiary,
                ),
                SizedBox(width: 4.w),
                Text(
                  '$viewCount',
                  style: FigmaTextStyles().caption3.copyWith(
                        color: NewAppColor.textTertiary,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return NewAppColor.primary600;

    switch (status.toLowerCase()) {
      case 'active':
        return NewAppColor.success600;
      case 'completed':
      case 'closed':
        return NewAppColor.neutral500;
      case 'cancelled':
        return Colors.red;
      case 'ing': // 예약중
      case 'reserved': // 예약중 (레거시)
        return NewAppColor.warning600;
      case 'requesting':
        return NewAppColor.primary600;
      case 'open':
        return NewAppColor.success600;
      default:
        return NewAppColor.primary600;
    }
  }

  Widget _getStatusIcon(String? status, {Color? useColor}) {
    if (status == null) {
      return Icon(LucideIcons.info,
          size: 16.sp, color: useColor ?? Colors.white);
    }

    final iconColor = useColor ?? Colors.white;

    switch (status.toLowerCase()) {
      case 'ing': // 예약중
      case 'reserved': // 예약중 (레거시)
        return Icon(LucideIcons.clock, size: 16.sp, color: iconColor);
      case 'completed':
      case 'closed':
      case 'sold':
        return Icon(LucideIcons.check, size: 16.sp, color: iconColor);
      default:
        return Icon(LucideIcons.info, size: 16.sp, color: iconColor);
    }
  }

  String _getStatusLabel(String? status,
      {String? tableName, bool isFree = false}) {
    if (status == null) return '';

    final statusLower = status.toLowerCase();

    // 무료나눔 상태
    if (tableName == 'community_sharing' && isFree) {
      switch (statusLower) {
        case 'active':
          return '나눔 가능';
        case 'ing':
        case 'reserved': // 레거시 지원
          return '예약중';
        case 'completed':
          return '나눔 완료';
        default:
          return status;
      }
    }

    // 물품판매 상태
    if (tableName == 'community_sharing' && !isFree) {
      switch (statusLower) {
        case 'active':
          return '판매중';
        case 'ing':
        case 'reserved': // 레거시 지원
          return '예약중';
        case 'completed':
        case 'sold':
          return '판매 완료';
        default:
          return status;
      }
    }

    // 물품요청 상태
    if (tableName == 'community_requests') {
      switch (statusLower) {
        case 'active':
        case 'requesting':
          return '요청중';
        case 'ing':
        case 'reserved': // 레거시 지원
          return '예약중';
        case 'completed':
          return '완료';
        case 'closed':
          return '마감';
        default:
          return status;
      }
    }

    // 구인구직 상태
    if (tableName == 'job_posts') {
      switch (statusLower) {
        case 'active':
        case 'open':
          return '모집중';
        case 'completed':
        case 'closed':
          return '마감';
        default:
          return status;
      }
    }

    // 찬양팀 모집/구함 상태
    if (tableName == 'community_music_teams' ||
        tableName == 'music_team_seekers') {
      switch (statusLower) {
        case 'active':
        case 'open':
          return '모집중';
        case 'completed':
        case 'closed':
          return '마감';
        default:
          return status;
      }
    }

    // 교회소식 상태
    if (tableName == 'church_news') {
      switch (statusLower) {
        case 'active':
          return '게시중';
        case 'completed':
        case 'closed':
          return '종료';
        default:
          return status;
      }
    }

    // 기본값 (tableName이 없거나 매칭되지 않는 경우)
    switch (statusLower) {
      case 'active':
        return '진행중';
      case 'completed':
        return '완료';
      case 'closed':
        return '마감';
      case 'cancelled':
        return '취소';
      case 'ing':
      case 'reserved': // 레거시 지원
        return '예약중';
      default:
        return status;
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _navigateToDetail(dynamic item) {
    int postId = 0;
    String tableName = '';

    // 게시글 ID와 테이블명 추출
    if (item is SharingItem) {
      postId = item.id;
      tableName = 'community_sharing';
    } else if (item is RequestItem) {
      postId = item.id;
      tableName = 'community_requests';
    } else if (item is JobPost) {
      postId = item.id;
      tableName = 'job_posts';
    } else if (item is MusicTeamRecruitment) {
      postId = item.id;
      tableName = 'community_music_teams';
    } else if (item is MusicTeamSeeker) {
      postId = item.id;
      tableName = 'music_team_seekers';
    } else if (item is ChurchNews) {
      postId = item.id;
      tableName = 'church_news';
    } else if (item is Map<String, dynamic>) {
      postId = item['id'] ?? 0;
      tableName = item['table'] ?? '';
    }

    if (postId > 0 && tableName.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityDetailScreen(
            postId: postId,
            tableName: tableName,
            categoryTitle: widget.title,
          ),
        ),
      ).then((result) {
        // 상세 화면에서 돌아왔을 때 항상 목록 새로고침 (조회수 반영)
        print('📋 COMMUNITY_LIST: 상세 화면에서 돌아옴 - result: $result');
        _loadItems();
      });
    }
  }

  bool _canCreatePost() {
    // 내 게시글과 찜한 글은 작성 불가
    if (widget.type == CommunityListType.myPosts ||
        widget.type == CommunityListType.myFavorites) {
      return false;
    }
    return true;
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommunityCreateScreen(
          type: widget.type,
          categoryTitle: widget.title,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadItems();
      }
    });
  }

  /// 위치 필터 UI
  /// 빠른 필터 (전체, 무료, 유료, 완료제거, 택배가능)
  Widget _buildQuickFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 가격 필터 그룹: 전체, 무료, 유료
              _buildSmallFilterChip(
                label: '전체',
                isSelected: _priceFilter == 'all',
                onTap: () {
                  setState(() {
                    _priceFilter = 'all';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '무료',
                isSelected: _priceFilter == 'free',
                onTap: () {
                  setState(() {
                    _priceFilter = 'free';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '유료',
                isSelected: _priceFilter == 'paid',
                onTap: () {
                  setState(() {
                    _priceFilter = 'paid';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 8.w),

              // 구분선
              Container(
                width: 1,
                height: 20.h,
                color: NewAppColor.neutral300,
              ),
              SizedBox(width: 8.w),

              // 상태 필터 그룹: 완료제거, 택배가능
              _buildSmallFilterChip(
                label: '완료제거',
                isSelected: _hideCompleted,
                onTap: () {
                  setState(() {
                    _hideCompleted = !_hideCompleted;
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '택배가능',
                isSelected: _deliveryAvailableFilter == true,
                onTap: () {
                  setState(() {
                    _deliveryAvailableFilter =
                        _deliveryAvailableFilter == true ? null : true;
                    _updateFilteredItems();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 고급 필터 바텀시트
  void _showAdvancedFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdvancedFilterBottomSheet(
        listType: widget.type,
        selectedCity: _selectedCity,
        selectedDistrict: _selectedDistrict,
        selectedCategory: _selectedCategory,
        onApply: (city, district, category) {
          setState(() {
            _selectedCity = city;
            _selectedDistrict = district;
            _selectedCategory = category;
            _updateFilteredItems();
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  /// 빠른 필터 (물품 요청)
  Widget _buildQuickRequestFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 전체 칩
              _buildSmallFilterChip(
                label: '전체',
                isSelected: !_hideCompleted,
                onTap: () {
                  setState(() {
                    _hideCompleted = false;
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 8.w),

              // 구분선
              Container(
                width: 1,
                height: 20.h,
                color: NewAppColor.neutral300,
              ),
              SizedBox(width: 8.w),

              // 완료 제거 필터
              _buildSmallFilterChip(
                label: '완료제거',
                isSelected: _hideCompleted,
                onTap: () {
                  setState(() {
                    _hideCompleted = !_hideCompleted;
                    _updateFilteredItems();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 빠른 필터 (사역자 모집)
  Widget _buildQuickJobFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 고용형태 필터 그룹: 전체, 정규직, 시간제, 자원봉사
              _buildSmallFilterChip(
                label: '전체',
                isSelected: _employmentTypeFilter == 'all',
                onTap: () {
                  setState(() {
                    _employmentTypeFilter = 'all';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '정규직',
                isSelected: _employmentTypeFilter == 'full-time',
                onTap: () {
                  setState(() {
                    _employmentTypeFilter = 'full-time';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '시간제',
                isSelected: _employmentTypeFilter == 'part-time',
                onTap: () {
                  setState(() {
                    _employmentTypeFilter = 'part-time';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '자원봉사',
                isSelected: _employmentTypeFilter == 'volunteer',
                onTap: () {
                  setState(() {
                    _employmentTypeFilter = 'volunteer';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 8.w),

              // 구분선
              Container(
                width: 1,
                height: 20.h,
                color: NewAppColor.neutral300,
              ),
              SizedBox(width: 8.w),

              // 완료 제거 필터
              _buildSmallFilterChip(
                label: '마감제거',
                isSelected: _hideCompleted,
                onTap: () {
                  setState(() {
                    _hideCompleted = !_hideCompleted;
                    _updateFilteredItems();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 빠른 필터 (행사팀 모집)
  Widget _buildQuickMusicTeamFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 팀형태 필터 그룹: 전체, 솔로, 찬양팀, 워십팀, 어쿠스틱, 밴드, 오케스트라, 합창단, 무용팀, 기타
              _buildSmallFilterChip(
                label: '전체',
                isSelected: _teamTypeFilter == 'all',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'all';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '솔로',
                isSelected: _teamTypeFilter == 'solo',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'solo';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '찬양팀',
                isSelected: _teamTypeFilter == 'praise-team',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'praise-team';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '워십팀',
                isSelected: _teamTypeFilter == 'worship-team',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'worship-team';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '어쿠스틱',
                isSelected: _teamTypeFilter == 'acoustic-team',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'acoustic-team';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '밴드',
                isSelected: _teamTypeFilter == 'band',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'band';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '오케스트라',
                isSelected: _teamTypeFilter == 'orchestra',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'orchestra';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '합창단',
                isSelected: _teamTypeFilter == 'choir',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'choir';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '무용팀',
                isSelected: _teamTypeFilter == 'dance-team',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'dance-team';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '기타',
                isSelected: _teamTypeFilter == 'other',
                onTap: () {
                  setState(() {
                    _teamTypeFilter = 'other';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 8.w),

              // 구분선
              Container(
                width: 1,
                height: 20.h,
                color: NewAppColor.neutral300,
              ),
              SizedBox(width: 8.w),

              // 완료 제거 필터
              _buildSmallFilterChip(
                label: '마감제거',
                isSelected: _hideCompleted,
                onTap: () {
                  setState(() {
                    _hideCompleted = !_hideCompleted;
                    _updateFilteredItems();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 빠른 필터 (행사팀 지원)
  Widget _buildQuickMusicTeamSeekingFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 팀형태 필터 그룹: 전체, 솔로, 찬양팀, 워십팀, 어쿠스틱, 밴드, 오케스트라, 합창단, 무용팀, 기타
              _buildSmallFilterChip(
                label: '전체',
                isSelected: _instrumentFilter == 'all',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'all';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '솔로',
                isSelected: _instrumentFilter == 'solo',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'solo';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '찬양팀',
                isSelected: _instrumentFilter == 'praise-team',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'praise-team';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '워십팀',
                isSelected: _instrumentFilter == 'worship-team',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'worship-team';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '어쿠스틱',
                isSelected: _instrumentFilter == 'acoustic-team',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'acoustic-team';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '밴드',
                isSelected: _instrumentFilter == 'band',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'band';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '오케스트라',
                isSelected: _instrumentFilter == 'orchestra',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'orchestra';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '합창단',
                isSelected: _instrumentFilter == 'choir',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'choir';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '무용팀',
                isSelected: _instrumentFilter == 'dance-team',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'dance-team';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 6.w),
              _buildSmallFilterChip(
                label: '기타',
                isSelected: _instrumentFilter == 'other',
                onTap: () {
                  setState(() {
                    _instrumentFilter = 'other';
                    _updateFilteredItems();
                  });
                },
              ),
              SizedBox(width: 8.w),

              // 구분선
              Container(
                width: 1,
                height: 20.h,
                color: NewAppColor.neutral300,
              ),
              SizedBox(width: 8.w),

              // 완료 제거 필터
              _buildSmallFilterChip(
                label: '완료제거',
                isSelected: _hideCompleted,
                onTap: () {
                  setState(() {
                    _hideCompleted = !_hideCompleted;
                    _updateFilteredItems();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 빠른 필터 (교회 소식)
  Widget _buildQuickChurchNewsFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 종료 제거 필터
              _buildSmallFilterChip(
                label: '종료제거',
                isSelected: _hideCompleted,
                onTap: () {
                  setState(() {
                    _hideCompleted = !_hideCompleted;
                    _updateFilteredItems();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상태 칩을 표시할지 여부 (예약중, 완료만)
  bool _shouldShowStatus(String status) {
    final statusLower = status.toLowerCase();
    return statusLower == 'ing' ||
        statusLower == 'reserved' || // 레거시 지원
        statusLower == 'completed' ||
        statusLower == 'closed' ||
        statusLower == 'sold';
  }

  /// 1.2.0 C 방향: 스카이 필터 칩 (활성=skyPrimary, 비활성=라인)
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.skyPrimary : Colors.white,
          border: isSelected
              ? null
              : Border.all(color: NewAppColor.borderStrong, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : NewAppColor.textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 1.2,
          ),
        ),
      ),
    );
  }

  /// 1.2.0 C 방향: 작은 스카이 필터 칩
  Widget _buildSmallFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.skyPrimary : Colors.white,
          border: isSelected
              ? null
              : Border.all(color: NewAppColor.borderStrong, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : NewAppColor.textSecondary,
            fontFamily: 'Pretendard',
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// 고급 필터 바텀시트 위젯
class _AdvancedFilterBottomSheet extends StatefulWidget {
  final CommunityListType listType;
  final String? selectedCity;
  final String? selectedDistrict;
  final String? selectedCategory;
  final Function(String?, String?, String?) onApply;

  const _AdvancedFilterBottomSheet({
    required this.listType,
    this.selectedCity,
    this.selectedDistrict,
    this.selectedCategory,
    required this.onApply,
  });

  @override
  State<_AdvancedFilterBottomSheet> createState() =>
      _AdvancedFilterBottomSheetState();
}

class _AdvancedFilterBottomSheetState
    extends State<_AdvancedFilterBottomSheet> {
  String? _tempCity;
  String? _tempDistrict;
  String? _tempCategory;

  // 카테고리 value와 표시 텍스트 매핑 (교회 소식용)
  final Map<String, String> _newsCategories = {
    'worship': '특별예배/연합예배',
    'event': '행사',
    'retreat': '수련회',
    'mission': '선교',
    'education': '교육',
    'volunteer': '봉사',
    'other': '기타',
  };

  @override
  void initState() {
    super.initState();
    _tempCity = widget.selectedCity;
    _tempDistrict = widget.selectedDistrict;
    _tempCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    // 리스트 타입에 따라 다른 카테고리 옵션 사용
    final List<String>? categoryOptions;
    final String? categoryLabel;

    if (widget.listType == CommunityListType.jobPosting) {
      // 사역자 모집: 직종 카테고리
      categoryOptions = [
        '목사',
        '전도사',
        '찬양사역자',
        '행정간사',
        '교육간사',
        '기타',
      ];
      categoryLabel = '직종';
    } else if (widget.listType == CommunityListType.musicTeamRecruit) {
      // 행사팀 모집: 예배 형태 카테고리
      categoryOptions = [
        '주일예배',
        '새벽예배',
        '수요예배',
        '금요예배',
        '특별예배',
        '콘서트',
        '수련회',
        '기타',
      ];
      categoryLabel = '예배 형태';
    } else if (widget.listType == CommunityListType.musicTeamSeeking) {
      // 행사팀 지원: 카테고리 필터 없음 (상단에 팀 형태 필터가 있음)
      categoryOptions = null;
      categoryLabel = null;
    } else if (widget.listType == CommunityListType.churchNews) {
      // 교회 소식: 소식 카테고리 (value 사용)
      categoryOptions = ['worship', 'event', 'retreat', 'mission', 'education', 'volunteer', 'other'];
      categoryLabel = '카테고리';
    } else {
      // 물품 판매/요청: 물품 카테고리
      categoryOptions = [
        '가구',
        '전자제품',
        '도서',
        '의류',
        '장난감',
        '생활용품',
        '기타',
      ];
      categoryLabel = '카테고리';
    }

    // 1.2.0 C 방향: 핸들바 + 제목 + 섹션 + 칩 + 주 버튼
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E020817),
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들바
            Container(
              margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NewAppColor.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // 헤더
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 4.h, 12.w, 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '상세 필터',
                    style: FigmaTextStyles().subtitle1.copyWith(
                          color: NewAppColor.textStrong,
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      size: 22.sp,
                      color: NewAppColor.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            // 필터 내용
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 지역 라벨
                  Text(
                    '지역',
                    style: FigmaTextStyles().body3.copyWith(
                          color: NewAppColor.textSecondary,
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  SizedBox(height: 10.h),
                  // 도시 선택 (커스텀 셀렉트 — 탭 시 시트로 풀다운)
                  _customSelect(
                    label: _tempCity ?? '전체 도/시',
                    isPlaceholder: _tempCity == null,
                    enabled: true,
                    onTap: () async {
                      final picked = await _showOptionSheet(
                        title: '지역 선택',
                        options: [null, ...LocationData.getCities()],
                        labelOf: (v) => v ?? '전체 도/시',
                        selected: _tempCity,
                      );
                      if (!mounted) return;
                      // picked가 null이면 '선택 안 함'으로, _NoValue면 시트 닫기만
                      if (picked is _PickedValue) {
                        setState(() {
                          _tempCity = picked.value as String?;
                          _tempDistrict = null;
                        });
                      }
                    },
                  ),
                  SizedBox(height: 10.h),
                  // 구 선택
                  _customSelect(
                    label: _tempDistrict ?? '전체 구',
                    isPlaceholder: _tempDistrict == null,
                    enabled: _tempCity != null,
                    onTap: _tempCity == null
                        ? null
                        : () async {
                            final picked = await _showOptionSheet(
                              title: '구/시/군 선택',
                              options: [
                                null,
                                ...LocationData.getDistricts(_tempCity!),
                              ],
                              labelOf: (v) => v ?? '전체 구',
                              selected: _tempDistrict,
                            );
                            if (!mounted) return;
                            if (picked is _PickedValue) {
                              setState(() {
                                _tempDistrict = picked.value as String?;
                              });
                            }
                          },
                  ),
                  // 카테고리/직종 선택
                  if (categoryOptions != null && categoryLabel != null) ...[
                    SizedBox(height: 22.h),
                    Text(
                      categoryLabel,
                      style: FigmaTextStyles().body3.copyWith(
                            color: NewAppColor.textSecondary,
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _categoryChip(
                          label: '전체',
                          isSelected: _tempCategory == null,
                          onTap: () => setState(() => _tempCategory = null),
                        ),
                        ...categoryOptions.map((category) {
                          final displayText = widget.listType ==
                                  CommunityListType.churchNews
                              ? (_newsCategories[category] ?? category)
                              : category;
                          return _categoryChip(
                            label: displayText,
                            isSelected: _tempCategory == category,
                            onTap: () =>
                                setState(() => _tempCategory = category),
                          );
                        }),
                      ],
                    ),
                    SizedBox(height: 22.h),
                  ] else
                    SizedBox(height: 22.h),

                  // 적용 버튼 — 주 버튼 (skyPrimary + 섀도)
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: NewAppColor.skyPrimary,
                      borderRadius: BorderRadius.circular(13.r),
                      child: InkWell(
                        onTap: () {
                          widget.onApply(
                              _tempCity, _tempDistrict, _tempCategory);
                        },
                        borderRadius: BorderRadius.circular(13.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13.r),
                            boxShadow: [
                              BoxShadow(
                                color: NewAppColor.skyPrimary
                                    .withOpacity(0.32),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            '적용',
                            style: FigmaTextStyles().button2.copyWith(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 1.2.0: 커스텀 셀렉트 (라운드 11 borderStrong, 탭 시 시트 풀다운)
  Widget _customSelect({
    required String label,
    required bool isPlaceholder,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : NewAppColor.borderSoft,
          border: Border.all(color: NewAppColor.borderStrong, width: 1),
          borderRadius: BorderRadius.circular(11.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: FigmaTextStyles().body3.copyWith(
                      color: !enabled
                          ? NewAppColor.textTertiary
                          : isPlaceholder
                              ? NewAppColor.textTertiary
                              : NewAppColor.textStrong,
                      fontSize: 14.sp,
                      fontWeight: isPlaceholder
                          ? FontWeight.w500
                          : FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20.sp,
              color: enabled ? NewAppColor.textMuted : NewAppColor.iconFaint,
            ),
          ],
        ),
      ),
    );
  }

  /// 1.2.0: 카테고리 칩 (활성=skyPrimary/흰글자, 비활성=흰배경+borderStrong+textSecondary)
  Widget _categoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.skyPrimary : Colors.white,
          border: isSelected
              ? null
              : Border.all(color: NewAppColor.borderStrong, width: 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : NewAppColor.textSecondary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
            height: 1.2,
          ),
        ),
      ),
    );
  }

  /// 1.2.0: 옵션 풀다운 시트 (라디오 리스트 시트)
  /// 결과: 선택 시 _PickedValue(value), 닫기/취소 시 null
  Future<_PickedValue?> _showOptionSheet<T>({
    required String title,
    required List<T> options,
    required String Function(T) labelOf,
    required T? selected,
  }) {
    return showModalBottomSheet<_PickedValue>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E020817),
                blurRadius: 40,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 10.h, bottom: 14.h),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NewAppColor.borderStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(22.w, 2.h, 22.w, 12.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: FigmaTextStyles().subtitle1.copyWith(
                            color: NewAppColor.textStrong,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 18.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: options.map((opt) {
                        final isSel = opt == selected;
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(
                                  ctx, _PickedValue(opt)),
                              borderRadius: BorderRadius.circular(12.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 14.h),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? NewAppColor.skyTint
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        labelOf(opt),
                                        style: FigmaTextStyles()
                                            .body2
                                            .copyWith(
                                              color: isSel
                                                  ? NewAppColor.skyDeep
                                                  : NewAppColor.neutral700,
                                              fontSize: 15.sp,
                                              fontWeight: isSel
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                    if (isSel)
                                      Icon(
                                        Icons.check,
                                        color: NewAppColor.skyDeep,
                                        size: 19.sp,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 옵션 시트 결과 래퍼 (null과 닫기/취소를 구분)
class _PickedValue {
  final Object? value;
  const _PickedValue(this.value);
}
