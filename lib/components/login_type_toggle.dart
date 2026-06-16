import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_yoram_app/resource/color_style_new.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 로그인 방식 토글 — 1.2.0 C 방향 segmented
///
/// 흰 indicator를 Stack 위 별도 레이어로 깔고 [AnimatedAlign]으로 좌우 슬라이드.
/// 텍스트/아이콘은 정지 상태로 색만 보간되어 깜빡임 없음.
class LoginTypeToggle extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const LoginTypeToggle({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  static const _duration = Duration(milliseconds: 220);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final bool isEmail = selectedType == 'email';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: NewAppColor.canvasAlt,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        children: [
          // 1) 슬라이드 indicator (흰 배경 + 그림자) — 좌우로 부드럽게 이동
          Positioned.fill(
            child: AnimatedAlign(
              duration: _duration,
              curve: _curve,
              alignment:
                  isEmail ? Alignment.centerLeft : Alignment.centerRight,
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
              _buildSegment(
                label: '이메일',
                icon: LucideIcons.mail,
                value: 'email',
                selected: isEmail,
              ),
              _buildSegment(
                label: '전화번호',
                icon: LucideIcons.phone,
                value: 'phone',
                selected: !isEmail,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment({
    required String label,
    required IconData icon,
    required String value,
    required bool selected,
  }) {
    final activeColor = NewAppColor.skyPrimary;
    final inactiveColor = NewAppColor.textTertiary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(value),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<Color?>(
                duration: _duration,
                curve: _curve,
                tween: ColorTween(end: selected ? activeColor : inactiveColor),
                builder: (_, color, __) =>
                    Icon(icon, size: 17.sp, color: color),
              ),
              SizedBox(width: 7.w),
              AnimatedDefaultTextStyle(
                duration: _duration,
                curve: _curve,
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
