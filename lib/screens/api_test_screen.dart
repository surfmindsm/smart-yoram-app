import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/api_config.dart';
import '../services/services.dart';

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

  final Map<String, String> _testResults = {};
  final Map<String, bool> _testingStatus = {};
  final List<String> _debugLogs = [];

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
            const SizedBox(height: 20),
            _buildSection('기본 연결 테스트', [
              _buildTestButton('기본 연결', 'basic_connection', testBasicConnection),
            ]),
            _buildSection('인증 서비스', [
              _buildTestButton('로그인', 'auth_login', testAuthLogin),
              _buildTestButton('회원가입', 'auth_register', testAuthRegister),
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
            ]),
            _buildSection('모바일 교인증', [
              _buildTestButton('교인증 정보', 'member_card', testMemberCard),
              _buildTestButton('QR 재생성', 'card_qr_regenerate', testCardQRRegenerate),
            ]),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _runAllTests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('모든 테스트 실행', style: TextStyle(fontSize: 16)),
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
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _debugLogs.add('[$timestamp] $message');
      // 로그가 너무 많이 쌓이지 않도록 100개로 제한
      if (_debugLogs.length > 100) {
        _debugLogs.removeAt(0);
      }
    });
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...buttons,
          ],
        ),
      ),
    );
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
      _testResults.remove(key);
    });
  }

  void _updateResult(String key, String result) {
    setState(() {
      _testingStatus[key] = false;
      _testResults[key] = result;
    });
  }

  Future<void> testBasicConnection() async {
    _startTest('basic_connection');
    try {
      // 로그 추가: 기본 연결 정보
      developer.log('=== 기본 API 연결 테스트 ===', name: 'API_TEST');
      developer.log('Base URL: ${ApiConfig.baseUrl}', name: 'API_TEST');
      developer.log('Auth Endpoint: ${ApiConfig.auth}', name: 'API_TEST');
      
      // 기본 API 연결 테스트
      _updateResult('basic_connection', '✅ 성공: API 서버 연결 가능\nBase URL: ${ApiConfig.baseUrl}');
    } catch (e) {
      developer.log('Basic connection error: $e', name: 'API_TEST');
      _updateResult('basic_connection', '❌ 오류: $e');
    }
  }

  Future<void> testAuthLogin() async {
    _startTest('auth_login');
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        _updateResult('auth_login', '❌ 실패: 사용자명과 비밀번호를 입력해주세요');
        return;
      }
      
      final username = _emailController.text.trim();
      final password = _passwordController.text;
      
      // 로그 추가: 요청 정보
      _addDebugLog('=== API 로그인 시도 ===');
      _addDebugLog('URL: ${ApiConfig.baseUrl}${ApiConfig.auth}/login');
      _addDebugLog('Username: $username');
      _addDebugLog('Password length: ${password.length}');
      
      developer.log('=== API 로그인 시도 ===', name: 'API_TEST');
      developer.log('URL: ${ApiConfig.baseUrl}${ApiConfig.auth}/login', name: 'API_TEST');
      developer.log('Username: $username', name: 'API_TEST');
      developer.log('Password length: ${password.length}', name: 'API_TEST');
      
      final result = await _authService.login(username, password);
      
      // 로그 추가: 응답 정보
      _addDebugLog('=== API 로그인 응답 ===');
      _addDebugLog('Success: ${result.success}');
      _addDebugLog('Message: ${result.message}');
      _addDebugLog('Data: ${result.data}');
      
      developer.log('=== API 로그인 응답 ===', name: 'API_TEST');
      developer.log('Success: ${result.success}', name: 'API_TEST');
      developer.log('Message: ${result.message}', name: 'API_TEST');
      developer.log('Data: ${result.data}', name: 'API_TEST');
      
      if (result.success) {
        final token = result.data?.accessToken;
        developer.log('Access Token: ${token?.substring(0, 20)}...', name: 'API_TEST');
        
        setState(() {
          _isLoggedIn = true;
          _authToken = token;
          _currentUserEmail = username;
        });
        _updateResult('auth_login', '✅ 성공: 로그인 완료 (${result.message})');
      } else {
        _updateResult('auth_login', '❌ 실패: ${result.message}\n디버그 로그를 확인하세요.');
      }
    } catch (e) {
      developer.log('Exception: $e', name: 'API_TEST');
      developer.log('Stack trace: ${StackTrace.current}', name: 'API_TEST');
      _updateResult('auth_login', '❌ 오류: $e\n디버그 로그를 확인하세요.');
    }
  }

  Future<void> testAuthRegister() async {
    _startTest('auth_register');
    try {
      // register 메서드가 없으므로 로그인만 테스트
      final result = await _authService.login('test@example.com', 'password123');
      if (result.success) {
        _updateResult('auth_register', '✅ 성공: ${result.message}');
      } else {
        _updateResult('auth_register', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('auth_register', '❌ 오류: $e');
    }
  }

  Future<void> testMemberList() async {
    _startTest('member_list');
    if (!_checkAuthRequired('member_list')) return;
    
    try {
      final result = await _memberService.getMembers();
      if (result.success) {
        _updateResult('member_list', '✅ 성공: ${result.data?.length ?? 0}명의 교인 목록 조회');
      } else {
        _updateResult('member_list', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('member_list', '❌ 오류: $e');
    }
  }

  Future<void> testMemberDetail() async {
    _startTest('member_detail');
    if (!_checkAuthRequired('member_detail')) return;
    
    try {
      final result = await _memberService.getMember(1);
      if (result.success) {
        _updateResult('member_detail', '✅ 성공: 교인 상세정보 조회됨');
      } else {
        _updateResult('member_detail', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('member_detail', '❌ 오류: $e');
    }
  }

  Future<void> testAttendanceRecords() async {
    _startTest('attendance_records');
    try {
      final result = await _attendanceService.getMemberAttendanceRecords(1);
      if (result.success) {
        _updateResult('attendance_records', '✅ 성공: ${result.data?.length ?? 0}개의 출석 기록 조회');
      } else {
        _updateResult('attendance_records', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('attendance_records', '❌ 오류: $e');
    }
  }

  Future<void> testAttendanceStats() async {
    _startTest('attendance_stats');
    try {
      final result = await _attendanceService.getMemberAttendanceStats(1);
      if (result.success) {
        _updateResult('attendance_stats', '✅ 성공: 출석 통계 데이터 조회됨');
      } else {
        _updateResult('attendance_stats', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('attendance_stats', '❌ 오류: $e');
    }
  }

  Future<void> testQRGenerate() async {
    _startTest('qr_generate');
    try {
      final result = await _qrService.generateQRCode(1);
      if (result.success) {
        _updateResult('qr_generate', '✅ 성공: QR 코드 생성됨 - ${result.data?.code ?? 'N/A'}');
      } else {
        _updateResult('qr_generate', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('qr_generate', '❌ 오류: $e');
    }
  }

  Future<void> testQRInfo() async {
    _startTest('qr_info');
    try {
      final result = await _qrService.getQRCodeInfo('test_qr_code');
      if (result.success) {
        _updateResult('qr_info', '✅ 성공: QR 코드 정보 조회됨');
      } else {
        _updateResult('qr_info', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('qr_info', '❌ 오류: $e');
    }
  }

  Future<void> testSmsSend() async {
    _startTest('sms_send');
    try {
      final result = await _smsService.sendSms(
        recipientPhone: '01012345678',
        message: '테스트 메시지',
        smsType: 'general',
      );
      if (result.success) {
        _updateResult('sms_send', '✅ 성공: SMS 발송 완료');
      } else {
        _updateResult('sms_send', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('sms_send', '❌ 오류: $e');
    }
  }

  Future<void> testSmsHistory() async {
    _startTest('sms_history');
    try {
      final result = await _smsService.getSmsHistory();
      if (result.success) {
        _updateResult('sms_history', '✅ 성공: ${result.data?.length ?? 0}개의 SMS 기록 조회');
      } else {
        _updateResult('sms_history', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('sms_history', '❌ 오류: $e');
    }
  }

  Future<void> testCalendarEvents() async {
    _startTest('calendar_events');
    try {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now().add(const Duration(days: 30));
      final result = await _calendarService.getEvents(
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );
      if (result.success) {
        _updateResult('calendar_events', '✅ 성공: ${result.data?.length ?? 0}개의 일정 조회');
      } else {
        _updateResult('calendar_events', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('calendar_events', '❌ 오류: $e');
    }
  }

  Future<void> testCalendarBirthdays() async {
    _startTest('calendar_birthdays');
    try {
      final result = await _calendarService.getUpcomingBirthdays();
      if (result.success) {
        _updateResult('calendar_birthdays', '✅ 성공: ${result.data?.length ?? 0}명의 생일 조회');
      } else {
        _updateResult('calendar_birthdays', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('calendar_birthdays', '❌ 오류: $e');
    }
  }

  Future<void> testFamilyRelations() async {
    _startTest('family_relations');
    try {
      final result = await _familyService.getMemberRelationships(1);
      if (result.success) {
        _updateResult('family_relations', '✅ 성공: ${result.data?.length ?? 0}개의 가족 관계 조회');
      } else {
        _updateResult('family_relations', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('family_relations', '❌ 오류: $e');
    }
  }

  Future<void> testFamilyTree() async {
    _startTest('family_tree');
    try {
      final result = await _familyService.getFamilyTree(1);
      if (result.success) {
        _updateResult('family_tree', '✅ 성공: 가족 트리 데이터 조회됨');
      } else {
        _updateResult('family_tree', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('family_tree', '❌ 오류: $e');
    }
  }

  Future<void> testExcelMembers() async {
    _startTest('excel_members');
    try {
      final result = await _excelService.downloadMembersExcel();
      if (result.success) {
        _updateResult('excel_members', '✅ 성공: 교인 엑셀 다운로드 완료');
      } else {
        _updateResult('excel_members', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('excel_members', '❌ 오류: $e');
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
        _updateResult('excel_attendance', '✅ 성공: 출석 엑셀 다운로드 완료');
      } else {
        _updateResult('excel_attendance', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('excel_attendance', '❌ 오류: $e');
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
        _updateResult('stats_attendance', '✅ 성공: 출석 통계 데이터 조회됨');
      } else {
        _updateResult('stats_attendance', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('stats_attendance', '❌ 오류: $e');
    }
  }

  Future<void> testStatsDashboard() async {
    _startTest('stats_dashboard');
    try {
      final result = await _statisticsService.getDashboardStats();
      if (result.success) {
        _updateResult('stats_dashboard', '✅ 성공: 대시보드 통계 데이터 조회됨');
      } else {
        _updateResult('stats_dashboard', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('stats_dashboard', '❌ 오류: $e');
    }
  }

  Future<void> testUserInfo() async {
    _startTest('user_info');
    if (!_checkAuthRequired('user_info')) return;
    
    try {
      final result = await _userService.getCurrentUser();
      if (result.success) {
        _updateResult('user_info', '✅ 성공: 현재 사용자 정보 조회됨');
      } else {
        _updateResult('user_info', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('user_info', '❌ 오류: $e');
    }
  }

  Future<void> testUserList() async {
    _startTest('user_list');
    try {
      final result = await _userService.getUsers();
      if (result.success) {
        _updateResult('user_list', '✅ 성공: ${result.data?.length ?? 0}명의 사용자 목록 조회');
      } else {
        _updateResult('user_list', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('user_list', '❌ 오류: $e');
    }
  }

  Future<void> testMemberCard() async {
    _startTest('member_card');
    try {
      final result = await _memberCardService.getMemberCard(1);
      if (result.success) {
        _updateResult('member_card', '✅ 성공: 모바일 교인증 데이터 조회됨');
      } else {
        _updateResult('member_card', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('member_card', '❌ 오류: $e');
    }
  }

  Future<void> testCardQRRegenerate() async {
    _startTest('card_qr_regenerate');
    try {
      final result = await _memberCardService.regenerateQRCode(1);
      if (result.success) {
        _updateResult('card_qr_regenerate', '✅ 성공: QR 코드 재생성 완료');
      } else {
        _updateResult('card_qr_regenerate', '❌ 실패: ${result.message}');
      }
    } catch (e) {
      _updateResult('card_qr_regenerate', '❌ 오류: $e');
    }
  }

  Future<void> _runAllTests() async {
    final tests = [
      testBasicConnection,
      testAuthLogin,
      testAuthRegister,
      testMemberList,
      testMemberDetail,
      testAttendanceRecords,
      testAttendanceStats,
      testQRGenerate,
      testQRInfo,
      testSmsSend,
      testSmsHistory,
      testCalendarEvents,
      testCalendarBirthdays,
      testFamilyRelations,
      testFamilyTree,
      testExcelMembers,
      testExcelAttendance,
      testStatsAttendance,
      testStatsDashboard,
      testUserInfo,
      testUserList,
      testMemberCard,
      testCardQRRegenerate,
    ];

    for (final test in tests) {
      await test();
      // 각 테스트 사이에 약간의 지연을 둠
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 모든 테스트 완료 메시지
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 API 테스트가 완료되었습니다!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
