import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import 'bulletin_screen.dart';
import 'notices_screen.dart';

class BulletinNoticesIntegratedScreen extends StatefulWidget {
  const BulletinNoticesIntegratedScreen({super.key});

  @override
  State<BulletinNoticesIntegratedScreen> createState() =>
      _BulletinNoticesIntegratedScreenState();
}

class _BulletinNoticesIntegratedScreenState
    extends State<BulletinNoticesIntegratedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 1.2.0 C 방향: 타이틀 + 세그먼트 토글 (흰 상단 영역)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.canvasAlt,
      body: Column(
        children: [
          // 흰 배경 상단 영역 (타이틀 + 세그먼트 토글)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(width: 1, color: NewAppColor.borderSoft),
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 6.h,
              left: 18.w,
              right: 18.w,
              bottom: 14.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Text(
                    '교회소식',
                    style: FigmaTextStyles().pageTitle.copyWith(
                          color: NewAppColor.textStrong,
                          fontSize: 21.sp,
                        ),
                  ),
                ),
                SizedBox(height: 12.h),
                _buildToggleButton(),
              ],
            ),
          ),
          // 탭 콘텐츠 — 가로 스와이프 차단 (자식 hit-test 보호)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                BulletinScreen(showTopPadding: false),
                NoticesScreen(showAppBar: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1.2.0 C 방향: 세그먼트 토글 (#F1F5F9 트랙 + 선택 시 흰배경 + skyDeep + 섀도)
  Widget _buildToggleButton() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            color: NewAppColor.borderSoft,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              _segmentTab(
                index: 0,
                icon: Icons.menu_book_outlined,
                label: '주보',
              ),
              _segmentTab(
                index: 1,
                icon: Icons.article_outlined,
                label: '교회소식',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _segmentTab({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _tabController.animateTo(index);
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF020817).withOpacity(0.07),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: isSelected
                    ? NewAppColor.skyDeep
                    : NewAppColor.textTertiary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: FigmaTextStyles().body3.copyWith(
                      color: isSelected
                          ? NewAppColor.skyDeep
                          : NewAppColor.textTertiary,
                      fontSize: 14.sp,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
