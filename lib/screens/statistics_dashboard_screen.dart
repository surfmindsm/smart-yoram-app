import 'package:flutter/material.dart';
import '../widget/widgets.dart';
import '../config/supabase_config.dart';

class StatisticsDashboardScreen extends StatefulWidget {
  const StatisticsDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsDashboardScreen> createState() => _StatisticsDashboardScreenState();
}

class _StatisticsDashboardScreenState extends State<StatisticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool isLoading = true;
  
  // 출석 통계 데이터
  Map<String, dynamic> attendanceStats = {};
  List<Map<String, dynamic>> attendanceData = [];
  List<Map<String, dynamic>> memberAttendanceStats = [];
  
  // 교인 통계 데이터
  Map<String, dynamic> memberDemographics = {};
  Map<String, dynamic> memberGrowth = {};
  
  DateTimeRange selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => isLoading = true);
    
    try {
      // TODO: 실제 API 연동 (현재는 더미 데이터)
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        // 출석 통계
        attendanceStats = {
          'summary': {
            'total_members': 100,
            'average_attendance': 85.5,
            'average_attendance_rate': 85.5,
            'period': {
              'start_date': selectedDateRange.start.toString().split(' ')[0],
              'end_date': selectedDateRange.end.toString().split(' ')[0],
            }
          }
        };
        
        attendanceData = [
          {
            'date': '2024-01-07',
            'present_count': 90,
            'total_members': 100,
            'attendance_rate': 90.0,
          },
          {
            'date': '2024-01-14',
            'present_count': 85,
            'total_members': 100,
            'attendance_rate': 85.0,
          },
          {
            'date': '2024-01-21',
            'present_count': 88,
            'total_members': 100,
            'attendance_rate': 88.0,
          },
          {
            'date': '2024-01-28',
            'present_count': 78,
            'total_members': 100,
            'attendance_rate': 78.0,
          },
        ];
        
        memberAttendanceStats = [
          {
            'member_name': '김철수',
            'attendance_count': 4,
            'total_services': 4,
            'attendance_rate': 100.0,
          },
          {
            'member_name': '이영희',
            'attendance_count': 3,
            'total_services': 4,
            'attendance_rate': 75.0,
          },
          {
            'member_name': '박민수',
            'attendance_count': 2,
            'total_services': 4,
            'attendance_rate': 50.0,
          },
        ];
        
        // 교인 인구통계
        memberDemographics = {
          'gender_distribution': [
            {'gender': '남', 'count': 45},
            {'gender': '여', 'count': 55}
          ],
          'age_distribution': [
            {'age_group': '20-29', 'count': 15},
            {'age_group': '30-39', 'count': 25},
            {'age_group': '40-49', 'count': 30},
            {'age_group': '50-59', 'count': 20},
            {'age_group': '60+', 'count': 10}
          ],
          'position_distribution': [
            {'position': '집사', 'count': 20},
            {'position': '권사', 'count': 15},
            {'position': '장로', 'count': 5},
            {'position': '성도', 'count': 60}
          ],
          'district_distribution': [
            {'district': '1구역', 'count': 25},
            {'district': '2구역', 'count': 30},
            {'district': '3구역', 'count': 20},
            {'district': '4구역', 'count': 25}
          ]
        };
        
        // 교인 증가 추이
        memberGrowth = {
          'period': {
            'start_date': '2023-01-01',
            'end_date': '2024-01-01',
            'months': 12
          },
          'growth_data': [
            {
              'month': '2023-01',
              'new_members': 5,
              'transfers_out': 1,
              'net_growth': 4,
              'total_members': 96
            },
            {
              'month': '2023-02',
              'new_members': 3,
              'transfers_out': 0,
              'net_growth': 3,
              'total_members': 99
            },
            {
              'month': '2023-03',
              'new_members': 2,
              'transfers_out': 1,
              'net_growth': 1,
              'total_members': 100
            },
          ],
          'summary': {
            'total_new_members': 50,
            'total_transfers_out': 10,
            'net_growth': 40,
            'current_total_members': 100
          }
        };
        
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('통계 데이터를 불러오는데 실패했습니다: $e');
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedDateRange,
    );
    
    if (picked != null && picked != selectedDateRange) {
      setState(() {
        selectedDateRange = picked;
      });
      _loadStatistics();
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('오류'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '통계 대시보드',
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: '기간 선택',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '출석 통계', icon: Icon(Icons.check_circle)),
            Tab(text: '교인 현황', icon: Icon(Icons.people)),
            Tab(text: '성장 추이', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceTab(),
                _buildMemberDemographicsTab(),
                _buildGrowthTab(),
              ],
            ),
    );
  }

  Widget _buildAttendanceTab() {
    final summary = attendanceStats['summary'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기간 표시
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.date_range, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    '분석 기간: ${selectedDateRange.start.toString().split(' ')[0]} ~ ${selectedDateRange.end.toString().split(' ')[0]}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 출석 요약 통계
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.people,
                  value: summary['total_members']?.toString() ?? '0',
                  title: '총 교인 수',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.check_circle,
                  value: summary['average_attendance']?.toStringAsFixed(1) ?? '0.0',
                  title: '평균 출석',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.percent,
                  value: '${summary['average_attendance_rate']?.toStringAsFixed(1) ?? '0.0'}%',
                  title: '출석률',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 주간별 출석 현황
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '주간별 출석 현황',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: attendanceData.isEmpty
                        ? const Center(child: Text('출석 데이터가 없습니다.'))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: attendanceData.length,
                            itemBuilder: (context, index) {
                              final data = attendanceData[index];
                              return Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          data['date'].split('-').sublist(1).join('/'),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${data['present_count']}명',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        Text('/ ${data['total_members']}명'),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getAttendanceRateColor(data['attendance_rate']),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${data['attendance_rate'].toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 개인별 출석 현황 (상위 10명)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '개인별 출석 현황',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...memberAttendanceStats.map((member) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            member['member_name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text('${member['attendance_count']}/${member['total_services']}'),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getAttendanceRateColor(member['attendance_rate']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${member['attendance_rate'].toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberDemographicsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 성별 분포
          _buildDemographicCard(
            '성별 분포',
            Icons.people,
            memberDemographics['gender_distribution'] ?? [],
            'gender',
            'count',
          ),
          
          const SizedBox(height: 16),
          
          // 연령 분포
          _buildDemographicCard(
            '연령대별 분포',
            Icons.cake,
            memberDemographics['age_distribution'] ?? [],
            'age_group',
            'count',
          ),
          
          const SizedBox(height: 16),
          
          // 직분 분포
          _buildDemographicCard(
            '직분별 분포',
            Icons.work,
            memberDemographics['position_distribution'] ?? [],
            'position',
            'count',
          ),
          
          const SizedBox(height: 16),
          
          // 구역 분포
          _buildDemographicCard(
            '구역별 분포',
            Icons.location_on,
            memberDemographics['district_distribution'] ?? [],
            'district',
            'count',
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthTab() {
    final summary = memberGrowth['summary'] ?? {};
    final growthData = memberGrowth['growth_data'] ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 성장 요약
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.person_add,
                  value: summary['total_new_members']?.toString() ?? '0',
                  title: '신규 교인',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.person_remove,
                  value: summary['total_transfers_out']?.toString() ?? '0',
                  title: '이적 교인',
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up,
                  value: summary['net_growth']?.toString() ?? '0',
                  title: '순증가',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 월별 성장 추이
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '월별 성장 추이',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: growthData.isEmpty
                        ? const Center(child: Text('성장 데이터가 없습니다.'))
                        : ListView.builder(
                            itemCount: growthData.length,
                            itemBuilder: (context, index) {
                              final data = growthData[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['month'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '+${data['new_members']}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text('신규', style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '-${data['transfers_out']}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text('이적', style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${data['net_growth'] >= 0 ? '+' : ''}${data['net_growth']}',
                                            style: TextStyle(
                                              color: data['net_growth'] >= 0 
                                                  ? Colors.blue 
                                                  : Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text('순증가', style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${data['total_members']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Text('총 교인', style: TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicCard(
    String title,
    IconData icon,
    List<dynamic> data,
    String labelKey,
    String valueKey,
  ) {
    final total = data.fold<int>(0, (sum, item) => sum + (item[valueKey] as int));
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...data.map((item) {
              final value = item[valueKey] as int;
              final percentage = total > 0 ? (value / total * 100) : 0.0;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        item[labelKey].toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text('$value명'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getAttendanceRateColor(double rate) {
    if (rate >= 90) return Colors.green;
    if (rate >= 80) return Colors.orange;
    if (rate >= 70) return Colors.yellow[700]!;
    return Colors.red;
  }
}
