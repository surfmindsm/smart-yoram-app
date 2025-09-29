import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../components/index.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../services/auth_service.dart';
import '../services/font_settings_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'profile_edit_screen.dart';

class _GroupedSettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _GroupedSettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  // 설정 값들
  bool _pushNotifications = true;
  bool _churchNotices = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider를 통해 현재 글꼴 크기 가져오기
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: Column(
        children: [
          // 상단 여백 (탭 네비게이션에서 들어올 때)
          SizedBox(height: MediaQuery.of(context).padding.top + 22.h),

          // 메인 콘텐츠
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              children: [
          // 계정 섹션
          _buildGroupedSection(
            title: '계정',
            items: [
              _GroupedSettingItem(
                icon: Icons.person_outline,
                title: '개인정보 수정',
                subtitle: '이름, 전화번호, 주소 등',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileEditScreen(),
                  ),
                ),
              ),
              _GroupedSettingItem(
                icon: Icons.lock_outline,
                title: '비밀번호 변경',
                subtitle: '로그인 비밀번호 변경',
                onTap: _changePassword,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 알림 설정 섹션
          _buildGroupedSection(
            title: '알림 설정',
            items: [
              _GroupedSettingItem(
                icon: Icons.notifications_outlined,
                title: '푸시 알림',
                subtitle: '모든 푸시 알림 수신',
                trailing: AppSwitch(
                  value: _pushNotifications,
                  onChanged: (value) => setState(() => _pushNotifications = value),
                ),
              ),
              _GroupedSettingItem(
                icon: Icons.campaign_outlined,
                title: '교회 공지',
                subtitle: '새로운 공지사항 알림',
                trailing: AppSwitch(
                  value: _churchNotices,
                  onChanged: (value) => setState(() => _churchNotices = value),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // 앱 설정 섹션
          Consumer<FontSettingsService>(
            builder: (context, fontSettings, child) {
              return _buildGroupedSection(
                title: '앱 설정',
                items: [
                  _GroupedSettingItem(
                    icon: Icons.text_fields_outlined,
                    title: '글꼴 크기',
                    subtitle: FontSettingsService.getFontSizeDescription(fontSettings.fontSize),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: NewAppColor.neutral200),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            FontSettingsService.getFontSizeDescription(fontSettings.fontSize),
                            style: const FigmaTextStyles().caption1.copyWith(
                              color: NewAppColor.neutral800,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 12.sp,
                            color: NewAppColor.neutral800,
                          ),
                        ],
                      ),
                    ),
                    onTap: () => _showFontSizeOptions(),
                  ),
                ],
              );
            },
          ),

          SizedBox(height: 16.h),

          // 교회 정보 섹션
          _buildGroupedSection(
            title: '교회 정보',
            items: [
              _GroupedSettingItem(
                icon: Icons.church_outlined,
                title: '교회 소개',
                onTap: _showChurchInfo,
              ),
              _GroupedSettingItem(
                icon: Icons.phone_outlined,
                title: '연락처',
                onTap: _showChurchContact,
              ),
              _GroupedSettingItem(
                icon: Icons.location_on_outlined,
                title: '위치',
                onTap: _showChurchLocation,
              ),
            ],
          ),

          // 도움말 및 지원
          _buildGroupedSection(
            title: '도움말 및 지원',
            items: [
              _GroupedSettingItem(
                icon: Icons.help_outline,
                title: '도움말',
                onTap: _showHelp,
              ),
              _GroupedSettingItem(
                icon: Icons.bug_report_outlined,
                title: '문제 신고',
                onTap: _reportBug,
              ),
              _GroupedSettingItem(
                icon: Icons.info_outline,
                title: '앱 정보',
                onTap: _showAppInfo,
              ),
              _GroupedSettingItem(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보처리방침',
                onTap: _showPrivacyPolicy,
              ),
              _GroupedSettingItem(
                icon: Icons.description_outlined,
                title: '서비스 이용약관',
                onTap: _showTermsOfService,
              ),
            ],
          ),

          // 로그아웃 섹션
          _buildGroupedSection(
            title: '계정 관리',
            items: [
              _GroupedSettingItem(
                icon: Icons.logout,
                title: '로그아웃',
                onTap: _logout,
              ),
            ],
          ),
          SizedBox(height: 32.h),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // 그룹화된 섹션 위젯
  Widget _buildGroupedSection({
    required String title,
    required List<_GroupedSettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Padding(
          padding: EdgeInsets.only(bottom: 16.h, top: 24.h),
          child: Text(
            title,
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
        ),
        // 그룹화된 컨테이너
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: ShapeDecoration(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isFirst = index == 0;
              final isLast = index == items.length - 1;

              return _buildGroupedSettingItem(
                item: item,
                isFirst: isFirst,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 그룹화된 설정 아이템 위젯
  Widget _buildGroupedSettingItem({
    required _GroupedSettingItem item,
    required bool isFirst,
    required bool isLast,
  }) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 58.h),
        padding: EdgeInsets.symmetric(horizontal: 15.5.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: !isLast ? Border(
            bottom: BorderSide(
              width: 1,
              color: NewAppColor.neutral200,
            ),
          ) : null,
        ),
        child: Row(
          children: [
            // 아이콘
            Container(
              width: 28.w,
              height: 28.h,
              decoration: ShapeDecoration(
                color: NewAppColor.primary200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.r),
                ),
              ),
              child: Icon(
                item.icon,
                size: 16.sp,
                color: NewAppColor.primary600,
              ),
            ),
            SizedBox(width: 12.w),
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: NewAppColor.neutral900,
                      fontSize: 14.sp,
                      fontFamily: 'Pretendard Variable',
                      fontWeight: FontWeight.w400,
                      height: 1.43,
                      letterSpacing: -0.35,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        color: NewAppColor.neutral600,
                        fontSize: 13.sp,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        height: 1.38,
                        letterSpacing: -0.33,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 19.w),
            // 트레일링 영역 (화살표 또는 스위치)
            if (item.trailing != null)
              item.trailing!
            else
              Container(
                width: 28.w,
                height: 28.h,
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: NewAppColor.neutral400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '비밀번호 변경',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(
              controller: currentPasswordController,
              placeholder: '현재 비밀번호',
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            AppInput(
              controller: newPasswordController,
              placeholder: '새 비밀번호',
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            AppInput(
              controller: confirmPasswordController,
              placeholder: '새 비밀번호 확인',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () {
              currentPasswordController.dispose();
              newPasswordController.dispose();
              confirmPasswordController.dispose();
              Navigator.pop(context);
            },
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () => _handlePasswordChange(
              currentPasswordController.text,
              newPasswordController.text,
              confirmPasswordController.text,
              currentPasswordController,
              newPasswordController,
              confirmPasswordController,
            ),
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePasswordChange(
    String currentPassword,
    String newPassword,
    String confirmPassword,
    TextEditingController currentController,
    TextEditingController newController,
    TextEditingController confirmController,
  ) async {
    // 입력값 검증
    if (currentPassword.isEmpty) {
      AppToast.show(
        context,
        '현재 비밀번호를 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    if (newPassword.isEmpty) {
      AppToast.show(
        context,
        '새 비밀번호를 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    if (newPassword.length < 6) {
      AppToast.show(
        context,
        '새 비밀번호는 6자 이상이어야 합니다.',
        type: ToastType.error,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppToast.show(
        context,
        '새 비밀번호와 확인 비밀번호가 일치하지 않습니다.',
        type: ToastType.error,
      );
      return;
    }

    if (currentPassword == newPassword) {
      AppToast.show(
        context,
        '현재 비밀번호와 새 비밀번호가 동일합니다.',
        type: ToastType.error,
      );
      return;
    }

    // 다이얼로그 닫기
    Navigator.pop(context);

    try {
      // 비밀번호 변경 요청
      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // 컨트롤러 정리
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();

      if (mounted) {
        if (response.success) {
          AppToast.show(
            context,
            '비밀번호가 성공적으로 변경되었습니다.',
            type: ToastType.success,
          );
        } else {
          AppToast.show(
            context,
            response.message.isNotEmpty
              ? response.message
              : '비밀번호 변경에 실패했습니다.',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      // 컨트롤러 정리
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();

      if (mounted) {
        AppToast.show(
          context,
          '비밀번호 변경 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _showFontSizeOptions() {
    showDialog(
      context: context,
      builder: (context) => Consumer<FontSettingsService>(
        builder: (context, fontSettings, child) {
          return AppDialog(
            title: '글꼴 크기 설정',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: FontSettingsService.fontSizeOptions.map((option) {
                final isSelected = fontSettings.fontSize == option;
                return GestureDetector(
                  onTap: () async {
                    await fontSettings.setFontSize(option);
                    if (mounted) {
                      Navigator.pop(context);
                      AppToast.show(
                        context,
                        '글꼴 크기가 ${FontSettingsService.getFontSizeDescription(option)}로 변경되었습니다.',
                        type: ToastType.success,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    margin: EdgeInsets.only(bottom: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? NewAppColor.primary100 : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral900,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                FontSettingsService.getFontSizeDescription(option),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isSelected ? NewAppColor.primary500 : NewAppColor.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: NewAppColor.primary600,
                            size: 24.sp,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            actions: [
              AppButton(
                onPressed: () => Navigator.pop(context),
                variant: ButtonVariant.ghost,
                child: const Text('닫기'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChurchInfo() {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '교회 소개',
        content: SingleChildScrollView(
          child: Text(
            '우리 교회는 하나님의 사랑을 실천하며, 지역사회와 함께 성장하는 교회입니다.\n\n'
            '설립년도: 1995년\n'
            '담임목사: 김목사님\n'
            '교인 수: 약 500명\n\n'
            '우리의 비전은 모든 성도가 그리스도의 제자로 성장하여 세상의 빛과 소금이 되는 것입니다.',
            style: TextStyle(
              fontSize: 14.sp,
              color: NewAppColor.neutral900,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showChurchContact() {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '연락처',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('전화: 02-1234-5678', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 8.h),
            Text('팩스: 02-1234-5679', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 8.h),
            Text('이메일: info@church.com', style: TextStyle(fontSize: 14.sp)),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showChurchLocation() {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '교회 위치',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주소: 서울특별시 강남구 테헤란로 123\n교회건물 2층',
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              '지하철: 2호선 강남역 3번 출구에서 도보 5분',
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '도움말',
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: ExpansionTile(
                  title: Text('로그인이 안돼요'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        '이메일과 비밀번호를 다시 한번 확인해주세요. 비밀번호를 잊으셨다면 "비밀번호 찾기"를 이용해주세요.',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.h),
              AppCard(
                child: ExpansionTile(
                  title: Text('알림을 받지 못해요'),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        '설정 > 알림 설정에서 원하는 알림을 켜주세요. 또한 기기 설정에서 앱 알림이 허용되어 있는지 확인해주세요.',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '문제 신고',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(
              placeholder: '문제 유형',
            ),
            SizedBox(height: 16.h),
            AppInput(
              placeholder: '문제 설명',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: Text('취소'),
          ),
          AppButton(
            onPressed: () {
              Navigator.pop(context);
              AppToast.show(
                context,
                '다운로드가 완료되었습니다.',
                type: ToastType.success,
              );
            },
            child: Text('전송'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '앱 정보',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('스마트 교회요람',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text('버전 1.0.0', style: TextStyle(fontSize: 14.sp)),
            SizedBox(height: 16.h),
            Text('© 2024 스마트 교회요람', style: TextStyle(fontSize: 12.sp)),
            SizedBox(height: 8.h),
            Text('교회 생활을 더욱 편리하게 만들어주는 앱입니다.',
                style: TextStyle(fontSize: 14.sp)),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceScreen(),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '로그아웃',
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _authService.logout();

                if (mounted) {
                  AppToast.show(
                    context,
                    '로그아웃되었습니다.',
                    type: ToastType.success,
                  );

                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  AppToast.show(
                    context,
                    '로그아웃 오류: $e',
                    type: ToastType.error,
                  );
                }
              }
            },
            variant: ButtonVariant.destructive,
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

}
