import 'package:flutter/material.dart';
import '../widget/widgets.dart';
import '../config/supabase_config.dart';
// import 'package:file_picker/file_picker.dart'; // TODO: 파일 선택용 패키지 추가 필요

class ExcelManagementScreen extends StatefulWidget {
  const ExcelManagementScreen({Key? key}) : super(key: key);

  @override
  State<ExcelManagementScreen> createState() => _ExcelManagementScreenState();
}

class _ExcelManagementScreenState extends State<ExcelManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Map<String, dynamic>> uploadHistory = [];
  bool isLoading = true;
  bool isUploading = false;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUploadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUploadHistory() async {
    setState(() => isLoading = true);
    
    try {
      // TODO: 실제 API 연동 (현재는 더미 데이터)
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        uploadHistory = [
          {
            'id': 1,
            'filename': '교인명단_2024_01.xlsx',
            'type': 'members',
            'uploaded_at': '2024-01-15 14:30:00',
            'uploaded_by': '관리자',
            'status': 'success',
            'created': 25,
            'updated': 5,
            'errors': 0,
          },
          {
            'id': 2,
            'filename': '교인명단_2023_12.xlsx',
            'type': 'members',
            'uploaded_at': '2023-12-28 16:20:00',
            'uploaded_by': '관리자',
            'status': 'success',
            'created': 30,
            'updated': 8,
            'errors': 2,
          },
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('업로드 기록을 불러오는데 실패했습니다: $e');
    }
  }

  Future<void> _uploadMembersExcel() async {
    try {
      // TODO: 파일 선택 기능 구현
      // final result = await FilePicker.platform.pickFiles(
      //   type: FileType.custom,
      //   allowedExtensions: ['xlsx', 'xls'],
      // );
      
      // if (result != null) {
      //   setState(() => isUploading = true);
      //   
      //   // TODO: POST /excel/members/upload API 연동
      //   await Future.delayed(const Duration(seconds: 3)); // 업로드 시뮬레이션
      //   
      //   setState(() => isUploading = false);
      //   _showSuccessSnackBar('교인 명단이 성공적으로 업로드되었습니다.');
      //   _loadUploadHistory();
      // }
      
      // 임시 구현 (파일 선택 기능 없이)
      setState(() => isUploading = true);
      await Future.delayed(const Duration(seconds: 2));
      
      final newUpload = {
        'id': uploadHistory.length + 1,
        'filename': '교인명단_${DateTime.now().toString().split(' ')[0]}.xlsx',
        'type': 'members',
        'uploaded_at': DateTime.now().toString(),
        'uploaded_by': '관리자',
        'status': 'success',
        'created': 10,
        'updated': 3,
        'errors': 0,
      };
      
      setState(() {
        uploadHistory.insert(0, newUpload);
        isUploading = false;
      });
      
      _showSuccessSnackBar('교인 명단이 성공적으로 업로드되었습니다.');
    } catch (e) {
      setState(() => isUploading = false);
      _showErrorDialog('파일 업로드에 실패했습니다: $e');
    }
  }

  Future<void> _downloadMembersExcel() async {
    try {
      setState(() => isDownloading = true);
      
      // TODO: GET /excel/members/download API 연동
      await Future.delayed(const Duration(seconds: 2)); // 다운로드 시뮬레이션
      
      setState(() => isDownloading = false);
      _showSuccessSnackBar('교인 명단 Excel 파일이 다운로드되었습니다.');
    } catch (e) {
      setState(() => isDownloading = false);
      _showErrorDialog('파일 다운로드에 실패했습니다: $e');
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      setState(() => isDownloading = true);
      
      // TODO: GET /excel/members/template API 연동
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() => isDownloading = false);
      _showSuccessSnackBar('Excel 템플릿이 다운로드되었습니다.');
    } catch (e) {
      setState(() => isDownloading = false);
      _showErrorDialog('템플릿 다운로드에 실패했습니다: $e');
    }
  }

  Future<void> _downloadAttendanceExcel() async {
    // 날짜 범위 선택 다이얼로그
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (dateRange != null) {
      try {
        setState(() => isDownloading = true);
        
        // TODO: GET /excel/attendance/download API 연동
        await Future.delayed(const Duration(seconds: 2));
        
        setState(() => isDownloading = false);
        _showSuccessSnackBar('출석 기록 Excel 파일이 다운로드되었습니다.');
      } catch (e) {
        setState(() => isDownloading = false);
        _showErrorDialog('출석 기록 다운로드에 실패했습니다: $e');
      }
    }
  }

  void _showUploadGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excel 업로드 가이드'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '파일 형식',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• .xlsx 또는 .xls 파일만 업로드 가능합니다.'),
              Text('• 첫 번째 행은 헤더로 사용됩니다.'),
              SizedBox(height: 16),
              Text(
                '필수 컬럼',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• 이름 (필수)'),
              Text('• 성별 (남/여)'),
              Text('• 생년월일 (YYYY-MM-DD)'),
              Text('• 전화번호 (010-1234-5678)'),
              Text('• 주소'),
              Text('• 직분'),
              Text('• 구역'),
              SizedBox(height: 16),
              Text(
                '주의사항',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• 중복된 전화번호가 있을 경우 업데이트됩니다.'),
              Text('• 잘못된 형식의 데이터는 건너뛰고 오류 보고서가 생성됩니다.'),
              Text('• 업로드 전에 반드시 백업을 권장합니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Excel 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showUploadGuide,
            tooltip: '업로드 가이드',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUploadHistory,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '파일 관리', icon: Icon(Icons.file_copy)),
            Tab(text: '업로드 기록', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFileManagementTab(),
          _buildUploadHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildFileManagementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 교인 명단 관리 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        '교인 명단 관리',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '교인 정보를 Excel 파일로 업로드하거나 다운로드할 수 있습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // 업로드 버튼
                  if (isUploading)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('파일을 업로드하는 중...'),
                        ],
                      ),
                    )
                  else
                    CommonButton.primary(
                      text: '교인 명단 업로드',
                      icon: Icons.upload_file,
                      onPressed: _uploadMembersExcel,
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // 다운로드 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: CommonButton.secondary(
                          text: '명단 다운로드',
                          icon: Icons.download,
                          onPressed: isDownloading ? null : _downloadMembersExcel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommonButton.secondary(
                          text: '템플릿 다운로드',
                          icon: Icons.description,
                          onPressed: isDownloading ? null : _downloadTemplate,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 출석 기록 관리 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        '출석 기록 관리',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '출석 기록을 Excel 파일로 다운로드할 수 있습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  CommonButton.primary(
                    text: '출석 기록 다운로드',
                    icon: Icons.download,
                    onPressed: isDownloading ? null : _downloadAttendanceExcel,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 사용법 안내 카드
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '사용법 안내',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. 템플릿 다운로드 버튼을 눌러 양식을 다운받으세요.\n'
                    '2. Excel 파일에 교인 정보를 입력하세요.\n'
                    '3. 업로드 버튼을 눌러 파일을 선택하고 업로드하세요.\n'
                    '4. 업로드 결과를 확인하고 오류가 있다면 수정하세요.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          
          if (isDownloading)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('파일을 다운로드하는 중...'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadHistoryTab() {
    return Column(
      children: [
        // 통계 카드
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.upload_file,
                  value: uploadHistory.length.toString(),
                  title: '총 업로드',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.add_circle,
                  value: uploadHistory.fold<int>(0, (sum, h) => sum + (h['created'] as int)).toString(),
                  title: '총 생성',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.edit,
                  value: uploadHistory.fold<int>(0, (sum, h) => sum + (h['updated'] as int)).toString(),
                  title: '총 수정',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        
        // 업로드 기록 목록
        Expanded(
          child: isLoading
              ? const LoadingWidget()
              : uploadHistory.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.history,
                      title: '업로드 기록이 없습니다.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: uploadHistory.length,
                      itemBuilder: (context, index) {
                        final history = uploadHistory[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: history['status'] == 'success'
                                  ? Colors.green
                                  : Colors.red,
                              child: Icon(
                                history['status'] == 'success'
                                    ? Icons.check
                                    : Icons.error,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(history['filename']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('업로드: ${history['uploaded_at'].split(' ')[0]}'),
                                Text('업로드자: ${history['uploaded_by']}'),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '업로드 결과',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildResultItem(
                                            '생성',
                                            history['created'].toString(),
                                            Icons.add_circle,
                                            Colors.green,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildResultItem(
                                            '수정',
                                            history['updated'].toString(),
                                            Icons.edit,
                                            Colors.blue,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildResultItem(
                                            '오류',
                                            history['errors'].toString(),
                                            Icons.error,
                                            Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
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
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
