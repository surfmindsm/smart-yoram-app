import 'package:flutter/material.dart';
import '../widget/widgets.dart';
import '../config/api_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({Key? key}) : super(key: key);

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    
    try {
      // TODO: 실제 API 연동 (현재는 더미 데이터)
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        users = [
          {
            'id': 1,
            'username': 'admin',
            'email': 'admin@church.com',
            'full_name': '관리자',
            'role': 'admin',
            'is_active': true,
            'created_at': '2024-01-01'
          },
          {
            'id': 2,
            'username': 'pastor',
            'email': 'pastor@church.com',
            'full_name': '담임목사',
            'role': 'pastor',
            'is_active': true,
            'created_at': '2024-01-02'
          },
          {
            'id': 3,
            'username': 'member1',
            'email': 'member1@church.com',
            'full_name': '김철수',
            'role': 'member',
            'is_active': false,
            'created_at': '2024-01-03'
          },
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorDialog('사용자 목록을 불러오는데 실패했습니다: $e');
    }
  }

  Future<void> _createUser() async {
    await _showUserDialog();
  }

  Future<void> _editUser(Map<String, dynamic> user) async {
    await _showUserDialog(user: user);
  }

  Future<void> _showUserDialog({Map<String, dynamic>? user}) async {
    final isEdit = user != null;
    final usernameController = TextEditingController(text: user?['username'] ?? '');
    final emailController = TextEditingController(text: user?['email'] ?? '');
    final fullNameController = TextEditingController(text: user?['full_name'] ?? '');
    final passwordController = TextEditingController();
    String selectedRole = user?['role'] ?? 'member';
    bool isActive = user?['is_active'] ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? '사용자 수정' : '새 사용자 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomFormField(
                  controller: usernameController,
                  label: '사용자명',
                  prefixIcon: const Icon(Icons.person),
                  enabled: !isEdit, // 수정 시 사용자명 변경 불가
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: emailController,
                  label: '이메일',
                  prefixIcon: const Icon(Icons.email),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: fullNameController,
                  label: '이름',
                  prefixIcon: const Icon(Icons.badge),
                ),
                if (!isEdit) ...[
                  const SizedBox(height: 12),
                  CustomFormField(
                    controller: passwordController,
                    label: '비밀번호',
                    prefixIcon: const Icon(Icons.lock),
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 12),
                CustomDropdownField<String>(
                  value: selectedRole,
                  label: '권한',
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('관리자')),
                    DropdownMenuItem(value: 'pastor', child: Text('목회자')),
                    DropdownMenuItem(value: 'member', child: Text('교인')),
                  ],
                  onChanged: (value) => setState(() {
                    selectedRole = value!;
                  }),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('활성 상태'),
                  value: isActive,
                  onChanged: (value) => setState(() {
                    isActive = value;
                  }),
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
                await _saveUser(
                  isEdit: isEdit,
                  userId: user?['id'],
                  username: usernameController.text,
                  email: emailController.text,
                  fullName: fullNameController.text,
                  password: passwordController.text,
                  role: selectedRole,
                  isActive: isActive,
                );
                Navigator.pop(context);
              },
              child: Text(isEdit ? '수정' : '추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUser({
    required bool isEdit,
    int? userId,
    required String username,
    required String email,
    required String fullName,
    required String password,
    required String role,
    required bool isActive,
  }) async {
    try {
      // TODO: 실제 API 연동
      if (isEdit) {
        // PUT /users/{userId}
        final index = users.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          setState(() {
            users[index] = {
              ...users[index],
              'email': email,
              'full_name': fullName,
              'role': role,
              'is_active': isActive,
            };
          });
        }
      } else {
        // POST /users/
        setState(() {
          users.add({
            'id': users.length + 1,
            'username': username,
            'email': email,
            'full_name': fullName,
            'role': role,
            'is_active': isActive,
            'created_at': DateTime.now().toString().split(' ')[0],
          });
        });
      }
      
      _showSuccessSnackBar(isEdit ? '사용자가 수정되었습니다.' : '새 사용자가 추가되었습니다.');
    } catch (e) {
      _showErrorDialog('사용자 저장에 실패했습니다: $e');
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 삭제'),
        content: Text('${user['full_name']}님을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
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
        // TODO: DELETE /users/{userId} API 연동
        setState(() {
          users.removeWhere((u) => u['id'] == user['id']);
        });
        _showSuccessSnackBar('사용자가 삭제되었습니다.');
      } catch (e) {
        _showErrorDialog('사용자 삭제에 실패했습니다: $e');
      }
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      final newStatus = !user['is_active'];
      // TODO: PUT /users/{userId} API 연동
      
      setState(() {
        final index = users.indexWhere((u) => u['id'] == user['id']);
        if (index != -1) {
          users[index]['is_active'] = newStatus;
        }
      });
      
      _showSuccessSnackBar(
        newStatus ? '사용자가 활성화되었습니다.' : '사용자가 비활성화되었습니다.'
      );
    } catch (e) {
      _showErrorDialog('사용자 상태 변경에 실패했습니다: $e');
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
    final filteredUsers = users.where((user) {
      if (searchQuery.isEmpty) return true;
      return user['full_name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
             user['email'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
             user['username'].toString().toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: '사용자 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createUser,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // 검색바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBarWidget(
              hintText: '사용자명, 이름, 이메일로 검색',
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
                    icon: Icons.people,
                    value: users.length.toString(),
                    title: '전체 사용자',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle,
                    value: users.where((u) => u['is_active']).length.toString(),
                    title: '활성 사용자',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.admin_panel_settings,
                    value: users.where((u) => u['role'] == 'admin').length.toString(),
                    title: '관리자',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 사용자 목록
          Expanded(
            child: isLoading
                ? const LoadingWidget()
                : filteredUsers.isEmpty
                    ? const EmptyStateWidget(
                        icon: Icons.people_outline,
                        title: '사용자가 없습니다.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getRoleColor(user['role']),
                                child: Icon(
                                  _getRoleIcon(user['role']),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                user['full_name'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('@${user['username']} • ${user['email']}'),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getRoleColor(user['role']),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _getRoleDisplayName(user['role']),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user['is_active'] 
                                              ? Colors.green 
                                              : Colors.grey,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          user['is_active'] ? '활성' : '비활성',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
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
                                    value: 'toggle_status',
                                    child: Row(
                                      children: [
                                        Icon(user['is_active'] 
                                            ? Icons.block 
                                            : Icons.check_circle),
                                        const SizedBox(width: 8),
                                        Text(user['is_active'] ? '비활성화' : '활성화'),
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
                                    case 'edit':
                                      _editUser(user);
                                      break;
                                    case 'toggle_status':
                                      _toggleUserStatus(user);
                                      break;
                                    case 'delete':
                                      _deleteUser(user);
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'pastor':
        return Colors.purple;
      case 'member':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'pastor':
        return Icons.church;
      case 'member':
        return Icons.person;
      default:
        return Icons.help;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return '관리자';
      case 'pastor':
        return '목회자';
      case 'member':
        return '교인';
      default:
        return '알 수 없음';
    }
  }
}
