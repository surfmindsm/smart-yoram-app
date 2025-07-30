import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;
  
  // 설정 값들
  bool _pushNotifications = true;
  bool _attendanceReminder = true;
  bool _birthdayNotifications = true;
  bool _churchNotices = true;
  bool _darkMode = false;
  String _fontSize = '보통';
  String _language = '한국어';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // 계정 섹션
          _buildSectionHeader('계정'),
          _buildListTile(
            Icons.person,
            '개인정보 수정',
            '이름, 전화번호, 주소 등',
            onTap: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          _buildListTile(
            Icons.lock,
            '비밀번호 변경',
            '로그인 비밀번호 변경',
            onTap: _changePassword,
          ),
          _buildListTile(
            Icons.family_restroom,
            '가족 관리',
            '가족 구성원 추가/수정',
            onTap: _manageFamilyMembers,
          ),
          
          const Divider(height: 32),
          
          // 알림 섹션
          _buildSectionHeader('알림 설정'),
          _buildSwitchTile(
            Icons.notifications,
            '푸시 알림',
            '모든 푸시 알림 수신',
            _pushNotifications,
            (value) => setState(() => _pushNotifications = value),
          ),
          _buildSwitchTile(
            Icons.schedule,
            '출석 알림',
            '예배 시간 30분 전 알림',
            _attendanceReminder,
            (value) => setState(() => _attendanceReminder = value),
          ),
          _buildSwitchTile(
            Icons.cake,
            '생일 알림',
            '교인 생일 알림',
            _birthdayNotifications,
            (value) => setState(() => _birthdayNotifications = value),
          ),
          _buildSwitchTile(
            Icons.campaign,
            '교회 공지',
            '새로운 공지사항 알림',
            _churchNotices,
            (value) => setState(() => _churchNotices = value),
          ),
          
          const Divider(height: 32),
          
          // 앱 설정 섹션
          _buildSectionHeader('앱 설정'),
          _buildSwitchTile(
            Icons.dark_mode,
            '다크 모드',
            '어두운 테마 사용',
            _darkMode,
            (value) => setState(() => _darkMode = value),
          ),
          _buildDropdownTile(
            Icons.text_fields,
            '글꼴 크기',
            _fontSize,
            ['작게', '보통', '크게'],
            (value) => setState(() => _fontSize = value!),
          ),
          _buildDropdownTile(
            Icons.language,
            '언어',
            _language,
            ['한국어', 'English'],
            (value) => setState(() => _language = value!),
          ),
          
          const Divider(height: 32),
          
          // 교회 정보 섹션
          _buildSectionHeader('교회 정보'),
          _buildListTile(
            Icons.church,
            '우리 교회',
            '새생명교회',
            onTap: _showChurchInfo,
          ),
          _buildListTile(
            Icons.contact_phone,
            '교회 연락처',
            '02-123-4567',
            onTap: _showChurchContact,
          ),
          _buildListTile(
            Icons.location_on,
            '교회 위치',
            '서울시 강남구',
            onTap: _showChurchLocation,
          ),
          
          const Divider(height: 32),
          
          // 지원 섹션
          _buildSectionHeader('지원'),
          _buildListTile(
            Icons.help,
            '도움말',
            '앱 사용법',
            onTap: _showHelp,
          ),
          _buildListTile(
            Icons.bug_report,
            '문제 신고',
            '오류 신고 및 개선 제안',
            onTap: _reportBug,
          ),
          _buildListTile(
            Icons.info,
            '앱 정보',
            '버전 1.0.0',
            onTap: _showAppInfo,
          ),
          
          const Divider(height: 32),
          
          // 기타 섹션
          _buildSectionHeader('기타'),
          _buildListTile(
            Icons.privacy_tip,
            '개인정보 처리방침',
            '',
            onTap: _showPrivacyPolicy,
          ),
          _buildListTile(
            Icons.article,
            '이용약관',
            '',
            onTap: _showTermsOfService,
          ),
          _buildListTile(
            Icons.logout,
            '로그아웃',
            '',
            onTap: _logout,
            textColor: Colors.red,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildDropdownTile(
    IconData icon,
    String title,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: Container(),
        items: options
            .map((option) => DropdownMenuItem(
                  value: option,
                  child: Text(option),
                ))
            .toList(),
        onChanged: onChanged,
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
                    child: Text('홈 화면의 "출석 체크" 버튼을 누르거나, 출석 탭에서 QR 코드를 스캔하여 출석을 체크할 수 있습니다.'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('교인증은 어떻게 사용하나요?'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('홈 화면의 "교인증" 버튼을 누르면 QR 코드가 포함된 교인증을 확인할 수 있습니다. 이를 교회 행사나 출석 체크 시 사용하세요.'),
                  ),
                ],
              ),
              ExpansionTile(
                title: Text('알림을 받지 못해요'),
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('설정 > 알림 설정에서 원하는 알림을 켜주세요. 또한 기기 설정에서 앱 알림이 허용되어 있는지 확인해주세요.'),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('개인정보 처리방침'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text(
              '개인정보 처리방침\n\n'
              '1. 개인정보의 처리 목적\n'
              '본 앱은 교회 교인들의 편의를 위해 다음과 같은 목적으로 개인정보를 처리합니다.\n'
              '- 교인 관리 및 연락처 서비스\n'
              '- 출석 관리 및 통계\n'
              '- 교회 공지사항 전달\n'
              '- 교인증 발급 및 관리\n\n'
              '2. 수집하는 개인정보 항목\n'
              '- 성명, 전화번호, 이메일 주소\n'
              '- 주소, 생년월일\n'
              '- 출석 기록\n\n'
              '3. 개인정보의 보유 및 이용기간\n'
              '교인 탈퇴 시까지 보유하며, 탈퇴 후 즉시 삭제됩니다.\n\n'
              '4. 개인정보의 제3자 제공\n'
              '원칙적으로 제3자에게 제공하지 않습니다.\n\n'
              '문의사항이 있으시면 교회 사무실로 연락해주세요.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsOfService() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('이용약관'),
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text(
              '이용약관\n\n'
              '제1조 (목적)\n'
              '본 약관은 스마트 교회요람 앱의 이용조건 및 절차, 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.\n\n'
              '제2조 (정의)\n'
              '1. "서비스"란 교회에서 제공하는 모든 앱 서비스를 의미합니다.\n'
              '2. "회원"이란 교회에 등록된 교인을 의미합니다.\n\n'
              '제3조 (약관의 효력 및 변경)\n'
              '본 약관은 서비스 화면에 게시하거나 기타의 방법으로 공지함으로써 효력이 발생합니다.\n\n'
              '제4조 (서비스의 제공)\n'
              '교회는 다음과 같은 서비스를 제공합니다.\n'
              '1. 교인 관리 서비스\n'
              '2. 출석 관리 서비스\n'
              '3. 공지사항 서비스\n'
              '4. 기타 교회 관련 서비스\n\n'
              '제5조 (회원의 의무)\n'
              '회원은 서비스 이용 시 타인에게 피해를 주거나 공공질서를 해치는 행위를 하여서는 안 됩니다.\n\n'
              '문의사항이 있으시면 교회 사무실로 연락해주세요.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ),
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
            onPressed: () {
              Navigator.pop(context);
              // 로그아웃 처리 후 로그인 화면으로 이동
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
