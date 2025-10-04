import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/community_models.dart';
import 'package:smart_yoram_app/services/community_service.dart';
import 'package:smart_yoram_app/screens/community/community_detail_screen.dart';
import 'package:smart_yoram_app/screens/community/community_create_screen.dart';

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

  bool _isLoading = true;
  List<dynamic> _items = [];

  // 검색 및 필터
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadItems();
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadItems,
                  child: ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: NewAppColor.neutral200,
                    ),
                    itemBuilder: (context, index) {
                      return _buildItemCard(_items[index]);
                    },
                  ),
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
    String? authorName;
    String? churchName;
    String? churchLocation; // 교회 지역 (도시 + 구/동)

    if (item is SharingItem) {
      title = item.title;
      imageUrl = item.images.isNotEmpty ? item.images.first : null;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorName = item.authorName;
      churchName = item.churchName;
      churchLocation = item.churchLocation;
    } else if (item is RequestItem) {
      title = item.title;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorName = item.authorName;
      churchName = item.churchName;
      churchLocation = item.location;
    } else if (item is JobPost) {
      title = item.title;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorName = item.authorName;
      churchName = item.churchName;
      churchLocation = item.location;
    } else if (item is MusicTeamRecruitment) {
      title = item.title;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorName = item.authorName;
      churchName = item.churchName;
      churchLocation = item.location;
    } else if (item is MusicTeamSeeker) {
      title = item.title;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorName = item.authorName;
      churchName = item.churchName;
    } else if (item is ChurchNews) {
      title = item.title;
      imageUrl = item.images?.isNotEmpty == true ? item.images!.first : null;
      date = item.formattedDate;
      viewCount = item.viewCount;
      likes = item.likes;
      authorName = item.authorName;
      churchName = item.churchName;
      churchLocation = item.location;
    } else if (item is Map<String, dynamic>) {
      // myPosts의 경우
      title = item['title'] ?? '';
      date = _formatDate(item['created_at']);
      viewCount = item['view_count'] ?? 0;
      likes = item['likes'] ?? 0;
      authorName = item['author_name'];
      churchName = item['church_name'];
      churchLocation = item['church_location'];
    }

    final hasImage = imageUrl != null;

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
                  // 제목
                  Text(
                    title,
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard Variable',
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                      color: NewAppColor.neutral600,
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
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
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
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case '진행중':
      case '나눔가능':
      case '모집중':
      case '요청중':
        return NewAppColor.success600;
      case 'completed':
      case '완료':
      case '마감':
        return NewAppColor.neutral500;
      case 'cancelled':
      case '취소':
        return Colors.red;
      case 'reserved':
      case '예약중':
        return NewAppColor.warning600;
      default:
        return NewAppColor.primary600;
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
}
