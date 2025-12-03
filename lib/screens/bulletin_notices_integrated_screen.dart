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
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
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
            // Container(
            //   height: 56.h,
            //   padding: EdgeInsets.symmetric(horizontal: 16.w),
            //   child: Row(
            //     children: [
            //       Text(
            //         '',
            //         style: TextStyle(
            //           color: NewAppColor.neutral900,
            //           fontSize: 20.sp,
            //           fontWeight: FontWeight.w700,
            //           fontFamily: 'Pretendard Variable',
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // 토글 버튼
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: _buildToggleButton(),
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

  Widget _buildToggleButton() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        return Container(
          height: 48.h,
          decoration: BoxDecoration(
            border: Border.all(
              color: NewAppColor.transparent,
              width: 0,
            ),
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Row(
            children: [
              // 주보 버튼
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _tabController.animateTo(0);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _tabController.index == 0
                          ? NewAppColor.neutral700
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Center(
                      child: Text(
                        '주보',
                        style: TextStyle(
                          color: _tabController.index == 0
                              ? Colors.white
                              : NewAppColor.neutral600,
                          fontSize: 16.sp,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // 교회소식 버튼
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _tabController.animateTo(1);
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _tabController.index == 1
                          ? NewAppColor.neutral700
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Center(
                      child: Text(
                        '교회소식',
                        style: TextStyle(
                          color: _tabController.index == 1
                              ? Colors.white
                              : NewAppColor.neutral600,
                          fontSize: 16.sp,
                          fontFamily: 'Pretendard Variable',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
