import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  
  String selectedServiceType = '주일예배';
  DateTime selectedDate = DateTime.now();
  List<Attendance> attendanceList = [];
  AttendanceStats? stats;
  bool isLoading = true;

  final List<String> serviceTypes = ['주일예배', '수요예배', '새벽예배', '금요기도회'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAttendanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceData() async {
    setState(() => isLoading = true);
    
    try {
      // 임시 출석 데이터 생성
      attendanceList = _generateSampleAttendance();
      stats = _generateSampleStats();
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출석 정보 로드 실패: $e')),
        );
      }
    }
  }

  List<Attendance> _generateSampleAttendance() {
    return [
      Attendance(
        id: '1',
        memberId: '1',
        memberName: '김목사',
        serviceDate: selectedDate,
        serviceType: selectedServiceType,
        present: true,
      ),
      Attendance(
        id: '2',
        memberId: '2',
        memberName: '이장로',
        serviceDate: selectedDate,
        serviceType: selectedServiceType,
        present: true,
      ),
      Attendance(
        id: '3',
        memberId: '3',
        memberName: '박권사',
        serviceDate: selectedDate,
        serviceType: selectedServiceType,
        present: false,
      ),
      Attendance(
        id: '4',
        memberId: '4',
        memberName: '최집사',
        serviceDate: selectedDate,
        serviceType: selectedServiceType,
        present: true,
      ),
      Attendance(
        id: '5',
        memberId: '5',
        memberName: '정성도',
        serviceDate: selectedDate,
        serviceType: selectedServiceType,
        present: true,
      ),
    ];
  }

  AttendanceStats _generateSampleStats() {
    int presentCount = attendanceList.where((a) => a.present).length;
    return AttendanceStats(
      totalMembers: attendanceList.length,
      presentMembers: presentCount,
      attendanceRate: (presentCount / attendanceList.length * 100),
      byDistrict: {'1구역': 2, '2구역': 1, '3구역': 1},
      byPosition: {'교역자': 1, '장로': 1, '권사': 0, '집사': 1, '성도': 1},
    );
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
            Tab(text: '출석 체크'),
            Tab(text: '내 출석 기록'),
            Tab(text: '통계'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAttendanceCheckTab(),
          _buildAttendanceStatusTab(),
          _buildAttendanceStatsTab(),
        ],
      ),
    );
  }

  Widget _buildAttendanceCheckTab() {
    return Column(
      children: [
        // 날짜 및 예배 선택
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedServiceType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: serviceTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedServiceType = value;
                          });
                          _loadAttendanceData();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // QR 출석 체크 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showQRScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('QR로 출석 체크'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // 내 출석 내역 보기 버튼
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: _showMyAttendanceHistory,
            icon: const Icon(Icons.history),
            label: const Text('내 출석 내역 보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        
        // 오늘 출석 현황
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTodayAttendanceList(),
        ),
      ],
    );
  }

  Widget _buildTodayAttendanceList() {
    if (stats == null) return const SizedBox();
    
    return Column(
      children: [
        // 출석 요약
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '${stats!.presentMembers}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text('출석'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${stats!.totalMembers - stats!.presentMembers}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Text('결석'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${stats!.attendanceRate.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text('출석률'),
                ],
              ),
            ],
          ),
        ),
        
        // 출석자 목록
        Expanded(
          child: ListView.builder(
            itemCount: attendanceList.length,
            itemBuilder: (context, index) {
              final attendance = attendanceList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: attendance.present ? Colors.green : Colors.red,
                  child: Icon(
                    attendance.present ? Icons.check : Icons.close,
                    color: Colors.white,
                  ),
                ),
                title: Text(attendance.memberName),
                subtitle: Text(attendance.present ? '출석' : '결석'),
                trailing: Switch(
                  value: attendance.present,
                  onChanged: (value) {
                    _toggleAttendance(attendance, value);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStatusTab() {
    return const Center(
      child: Text(
        '출석 현황 탭\n(구현 예정)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildAttendanceStatsTab() {
    if (stats == null) {
      return const Center(child: Text('통계 데이터가 없습니다.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 통계
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '전체 출석 통계',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('전체 교인', '${stats!.totalMembers}명'),
                      _buildStatItem('출석자', '${stats!.presentMembers}명'),
                      _buildStatItem('출석률', '${stats!.attendanceRate.toStringAsFixed(1)}%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 구역별 출석
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '구역별 출석 현황',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...stats!.byDistrict.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text('${entry.value}명'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 직분별 출석
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '직분별 출석 현황',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...stats!.byPosition.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text('${entry.value}명'),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
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
        Text(title),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadAttendanceData();
    }
  }

  void _showQRScanner() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR 출석 체크'),
        content: const Text('QR 스캐너 기능은 준비 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _showMyAttendanceHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내 출석 내역'),
        content: SizedBox(
          height: 300,
          width: 300,
          child: ListView(
            children: const [
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('2024.01.28 주일예배'),
                subtitle: Text('출석'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('2024.01.24 수요예배'),
                subtitle: Text('출석'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('2024.01.21 주일예배'),
                subtitle: Text('출석'),
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: Colors.red),
                title: Text('2024.01.17 수요예배'),
                subtitle: Text('결석'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('2024.01.14 주일예배'),
                subtitle: Text('출석'),
              ),
            ],
          ),
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

  void _toggleAttendance(Attendance attendance, bool isPresent) {
    setState(() {
      final index = attendanceList.indexWhere((a) => a.id == attendance.id);
      if (index != -1) {
        attendanceList[index] = Attendance(
          id: attendance.id,
          memberId: attendance.memberId,
          memberName: attendance.memberName,
          serviceDate: attendance.serviceDate,
          serviceType: attendance.serviceType,
          present: isPresent,
          notes: attendance.notes,
        );
      }
      stats = _generateSampleStats();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${attendance.memberName}의 출석 상태가 변경되었습니다.'),
      ),
    );
  }
}
