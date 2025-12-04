import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:smart_yoram_app/resource/text_style_new.dart';
import 'package:smart_yoram_app/models/wishlist_models.dart';
import 'package:smart_yoram_app/services/wishlist_service.dart';
import 'package:smart_yoram_app/screens/community/community_detail_screen.dart';
import 'package:smart_yoram_app/components/app_dialog.dart';

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
  String _selectedTab = 'sharing'; // 선택된 탭 (물품판매가 기본)

  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadWishlists();
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
    final confirmed = await AppAlertDialog.show(
      context: context,
      title: '찜하기 제거',
      description: '이 글을 찜한 글에서 제거하시겠습니까?',
      confirmText: '제거',
      cancelText: '취소',
      destructive: true,
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '내가 찜한 글',
          style: FigmaTextStyles().headline4.copyWith(
                color: NewAppColor.neutral900,
              ),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final List<Map<String, String>> tabs = [
      {'label': '물품판매', 'value': 'sharing'},
      {'label': '물품요청', 'value': 'item-request'},
      {'label': '사역자모집', 'value': 'job-posting'},
      {'label': '행사팀모집', 'value': 'music-team-recruit'},
      {'label': '행사팀지원', 'value': 'music-team-seeking'},
      {'label': '교회소식', 'value': 'church-events'},
    ];

    return Container(
      height: 56.h,
      decoration: BoxDecoration(
        color: NewAppColor.neutral100,
        border: Border(
          bottom: BorderSide(
            color: Colors.transparent,
            width: 2.0,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _selectedTab == tab['value'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = tab['value']!;
                });
              },
              child: Container(
                height: 56.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  border: isSelected
                      ? Border(
                          bottom: BorderSide(
                            color: NewAppColor.primary600,
                            width: 2.0,
                          ),
                        )
                      : null,
                ),
                child: Center(
                  child: Text(
                    tab['label']!,
                    style: const FigmaTextStyles().title4.copyWith(
                          color: isSelected
                              ? NewAppColor.primary600
                              : NewAppColor.neutral400,
                          fontWeight: FontWeight.w500,
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

  Widget _buildContent() {
    final allItems = _wishlistData?.items ?? [];

    // 탭에 따라 필터링
    List<WishlistItem> items;
    if (_selectedTab == 'sharing') {
      // 물품판매 탭: 무료나눔과 물품판매 모두 표시
      items = allItems
          .where((item) =>
              item.postType == 'community-sharing' ||
              item.postType == 'sharing-offer')
          .toList();
    } else {
      items = allItems.where((item) => item.postType == _selectedTab).toList();
    }

    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadWishlists,
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: NewAppColor.neutral200,
        ),
        itemBuilder: (context, index) {
          return _buildItemCard(items[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String emptyMessage = '해당 카테고리에 찜한 글이 없습니다';

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
            emptyMessage,
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
    final hasImage = item.postImageUrl != null && item.postImageUrl!.isNotEmpty;
    final isSharingType = item.postType == 'community-sharing' ||
                          item.postType == 'sharing-offer';

    return InkWell(
      onTap: () => _navigateToDetail(item),
      child: Container(
        padding: EdgeInsets.all(16.w),
        color: NewAppColor.neutral100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 썸네일 이미지 (왼쪽)
            if (hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  item.postImageUrl!,
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
              SizedBox(width: 16.w),
            ],
            // 게시글 정보 (오른쪽)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목
                  Text(
                    item.postTitle,
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
                  SizedBox(height: 8.h),
                  // 지역 + 날짜
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          [
                            // churchLocation 우선, 없으면 location
                            if (item.churchLocation != null &&
                                item.churchLocation!.isNotEmpty)
                              item.churchLocation
                            else if (item.location != null && item.location!.isNotEmpty)
                              item.location,
                            item.formattedDate,
                          ].join(' · '),
                          style: TextStyle(
                            color: NewAppColor.neutral600,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'Pretendard Variable',
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 가격 + 조회수 (물품 판매/나눔인 경우)
                  if (isSharingType) ...[
                    SizedBox(height: 8.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 가격
                        Text(
                          item.formattedPrice ?? '가격 미정',
                          style: TextStyle(
                            color: NewAppColor.neutral900,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard Variable',
                            height: 1.4,
                          ),
                        ),
                        // 조회수
                        if (item.viewCount != null)
                          Row(
                            children: [
                              Icon(
                                LucideIcons.eye,
                                size: 14.sp,
                                color: NewAppColor.neutral600,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${item.viewCount}',
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
                  ] else ...[
                    // 물품 판매/나눔이 아닌 경우 조회수만 표시
                    if (item.viewCount != null) ...[
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            LucideIcons.eye,
                            size: 14.sp,
                            color: NewAppColor.neutral600,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${item.viewCount}',
                            style: TextStyle(
                              color: NewAppColor.neutral600,
                              fontSize: 12.sp,
                              fontFamily: 'Pretendard Variable',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
            // 찜하기 버튼 (우측 상단)
            SizedBox(width: 8.w),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: () => _removeFromWishlist(item),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24.sp,
            ),
          ],
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
