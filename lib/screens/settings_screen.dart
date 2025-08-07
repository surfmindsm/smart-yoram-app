import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../widget/widgets.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/font_settings_service.dart';
import 'api_test_screen.dart';
import 'users_management_screen.dart';
import 'family_management_screen.dart';
import 'sms_management_screen.dart';
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
    // 초기에 글꼴 설정 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider를 통해 현재 글꼴 크기 가져오기
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: CommonAppBar(
      //   title: '설정',
      // ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10.h),
          // 계정 섹션
          SectionHeader(title: '계정'),
          CustomListTile(
            icon: Icons.person,
            title: '개인정보 수정',
            subtitle: '이름, 전화번호, 주소 등',
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          CustomListTile(
            icon: Icons.lock,
            title: '비밀번호 변경',
            subtitle: '로그인 비밀번호 변경',
            onTap: _changePassword,
          ),
          // CustomListTile(
          //   icon: Icons.family_restroom,
          //   title: '가족 관리',
          //   subtitle: '가족 구성원 추가/수정',
          //   onTap: _manageFamilyMembers,
          // ),

          const Divider(height: 32),

          // 알림 섹션
          SectionHeader(title: '알림 설정'),
          CustomListTile(
            icon: Icons.notifications,
            title: '푸시 알림',
            subtitle: '모든 푸시 알림 수신',
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
            ),
          ),

          // 생일 알림은 삭제
          CustomListTile(
            icon: Icons.campaign,
            title: '교회 공지',
            subtitle: '새로운 공지사항 알림',
            trailing: Switch(
              value: _churchNotices,
              onChanged: (value) => setState(() => _churchNotices = value),
            ),
          ),

          const Divider(height: 32),

          // 앱 설정 섹션
          SectionHeader(title: '앱 설정'),
          // CustomListTile(
          //   icon: Icons.dark_mode,
          //   title: '다크 모드',
          //   subtitle: '어두운 테마 사용',
          //   trailing: Switch(
          //     value: _darkMode,
          //     onChanged: (value) => setState(() => _darkMode = value),
          //   ),
          // ),
          Consumer<FontSettingsService>(
            builder: (context, fontSettings, child) {
              return CustomListTile(
                icon: Icons.text_fields,
                title: '글꼴 크기',
                subtitle:
                    '${fontSettings.fontSize} (${FontSettingsService.getFontSizeDescription(fontSettings.fontSize)})',
                trailing: DropdownButton<String>(
                  value: fontSettings.fontSize,
                  items: FontSettingsService.fontSizeOptions
                      .map((size) => DropdownMenuItem<String>(
                            value: size,
                            child: Text(size),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    if (value != null) {
                      await fontSettings.setFontSize(value);
                      if (mounted) {
                        // 사용자에게 변경 알림
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('글꼴 크기가 "$value"로 변경되었습니다.'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  underline: Container(),
                ),
              );
            },
          ),
          // CustomListTile(
          //   icon: Icons.language,
          //   title: '언어',
          //   subtitle: _language,
          //   trailing: DropdownButton<String>(
          //     value: _language,
          //     items: ['한국어', 'English']
          //         .map(
          //             (e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          //         .toList(),
          //     onChanged: (value) => setState(() => _language = value!),
          //     underline: Container(),
          //   ),
          // ),

          const Divider(height: 32),

          // 교회 정보 섹션
          SectionHeader(title: '교회 정보'),
          CustomListTile(
            icon: Icons.church,
            title: '우리 교회',
            subtitle: '새생명교회',
            onTap: _showChurchInfo,
            showArrow: false,
          ),
          CustomListTile(
            icon: Icons.contact_phone,
            title: '교회 연락처',
            subtitle: '02-123-4567',
            onTap: _showChurchContact,
            showArrow: false,
          ),
          CustomListTile(
            icon: Icons.location_on,
            title: '교회 위치',
            subtitle: '서울시 강남구',
            onTap: _showChurchLocation,
            showArrow: false,
          ),

          const Divider(height: 32),

          // 도움말 섹션
          SectionHeader(title: '도움말'),
          CustomListTile(
            icon: Icons.help,
            title: '도움말',
            subtitle: '자주 묻는 질문',
            onTap: _showHelp,
          ),
          // CustomListTile(
          //   icon: Icons.bug_report,
          //   title: '버그 신고',
          //   subtitle: '오류 또는 개선사항 신고',
          //   onTap: _reportBug,
          // ),
          // CustomListTile(
          //   icon: Icons.api,
          //   title: 'API 테스트',
          //   subtitle: 'API 연결 상태 확인',
          //   onTap: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (context) => const ApiTestScreen()),
          //     );
          //   },
          // ),

          CustomListTile(
            icon: Icons.info,
            title: '앱 정보',
            subtitle: '버전 및 담당자 정보',
            onTap: _showAppInfo,
          ),
          CustomListTile(
            icon: Icons.security,
            title: '개인정보 처리방침',
            subtitle: '개인정보 보호 정책',
            onTap: _showPrivacyPolicy,
          ),
          CustomListTile(
            icon: Icons.article,
            title: '이용약관',
            subtitle: '서비스 이용약관',
            onTap: _showTermsOfService,
          ),
          CustomListTile(
            icon: Icons.logout,
            title: '로그아웃',
            subtitle: '계정에서 로그아웃',
            onTap: _logout,
            textColor: Colors.red,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '현재 비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '새 비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '새 비밀번호 확인',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('비밀번호가 변경되었습니다')),
              );
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  void _manageFamilyMembers() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가족 관리'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 등록된 가족:'),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16),
                SizedBox(width: 8),
                Text('김성도 (본인)'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.person, size: 16),
                SizedBox(width: 8),
                Text('이은혜 (배우자)'),
              ],
            ),
            Row(
              children: [
                Icon(Icons.child_care, size: 16),
                SizedBox(width: 8),
                Text('김믿음 (자녀)'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 가족 추가 기능
            },
            child: const Text('가족 추가'),
          ),
        ],
      ),
    );
  }

  void _showChurchInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('교회 정보'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('교회명: 새생명교회'),
            SizedBox(height: 8),
            Text('담任목사: 김은혜 목사'),
            SizedBox(height: 8),
            Text('설립연도: 1995년'),
            SizedBox(height: 8),
            Text('교인수: 약 500명'),
            SizedBox(height: 8),
            Text('주일예배: 오전 9시, 11시'),
            SizedBox(height: 8),
            Text('수요예배: 오후 7시 30분'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showChurchContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('교회 연락처'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('전화: 02-123-4567'),
            SizedBox(height: 8),
            Text('팩스: 02-123-4568'),
            SizedBox(height: 8),
            Text('이메일: info@newlife.church'),
            SizedBox(height: 8),
            Text('홈페이지: www.newlife.church'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showChurchLocation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('교회 위치'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('주소: 서울시 강남구 테헤란로 123'),
            SizedBox(height: 8),
            Text('지하철: 2호선 강남역 3번 출구'),
            SizedBox(height: 8),
            Text('버스: 146, 540, 강남01'),
            SizedBox(height: 8),
            Text('주차: 지하 1층 (50대)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 지도 앱으로 연결
            },
            child: const Text('지도 보기'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('도움말'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: EdgeInsets.all(16),
            children: [
              ExpansionTile(
                title: Text('출석 체크는 어떻게 하나요?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        '홈 화면의 "출석 체크" 버튼을 누르거나, 출석 탭에서 QR 코드를 스캔하여 출석을 체크할 수 있습니다.'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('교인증은 어떻게 사용하나요?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        '홈 화면의 "교인증" 버튼을 누르면 QR 코드가 포함된 교인증을 확인할 수 있습니다. 이를 교회 행사나 출석 체크 시 사용하세요.'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('알림을 받지 못해요'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                        '설정 > 알림 설정에서 원하는 알림을 켜주세요. 또한 기기 설정에서 앱 알림이 허용되어 있는지 확인해주세요.'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('문제 신고'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: '문제 유형',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '문제 설명',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('문제 신고가 전송되었습니다')),
              );
            },
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }

  void _showAppInfo() {
    showAboutDialog(
      context: context,
      applicationName: '스마트 교회요람',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 스마트 교회요람',
      children: const [
        Text('교회 생활을 더욱 편리하게 만들어주는 앱입니다.'),
      ],
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
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                // AuthService 로그아웃 호출
                await _authService.logout();
                print('설정 화면: 로그아웃 완료');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('로그아웃되었습니다'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // 로그인 화면으로 이동
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('로그아웃 오류: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
