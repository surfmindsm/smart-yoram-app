import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Container(
              height: 56.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    '교회소식',
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard Variable',
                    ),
                  ),
                ],
              ),
            ),

            // 탭바
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 2,
                  color: NewAppColor.neutral200,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTab(
                  index: 0,
                  label: '주보',
                ),
                SizedBox(width: 24.w),
                _buildTab(
                  index: 1,
                  label: '교회소식',
                ),
              ],
            ),
          ),

            // 탭 콘텐츠
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  BulletinScreen(showTopPadding: false),
                  NoticesScreen(showAppBar: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          final isCurrentlySelected = _tabController.index == index;
          return Container(
            height: 48.h,
            decoration: isCurrentlySelected
                ? const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: NewAppColor.neutral900,
                      ),
                    ),
                  )
                : null,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isCurrentlySelected
                      ? NewAppColor.neutral900
                      : NewAppColor.neutral400,
                  fontSize: 16.sp,
                  fontFamily: 'Pretendard Variable',
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
