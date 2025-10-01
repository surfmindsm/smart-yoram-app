import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/wishlist_models.dart';
import 'package:smart_yoram_app/services/wishlist_service.dart';
import 'package:smart_yoram_app/screens/community/community_detail_screen.dart';

/// 찜한 글 목록 화면
class CommunityFavoritesScreen extends StatefulWidget {
  const CommunityFavoritesScreen({super.key});

  @override
  State<CommunityFavoritesScreen> createState() =>
      _CommunityFavoritesScreenState();
}

class _CommunityFavoritesScreenState extends State<CommunityFavoritesScreen> {
  final WishlistService _wishlistService = WishlistService();

  bool _isLoading = true;
  WishlistData? _wishlistData;
  String? _selectedFilter; // 카테고리 필터
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadWishlists();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWishlists() async {
    setState(() => _isLoading = true);

    try {
      final data = await _wishlistService.getWishlists(
        page: _currentPage,
        limit: _pageSize,
      );

      setState(() {
        _wishlistData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ FAVORITES: 찜한 글 로드 실패 - $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFromWishlist(WishlistItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('찜하기 제거'),
        content: const Text('이 글을 찜한 글에서 제거하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('제거', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final response = await _wishlistService.removeFromWishlist(
        postType: item.postType,
        postId: item.postId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );

        if (response.success) {
          _loadWishlists(); // 목록 새로고침
        }
      }
    }
  }

  List<WishlistItem> _getFilteredItems() {
    if (_wishlistData == null) return [];

    var items = _wishlistData!.items;

    // 카테고리 필터
    if (_selectedFilter != null && _selectedFilter != 'all') {
      items = items.where((item) => item.postType == _selectedFilter).toList();
    }

    // 검색어 필터
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      items = items.where((item) {
        return item.postTitle.toLowerCase().contains(searchQuery) ||
            item.postDescription.toLowerCase().contains(searchQuery);
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내가 찜한 글',
              style: FigmaTextStyles().headline4.copyWith(
                    color: NewAppColor.neutral900,
                  ),
            ),
            Text(
              '관심있는 게시물들을 한 곳에서 확인하세요',
              style: FigmaTextStyles().caption3.copyWith(
                    color: NewAppColor.neutral500,
                  ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: NewAppColor.neutral200,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          // 검색바
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '검색',
                hintStyle: FigmaTextStyles().body3.copyWith(
                      color: NewAppColor.neutral400,
                    ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: NewAppColor.neutral100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          SizedBox(width: 8.w),
          // 카테고리 필터
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: NewAppColor.neutral600),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('전체')),
              const PopupMenuItem(
                  value: 'community-sharing', child: Text('무료나눔')),
              const PopupMenuItem(
                  value: 'sharing-offer', child: Text('물품판매')),
              const PopupMenuItem(
                  value: 'item-request', child: Text('물품요청')),
              const PopupMenuItem(
                  value: 'job-posting', child: Text('사역자모집')),
              const PopupMenuItem(
                  value: 'music-team-recruit', child: Text('행사팀모집')),
              const PopupMenuItem(
                  value: 'music-team-seeking', child: Text('행사팀지원')),
              const PopupMenuItem(
                  value: 'church-events', child: Text('행사소식')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final items = _getFilteredItems();

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadWishlists,
      child: ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: items.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          return _buildItemCard(items[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 64.sp,
            color: NewAppColor.neutral300,
          ),
          SizedBox(height: 16.h),
          Text(
            '찜한 글이 없습니다',
            style: FigmaTextStyles().body2.copyWith(
                  color: NewAppColor.neutral500,
                ),
          ),
          SizedBox(height: 8.h),
          Text(
            '관심있는 게시물을 찜해보세요',
            style: FigmaTextStyles().caption3.copyWith(
                  color: NewAppColor.neutral400,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(WishlistItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () => _navigateToDetail(item),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: NewAppColor.neutral200,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 카테고리 + 날짜 + 삭제 버튼
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      item.postTypeName,
                      style: FigmaTextStyles().caption3.copyWith(
                            color: Colors.pink,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.formattedDate,
                    style: FigmaTextStyles().caption3.copyWith(
                          color: NewAppColor.neutral400,
                        ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.pink),
                    onPressed: () => _removeFromWishlist(item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // 이미지 + 제목
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.needsImage && item.postImageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        item.postImageUrl!,
                        width: 60.w,
                        height: 60.h,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60.w,
                            height: 60.h,
                            color: NewAppColor.neutral100,
                            child: Icon(
                              Icons.image_not_supported,
                              color: NewAppColor.neutral400,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.postTitle,
                          style: FigmaTextStyles().subtitle2.copyWith(
                                color: NewAppColor.neutral900,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.postDescription.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            item.postDescription,
                            style: FigmaTextStyles().body3.copyWith(
                                  color: NewAppColor.neutral600,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(WishlistItem item) {
    // postType을 tableName으로 변환
    String tableName = '';
    String categoryTitle = item.postTypeName;

    switch (item.postType) {
      case 'community-sharing':
      case 'sharing-offer':
        tableName = 'community_sharing';
        break;
      case 'item-request':
        tableName = 'community_requests';
        break;
      case 'job-posting':
        tableName = 'job_posts';
        break;
      case 'music-team-recruit':
        tableName = 'community_music_teams';
        break;
      case 'music-team-seeking':
        tableName = 'music_team_seekers';
        break;
      case 'church-events':
        tableName = 'church_news';
        break;
    }

    if (tableName.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CommunityDetailScreen(
            postId: item.postId,
            tableName: tableName,
            categoryTitle: categoryTitle,
          ),
        ),
      ).then((result) {
        // 상세 화면에서 찜하기 해제하고 돌아온 경우 목록 새로고침
        if (result == true) {
          _loadWishlists();
        }
      });
    }
  }
}
