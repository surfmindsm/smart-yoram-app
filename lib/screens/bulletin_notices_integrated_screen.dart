import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import 'bulletin_screen.dart';
import 'notices_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
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
    ));
  }

  // 1.2.0 C 방향: 세그먼트 토글 (로그인 화면 이메일/전화 토글과 동일)
  // Stack 위에 흰 indicator를 별도 레이어로 두고 AnimatedAlign으로 좌우 슬라이드.
  // 텍스트/아이콘은 정지 상태로 색만 보간되어 깜빡임 없음.
  Widget _buildToggleButton() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final bool isBulletin = _tabController.index == 0;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: NewAppColor.canvasAlt,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Stack(
            children: [
              // 1) 슬라이드 indicator (흰 배경 + 그림자)
              Positioned.fill(
                child: AnimatedAlign(
                  duration: _toggleDuration,
                  curve: _toggleCurve,
                  alignment: isBulletin
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // 2) 라벨 레이어 — 항상 같은 자리 (텍스트 점프 없음)
              Row(
                children: [
                  _segmentTab(
                    index: 0,
                    icon: LucideIcons.bookOpen,
                    label: '주보',
                    selected: isBulletin,
                  ),
                  _segmentTab(
                    index: 1,
                    icon: LucideIcons.fileText,
                    label: '교회소식',
                    selected: !isBulletin,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static const Duration _toggleDuration = Duration(milliseconds: 220);
  static const Curve _toggleCurve = Curves.easeOutCubic;

  Widget _segmentTab({
    required int index,
    required IconData icon,
    required String label,
    required bool selected,
  }) {
    final activeColor = NewAppColor.skyPrimary;
    final inactiveColor = NewAppColor.textTertiary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _tabController.animateTo(index);
          });
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<Color?>(
                duration: _toggleDuration,
                curve: _toggleCurve,
                tween: ColorTween(end: selected ? activeColor : inactiveColor),
                builder: (_, color, __) =>
                    Icon(icon, size: 16.sp, color: color),
              ),
              SizedBox(width: 7.w),
              AnimatedDefaultTextStyle(
                duration: _toggleDuration,
                curve: _toggleCurve,
                style: TextStyle(
                  color: selected ? activeColor : inactiveColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
