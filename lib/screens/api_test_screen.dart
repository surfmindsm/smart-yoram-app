import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/services.dart';
import '../models/announcement.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final AuthService _authService = AuthService();
  final MemberService _memberService = MemberService();
  final AttendanceService _attendanceService = AttendanceService();
  final QRService _qrService = QRService();
  final SmsService _smsService = SmsService();
  final CalendarService _calendarService = CalendarService();
  final FamilyService _familyService = FamilyService();
  final ExcelService _excelService = ExcelService();
  final StatisticsService _statisticsService = StatisticsService();
  final UserService _userService = UserService();
  final MemberCardService _memberCardService = MemberCardService();
  final AnnouncementService _announcementService = AnnouncementService();
  final DailyVerseService _dailyVerseService = DailyVerseService();

  final Map<String, String> _testResults = {};
  final Map<String, bool> _testingStatus = {};
  final List<String> _debugLogs = [];

  // 동적으로 가져온 첫 번째 교인 ID
  int? _firstMemberId;

  // QR 코드 관련 데이터
  String? _generatedQRCode;
  
  // 전체 테스트 진행률
  bool _runningAllTests = false;
  int _currentTestIndex = 0;
  int _totalTests = 0;
  
  // 로그인 상태 관리
  bool _isLoggedIn = false;
  String? _authToken;
  String? _currentUserEmail;
  
  // 로그인 폼 컨트롤러
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 테스트'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Smart Yoram App API 테스트',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // 로그인 상태 표시 및 로그인 폼
            _buildLoginSection(),
            // 테스트 결과 요약
            _buildTestSummary(),
            const SizedBox(height: 20),
            _buildSection('기본 연결 테스트', [
              _buildTestButton('기본 연결', 'basic_connection', testBasicConnection),
            ]),
            _buildSection('인증 서비스', [
              _buildTestButton('로그인', 'auth_login', testAuthLogin),
            ]),
            _buildSection('교인 관리', [
              _buildTestButton('교인 목록', 'member_list', testMemberList),
              _buildTestButton('교인 상세', 'member_detail', testMemberDetail),
            ]),
            _buildSection('출석 관리', [
              _buildTestButton('출석 기록', 'attendance_records', testAttendanceRecords),
              _buildTestButton('출석 통계', 'attendance_stats', testAttendanceStats),
            ]),
            _buildSection('QR 코드', [
              _buildTestButton('QR 생성', 'qr_generate', testQRGenerate),
              _buildTestButton('QR 정보', 'qr_info', testQRInfo),
            ]),
            _buildSection('SMS 서비스', [
              _buildTestButton('SMS 발송', 'sms_send', testSmsSend),
              _buildTestButton('SMS 기록', 'sms_history', testSmsHistory),
            ]),
            _buildSection('일정 관리', [
              _buildTestButton('일정 조회', 'calendar_events', testCalendarEvents),
              _buildTestButton('생일 조회', 'calendar_birthdays', testCalendarBirthdays),
            ]),
            _buildSection('가족 관리', [
              _buildTestButton('가족 관계', 'family_relations', testFamilyRelations),
              _buildTestButton('가족 트리', 'family_tree', testFamilyTree),
            ]),
            _buildSection('엑셀 연동', [
              _buildTestButton('교인 엑셀', 'excel_members', testExcelMembers),
              _buildTestButton('출석 엑셀', 'excel_attendance', testExcelAttendance),
            ]),
            _buildSection('통계 서비스', [
              _buildTestButton('출석 통계', 'stats_attendance', testStatsAttendance),
              _buildTestButton('대시보드', 'stats_dashboard', testStatsDashboard),
            ]),
            _buildSection('사용자 관리', [
              _buildTestButton('사용자 정보', 'user_info', testUserInfo),
              _buildTestButton('사용자 목록', 'user_list', testUserList),
              _buildTestButton('비밀번호 변경', 'password_change', testPasswordChange),
              _buildTestButton('is_first 업데이트', 'is_first_update', testIsFirstUpdate),
            ]),
            _buildSection('모바일 교인증', [
              _buildTestButton('교인증 정보', 'member_card', testMemberCard),
              _buildTestButton('QR 재생성', 'card_qr_regenerate', testCardQRRegenerate),
            ]),
            _buildSection('공지사항 관리', [
              _buildTestButton('공지사항 목록', 'announcement_list', testAnnouncementList),
              _buildTestButton('공지사항 생성', 'announcement_create', testAnnouncementCreate),
              _buildTestButton('공지사항 상세', 'announcement_detail', testAnnouncementDetail),
              _buildTestButton('공지사항 고정 토글', 'announcement_toggle_pin', testAnnouncementTogglePin),
            ]),
            _buildSection('오늘의 말씀', [
              _buildTestButton('랜덤 말씀 조회', 'daily_verse_random', testDailyVerseRandom),
            ]),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runningAllTests ? null : _runAllTests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _runningAllTests ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: _runningAllTests 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('테스트 실행 중... ($_currentTestIndex/$_totalTests)', 
                                   style: const TextStyle(fontSize: 16)),
                            ],
                          )
                        : const Text('모든 테스트 실행', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _showDebugLogs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text('디버그 로그'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSummary() {
    if (_testResults.isEmpty) {
      return const SizedBox.shrink();
    }

    final successCount = _testResults.values.where((result) => result.contains('성공')).length;
    final failCount = _testResults.values.where((result) => result.contains('실패') || result.contains('오류')).length;
    final totalCount = _testResults.length;
    final successRate = totalCount > 0 ? (successCount / totalCount * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('테스트 결과 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('성공', successCount.toString(), Colors.green, Icons.check_circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard('실패', failCount.toString(), Colors.red, Icons.error),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard('성공률', '$successRate%', Colors.blue, Icons.percent),
                ),
              ],
            ),
            if (totalCount > 0) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: successCount / totalCount,
                backgroundColor: Colors.red[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text('전체 $totalCount개 테스트 중 $successCount개 성공',
                   style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildLoginSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: _isLoggedIn ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isLoggedIn ? Icons.check_circle : Icons.warning,
                  color: _isLoggedIn ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _isLoggedIn ? '로그인 상태: $_currentUserEmail' : '로그인 필요 (API 인증)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isLoggedIn ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
            if (!_isLoggedIn) ...[
              const SizedBox(height: 16),
              const Text(
                '실제 계정으로 로그인하여 API 인증을 받으세요:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('테스트 계정 예시:', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(height: 4),
                    Text('Username: admin', 
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    Text('Password: admin123 또는 password', 
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Username (사용자명)',
                  hintText: 'admin',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password (비밀번호)',
                  hintText: 'admin123 또는 password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: testAuthLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('로그인하기'),
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '토큰: ${_authToken?.substring(0, 20)}...',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _authToken = null;
      _currentUserEmail = null;
      _emailController.clear();
      _passwordController.clear();
    });
    
    // 로그아웃 결과 업데이트
    _updateResult('auth_login', '로그아웃 완료');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로그아웃되었습니다. 다시 로그인하여 API 테스트를 진행하세요.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  bool _checkAuthRequired(String testKey) {
    if (!_isLoggedIn && testKey != 'basic_connection') {
      _updateResult(testKey, '❌ 실패: 로그인이 필요합니다. 먼저 실제 계정으로 로그인해주세요.');
      return false;
    }
    return true;
  }

  void _addDebugLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $message';
    setState(() {
      _debugLogs.add(logEntry);
      // 최대 1000개 로그만 유지
      if (_debugLogs.length > 1000) {
        _debugLogs.removeAt(0);
      }
    });
    
    // developer.log를 사용하여 콘솔에도 출력
    developer.log(logEntry, name: 'API_TEST');
    // print도 함께 사용하여 더 확실하게 출력
    print('🔍 API_TEST: $logEntry');
  }

  void _showDebugLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('디버그 로그'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _debugLogs.isEmpty
              ? const Center(child: Text('로그가 없습니다.'))
              : ListView.builder(
                  itemCount: _debugLogs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _debugLogs[index],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _debugLogs.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('로그 지우기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> buttons) {
    // 해당 섹션의 테스트 결과를 계산
    final sectionResults = _getSectionResults(title);
    final sectionProgress = _getSectionProgress(sectionResults);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (sectionResults.isNotEmpty) 
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: sectionProgress['color']!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sectionProgress['color']!.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${sectionProgress['success']}/${sectionProgress['total']}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: sectionProgress['color'],
                      ),
                    ),
                  ),
              ],
            ),
            if (sectionResults.isNotEmpty && sectionProgress['total']! > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: sectionProgress['success']! / sectionProgress['total']!,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(sectionProgress['color']!),
                minHeight: 3,
              ),
            ],
            const SizedBox(height: 12),
            ...buttons,
          ],
        ),
      ),
    );
  }

  List<String> _getSectionResults(String sectionTitle) {
    final sectionTestKeys = <String>[];
    
    switch (sectionTitle) {
      case '기본 연결 테스트':
        sectionTestKeys.addAll(['basic_connection']);
        break;
      case '인증 서비스':
        sectionTestKeys.addAll(['auth_login']);
        break;
      case '교인 관리':
        sectionTestKeys.addAll(['member_list', 'member_detail']);
        break;
      case '출석 관리':
        sectionTestKeys.addAll(['attendance_records', 'attendance_stats']);
        break;
      case 'QR 코드':
        sectionTestKeys.addAll(['qr_generate', 'qr_info']);
        break;
      case 'SMS 서비스':
        sectionTestKeys.addAll(['sms_send', 'sms_history']);
        break;
      case '일정 관리':
        sectionTestKeys.addAll(['calendar_events', 'calendar_birthdays']);
        break;
      case '가족 관리':
        sectionTestKeys.addAll(['family_relations', 'family_tree']);
        break;
      case '엑셀 다운로드':
        sectionTestKeys.addAll(['excel_members', 'excel_attendance']);
        break;
      case '통계 서비스':
        sectionTestKeys.addAll(['stats_attendance', 'stats_dashboard']);
        break;
      case '사용자 관리':
        sectionTestKeys.addAll(['user_info', 'user_list']);
        break;
      case '교인증 관리':
        sectionTestKeys.addAll(['member_card', 'card_qr_regenerate']);
        break;
      case '공지사항 관리':
        sectionTestKeys.addAll(['announcement_list', 'announcement_create', 'announcement_detail', 'announcement_toggle_pin']);
        break;
    }
    
    return sectionTestKeys.where((key) => _testResults.containsKey(key)).map((key) => _testResults[key]!).toList();
  }

  Map<String, dynamic> _getSectionProgress(List<String> results) {
    if (results.isEmpty) {
      return {
        'success': 0,
        'total': 0,
        'color': Colors.grey,
      };
    }
    
    final successCount = results.where((result) => result.contains('성공')).length;
    final totalCount = results.length;
    final successRate = successCount / totalCount;
    
    Color color;
    if (successRate == 1.0) {
      color = Colors.green;
    } else if (successRate >= 0.5) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }
    
    return {
      'success': successCount,
      'total': totalCount,
      'color': color,
    };
  }

  Widget _buildTestButton(String title, String key, VoidCallback onPressed) {
    final isLoading = _testingStatus[key] ?? false;
    final result = _testResults[key];
    
    Color? cardColor;
    if (result != null) {
      cardColor = result.contains('성공') ? Colors.green[50] : Colors.red[50];
    }

    return Card(
      color: cardColor,
      child: ListTile(
        title: Text(title),
        subtitle: result != null ? Text(result, style: const TextStyle(fontSize: 12)) : null,
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                result == null
                    ? Icons.radio_button_unchecked
                    : result.contains('성공')
                        ? Icons.check_circle
                        : Icons.error,
                color: result == null
                    ? Colors.grey
                    : result.contains('성공')
                        ? Colors.green
                        : Colors.red,
              ),
        onTap: isLoading ? null : onPressed,
      ),
    );
  }

  void _startTest(String key) {
    setState(() {
      _testingStatus[key] = true;
      _testResults[key] = '테스팅 중...';
    });
    _addDebugLog('[$key] 테스트 시작');
  }

  void _updateResult(String key, String result) {
    setState(() {
      _testingStatus[key] = false;
      _testResults[key] = result;
    });
    _addDebugLog('[$key] 결과: $result');
  }

  // 테스트 상태 리셋
  void _resetTestState() {
    setState(() {
      _testResults.clear();
      _testingStatus.clear();
      _generatedQRCode = null;
      _firstMemberId = null;
    });
    _addDebugLog('🔄 테스트 상태 리셋 완료');
  }

  Future<void> testBasicConnection() async {
    _startTest('basic_connection');
    try {
      // health 엔드포인트가 없으므로 docs 엔드포인트로 테스트
      final url = '${ApiConfig.baseUrl.replaceAll('/api/v1', '')}/docs';
      _addDebugLog('📡 [basic_connection] 요청 URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'text/html,application/xhtml+xml'},
      ).timeout(const Duration(seconds: 10));
      
      _addDebugLog('📡 [basic_connection] 응답 상태코드: ${response.statusCode}');
      _addDebugLog('📡 [basic_connection] 응답 헤더: ${response.headers}');
      _addDebugLog('📡 [basic_connection] 응답 본문 크기: ${response.body.length} bytes');
      
      if (response.statusCode == 200) {
        _updateResult('basic_connection', '✅ 성공: 서버 연결 정상 (Swagger Docs 접근 가능)');
      } else {
        _updateResult('basic_connection', '❌ 실패: HTTP ${response.statusCode}');
      }
    } catch (e) {
      _addDebugLog('❌ [basic_connection] 예외 발생: $e');
      _updateResult('basic_connection', '❌ 오류: $e');
    }
  }

  Future<void> testAuthLogin() async {
    _startTest('auth_login');
    try {
      final email = _emailController.text.isNotEmpty ? _emailController.text : 'test@example.com';
      final password = _passwordController.text.isNotEmpty ? _passwordController.text : 'password123';
      
      _addDebugLog('[auth_login] 로그인 시도 - 이메일: $email');
      
      final result = await _authService.login(email, password);
      
      _addDebugLog('[auth_login] 응답 성공여부: ${result.success}');
      _addDebugLog('[auth_login] 응답 메시지: ${result.message}');
      _addDebugLog('[auth_login] 응답 데이터: ${result.data}');
      
      if (result.success) {
        setState(() {
          _isLoggedIn = true;
          _authToken = result.data?.accessToken;
          _currentUserEmail = email;
        });
        
        _addDebugLog('[auth_login] 토큰 획득: ${_authToken?.substring(0, 20)}...');
        
        _addDebugLog('🔑 [auth_login] 로그인 성공, 토큰이 서비스에 자동 설정됨');
        
        _updateResult('auth_login', '성공: 로그인 완료');
      } else {
        _updateResult('auth_login', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[auth_login] 예외 발생: $e');
      _updateResult('auth_login', '오류: $e');
    }
  }

  Future<void> testMemberList() async {
    _startTest('member_list');
    if (!_checkAuthRequired('member_list')) return;
    
    try {
      _addDebugLog('📡 [member_list] 교인 목록 요청 시작');
      
      final result = await _memberService.getMembers();
      
      _addDebugLog('📡 [member_list] 응답 성공여부: ${result.success}');
      _addDebugLog('📡 [member_list] 응답 메시지: ${result.message}');
      _addDebugLog('📡 [member_list] 데이터 개수: ${result.data?.length ?? 0}');
      
      // 첫 번째 교인 ID 저장 (다른 테스트에서 사용)
      if (result.success && result.data != null && result.data!.isNotEmpty) {
        _firstMemberId = result.data!.first.id;
        _addDebugLog('📡 [member_list] 첫 번째 교인 ID 저장: $_firstMemberId');
      }
      
      if (result.success) {
        _updateResult('member_list', '성공: ${result.data?.length ?? 0}명의 교인 목록 조회');
      } else {
        _updateResult('member_list', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [member_list] 예외 발생: $e');
      _updateResult('member_list', '오류: $e');
    }
  }

  Future<void> testMemberDetail() async {
    _startTest('member_detail');
    if (!_checkAuthRequired('member_detail')) return;
    
    try {
      final memberId = _firstMemberId ?? 1;
      _addDebugLog('📡 [member_detail] 교인 상세정보 요청 (ID: $memberId)');
      
      final result = await _memberService.getMember(memberId);
      
      _addDebugLog('📡 [member_detail] 응답 성공여부: ${result.success}');
      _addDebugLog('📡 [member_detail] 응답 메시지: ${result.message}');
      if (result.data != null) {
        _addDebugLog('📡 [member_detail] 교인 이름: ${result.data?.name}');
        _addDebugLog('📡 [member_detail] 교인 전화번호: ${result.data?.phone}');
        _addDebugLog('📡 [member_detail] 교인 직분: ${result.data?.position}');
      }
      
      if (result.success) {
        _updateResult('member_detail', '성공: 교인 상세정보 조회됨');
      } else {
        _updateResult('member_detail', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [member_detail] 예외 발생: $e');
      _updateResult('member_detail', '오류: $e');
    }
  }

  Future<void> testAttendanceRecords() async {
    _startTest('attendance_records');
    try {
      final memberId = _firstMemberId ?? 1;
      _addDebugLog('📡 [attendance_records] 출석 기록 요청 (Member ID: $memberId)');
      
      final result = await _attendanceService.getMemberAttendanceRecords(memberId);
      
      _addDebugLog('📡 [attendance_records] 응답 성공여부: ${result.success}');
      _addDebugLog('📡 [attendance_records] 응답 메시지: ${result.message}');
      _addDebugLog('📡 [attendance_records] 기록 개수: ${result.data?.length ?? 0}');
      
      if (result.success) {
        _updateResult('attendance_records', '성공: ${result.data?.length ?? 0}개의 출석 기록 조회');
      } else {
        _updateResult('attendance_records', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [attendance_records] 예외 발생: $e');
      _updateResult('attendance_records', '오류: $e');
    }
  }

  Future<void> testAttendanceStats() async {
    _startTest('attendance_stats');
    try {
      final memberId = _firstMemberId ?? 1;
      _addDebugLog('📡 [attendance_stats] 출석 통계 요청 (Member ID: $memberId)');
      
      final result = await _attendanceService.getMemberAttendanceStats(memberId);
      
      _addDebugLog('📡 [attendance_stats] 응답 성공여부: ${result.success}');
      _addDebugLog('📡 [attendance_stats] 응답 메시지: ${result.message}');
      
      if (result.success) {
        _updateResult('attendance_stats', '성공: 출석 통계 데이터 조회됨');
      } else {
        _updateResult('attendance_stats', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [attendance_stats] 예외 발생: $e');
      _updateResult('attendance_stats', '오류: $e');
    }
  }

  Future<void> testQRGenerate() async {
    _startTest('qr_generate');
    try {
      final memberId = _firstMemberId ?? 1;
      _addDebugLog('📡 [qr_generate] QR 코드 생성 요청 (Member ID: $memberId)');
      
      final result = await _qrService.generateQRCode(memberId);
      
      _addDebugLog('📡 [qr_generate] 응답 성공여부: ${result.success}');
      _addDebugLog('📡 [qr_generate] 응답 메시지: ${result.message}');
      if (result.data != null) {
        _addDebugLog('📡 [qr_generate] 생성된 QR 코드: ${result.data?.code}');
        _addDebugLog('📡 [qr_generate] 만료 시간: ${result.data?.expiresAt}');
      }
      
      if (result.success) {
        // 생성된 QR 코드 저장 (다른 테스트에서 사용)
        _generatedQRCode = result.data?.code;
        _addDebugLog('🔑 [qr_generate] 생성된 QR 코드 저장: $_generatedQRCode');
        _updateResult('qr_generate', '성공: QR 코드 생성됨 - ${result.data?.code ?? 'N/A'}');
      } else {
        _updateResult('qr_generate', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [qr_generate] 예외 발생: $e');
      _updateResult('qr_generate', '오류: $e');
    }
  }

  Future<void> testQRInfo() async {
    _startTest('qr_info');
    try {
      // 이전에 생성된 QR 코드 사용, 없으면 테스트 코드 사용
      final qrCode = _generatedQRCode ?? 'test_qr_code';
      _addDebugLog('📱 [qr_info] QR 코드 정보 조회 (Code: $qrCode)');
      
      final result = await _qrService.getQRCodeInfo(qrCode);
      
      _addDebugLog('📱 [qr_info] 응답 성공여부: ${result.success}');
      _addDebugLog('📱 [qr_info] 응답 메시지: ${result.message}');
      
      if (result.success) {
        _addDebugLog('📱 [qr_info] QR 코드 정보: ${result.data?.code}');
        _addDebugLog('📱 [qr_info] 교인 ID: ${result.data?.memberId}');
        _addDebugLog('📱 [qr_info] 교인 이름: ${result.data?.memberName}');
        _addDebugLog('📱 [qr_info] 활성 상태: ${result.data?.isActive}');
        _addDebugLog('📱 [qr_info] 만료 시간: ${result.data?.expiresAt}');
        _updateResult('qr_info', '성공: QR 코드 정보 조회됨');
      } else {
        _updateResult('qr_info', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[qr_info] 예외 발생: $e');
      _updateResult('qr_info', '오류: $e');
    }
  }

  Future<void> testSmsSend() async {
    _startTest('sms_send');
    try {
      const testPhone = '01012345678';
      const testMessage = '테스트 메시지';
      const testType = 'general';
      
      _addDebugLog('📱 [sms_send] SMS 발송 요청 (Phone: $testPhone)');
      _addDebugLog('📱 [sms_send] 메시지: $testMessage');
      _addDebugLog('📱 [sms_send] 타입: $testType');
      
      final result = await _smsService.sendSms(
        recipientPhone: testPhone,
        message: testMessage,
        smsType: testType,
      );
      
      _addDebugLog('📱 [sms_send] 응답 성공여부: ${result.success}');
      _addDebugLog('📱 [sms_send] 응답 메시지: ${result.message}');
      
      if (result.success) {
        _addDebugLog('📱 [sms_send] SMS ID: ${result.data?.id}');
        _addDebugLog('📱 [sms_send] 발송 시간: ${result.data?.sentAt}');
        _updateResult('sms_send', '성공: SMS 발송 완료');
      } else {
        _updateResult('sms_send', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[sms_send] 예외 발생: $e');
      _updateResult('sms_send', '오류: $e');
    }
  }

  Future<void> testSmsHistory() async {
    _startTest('sms_history');
    try {
      _addDebugLog('📜 [sms_history] SMS 기록 조회 요청');
      
      final result = await _smsService.getSmsHistory();
      
      _addDebugLog('📜 [sms_history] 응답 성공여부: ${result.success}');
      _addDebugLog('📜 [sms_history] 응답 메시지: ${result.message}');
      _addDebugLog('📜 [sms_history] 기록 갯수: ${result.data?.length ?? 0}');
      
      if (result.success) {
        // 최신 SMS 기록 상세 정보 로깅
        if (result.data != null && result.data!.isNotEmpty) {
          final latestSms = result.data!.first;
          _addDebugLog('📜 [sms_history] 최신 SMS - ID: ${latestSms.id}');
          _addDebugLog('📜 [sms_history] 최신 SMS - 수신자: ${latestSms.recipientPhone}');
          _addDebugLog('📜 [sms_history] 최신 SMS - 상태: ${latestSms.status}');
        }
        _updateResult('sms_history', '성공: ${result.data?.length ?? 0}개의 SMS 기록 조회');
      } else {
        _updateResult('sms_history', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[sms_history] 예외 발생: $e');
      _updateResult('sms_history', '오류: $e');
    }
  }

  Future<void> testCalendarEvents() async {
    _startTest('calendar_events');
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now().add(const Duration(days: 30));
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];
      
      _addDebugLog('📅 [calendar_events] 일정 조회 요청');
      _addDebugLog('📅 [calendar_events] 기간: $startDateStr ~ $endDateStr');
      
      final result = await _calendarService.getEvents(
        startDate: startDateStr,
        endDate: endDateStr,
      );
      
      _addDebugLog('📅 [calendar_events] 응답 성공여부: ${result.success}');
      _addDebugLog('📅 [calendar_events] 응답 메시지: ${result.message}');
      _addDebugLog('📅 [calendar_events] 일정 갯수: ${result.data?.length ?? 0}');
      
      if (result.success) {
        // 첫 번째 일정 상세 정보 로깅
        if (result.data != null && result.data!.isNotEmpty) {
          final firstEvent = result.data!.first;
          _addDebugLog('📅 [calendar_events] 첫 번째 일정: ${firstEvent.title}');
          _addDebugLog('📅 [calendar_events] 일정 날짜: ${firstEvent.eventDate}');
          _addDebugLog('📅 [calendar_events] 일정 타입: ${firstEvent.eventType}');
        }
        _updateResult('calendar_events', '성공: ${result.data?.length ?? 0}개의 일정 조회');
      } else {
        _updateResult('calendar_events', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[calendar_events] 예외 발생: $e');
      _updateResult('calendar_events', '오류: $e');
    }
  }

  Future<void> testCalendarBirthdays() async {
    _startTest('calendar_birthdays');
    try {
      const daysAhead = 30;
      _addDebugLog('🎂 [calendar_birthdays] 다가오는 생일 조회 요청 (30일 내)');
      
      final result = await _calendarService.getUpcomingBirthdays(daysAhead: daysAhead);
      
      _addDebugLog('🎂 [calendar_birthdays] 응답 성공여부: ${result.success}');
      _addDebugLog('🎂 [calendar_birthdays] 응답 메시지: ${result.message}');
      _addDebugLog('🎂 [calendar_birthdays] 생일 갯수: ${result.data?.length ?? 0}');
      
      if (result.success) {
        // 첫 번째 생일 상세 정보 로깅
        if (result.data != null && result.data!.isNotEmpty) {
          final firstBirthday = result.data!.first;
          _addDebugLog('🎂 [calendar_birthdays] 첫 번째 생일 - 이름: ${firstBirthday.memberName}');
          _addDebugLog('🎂 [calendar_birthdays] 첫 번째 생일 - 날짜: ${firstBirthday.birthday}');
          _addDebugLog('🎂 [calendar_birthdays] 첫 번째 생일 - 나이: ${firstBirthday.age}세');
        }
        _updateResult('calendar_birthdays', '성공: ${result.data?.length ?? 0}명의 생일 조회');
      } else {
        _updateResult('calendar_birthdays', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[calendar_birthdays] 예외 발생: $e');
      _updateResult('calendar_birthdays', '오류: $e');
    }
  }

  Future<void> testFamilyRelations() async {
    _startTest('family_relations');
    try {
      final memberId = _firstMemberId ?? 1;
      _addDebugLog('📡 [family_relations] 가족 관계 요청 (Member ID: $memberId)');
      
      final result = await _familyService.getMemberRelationships(memberId);
      
      _addDebugLog('📡 [family_relations] 응답 성공여부: ${result.success}');
      _addDebugLog('📡 [family_relations] 응답 메시지: ${result.message}');
      _addDebugLog('📡 [family_relations] 관계 개수: ${result.data?.length ?? 0}');
      
      if (result.success) {
        _updateResult('family_relations', '성공: ${result.data?.length ?? 0}개의 가족 관계 조회');
      } else {
        _updateResult('family_relations', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [family_relations] 예외 발생: $e');
      _updateResult('family_relations', '오류: $e');
    }
  }

  Future<void> testFamilyTree() async {
    _startTest('family_tree');
    try {
      final memberId = _firstMemberId ?? 1;
      _addDebugLog('📡 [family_tree] 가족 트리 요청 (Member ID: $memberId)');
      
      final result = await _familyService.getFamilyTree(memberId);
      
      _addDebugLog('📡 [family_tree] 응답 성공여부: ${result.success}');
      _addDebugLog('📡 [family_tree] 응답 메시지: ${result.message}');
      
      if (result.success) {
        _updateResult('family_tree', '성공: 가족 트리 데이터 조회됨');
      } else {
        _updateResult('family_tree', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [family_tree] 예외 발생: $e');
      _updateResult('family_tree', '오류: $e');
    }
  }

  Future<void> testExcelMembers() async {
    _startTest('excel_members');
    try {
      final result = await _excelService.downloadMembersExcel();
      if (result.success) {
        _updateResult('excel_members', '성공: 교인 엑셀 다운로드 완료');
      } else {
        _updateResult('excel_members', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[excel_members] 예외 발생: $e');
      _updateResult('excel_members', '오류: $e');
    }
  }

  Future<void> testExcelAttendance() async {
    _startTest('excel_attendance');
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();
      final result = await _excelService.downloadAttendanceExcel(
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );
      if (result.success) {
        _updateResult('excel_attendance', '성공: 출석 엑셀 다운로드 완료');
      } else {
        _updateResult('excel_attendance', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[excel_attendance] 예외 발생: $e');
      _updateResult('excel_attendance', '오류: $e');
    }
  }

  Future<void> testStatsAttendance() async {
    _startTest('stats_attendance');
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();
      final result = await _statisticsService.getAttendanceSummary(
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );
      if (result.success) {
        _updateResult('stats_attendance', '성공: 출석 통계 데이터 조회됨');
      } else {
        _updateResult('stats_attendance', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[stats_attendance] 예외 발생: $e');
      _updateResult('stats_attendance', '오류: $e');
    }
  }

  Future<void> testStatsDashboard() async {
    _startTest('stats_dashboard');
    if (!_checkAuthRequired('stats_dashboard')) return;
    
    try {
      // 대시보드 엔드포인트가 없으므로 교인 인구통계로 대체
      final result = await _statisticsService.getMemberDemographics();
      
      if (result.success) {
        _updateResult('stats_dashboard', '성공: 교인 인구통계 데이터 조회됨');
      } else {
        _updateResult('stats_dashboard', '실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('stats_dashboard', '오류: $e');
    }
  }

  Future<void> testUserInfo() async {
    _startTest('user_info');
    if (!_checkAuthRequired('user_info')) return;
    
    try {
      final result = await _userService.getCurrentUser();
      
      _addDebugLog('📝 [user_info] 응답 성공여부: ${result.success}');
      _addDebugLog('📝 [user_info] 응답 메시지: ${result.message}');
      
      if (result.success && result.data != null) {
        final user = result.data!;
        _addDebugLog('📝 [user_info] 사용자 ID: ${user.id}');
        _addDebugLog('📝 [user_info] 사용자명: ${user.username}');
        _addDebugLog('📝 [user_info] 이름: ${user.fullName}');
        _addDebugLog('📝 [user_info] 이메일: ${user.email}');
        _addDebugLog('📝 [user_info] 교회 ID: ${user.churchId}');
        _addDebugLog('📝 [user_info] 권한: ${user.role}');
        _addDebugLog('📝 [user_info] 활성 상태: ${user.isActive}');
        _addDebugLog('📝 [user_info] 첫 로그인 여부: ${user.isFirst}');
        _addDebugLog('📝 [user_info] 생성일: ${user.createdAt}');
        
        _updateResult('user_info', '성공: 현재 사용자 정보 조회됨 (is_first: ${user.isFirst})');
      } else {
        _updateResult('user_info', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [user_info] 예외 발생: $e');
      _updateResult('user_info', '오류: $e');
    }
  }

  Future<void> testUserList() async {
    _startTest('user_list');
    try {
      final result = await _userService.getUsers();
      if (result.success) {
        _updateResult('user_list', '성공: ${result.data?.length ?? 0}명의 사용자 목록 조회');
      } else {
        _updateResult('user_list', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('[user_list] 예외 발생: $e');
      _updateResult('user_list', '오류: $e');
    }
  }

  Future<void> testPasswordChange() async {
    _startTest('password_change');
    try {
      const currentPassword = 'test123'; // 테스트용 현재 비밀번호
      const newPassword = 'newtest123'; // 테스트용 새 비밀번호
      
      _addDebugLog('🔑 [password_change] 비밀번호 변경 요청');
      _addDebugLog('🔑 [password_change] 현재 비밀번호: $currentPassword');
      _addDebugLog('🔑 [password_change] 새 비밀번호: $newPassword');
      
      final result = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      _addDebugLog('🔑 [password_change] 응답 성공여부: ${result.success}');
      _addDebugLog('🔑 [password_change] 응답 메시지: ${result.message}');
      
      if (result.success) {
        _updateResult('password_change', '성공: 비밀번호가 변경되었습니다');
        
        // 비밀번호를 다시 원래대로 돌려놓기 (테스트 후 상태 복구)
        _addDebugLog('🔑 [password_change] 테스트 뒤정리 - 원래 비밀번호로 복구 시도');
        await _authService.changePassword(
          currentPassword: newPassword,
          newPassword: currentPassword,
        );
      } else {
        _updateResult('password_change', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [password_change] 예외 발생: $e');
      _updateResult('password_change', '오류: $e');
    }
  }

  Future<void> testIsFirstUpdate() async {
    _startTest('is_first_update');
    try {
      _addDebugLog('🔄 [is_first_update] is_first 상태 업데이트 요청');
      
      // 현재 사용자 정보 확인
      final userInfoResult = await _userService.getCurrentUser();
      if (userInfoResult.success && userInfoResult.data != null) {
        final currentIsFirst = userInfoResult.data!.isFirst;
        _addDebugLog('🔄 [is_first_update] 현재 is_first 상태: $currentIsFirst');
        
        // 반대 값으로 업데이트 테스트
        final newIsFirst = !currentIsFirst;
        _addDebugLog('🔄 [is_first_update] 새로운 is_first 값: $newIsFirst');
        
        final updateResult = await _userService.updateIsFirst(newIsFirst);
        
        _addDebugLog('🔄 [is_first_update] 업데이트 응답 성공여부: ${updateResult.success}');
        _addDebugLog('🔄 [is_first_update] 업데이트 응답 메시지: ${updateResult.message}');
        
        if (updateResult.success && updateResult.data != null) {
          final updatedUser = updateResult.data!;
          _addDebugLog('🔄 [is_first_update] 업데이트 후 is_first: ${updatedUser.isFirst}');
          
          // 원래 상태로 다시 복구 (테스트 후 상태 복구)
          _addDebugLog('🔄 [is_first_update] 테스트 뒤정리 - 원래 상태로 복구 시도');
          await _userService.updateIsFirst(currentIsFirst);
          
          _updateResult('is_first_update', '성공: is_first 업데이트됨 ($currentIsFirst → $newIsFirst → $currentIsFirst)');
        } else {
          _updateResult('is_first_update', '실패: ${updateResult.message}');
        }
      } else {
        _addDebugLog('❌ [is_first_update] 사용자 정보 조회 실패: ${userInfoResult.message}');
        _updateResult('is_first_update', '실패: 사용자 정보 조회 실패');
      }
    } catch (e) {
      _addDebugLog('❌ [is_first_update] 예외 발생: $e');
      _updateResult('is_first_update', '오류: $e');
    }
  }



  Future<void> testMemberCard() async {
    _startTest('member_card');
    try {
      final memberId = _firstMemberId ?? 1;
      _addDebugLog('📡 [member_card] 모바일 교인증 요청 (Member ID: $memberId)');
      
      final result = await _memberCardService.getMemberCard(memberId);
      
      _addDebugLog('📡 [member_card] 응답 성공여부: ${result.success}');
      _addDebugLog('📡 [member_card] 응답 메시지: ${result.message}');
      
      if (result.success) {
        _updateResult('member_card', '성공: 모바일 교인증 데이터 조회됨');
      } else {
        _updateResult('member_card', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [member_card] 예외 발생: $e');
      _updateResult('member_card', '오류: $e');
    }
  }

  Future<void> testCardQRRegenerate() async {
    _startTest('card_qr_regenerate');
    try {
      final memberId = _firstMemberId ?? 1;
      _addDebugLog('📡 [card_qr_regenerate] QR 코드 재생성 요청 (Member ID: $memberId)');
      
      final result = await _memberCardService.regenerateQRCode(memberId);
      
      _addDebugLog('📡 [card_qr_regenerate] 응답 성공여부: ${result.success}');
      _addDebugLog('📡 [card_qr_regenerate] 응답 메시지: ${result.message}');
      
      if (result.success) {
        _updateResult('card_qr_regenerate', '성공: QR 코드 재생성 완료');
      } else {
        _updateResult('card_qr_regenerate', '실패: ${result.message}');
      }
    } catch (e) {
      _addDebugLog('❌ [card_qr_regenerate] 예외 발생: $e');
      _updateResult('card_qr_regenerate', '오류: $e');
    }
  }

  // 공지사항 목록 조회 테스트
  Future<void> testAnnouncementList() async {
    _addDebugLog('📢 [announcement_list] 공지사항 목록 조회 테스트 시작');
    
    try {
      final announcements = await _announcementService.getAnnouncements(
        skip: 0,
        limit: 10,
      );
      
      _addDebugLog('📢 [announcement_list] 공지사항 ${announcements.length}개 조회됨');
      
      if (announcements.isNotEmpty) {
        for (int i = 0; i < announcements.length && i < 3; i++) {
          final announcement = announcements[i];
          _addDebugLog('📢 [announcement_list] [$i] ID: ${announcement.id}, 제목: ${announcement.title}');
          _addDebugLog('📢 [announcement_list] [$i] 고정: ${announcement.isPinned}, 작성자: ${announcement.authorName}');
        }
      }
      
      _updateResult('announcement_list', '성공: 공지사항 ${announcements.length}개 조회');
    } catch (e) {
      _addDebugLog('❌ [announcement_list] 예외 발생: $e');
      _updateResult('announcement_list', '오류: $e');
    }
  }

  // 공지사항 생성 테스트
  Future<void> testAnnouncementCreate() async {
    _addDebugLog('📢 [announcement_create] 공지사항 생성 테스트 시작');
    
    try {
      final request = AnnouncementCreateRequest(
        title: '테스트 공지사항',
        content: '이것은 API 테스트를 위한 공지사항입니다. 생성일시: ${DateTime.now()}',
        isPinned: false,
        targetAudience: '전체',
      );
      
      _addDebugLog('📢 [announcement_create] 요청 데이터: 제목=${request.title}');
      _addDebugLog('📢 [announcement_create] 요청 데이터: 고정=${request.isPinned}');
      
      final announcement = await _announcementService.createAnnouncement(request);
      
      _addDebugLog('📢 [announcement_create] 생성된 공지사항 ID: ${announcement.id}');
      _addDebugLog('📢 [announcement_create] 제목: ${announcement.title}');
      _addDebugLog('📢 [announcement_create] 작성자: ${announcement.authorName}');
      
      _updateResult('announcement_create', '성공: 공지사항 생성 완료 (ID: ${announcement.id})');
    } catch (e) {
      _addDebugLog('❌ [announcement_create] 예외 발생: $e');
      _updateResult('announcement_create', '오류: $e');
    }
  }

  // 공지사항 상세 조회 테스트
  Future<void> testAnnouncementDetail() async {
    _addDebugLog('📢 [announcement_detail] 공지사항 상세 조회 테스트 시작');
    
    try {
      // 먼저 공지사항 목록을 가져와서 첫 번째 항목의 ID 사용
      final announcements = await _announcementService.getAnnouncements(limit: 1);
      
      if (announcements.isEmpty) {
        _updateResult('announcement_detail', '실패: 테스트할 공지사항이 없음');
        return;
      }
      
      final firstId = announcements.first.id;
      _addDebugLog('📢 [announcement_detail] 조회할 공지사항 ID: $firstId');
      
      final announcement = await _announcementService.getAnnouncement(firstId);
      
      _addDebugLog('📢 [announcement_detail] 제목: ${announcement.title}');
      _addDebugLog('📢 [announcement_detail] 내용 길이: ${announcement.content.length}자');
      _addDebugLog('📢 [announcement_detail] 고정 여부: ${announcement.isPinned}');
      _addDebugLog('📢 [announcement_detail] 대상: ${announcement.targetAudience}');
      
      _updateResult('announcement_detail', '성공: 공지사항 상세 조회 완료');
    } catch (e) {
      _addDebugLog('❌ [announcement_detail] 예외 발생: $e');
      _updateResult('announcement_detail', '오류: $e');
    }
  }

  // 공지사항 고정 토글 테스트
  Future<void> testAnnouncementTogglePin() async {
    _addDebugLog('📢 [announcement_toggle_pin] 공지사항 고정 토글 테스트 시작');
    
    try {
      // 먼저 공지사항 목록을 가져와서 첫 번째 항목 사용
      final announcements = await _announcementService.getAnnouncements(limit: 1);
      
      if (announcements.isEmpty) {
        _updateResult('announcement_toggle_pin', '실패: 테스트할 공지사항이 없음');
        return;
      }
      
      final firstAnnouncement = announcements.first;
      final originalPinStatus = firstAnnouncement.isPinned;
      
      _addDebugLog('📢 [announcement_toggle_pin] 대상 ID: ${firstAnnouncement.id}');
      _addDebugLog('📢 [announcement_toggle_pin] 현재 고정 상태: $originalPinStatus');
      
      final updatedAnnouncement = await _announcementService.togglePin(firstAnnouncement.id);
      
      _addDebugLog('📢 [announcement_toggle_pin] 변경된 고정 상태: ${updatedAnnouncement.isPinned}');
      
      if (updatedAnnouncement.isPinned != originalPinStatus) {
        _updateResult('announcement_toggle_pin', '성공: 고정 상태 토글 완료');
      } else {
        _updateResult('announcement_toggle_pin', '실패: 고정 상태가 변경되지 않음');
      }
    } catch (e) {
      _addDebugLog('❌ [announcement_toggle_pin] 예외 발생: $e');
      _updateResult('announcement_toggle_pin', '오류: $e');
    }
  }

  Future<void> testDailyVerseRandom() async {
    if (!_checkAuthRequired('daily_verse_random')) return;
    
    _startTest('daily_verse_random');
    
    try {
      _addDebugLog('📖 [daily_verse_random] 랜덤 말씀 조회 시작');
      
      final dailyVerse = await _dailyVerseService.getRandomVerse();
      
      if (dailyVerse != null) {
        _addDebugLog('📖 [daily_verse_random] 말씀 ID: ${dailyVerse.id}');
        _addDebugLog('📖 [daily_verse_random] 말씀 내용: ${dailyVerse.verse.length > 50 ? dailyVerse.verse.substring(0, 50) + '...' : dailyVerse.verse}');
        _addDebugLog('📖 [daily_verse_random] 참조: ${dailyVerse.reference}');
        _addDebugLog('📖 [daily_verse_random] 활성상태: ${dailyVerse.isActive}');
        _addDebugLog('📖 [daily_verse_random] 생성일: ${dailyVerse.createdAt}');
        
        _updateResult('daily_verse_random', '성공: 말씀 조회 완료 (${dailyVerse.reference})');
      } else {
        _addDebugLog('❌ [daily_verse_random] 말씀 데이터가 null입니다');
        _updateResult('daily_verse_random', '실패: 말씀 데이터가 null');
      }
    } catch (e) {
      _addDebugLog('❌ [daily_verse_random] 예외 발생: $e');
      _updateResult('daily_verse_random', '오류: $e');
    }
  }

  Future<void> _runAllTests() async {
    // 테스트 시작 전 상태 리셋
    _resetTestState();
    
    setState(() {
      _runningAllTests = true;
      _currentTestIndex = 0;
    });
    
    _addDebugLog('전체 API 테스트 시작');
    
    final tests = [
      ('기본 연결', testBasicConnection),
      ('로그인', testAuthLogin),
      ('교인 목록', testMemberList),
      ('교인 상세', testMemberDetail),
      ('출석 기록', testAttendanceRecords),
      ('출석 통계', testAttendanceStats),
      ('QR 생성', testQRGenerate),
      ('QR 정보', testQRInfo),
      ('SMS 발송', testSmsSend),
      ('SMS 기록', testSmsHistory),
      ('일정 조회', testCalendarEvents),
      ('생일 조회', testCalendarBirthdays),
      ('가족 관계', testFamilyRelations),
      ('가족 트리', testFamilyTree),
      ('엑셀 교인', testExcelMembers),
      ('엑셀 출석', testExcelAttendance),
      ('출석 통계', testStatsAttendance),
      ('대시보드 통계', testStatsDashboard),
      ('사용자 정보', testUserInfo),
      ('사용자 목록', testUserList),
      ('비밀번호 변경', testPasswordChange),
      ('is_first 업데이트', testIsFirstUpdate),
      ('교인증', testMemberCard),
      ('QR 재생성', testCardQRRegenerate),
      ('공지사항 목록', testAnnouncementList),
      ('공지사항 생성', testAnnouncementCreate),
      ('공지사항 상세', testAnnouncementDetail),
      ('공지사항 고정', testAnnouncementTogglePin),
      ('오늘의 말씀', testDailyVerseRandom),
    ];

    setState(() {
      _totalTests = tests.length;
    });

    for (int i = 0; i < tests.length; i++) {
      final (testName, testFunction) = tests[i];
      
      setState(() {
        _currentTestIndex = i + 1;
      });
      
      _addDebugLog('📋 [${i + 1}/${tests.length}] $testName 테스트 실행 중...');
      
      try {
        await testFunction();
      } catch (e) {
        _addDebugLog('❌ [$testName] 테스트 중 예외 발생: $e');
      }
      
      // 각 테스트 사이에 약간의 지연을 둡
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _addDebugLog('✅ 전체 API 테스트 완료');
    
    // 테스트 결과 요약
    final successCount = _testResults.values.where((result) => result.contains('성공')).length;
    final failCount = _testResults.values.where((result) => result.contains('실패') || result.contains('오류')).length;
    
    _addDebugLog('📊 테스트 결과 요약: 성공 $successCount개, 실패 $failCount개');
    
    // 상세 결과 로그
    _testResults.forEach((key, result) {
      final status = result.contains('성공') ? '✅' : '❌';
      _addDebugLog('$status [$key]: $result');
    });

    // 테스트 완료 후 상태 리셋
    setState(() {
      _runningAllTests = false;
      _currentTestIndex = 0;
      _totalTests = 0;
    });

    // 모든 테스트 완료 메시지
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('모든 API 테스트가 완료되었습니다! (성공: $successCount, 실패: $failCount)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
