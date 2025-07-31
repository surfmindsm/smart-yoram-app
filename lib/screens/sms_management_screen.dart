import 'package:flutter/material.dart';
import '../widget/widgets.dart';
import '../config/api_config.dart';

class SmsManagementScreen extends StatefulWidget {
  const SmsManagementScreen({Key? key}) : super(key: key);

  @override
  State<SmsManagementScreen> createState() => _SmsManagementScreenState();
}

class _SmsManagementScreenState extends State<SmsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // SMS 발송 관련
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> selectedMembers = [];
  List<Map<String, dynamic>> smsHistory = [];
  List<Map<String, dynamic>> templates = [];
  bool isLoading = true;
  
  // 개별 발송 컨트롤러
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  // 단체 발송 컨트롤러
  final TextEditingController _bulkMessageController = TextEditingController();
  
  String selectedSmsType = 'notice';
  Map<String, dynamic>? selectedTemplate;

  final List<Map<String, String>> smsTypes = [
    {'value': 'notice', 'label': '공지사항'},
    {'value': 'invitation', 'label': '초대장'},
    {'value': 'reminder', 'label': '알림'},
    {'value': 'birthday', 'label': '생일축하'},
    {'value': 'event', 'label': '행사안내'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _bulkMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      // TODO: 실제 API 연동 (현재는 더미 데이터)
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        members = [
          {
            'id': 1,
            'name': '김철수',
            'phone': '010-1234-5678',
            'position': '집사',
            'district': '1구역',
          },
          {
            'id': 2,
            'name': '이영희',
            'phone': '010-9876-5432',
            'position': '권사',
            'district': '2구역',
          },
          {
            'id': 3,
            'name': '박민수',
            'phone': '010-5555-6666',
            'position': '성도',
            'district': '1구역',
          },
        ];
        
        templates = [
          {
            'id': 1,
            'name': '주일예배 안내',
            'message': '[성광교회] 안녕하세요 {name}님! 이번 주일예배에 참석하여 은혜받는 시간 되시길 바랍니다. 오전 11시 본당에서 뵙겠습니다.',
            'sms_type': 'invitation',
          },
          {
            'id': 2,
            'name': '생일축하',
            'message': '[성광교회] {name}님의 생일을 축하합니다! 하나님의 사랑과 은혜가 새로운 한 해 동안 가득하시길 기도합니다. 생일축하드립니다!',
            'sms_type': 'birthday',
          },
          {
            'id': 3,
            'name': '행사 안내',
            'message': '[성광교회] {name}님, {event_name} 행사가 {event_date}에 있습니다. 많은 참여 부탁드립니다.',
            'sms_type': 'event',
          },
        ];
        
        smsHistory = [
          {
            'id': 1,
            'recipient_name': '김철수',
            'recipient_phone': '010-1234-5678',
            'message': '주일예배 안내 메시지입니다.',
            'sms_type': 'invitation',
            'sent_at': '2024-01-01 10:30:00',
            'status': 'success',
          },
          {
            'id': 2,
            'recipient_name': '단체발송',
            'recipient_phone': '5명',
            'message': '새해 감사예배 안내',
            'sms_type': 'notice',
            'sent_at': '2024-01-01 09:00:00',
            'status': 'success',
          },
        ];
        
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('데이터를 불러오는데 실패했습니다: $e');
    }
  }

  Future<void> _sendIndividualSms() async {
    if (_phoneController.text.isEmpty || _messageController.text.isEmpty) {
      _showErrorDialog('전화번호와 메시지를 입력해주세요.');
      return;
    }

    try {
      // TODO: POST /sms/send API 연동
      final newHistory = {
        'id': smsHistory.length + 1,
        'recipient_name': '직접입력',
        'recipient_phone': _phoneController.text,
        'message': _messageController.text,
        'sms_type': selectedSmsType,
        'sent_at': DateTime.now().toString(),
        'status': 'success',
      };
      
      setState(() {
        smsHistory.insert(0, newHistory);
      });
      
      _phoneController.clear();
      _messageController.clear();
      _showSuccessSnackBar('SMS가 발송되었습니다.');
    } catch (e) {
      _showErrorDialog('SMS 발송에 실패했습니다: $e');
    }
  }

  Future<void> _sendBulkSms() async {
    if (selectedMembers.isEmpty || _bulkMessageController.text.isEmpty) {
      _showErrorDialog('수신자와 메시지를 선택/입력해주세요.');
      return;
    }

    try {
      // TODO: POST /sms/send-bulk API 연동
      final newHistory = {
        'id': smsHistory.length + 1,
        'recipient_name': '단체발송',
        'recipient_phone': '${selectedMembers.length}명',
        'message': _bulkMessageController.text,
        'sms_type': selectedSmsType,
        'sent_at': DateTime.now().toString(),
        'status': 'success',
      };
      
      setState(() {
        smsHistory.insert(0, newHistory);
        selectedMembers.clear();
      });
      
      _bulkMessageController.clear();
      _showSuccessSnackBar('단체 SMS가 발송되었습니다.');
    } catch (e) {
      _showErrorDialog('단체 SMS 발송에 실패했습니다: $e');
    }
  }

  void _applyTemplate(Map<String, dynamic> template) {
    if (_tabController.index == 0) {
      // 개별 발송
      _messageController.text = template['message'];
    } else {
      // 단체 발송
      _bulkMessageController.text = template['message'];
    }
    
    setState(() {
      selectedSmsType = template['sms_type'];
      selectedTemplate = template;
    });
  }

  void _showMemberSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('수신자 선택'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                // 전체 선택/해제 버튼
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedMembers = List.from(members);
                        });
                      },
                      child: const Text('전체 선택'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedMembers.clear();
                        });
                      },
                      child: const Text('전체 해제'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 교인 목록
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isSelected = selectedMembers.any((m) => m['id'] == member['id']);
                      
                      return CheckboxListTile(
                        title: Text(member['name']),
                        subtitle: Text('${member['phone']} • ${member['position']} • ${member['district']}'),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedMembers.add(member);
                            } else {
                              selectedMembers.removeWhere((m) => m['id'] == member['id']);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                this.setState(() {}); // 외부 setState 호출
              },
              child: Text('선택 완료 (${selectedMembers.length}명)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('템플릿 선택'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                child: ListTile(
                  title: Text(template['name']),
                  subtitle: Text(
                    template['message'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      smsTypes.firstWhere((t) => t['value'] == template['sms_type'])['label']!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  onTap: () {
                    _applyTemplate(template);
                    Navigator.pop(context);
                  },
                ),
              );
            },
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

  void _showErrorDialog(String message) {
    CommonDialog.showErrorDialog(
      context,
      message: message,
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
        title: 'SMS 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.text_snippet),
            onPressed: _showTemplateDialog,
            tooltip: '템플릿',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '개별 발송', icon: Icon(Icons.person)),
            Tab(text: '단체 발송', icon: Icon(Icons.group)),
            Tab(text: '발송 기록', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: isLoading
          ? const LoadingWidget()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildIndividualSmsTab(),
                _buildBulkSmsTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildIndividualSmsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '개별 SMS 발송',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // 전화번호 입력
                  CustomFormField(
                    controller: _phoneController,
                    label: '수신자 전화번호',
                    prefixIcon: const Icon(Icons.phone),
                    keyboardType: TextInputType.phone,
                    hintText: '010-1234-5678',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '전화번호를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // SMS 유형 선택
                  CustomDropdownField<String>(
                    value: selectedSmsType,
                    label: 'SMS 유형',
                    items: smsTypes.map((type) => DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    )).toList(),
                    onChanged: (value) => setState(() {
                      selectedSmsType = value!;
                    }),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 메시지 입력
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    maxLength: 90, // SMS 길이 제한
                    decoration: const InputDecoration(
                      labelText: '메시지 내용',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                      hintText: '발송할 메시지를 입력하세요...',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showTemplateDialog,
                          icon: const Icon(Icons.text_snippet),
                          label: const Text('템플릿 사용'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sendIndividualSms,
                          icon: const Icon(Icons.send),
                          label: const Text('발송'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 교인 빠른 선택
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '교인 빠른 선택',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          child: Card(
                            child: InkWell(
                              onTap: () {
                                _phoneController.text = member['phone'];
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      child: Text(member['name'][0]),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      member['name'],
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      member['position'],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
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
        ],
      ),
    );
  }

  Widget _buildBulkSmsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '단체 SMS 발송',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // 수신자 선택 버튼
                  InkWell(
                    onTap: _showMemberSelectionDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedMembers.isEmpty
                                  ? '수신자를 선택하세요'
                                  : '${selectedMembers.length}명 선택됨',
                              style: TextStyle(
                                color: selectedMembers.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 선택된 수신자 미리보기
                  if (selectedMembers.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '선택된 수신자:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: selectedMembers.map((member) => Chip(
                              label: Text(member['name']),
                              onDeleted: () {
                                setState(() {
                                  selectedMembers.removeWhere((m) => m['id'] == member['id']);
                                });
                              },
                            )).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // SMS 유형 선택
                  CustomDropdownField<String>(
                    value: selectedSmsType,
                    label: 'SMS 유형',
                    items: smsTypes.map((type) => DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['label']!),
                    )).toList(),
                    onChanged: (value) => setState(() {
                      selectedSmsType = value!;
                    }),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 메시지 입력
                  TextField(
                    controller: _bulkMessageController,
                    maxLines: 5,
                    maxLength: 90,
                    decoration: const InputDecoration(
                      labelText: '메시지 내용',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                      hintText: '단체 발송할 메시지를 입력하세요...',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showTemplateDialog,
                          icon: const Icon(Icons.text_snippet),
                          label: const Text('템플릿 사용'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: selectedMembers.isEmpty ? null : _sendBulkSms,
                          icon: const Icon(Icons.send),
                          label: Text('발송 (${selectedMembers.length}명)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // 통계 카드
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.send,
                  value: smsHistory.length.toString(),
                  title: '총 발송',
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.check_circle,
                  value: smsHistory.where((h) => h['status'] == 'success').length.toString(),
                  title: '성공',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.error,
                  value: smsHistory.where((h) => h['status'] == 'failed').length.toString(),
                  title: '실패',
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        
        // 발송 기록 목록
        Expanded(
          child: smsHistory.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.history,
                  title: '발송 기록이 없습니다.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: smsHistory.length,
                  itemBuilder: (context, index) {
                    final history = smsHistory[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
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
                        title: Text(history['recipient_name']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('수신자: ${history['recipient_phone']}'),
                            Text(
                              history['message'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    smsTypes.firstWhere(
                                      (t) => t['value'] == history['sms_type'],
                                      orElse: () => {'label': '기타'}
                                    )['label']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  history['sent_at'].split(' ')[0], // 날짜만 표시
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
