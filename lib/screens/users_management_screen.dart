import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart';
import '../resource/color_style.dart';
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
        builder: (context, setState) => AppDialog(
          title: isEdit ? '사용자 수정' : '새 사용자 추가',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppInput(
                controller: usernameController,
                label: '사용자명',
                prefixIcon: Icons.person,
                disabled: isEdit, // 수정 시 사용자명 변경 불가
              ),
              SizedBox(height: 16.h),
              AppInput(
                controller: emailController,
                label: '이메일',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16.h),
              AppInput(
                controller: fullNameController,
                label: '이름',
                prefixIcon: Icons.badge,
              ),
              if (!isEdit) ...[
                SizedBox(height: 16.h),
                AppInput(
                  label: '비밀번호',
                  placeholder: '비밀번호를 입력하세요',
                  controller: passwordController,
                  obscureText: true,
                ),
              ],
              SizedBox(height: 16.h),
              AppDropdown<String>(
                value: selectedRole,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedRole = value);
                  }
                },
                items: const [
                  AppDropdownMenuItem(value: 'admin', text: '관리자'),
                  AppDropdownMenuItem(value: 'pastor', text: '목회자'),
                  AppDropdownMenuItem(value: 'member', text: '교인'),
                ],
                placeholder: '역할 선택',
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Text(
                    '활성 상태',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColor.secondary07,
                    ),
                  ),
                  const Spacer(),
                  AppSwitch(
                    value: isActive,
                    onChanged: (value) => setState(() => isActive = value),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            AppButton(
              onPressed: () => Navigator.of(context).pop(),
              variant: ButtonVariant.ghost,
              child: Text('취소'),
            ),
            AppButton(
              onPressed: () async {
                if (usernameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    fullNameController.text.isEmpty ||
                    (!isEdit && passwordController.text.isEmpty)) {
                  AppToast.show(
                    context,
                    '모든 필수 항목을 입력해주세요',
                    type: ToastType.error,
                  );
                  return;
                }

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
                
                Navigator.of(context).pop();
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
      await Future.delayed(const Duration(seconds: 1));
      
      if (isEdit) {
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
        AppToast.show(
          context,
          '사용자 정보가 수정되었습니다.',
          type: ToastType.success,
        );
      } else {
        final newUser = {
          'id': users.length + 1,
          'username': username,
          'email': email,
          'full_name': fullName,
          'role': role,
          'is_active': isActive,
          'created_at': DateTime.now().toString().split(' ')[0],
        };
        setState(() => users.add(newUser));
        AppToast.show(
          context,
          '새 사용자가 등록되었습니다.',
          type: ToastType.success,
        );
      }
    } catch (e) {
      _showErrorDialog('사용자 저장에 실패했습니다: $e');
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: '사용자 삭제',
        content: Text('${user['full_name']} 사용자를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          AppButton(
            onPressed: () => Navigator.of(context).pop(false),
            variant: ButtonVariant.ghost,
            child: Text('취소'),
          ),
          AppButton(
            onPressed: () => Navigator.of(context).pop(true),
            variant: ButtonVariant.destructive,
            child: Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: 실제 API 연동
        await Future.delayed(const Duration(seconds: 1));
        
        setState(() => users.removeWhere((u) => u['id'] == user['id']));
        _showSuccessSnackBar('사용자가 삭제되었습니다');
      } catch (e) {
        _showErrorDialog('사용자 삭제에 실패했습니다: $e');
      }
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    try {
      // TODO: 실제 API 연동
      await Future.delayed(const Duration(seconds: 1));
      
      final index = users.indexWhere((u) => u['id'] == user['id']);
      if (index != -1) {
        setState(() {
          users[index]['is_active'] = !users[index]['is_active'];
        });
        _showSuccessSnackBar('사용자 상태가 변경되었습니다');
      }
    } catch (e) {
      _showErrorDialog('상태 변경에 실패했습니다: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '오류',
        content: Text(message),
        actions: [
          AppButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColor.primary600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users.where((user) {
      return user['full_name'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
             user['email'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
             user['username'].toString().toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          '사용자 관리',
          style: TextStyle(
            color: AppColor.secondary07,
            fontWeight: FontWeight.w600,
            fontSize: 20.sp,
          ),
        ),
        backgroundColor: AppColor.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColor.secondary07),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: AppButton(
              onPressed: _createUser,
              size: ButtonSize.sm,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16.sp),
                  SizedBox(width: 4.w),
                  Text('추가'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: EdgeInsets.all(16.w),
            child: AppInput(
              placeholder: '사용자 검색...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          
          // 사용자 목록
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColor.primary600),
                        SizedBox(height: 16.h),
                        Text(
                          '사용자 목록을 불러오는 중...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColor.secondary05,
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 64.sp,
                              color: AppColor.secondary03,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              searchQuery.isEmpty ? '등록된 사용자가 없습니다' : '검색 결과가 없습니다',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColor.secondary05,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: AppCard(
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16.w),
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(user['role']),
                                  child: Icon(
                                    _getRoleIcon(user['role']),
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['full_name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16.sp,
                                        color: AppColor.secondary07,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      user['email'],
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppColor.secondary05,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        AppBadge(
                                          text: _getRoleDisplayName(user['role']),
                                          variant: user['role'] == 'admin' 
                                              ? BadgeVariant.error
                                              : user['role'] == 'pastor' 
                                                  ? BadgeVariant.secondary
                                                  : BadgeVariant.secondary,
                                        ),
                                        SizedBox(width: 8.w),
                                        AppBadge(
                                          text: user['is_active'] ? '활성' : '비활성',
                                          variant: user['is_active'] 
                                              ? BadgeVariant.success 
                                              : BadgeVariant.outline,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  icon: Icon(Icons.more_vert, color: AppColor.secondary05),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: AppColor.secondary07),
                                          SizedBox(width: 8.w),
                                          Text('수정'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'toggle_status',
                                      child: Row(
                                        children: [
                                          Icon(
                                            user['is_active'] ? Icons.block : Icons.check_circle,
                                            color: AppColor.secondary07,
                                          ),
                                          SizedBox(width: 8.w),
                                          Text(user['is_active'] ? '비활성화' : '활성화'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: AppColor.error),
                                          SizedBox(width: 8.w),
                                          Text('삭제', style: TextStyle(color: AppColor.error)),
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
        return AppColor.error;
      case 'pastor':
        return AppColor.primary600;
      case 'member':
        return AppColor.secondary05;
      default:
        return AppColor.secondary03;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.person;
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
