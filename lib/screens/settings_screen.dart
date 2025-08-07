import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../components/index.dart';
import '../resource/color_style.dart';
import '../services/auth_service.dart';
import '../services/font_settings_service.dart';
import 'api_test_screen.dart';
import 'users_management_screen.dart';

import 'excel_management_screen.dart';
import 'statistics_dashboard_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  // 설정 값들
  bool _pushNotifications = true;
  bool _attendanceReminder = true;
  bool _birthdayNotifications = true;
  bool _churchNotices = true;
  bool _darkMode = false;
  String _language = '한국어';

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
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          '설정',
          style: TextStyle(
            color: AppColor.secondary07,
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: AppColor.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColor.secondary07),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // 계정 섹션
          _buildSectionHeader('계정'),
          SizedBox(height: 12.h),
          AppCard(
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.person,
                  title: '개인정보 수정',
                  subtitle: '이름, 전화번호, 주소 등',
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                Divider(height: 1, color: AppColor.border1),
                _buildSettingItem(
                  icon: Icons.lock,
                  title: '비밀번호 변경',
                  subtitle: '로그인 비밀번호 변경',
                  onTap: _changePassword,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // 알림 섹션
          _buildSectionHeader('알림 설정'),
          SizedBox(height: 12.h),
          AppCard(
            child: Column(
              children: [
                _buildSwitchItem(
                  icon: Icons.notifications,
                  title: '푸시 알림',
                  subtitle: '모든 푸시 알림 수신',
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
                Divider(height: 1, color: AppColor.border1),
                _buildSwitchItem(
                  icon: Icons.campaign,
                  title: '교회 공지',
                  subtitle: '새로운 공지사항 알림',
                  value: _churchNotices,
                  onChanged: (value) => setState(() => _churchNotices = value),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // 앱 설정 섹션
          _buildSectionHeader('앱 설정'),
          SizedBox(height: 12.h),
          AppCard(
            child: Consumer<FontSettingsService>(
              builder: (context, fontSettings, child) {
                return _buildDropdownItem(
                  icon: Icons.text_fields,
                  title: '글꼴 크기',
                  subtitle:
                      '${fontSettings.fontSize} (${FontSettingsService.getFontSizeDescription(fontSettings.fontSize)})',
                  child: DropdownButton<String>(
                    value: fontSettings.fontSize,
                    onChanged: (value) {
                      if (value != null) {
                        fontSettings.setFontSize(value);
                      }
                    },
                    items: FontSettingsService.fontSizeOptions
                        .map((size) => DropdownMenuItem(
                              value: size,
                              child: Text(
                                  FontSettingsService.getFontSizeDescription(
                                      size)),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 24.h),

          // 교회 정보 섹션
          _buildSectionHeader('교회 정보'),
          SizedBox(height: 12.h),
          AppCard(
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.info,
                  title: '교회 소개',
                  onTap: _showChurchInfo,
                ),
                Divider(height: 1, color: AppColor.border1),
                _buildSettingItem(
                  icon: Icons.phone,
                  title: '연락처',
                  onTap: _showChurchContact,
                ),
                Divider(height: 1, color: AppColor.border1),
                _buildSettingItem(
                  icon: Icons.location_on,
                  title: '위치',
                  onTap: _showChurchLocation,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // 도움말 및 지원
          _buildSectionHeader('도움말 및 지원'),
          SizedBox(height: 12.h),
          AppCard(
            child: Column(
              children: [
                _buildSettingItem(
                  icon: Icons.help,
                  title: '도움말',
                  onTap: _showHelp,
                ),
                Divider(height: 1, color: AppColor.border1),
                _buildSettingItem(
                  icon: Icons.bug_report,
                  title: '문제 신고',
                  onTap: _reportBug,
                ),
                Divider(height: 1, color: AppColor.border1),
                _buildSettingItem(
                  icon: Icons.info_outline,
                  title: '앱 정보',
                  onTap: _showAppInfo,
                ),
                Divider(height: 1, color: AppColor.border1),
                _buildSettingItem(
                  icon: Icons.privacy_tip,
                  title: '개인정보처리방침',
                  onTap: _showPrivacyPolicy,
                ),
                Divider(height: 1, color: AppColor.border1),
                _buildSettingItem(
                  icon: Icons.article,
                  title: '서비스 이용약관',
                  onTap: _showTermsOfService,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // 로그아웃
          AppButton(
            onPressed: _logout,
            variant: ButtonVariant.destructive,
            child: Text('로그아웃'),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  // 섹션 헤더 위젯
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColor.secondary05,
        ),
      ),
    );
  }

  // 설정 아이템 위젯
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: AppColor.primary600,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColor.secondary07,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColor.secondary05,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20.sp,
              color: AppColor.secondary05,
            ),
          ],
        ),
      ),
    );
  }

  // 스위치 아이템 위젯
  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24.sp,
            color: AppColor.primary600,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColor.secondary07,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColor.secondary05,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // 드롭다운 아이템 위젯
  Widget _buildDropdownItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Icon(
            icon,
            size: 24.sp,
            color: AppColor.primary600,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColor.secondary07,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColor.secondary05,
                    ),
                  ),
                ],
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '비밀번호 변경',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(
              placeholder: '현재 비밀번호',
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            AppInput(
              placeholder: '새 비밀번호',
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            AppInput(
              placeholder: '새 비밀번호 확인',
              obscureText: true,
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
                '비밀번호가 성공적으로 변경되었습니다.',
                type: ToastType.success,
              );
            },
            child: Text('변경'),
          ),
        ],
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
              color: AppColor.secondary07,
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
        content: Text('정말 로그아웃하시겠습니까?'),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: Text('취소'),
          ),
          AppButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _authService.logout();
                print('설정 화면: 로그아웃 완료');

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
            child: Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
