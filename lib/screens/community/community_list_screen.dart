import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/models/user.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/services/auth_service.dart';
import 'package:smart_yoram_app/screens/community/community_detail_screen.dart';
import 'package:smart_yoram_app/screens/community/community_create_screen.dart';
import 'package:smart_yoram_app/utils/location_data.dart';

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
  User? _currentUser;

  // 검색 및 필터
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory; // 카테고리 필터 (가구, 전자제품 등)
  String? _selectedStatus; // 상태 필터 (나눔가능, 예약중, 완료)
  String? _selectedCity; // 도/시 필터
  String? _selectedDistrict; // 시/군/구 필터
  bool? _deliveryAvailableFilter; // 택배가능 필터

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadItems();
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
          items = await _communityService.getSharingItems(isFree: true);
          break;
        case CommunityListType.itemSale:
          items = await _communityService.getSharingItems(isFree: false);
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
      });
    } catch (e) {
      print('❌ COMMUNITY_LIST: 목록 로드 실패 - $e');
      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  /// 필터링된 아이템 목록
  List<dynamic> get _filteredItems {
    List<dynamic> filtered = _items;

    // 상태 필터 (무료나눔/물품판매)
    if (_selectedStatus != null && (widget.type == CommunityListType.freeSharing || widget.type == CommunityListType.itemSale)) {
      filtered = filtered.where((item) {
        if (item is SharingItem) {
          return item.status.toLowerCase() == _selectedStatus!.toLowerCase();
        }
        return false;
      }).toList();
    }

    // 카테고리 필터 (무료나눔/물품판매)
    if (_selectedCategory != null && (widget.type == CommunityListType.freeSharing || widget.type == CommunityListType.itemSale)) {
      filtered = filtered.where((item) {
        if (item is SharingItem) {
          return item.category == _selectedCategory;
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
          location = item.location;
        } else if (item is ChurchNews) {
          location = item.location;
        }

        // SharingItem은 province 우선, 없으면 location
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
          location = item.location;
        } else if (item is ChurchNews) {
          location = item.location;
        }

        // SharingItem은 district 우선, 없으면 location
        if (district != null && district.isNotEmpty) {
          return district == _selectedDistrict;
        } else if (location != null && location.isNotEmpty) {
          return location.contains(_selectedDistrict!);
        }
        return false;
      }).toList();
    }

    // 택배가능 필터 (무료나눔/물품판매)
    if (_deliveryAvailableFilter != null && (widget.type == CommunityListType.freeSharing || widget.type == CommunityListType.itemSale)) {
      filtered = filtered.where((item) {
        if (item is SharingItem) {
          return item.deliveryAvailable == _deliveryAvailableFilter;
        }
        return false;
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: FigmaTextStyles().headline4.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
        actions: [
          // 검색 버튼
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // TODO: 검색 기능
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('검색 기능은 준비 중입니다')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 위치 필터
          if (widget.type == CommunityListType.freeSharing ||
              widget.type == CommunityListType.itemSale ||
              widget.type == CommunityListType.itemRequest ||
              widget.type == CommunityListType.jobPosting ||
              widget.type == CommunityListType.musicTeamRecruit ||
              widget.type == CommunityListType.musicTeamSeeking ||
              widget.type == CommunityListType.churchNews)
            _buildLocationFilters(),
          // 상태 + 카테고리 필터 (무료나눔/물품판매)
          if (widget.type == CommunityListType.freeSharing ||
              widget.type == CommunityListType.itemSale)
            _buildStatusAndCategoryFilters(),
          // 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadItems,
                        child: ListView.separated(
                          itemCount: _filteredItems.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 1,
                            color: NewAppColor.neutral200,
                          ),
                          itemBuilder: (context, index) {
                            return _buildItemCard(_filteredItems[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: _canCreatePost()
          ? FloatingActionButton(
              onPressed: _navigateToCreate,
              backgroundColor: NewAppColor.primary600,
              child: Icon(Icons.add, color: Colors.white, size: 32.sp),
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
            size: 64.sp,
            color: NewAppColor.neutral300,
          ),
          SizedBox(height: 16.h),
          Text(
            '게시글이 없습니다',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) {
    // 공통 필드 추출
    String title = '';
    String? imageUrl;
    String date = '';
    int viewCount = 0;
    int likes = 0;
    int? authorId; // 작성자 ID
    String? authorName;
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
      churchName = item.churchName;
      churchLocation = item.displayLocation; // province + district
      deliveryAvailable = item.deliveryAvailable;
      status = item.status;
      statusLabel = item.statusDisplayName;
      // 무료나눔이 아닌 경우만 가격 표시
      if (!item.isFree) {
        priceText = item.formattedPrice;
      }
    } else if (item is RequestItem) {
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
      churchLocation = item.location;
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
    } else if (item is ChurchNews) {
      title = item.title;
      imageUrl = item.images?.isNotEmpty == true ? item.images!.first : null;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorId = item.authorId;
      authorName = item.authorName;
      churchName = item.churchName;
      churchLocation = item.location;
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
      statusLabel = _getStatusLabel(item['status'], tableName: tableName, isFree: isFree);

      // 이미지 추출 (images 필드가 있는 경우)
      if (item['images'] != null) {
        if (item['images'] is List && (item['images'] as List).isNotEmpty) {
          imageUrl = (item['images'] as List).first.toString();
        } else if (item['images'] is String && (item['images'] as String).isNotEmpty) {
          // JSON 문자열인 경우 파싱 시도
          try {
            final parsed = item['images'] as String;
            if (parsed.startsWith('[') && parsed.endsWith(']')) {
              // 간단한 JSON 배열 파싱
              final urls = parsed.substring(1, parsed.length - 1).split(',');
              if (urls.isNotEmpty) {
                imageUrl = urls.first.trim().replaceAll('"', '').replaceAll("'", '');
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
    final isCompleted = status != null && (status.toLowerCase() == 'completed' || status.toLowerCase() == 'closed' || status.toLowerCase() == 'sold');

    return InkWell(
      onTap: () => _navigateToDetail(item),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 게시글 정보 (왼쪽)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상태 칩 (이미지가 없고, 예약중/완료인 경우만)
                  if (statusLabel != null && status != null && _shouldShowStatus(status) && !hasImage) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                  ],
                  // 제목
                  Text(
                    title,
                    style: TextStyle(
                      color: isCompleted ? NewAppColor.neutral500 : NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 가격 (물품 판매/나눔인 경우)
                  if (priceText != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      priceText,
                      style: TextStyle(
                        color: isCompleted ? NewAppColor.neutral500 : NewAppColor.neutral900,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard Variable',
                      ),
                    ),
                  ],
                  SizedBox(height: 4.h),
                  // 작성자 · 교회명 · 지역 · 시간
                  Text(
                    [
                      if (authorName != null && authorName.isNotEmpty) authorName,
                      if (churchName != null && churchName.isNotEmpty) churchName,
                      if (churchLocation != null && churchLocation.isNotEmpty) churchLocation,
                      date,
                    ].join(' · '),
                    style: TextStyle(
                      color: isCompleted ? NewAppColor.neutral400 : NewAppColor.neutral600,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  // 조회수
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 16.sp,
                        color: NewAppColor.neutral500,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '$viewCount',
                        style: TextStyle(
                          color: NewAppColor.neutral500,
                          fontSize: 13.sp,
                          fontFamily: 'Pretendard Variable',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 썸네일 이미지 (오른쪽)
            if (hasImage) ...[
              SizedBox(width: 16.w),
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
                              Icons.image_outlined,
                              size: 48.sp,
                              color: NewAppColor.neutral400,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // 상태 칩 (예약중, 완료만 표시)
                  if (status != null && statusLabel != null && _shouldShowStatus(status))
                    Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                      ),
                    ),
                  // 택배가능 배지 (우측 상단)
                  if (deliveryAvailable)
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
                          '택배가능',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
        return NewAppColor.warning600;
      case 'requesting':
        return NewAppColor.primary600;
      case 'open':
        return NewAppColor.success600;
      default:
        return NewAppColor.primary600;
    }
  }

  String _getStatusLabel(String? status, {String? tableName, bool isFree = false}) {
    if (status == null) return '';

    final statusLower = status.toLowerCase();

    // 무료나눔 상태
    if (tableName == 'community_sharing' && isFree) {
      switch (statusLower) {
        case 'active':
          return '나눔 가능';
        case 'ing':
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
    if (tableName == 'community_music_teams' || tableName == 'music_team_seekers') {
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
        return '예약중';
      default:
        return status;
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return '방금 전';
      if (difference.inHours < 1) return '${difference.inMinutes}분 전';
      if (difference.inDays < 1) return '${difference.inHours}시간 전';
      if (difference.inDays < 7) return '${difference.inDays}일 전';

      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
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
        // 상세 화면에서 삭제 등의 작업 후 돌아왔을 때 목록 새로고침
        if (result == true) {
          _loadItems();
        }
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
  Widget _buildLocationFilters() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(
            color: NewAppColor.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 도/시 선택
          Expanded(
            child: Container(
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                border: Border.all(color: NewAppColor.neutral300),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedCity,
                  hint: Text(
                    '전체 도/시',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: NewAppColor.neutral900,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('전체 도/시'),
                    ),
                    ...LocationData.getCities().map((city) {
                      return DropdownMenuItem<String?>(
                        value: city,
                        child: Text(
                          city,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: NewAppColor.neutral900,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                      _selectedDistrict = null; // 도/시 변경 시 구 초기화
                    });
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // 시/군/구 선택
          Expanded(
            child: Container(
              height: 40.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedCity == null
                      ? NewAppColor.neutral200
                      : NewAppColor.neutral300,
                ),
                borderRadius: BorderRadius.circular(8.r),
                color: _selectedCity == null
                    ? NewAppColor.neutral100
                    : Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedDistrict,
                  hint: Text(
                    '전체 구',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _selectedCity == null
                          ? NewAppColor.neutral400
                          : NewAppColor.neutral900,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('전체 구'),
                    ),
                    if (_selectedCity != null)
                      ...LocationData.getDistricts(_selectedCity!).map((district) {
                        return DropdownMenuItem<String?>(
                          value: district,
                          child: Text(
                            district,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: NewAppColor.neutral900,
                              fontFamily: 'Pretendard Variable',
                            ),
                          ),
                        );
                      }),
                  ],
                  onChanged: _selectedCity == null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedDistrict = value;
                          });
                        },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 + 카테고리 필터 (무료나눔/물품판매)
  Widget _buildStatusAndCategoryFilters() {
    // 상태 옵션
    final List<Map<String, String>> statusOptions = widget.type == CommunityListType.freeSharing
        ? [
            {'value': 'active', 'label': '나눔 가능'},
            {'value': 'ing', 'label': '예약중'},
            {'value': 'completed', 'label': '나눔 완료'},
          ]
        : [
            {'value': 'active', 'label': '판매중'},
            {'value': 'ing', 'label': '예약중'},
            {'value': 'completed', 'label': '판매 완료'},
          ];

    // 카테고리 옵션
    final List<String> categoryOptions = [
      '가구',
      '전자제품',
      '도서',
      '의류',
      '장난감',
      '생활용품',
      '기타',
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: NewAppColor.neutral200, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 전체 칩
            _buildFilterChip(
              label: '전체',
              isSelected: _selectedStatus == null && _selectedCategory == null && _deliveryAvailableFilter == null,
              onTap: () {
                setState(() {
                  _selectedStatus = null;
                  _selectedCategory = null;
                  _deliveryAvailableFilter = null;
                });
              },
            ),
            SizedBox(width: 8.w),

            // 상태 필터 칩들
            ...statusOptions.map((option) {
              final value = option['value']!;
              final label = option['label']!;
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildFilterChip(
                  label: label,
                  isSelected: _selectedStatus == value,
                  onTap: () {
                    setState(() {
                      _selectedStatus = _selectedStatus == value ? null : value;
                    });
                  },
                ),
              );
            }),

            // 택배가능 필터
            _buildFilterChip(
              label: '택배가능',
              isSelected: _deliveryAvailableFilter == true,
              onTap: () {
                setState(() {
                  _deliveryAvailableFilter = _deliveryAvailableFilter == true ? null : true;
                });
              },
            ),
            SizedBox(width: 8.w),

            // 구분선
            Container(
              width: 1,
              height: 24.h,
              color: NewAppColor.neutral300,
              margin: EdgeInsets.symmetric(horizontal: 8.w),
            ),

            // 카테고리 필터 칩들
            ...categoryOptions.map((category) {
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildFilterChip(
                  label: category,
                  isSelected: _selectedCategory == category,
                  onTap: () {
                    setState(() {
                      _selectedCategory = _selectedCategory == category ? null : category;
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 상태 칩을 표시할지 여부 (예약중, 완료만)
  bool _shouldShowStatus(String status) {
    final statusLower = status.toLowerCase();
    return statusLower == 'ing' ||
           statusLower == 'completed' ||
           statusLower == 'closed' ||
           statusLower == 'sold';
  }

  /// 필터 칩 위젯
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.neutral900 : NewAppColor.neutral100,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? NewAppColor.neutral900 : NewAppColor.neutral300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: FigmaTextStyles().body2.copyWith(
            color: isSelected ? Colors.white : NewAppColor.neutral700,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
