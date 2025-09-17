import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../models/attendance.dart';
import '../models/api_response.dart';
import '../models/qr_code.dart';
import '../services/attendance_service.dart';
import '../services/qr_service.dart';
import '../services/auth_service.dart';
import '../services/member_service.dart';


class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // QR 코드 관련
  QRCodeInfo? myQRCode;
  bool isLoadingQR = false;
  
  // 출석 기록 관련
  List<Attendance> myAttendanceHistory = [];
  bool isLoadingHistory = false;
  
  // 출석 통계 관련
  Map<String, dynamic> attendanceStats = {};
  bool isLoadingStats = false;
  
  final AttendanceService _attendanceService = AttendanceService();
  final QRService _qrService = QRService();
  final AuthService _authService = AuthService();
  final MemberService _memberService = MemberService();


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadMyQRCode(),
      _loadMyAttendanceHistory(),
      _loadAttendanceStats(),
    ]);
  }

  // QR 코드 로드
  Future<void> _loadMyQRCode() async {
    print('🔍 QR_LOAD: QR 코드 로드 시작');
    setState(() => isLoadingQR = true);
    try {
      print('🔍 QR_LOAD: 사용자 정보 조회 시작');
      final userResponse = await _authService.getCurrentUser();
      print('🔍 QR_LOAD: 사용자 응답 - success: ${userResponse.success}, data: ${userResponse.data != null}');
      
      if (userResponse.success && userResponse.data != null) {
        final user = userResponse.data!;
        final userId = user.id;
        print('🔍 QR_LOAD: 사용자 ID: $userId, is_first: ${user.isFirst}');
        
        // 첫 로그인 체크
        if (user.isFirst) {
          print('🔍 QR_LOAD: 첫 로그인 사용자입니다. 새 QR 코드를 생성합니다.');
        } else {
          print('🔍 QR_LOAD: 기존 사용자입니다. QR 코드를 조회합니다.');
        }
        
        // 올바른 매핑: user_id → member_id → QR 코드
        print('🔍 QR_LOAD: members 테이블에서 user_id $userId로 member 조회');
        final memberResponse = await _memberService.getMemberByUserId(userId);
        
        if (memberResponse.success && memberResponse.data != null) {
          final memberId = memberResponse.data!.id;
          print('🔍 QR_LOAD: 매핑 성공! user_id $userId → member_id $memberId');
          
          late ApiResponse qrResponse;
          
          if (user.isFirst) {
            // 첫 로그인: 새로운 QR 코드 생성
            print('🔍 QR_LOAD: 첫 로그인 → 새 QR 코드 생성');
            qrResponse = await _qrService.generateQRCode(memberId);
            
            if (qrResponse.success && qrResponse.data != null) {
              myQRCode = qrResponse.data;
              print('🔍 QR_LOAD: 새 QR 코드 생성 성공! code: ${myQRCode!.code}');
            } else {
              print('🔍 QR_LOAD: 새 QR 코드 생성 실패 - ${qrResponse.message}');
              await _createTemporaryQRCode();
            }
          } else {
            // 기존 사용자: 기존 QR 코드 조회
            print('🔍 QR_LOAD: 기존 사용자 → 기존 QR 코드 조회');
            final qrListResponse = await _qrService.getMemberQRCodes(memberId);
            
            if (qrListResponse.success && qrListResponse.data != null && qrListResponse.data!.isNotEmpty) {
              // 가장 최신 QR 코드 사용 (첫 번째)
              myQRCode = qrListResponse.data!.first;
              print('🔍 QR_LOAD: 기존 QR 코드 조회 성공! code: ${myQRCode!.code}');
              print('🔍 QR_LOAD: 총 ${qrListResponse.data!.length}개 QR 코드 중 첫 번째 사용');
            } else {
              // 기존 QR이 없으면 새로 생성
              print('🔍 QR_LOAD: 기존 QR 코드가 없음, 새로 생성');
              qrResponse = await _qrService.generateQRCode(memberId);
              
              if (qrResponse.success && qrResponse.data != null) {
                myQRCode = qrResponse.data;
                print('🔍 QR_LOAD: 대체 QR 코드 생성 성공! code: ${myQRCode!.code}');
              } else {
                print('🔍 QR_LOAD: 대체 QR 코드 생성 실패 - ${qrResponse.message}');
                await _createTemporaryQRCode();
              }
            }
          }
        } else {
          print('🔍 QR_LOAD: user_id $userId에 해당하는 member를 찾을 수 없음');
          print('🔍 QR_LOAD: 오류: ${memberResponse.message}');
          await _createTemporaryQRCode();
        }
        
        if (myQRCode == null) {
          print('🔍 QR_LOAD: 모든 member_id 시도 실패, 임시 QR 코드 생성');
          await _createTemporaryQRCode();
        }
      } else {
        print('🔍 QR_LOAD: 사용자 정보 조회 실패 - message: ${userResponse.message}');
      }
    } catch (e) {
      print('🔍 QR_LOAD: 예외 발생 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR 코드 로드 실패: $e')),
        );
      }
    } finally {
      setState(() => isLoadingQR = false);
      print('🔍 QR_LOAD: QR 코드 로드 완료');
    }
  }
  

  // 임시 QR 코드 생성 (Member가 없는 경우)
  Future<void> _createTemporaryQRCode() async {
    print('🔍 QR_LOAD: 임시 QR 코드 생성 시작');
    
    // 임시 QR 코드 데이터 생성
    myQRCode = QRCodeInfo(
      id: 999,
      code: 'TEMP_QR_${DateTime.now().millisecondsSinceEpoch}',
      memberId: 999,
      memberName: '임시 사용자',
      isActive: true,
      createdAt: DateTime.now(),
    );
    
    print('🔍 QR_LOAD: 임시 QR 코드 생성 완료 - code: ${myQRCode!.code}');
  }

  // 출석 기록 로드
  Future<void> _loadMyAttendanceHistory() async {
    setState(() => isLoadingHistory = true);
    try {
      final userResponse = await _authService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        myAttendanceHistory = await _attendanceService.getAttendanceHistory(userResponse.data!.id.toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출석 기록 로드 실패: $e')),
        );
      }
    } finally {
      setState(() => isLoadingHistory = false);
    }
  }

  // 출석 통계 로드
  Future<void> _loadAttendanceStats() async {
    setState(() => isLoadingStats = true);
    try {
      final userResponse = await _authService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        attendanceStats = await _attendanceService.getMyAttendanceStats(userResponse.data!.id.toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출석 통계 로드 실패: $e')),
        );
      }
    } finally {
      setState(() => isLoadingStats = false);
    }
  }

  // QR 코드 새로고침
  Future<void> _refreshQRCode() async {
    setState(() => isLoadingQR = true);
    try {
      final userResponse = await _authService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        final qrResponse = await _qrService.generateQRCode(userResponse.data!.id);
        if (qrResponse.success && qrResponse.data != null) {
          myQRCode = qrResponse.data;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR 코드가 새로 생성되었습니다')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('QR 코드 생성 실패: $e')),
        );
      }
    } finally {
      setState(() => isLoadingQR = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('출석 관리'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: '내 QR 코드'),
            Tab(icon: Icon(Icons.history), text: '출석 기록'),
            Tab(icon: Icon(Icons.bar_chart), text: '내 출석률'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyQRCodeTab(),
          _buildAttendanceHistoryTab(),
          _buildMyStatsTab(),
        ],
      ),
    );
  }

  // 내 QR 코드 탭
  Widget _buildMyQRCodeTab() {
    return RefreshIndicator(
      onRefresh: _loadMyQRCode,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 설명 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info,
                      color: Colors.blue,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '출석 확인 방법',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '아래 QR 코드를 교회의 출석 체크 스캐너에 스캔해주세요.\n예배 시작 전후에 출석 확인이 가능합니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // QR 코드 표시
            if (isLoadingQR)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('QR 코드 로딩 중...'),
                  ],
                ),
              )
            else if (myQRCode != null)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: myQRCode!.code,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '교인 ID: ${myQRCode!.memberId}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '생성일: ${_formatDateTime(myQRCode!.createdAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // QR 코드 새로고침 버튼
                  ElevatedButton.icon(
                    onPressed: isLoadingQR ? null : _refreshQRCode,
                    icon: const Icon(Icons.refresh),
                    label: const Text('QR 코드 새로고침'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'QR 코드를 불러올 수 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMyQRCode,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 출석 기록 탭
  Widget _buildAttendanceHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadMyAttendanceHistory,
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '내 출석 기록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '총 ${myAttendanceHistory.length}건',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // 출석 기록 리스트
          Expanded(
            child: isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : myAttendanceHistory.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '출석 기록이 없습니다',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: myAttendanceHistory.length,
                        itemBuilder: (context, index) {
                          final attendance = myAttendanceHistory[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: attendance.present
                                    ? Colors.green
                                    : Colors.red,
                                child: Icon(
                                  attendance.present
                                      ? Icons.check
                                      : Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                attendance.serviceType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                _formatDate(attendance.serviceDate),
                              ),
                              trailing: Text(
                                attendance.present ? '출석' : '결석',
                                style: TextStyle(
                                  color: attendance.present
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // 내 출석률 탭
  Widget _buildMyStatsTab() {
    return RefreshIndicator(
      onRefresh: _loadAttendanceStats,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: isLoadingStats
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // 전체 출석률 카드
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            '전체 출석률',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${attendanceStats['overall_rate']?.toStringAsFixed(1) ?? '0.0'}%',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: _getAttendanceRateColor(
                                attendanceStats['overall_rate']?.toDouble() ?? 0.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '총 ${attendanceStats['total_services'] ?? 0}회 중 ${attendanceStats['attended_services'] ?? 0}회 출석',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 간단한 통계 카드
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            '이번 달 출석 현황',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('주일예배', '4/4'),
                              _buildStatItem('수요예배', '3/4'),
                              _buildStatItem('새벽예배', '12/16'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getAttendanceRateColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 70) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
