import 'package:flutter/material.dart';
import '../widget/widgets.dart';
import '../config/supabase_config.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({Key? key}) : super(key: key);

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> relationships = [];
  bool isLoading = true;
  String searchQuery = '';
  Map<String, dynamic>? selectedMember;

  final List<String> relationshipTypes = [
    '부모', '자녀', '배우자', '형제', '자매', 
    '조부모', '손자녀', '삼촌', '이모', '고모', '조카'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
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
            'gender': '남',
            'date_of_birth': '1980-05-15',
            'phone_number': '010-1234-5678',
            'age': 44,
          },
          {
            'id': 2,
            'name': '김미영',
            'gender': '여',
            'date_of_birth': '1985-03-20',
            'phone_number': '010-9876-5432',
            'age': 39,
          },
          {
            'id': 3,
            'name': '김지민',
            'gender': '남',
            'date_of_birth': '2010-07-10',
            'phone_number': '010-1111-2222',
            'age': 14,
          },
          {
            'id': 4,
            'name': '김하늘',
            'gender': '여',
            'date_of_birth': '2012-12-25',
            'phone_number': '010-3333-4444',
            'age': 12,
          },
        ];
        
        relationships = [
          {
            'id': 1,
            'member_id': 1,
            'member_name': '김철수',
            'related_member_id': 2,
            'related_member_name': '김미영',
            'relationship_type': '배우자',
          },
          {
            'id': 2,
            'member_id': 1,
            'member_name': '김철수',
            'related_member_id': 3,
            'related_member_name': '김지민',
            'relationship_type': '자녀',
          },
          {
            'id': 3,
            'member_id': 1,
            'member_name': '김철수',
            'related_member_id': 4,
            'related_member_name': '김하늘',
            'relationship_type': '자녀',
          },
        ];
        
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('데이터를 불러오는데 실패했습니다: $e');
    }
  }

  Future<void> _addRelationship() async {
    await _showRelationshipDialog();
  }

  Future<void> _editRelationship(Map<String, dynamic> relationship) async {
    await _showRelationshipDialog(relationship: relationship);
  }

  Future<void> _showRelationshipDialog({Map<String, dynamic>? relationship}) async {
    final isEdit = relationship != null;
    Map<String, dynamic>? selectedMainMember = isEdit 
        ? members.firstWhere((m) => m['id'] == relationship!['member_id'])
        : null;
    Map<String, dynamic>? selectedRelatedMember = isEdit 
        ? members.firstWhere((m) => m['id'] == relationship!['related_member_id'])
        : null;
    String selectedRelationType = relationship?['relationship_type'] ?? relationshipTypes[0];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? '가족 관계 수정' : '새 가족 관계 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 주 교인 선택
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedMainMember,
                  decoration: const InputDecoration(
                    labelText: '주 교인',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  items: members.map((member) => DropdownMenuItem(
                    value: member,
                    child: Text('${member['name']} (${member['age']}세)'),
                  )).toList(),
                  onChanged: isEdit ? null : (value) {
                    setState(() {
                      selectedMainMember = value;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 관계 유형 선택
                DropdownButtonFormField<String>(
                  value: selectedRelationType,
                  decoration: const InputDecoration(
                    labelText: '관계',
                    prefixIcon: Icon(Icons.family_restroom),
                    border: OutlineInputBorder(),
                  ),
                  items: relationshipTypes.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRelationType = value!;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 관련 교인 선택
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedRelatedMember,
                  decoration: const InputDecoration(
                    labelText: '관련 교인',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  items: members
                      .where((member) => member['id'] != selectedMainMember?['id'])
                      .map((member) => DropdownMenuItem(
                        value: member,
                        child: Text('${member['name']} (${member['age']}세)'),
                      )).toList(),
                  onChanged: isEdit ? null : (value) {
                    setState(() {
                      selectedRelatedMember = value;
                    });
                  },
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
              onPressed: () async {
                if (selectedMainMember != null && selectedRelatedMember != null) {
                  await _saveRelationship(
                    isEdit: isEdit,
                    relationshipId: relationship?['id'],
                    memberId: selectedMainMember!['id'],
                    memberName: selectedMainMember!['name'],
                    relatedMemberId: selectedRelatedMember!['id'],
                    relatedMemberName: selectedRelatedMember!['name'],
                    relationshipType: selectedRelationType,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(isEdit ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRelationship({
    required bool isEdit,
    int? relationshipId,
    required int memberId,
    required String memberName,
    required int relatedMemberId,
    required String relatedMemberName,
    required String relationshipType,
  }) async {
    try {
      // TODO: 실제 API 연동
      if (isEdit) {
        // PUT /family/relationships/{relationshipId}
        final index = relationships.indexWhere((r) => r['id'] == relationshipId);
        if (index != -1) {
          setState(() {
            relationships[index] = {
              ...relationships[index],
              'relationship_type': relationshipType,
            };
          });
        }
      } else {
        // POST /family/relationships
        setState(() {
          relationships.add({
            'id': relationships.length + 1,
            'member_id': memberId,
            'member_name': memberName,
            'related_member_id': relatedMemberId,
            'related_member_name': relatedMemberName,
            'relationship_type': relationshipType,
          });
        });
      }
      
      _showSuccessSnackBar(isEdit ? '가족 관계가 수정되었습니다.' : '새 가족 관계가 추가되었습니다.');
    } catch (e) {
      _showErrorDialog('가족 관계 저장에 실패했습니다: $e');
    }
  }

  Future<void> _deleteRelationship(Map<String, dynamic> relationship) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가족 관계 삭제'),
        content: Text('${relationship['member_name']}님과 ${relationship['related_member_name']}님의 가족 관계를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: DELETE /family/relationships/{relationshipId} API 연동
        setState(() {
          relationships.removeWhere((r) => r['id'] == relationship['id']);
        });
        _showSuccessSnackBar('가족 관계가 삭제되었습니다.');
      } catch (e) {
        _showErrorDialog('가족 관계 삭제에 실패했습니다: $e');
      }
    }
  }

  void _viewFamilyTree(Map<String, dynamic> member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyTreeScreen(member: member),
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
    final filteredRelationships = relationships.where((rel) {
      if (searchQuery.isEmpty) return true;
      return rel['member_name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
             rel['related_member_name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
             rel['relationship_type'].toString().toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: '가족 관계 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRelationship,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              hintText: '교인명, 관계로 검색',
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          
          // 통계 카드
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.family_restroom,
                    value: relationships.length.toString(),
                    title: '전체 관계',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: '부부 관계',
                    value: '${relationships.where((r) => r['relationship_type'] == '배우자').length}건',
                    icon: Icons.people,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: '부모-자녀 관계',
                    value: '${relationships.where((r) => r['relationship_type'] == '부모-자녀').length}건',
                    icon: Icons.family_restroom,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 관계 목록
          Expanded(
            child: isLoading
                ? const LoadingWidget()
                : filteredRelationships.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.people_outline,
                        title: '가족 관계가 없습니다.',
                        subtitle: '새로운 가족 관계를 추가해보세요.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredRelationships.length,
                        itemBuilder: (context, index) {
                          final relationship = filteredRelationships[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRelationshipColor(relationship['relationship_type']),
                                child: Icon(
                                  _getRelationshipIcon(relationship['relationship_type']),
                                  color: Colors.white,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    relationship['member_name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getRelationshipColor(relationship['relationship_type']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      relationship['relationship_type'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    relationship['related_member_name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '${relationship['member_name']}님의 ${relationship['relationship_type']}',
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'family_tree',
                                    child: const Row(
                                      children: [
                                        Icon(Icons.account_tree),
                                        SizedBox(width: 8),
                                        Text('가족도 보기'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('수정'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: const Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('삭제', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  switch (value) {
                                    case 'family_tree':
                                      final member = members.firstWhere(
                                        (m) => m['id'] == relationship['member_id']
                                      );
                                      _viewFamilyTree(member);
                                      break;
                                    case 'edit':
                                      _editRelationship(relationship);
                                      break;
                                    case 'delete':
                                      _deleteRelationship(relationship);
                                      break;
                                  }
                                },
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

  Color _getRelationshipColor(String relationshipType) {
    switch (relationshipType) {
      case '배우자':
        return Colors.red;
      case '부모':
      case '자녀':
        return Colors.blue;
      case '형제':
      case '자매':
        return Colors.green;
      case '조부모':
      case '손자녀':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  IconData _getRelationshipIcon(String relationshipType) {
    switch (relationshipType) {
      case '배우자':
        return Icons.favorite;
      case '부모':
        return Icons.supervisor_account;
      case '자녀':
        return Icons.child_care;
      case '형제':
      case '자매':
        return Icons.people;
      case '조부모':
        return Icons.elderly;
      case '손자녀':
        return Icons.child_friendly;
      default:
        return Icons.family_restroom;
    }
  }
}

// 가족도 화면
class FamilyTreeScreen extends StatelessWidget {
  final Map<String, dynamic> member;

  const FamilyTreeScreen({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '${member['name']}님 가족도',
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '가족도 기능은 개발 중입니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'API 연동 후 가족 관계를 시각적으로 표시할 예정입니다.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
