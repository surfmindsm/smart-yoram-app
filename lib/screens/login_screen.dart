import 'package:flutter/material.dart';
import '../widget/widgets.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/api_response.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool isLoading = false;
  bool obscurePassword = true;
  
  // 로그인 방식
  String _loginType = 'email'; // 'email' 또는 'phone'

  @override
  void initState() {
    super.initState();
    _checkExistingLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // 기존 로그인 상태 확인
  Future<void> _checkExistingLogin() async {
    final hasStoredAuth = await _authService.loadStoredAuth();
    if (hasStoredAuth && mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // 앱 로고 및 제목
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.church,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '스마트 교회요람',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '교회 생활의 새로운 시작',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // 로그인 방식 선택 탭
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginType = 'email'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _loginType == 'email' ? Colors.blue[700] : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '이메일 로그인',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _loginType == 'email' ? Colors.white : Colors.grey[600],
                                fontWeight: _loginType == 'email' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _loginType = 'phone'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _loginType == 'phone' ? Colors.blue[700] : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '전화번호 로그인',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _loginType == 'phone' ? Colors.white : Colors.grey[600],
                                fontWeight: _loginType == 'phone' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 사용자명/이메일/전화번호 입력
                CustomFormField(
                  label: _loginType == 'email' ? '이메일' : '전화번호',
                  controller: _usernameController,
                  hintText: _loginType == 'email' 
                    ? 'user@example.com'
                    : '010-1234-5678',
                  prefixIcon: Icon(
                    _loginType == 'email' ? Icons.email : Icons.phone,
                  ),
                  keyboardType: _loginType == 'email' 
                    ? TextInputType.emailAddress 
                    : TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '${_loginType == 'email' ? '이메일' : '전화번호'}를 입력해주세요';
                    }
                    if (_loginType == 'email' && !value.contains('@')) {
                      return '유효한 이메일 주소를 입력해주세요';
                    }
                    if (_loginType == 'phone' && !RegExp(r'^[0-9-+]+$').hasMatch(value)) {
                      return '유효한 전화번호를 입력해주세요';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // 비밀번호 입력
                CustomFormField(
                  label: '비밀번호',
                  controller: _passwordController,
                  hintText: '비밀번호를 입력하세요',
                  prefixIcon: const Icon(Icons.lock),
                  obscureText: obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // 로그인 버튼
                CommonButton(
                  text: '로그인',
                  type: ButtonType.primary,
                  width: double.infinity,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _login,
                ),
                
                const SizedBox(height: 16),
              
              // 개발자 옵션: 자동 로그인 상태 표시 및 활성화
              FutureBuilder<bool>(
                future: _authService.isAutoLoginDisabled,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, 
                            color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '개발 모드: 자동 로그인 비활성화됨',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: _enableAutoLogin,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            ),
                            child: Text(
                              '활성화',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              
              // 비밀번호 찾기
              Center(
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
                
                const SizedBox(height: 40),
                
                // 교회 가입 안내
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '처음 이용하시나요?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '교회 관리자에게 계정 생성을 요청하거나\n초대장을 받아 가입하실 수 있습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _requestAccount,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blue[700]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            '계정 생성 요청',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String username = _usernameController.text.trim();
      
      // 새로운 멤버 API는 이메일/전화번호 모두 지원
      print('🔑 LOGIN: $_loginType 로그인 시도 - username: $username');
      
      // 전화번호인 경우 숫자만 전송 (사용자 테이블의 phone 필드와 매치)
      if (_loginType == 'phone') {
        username = username.replaceAll(RegExp(r'[^0-9]'), ''); // 숫자만 추출
        print('🔑 LOGIN: 전화번호 정규화: $username');
      }
      
      final result = await _authService.login(username, _passwordController.text);

      await _handleLoginSuccess(result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  // 로그인 성공 처리
  Future<void> _handleLoginSuccess(ApiResponse<LoginResponse> result) async {
    if (mounted) {
      if (result.success) {
        print('🔑 LOGIN: 로그인 성공');
        
        // 로그인 성공 후 사용자 정보 가져오기
        final userResponse = await _authService.getCurrentUser();
        if (userResponse.success && userResponse.data != null) {
          final currentUser = userResponse.data!;
          print('🔑 LOGIN: User ID: ${currentUser.id}, is_first: ${currentUser.isFirst}');
          
          // 첫 로그인 처리
          if (currentUser.isFirst) {
            print('🔑 LOGIN: 첫 로그인 사용자 - 비밀번호 변경 다이얼로그 표시');
            _showPasswordChangeDialog();
          } else {
            print('🔑 LOGIN: 기존 사용자 - 홈 화면으로 이동');
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          print('🔑 LOGIN: 사용자 정보 가져오기 실패, 홈으로 이동');
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        String errorMessage = result.message;
        if (errorMessage.isEmpty) {
          errorMessage = '로그인에 실패했습니다. 아이디와 비밀번호를 확인해주세요.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인 실패: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _forgotPassword() async {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('비밀번호 찾기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('등록된 이메일을 입력하시면\n비밀번호 재설정 링크를 전송해드립니다.'),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  hintText: 'your-email@example.com',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('이메일을 입력해주세요')),
                  );
                  return;
                }
                
                if (!email.contains('@')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('유효한 이메일 주소를 입력해주세요')),
                  );
                  return;
                }
                
                setState(() {
                  isLoading = true;
                });
                
                try {
                  // 비밀번호 재설정 API 호출
                  final result = await _authService.requestPasswordReset(email);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result.message),
                        backgroundColor: result.success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      isLoading = false;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('오류가 발생했습니다: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: isLoading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('전송'),
            ),
          ],
        ),
      ),
    );
  }

  void _requestAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 생성 요청'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('교회 관리자에게 계정 생성을 요청합니다.'),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: '전화번호',
                hintText: '010-0000-0000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: '요청 메시지 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('계정 생성 요청이 전송되었습니다')),
              );
            },
            child: const Text('요청'),
          ),
        ],
      ),
    );
  }

  // 개발용: 자동 로그인 활성화
  Future<void> _enableAutoLogin() async {
    try {
      await _authService.setAutoLoginEnabled(true);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('자동 로그인이 활성화되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('설정 변경 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 첫 로그인 시 비밀번호 변경 다이얼로그
  void _showPasswordChangeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 밖 클릭으로 닫기 방지
      builder: (context) => _PasswordChangeDialog(),
    );
  }
}

// 비밀번호 변경 다이얼로그 위젯
class _PasswordChangeDialog extends StatefulWidget {
  @override
  _PasswordChangeDialogState createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Column(
        children: [
          Icon(Icons.lock_reset, size: 40, color: Colors.orange),
          SizedBox(height: 8),
          Text('첫 로그인 - 비밀번호 변경'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '보안상 첫 로그인 시 비밀번호를 변경해주세요.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // 현재 비밀번호
            TextFormField(
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              decoration: InputDecoration(
                labelText: '현재 비밀번호',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '현재 비밀번호를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 새 비밀번호
            TextFormField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: '새 비밀번호',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '새 비밀번호를 입력해주세요';
                }
                if (value.length < 6) {
                  return '비밀번호는 최소 6자 이상이어야 합니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 비밀번호 확인
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: '비밀번호 확인',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호 확인을 입력해주세요';
                }
                if (value != _newPasswordController.text) {
                  return '비밀번호가 일치하지 않습니다';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () {
            // 나중에 변경하기 - 홈으로 이동
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/home');
          },
          child: const Text('나중에'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
          ),
          child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('변경하기'),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        if (result.success) {
          print('🔑 PASSWORD_CHANGE: 비밀번호 변경 성공, is_first 상태 업데이트 시작');
          
          try {
            // UserService를 사용하여 첫 로그인 완료 처리
            final userService = UserService();
            final firstLoginResult = await userService.completeFirstLogin();
            
            if (firstLoginResult.success && firstLoginResult.data != null) {
              final updatedUser = firstLoginResult.data!;
              print('🔑 PASSWORD_CHANGE: is_first 업데이트 성공 - 새 상태: ${updatedUser.isFirst}');
              
              // AuthService에도 업데이트된 사용자 정보 반영
              await _authService.getCurrentUser();
            } else {
              print('⚠️ PASSWORD_CHANGE: is_first 업데이트 실패: ${firstLoginResult.message}');
              // 실패해도 비밀번호 변경은 성공했으므로 계속 진행
            }
          } catch (e) {
            print('⚠️ PASSWORD_CHANGE: is_first 업데이트 예외: $e');
            // 예외가 발생해도 비밀번호 변경은 성공했으므로 계속 진행
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('비밀번호가 성공적으로 변경되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 비밀번호 변경 성공 후 홈으로 이동
          Navigator.pop(context);
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('비밀번호 변경 실패: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
