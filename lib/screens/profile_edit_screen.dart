import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../components/index.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  User? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        setState(() {
          _currentUser = user;
          _fullNameController.text = user.fullName;
          _emailController.text = user.email;
          // 전화번호와 주소는 User 모델에 없으므로 임시로 빈 값
          _phoneController.text = '';
          _addressController.text = '';
          _isLoading = false;
        });
      } else {
        // 사용자 정보를 다시 가져오기
        final response = await _authService.getCurrentUser();
        if (response.success && response.data != null) {
          setState(() {
            _currentUser = response.data;
            _fullNameController.text = response.data!.fullName;
            _emailController.text = response.data!.email;
            _phoneController.text = '';
            _addressController.text = '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        AppToast.show(
          context,
          '사용자 정보를 불러오는데 실패했습니다: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_fullNameController.text.trim().isEmpty) {
      AppToast.show(
        context,
        '이름을 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      AppToast.show(
        context,
        '이메일을 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: 실제 API 엔드포인트가 있다면 여기서 사용자 정보 업데이트
      // 현재는 시뮬레이션
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        AppToast.show(
          context,
          '개인정보가 성공적으로 수정되었습니다.',
          type: ToastType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '개인정보 수정에 실패했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              Icons.arrow_back_ios,
              color: NewAppColor.neutral900,
              size: 20.sp,
            ),
          ),
        ),
        title: Text(
          '개인정보 수정',
          style: const FigmaTextStyles().title2.copyWith(
            color: NewAppColor.neutral900,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              '저장',
              style: const FigmaTextStyles().body1.copyWith(
                color: _isSaving ? NewAppColor.neutral400 : NewAppColor.primary600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 섹션
                  _buildSection(
                    title: '기본 정보',
                    children: [
                      _buildInputField(
                        label: '이름',
                        controller: _fullNameController,
                        placeholder: '이름을 입력하세요',
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        label: '이메일',
                        controller: _emailController,
                        placeholder: '이메일을 입력하세요',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 16.h),
                      _buildReadOnlyField(
                        label: '사용자명',
                        value: _currentUser?.username ?? '',
                      ),
                    ],
                  ),

                  SizedBox(height: 32.h),

                  // 연락처 정보 섹션
                  _buildSection(
                    title: '연락처 정보',
                    children: [
                      _buildInputField(
                        label: '전화번호',
                        controller: _phoneController,
                        placeholder: '전화번호를 입력하세요',
                        keyboardType: TextInputType.phone,
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        label: '주소',
                        controller: _addressController,
                        placeholder: '주소를 입력하세요',
                        maxLines: 2,
                      ),
                    ],
                  ),

                  SizedBox(height: 32.h),

                  // 계정 정보 섹션
                  _buildSection(
                    title: '계정 정보',
                    children: [
                      _buildReadOnlyField(
                        label: '권한',
                        value: _getRoleDisplayName(_currentUser?.role ?? ''),
                      ),
                      SizedBox(height: 16.h),
                      _buildReadOnlyField(
                        label: '가입일',
                        value: _currentUser?.createdAt != null
                            ? '${_currentUser!.createdAt!.year}-${_currentUser!.createdAt!.month.toString().padLeft(2, '0')}-${_currentUser!.createdAt!.day.toString().padLeft(2, '0')}'
                            : '정보 없음',
                      ),
                    ],
                  ),

                  SizedBox(height: 40.h),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 20.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const FigmaTextStyles().body1.copyWith(
            color: NewAppColor.neutral900,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        AppInput(
          controller: controller,
          placeholder: placeholder,
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const FigmaTextStyles().body1.copyWith(
            color: NewAppColor.neutral900,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: NewAppColor.neutral100,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: NewAppColor.neutral200),
          ),
          child: Text(
            value,
            style: const FigmaTextStyles().body1.copyWith(
              color: NewAppColor.neutral600,
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return '관리자';
      case 'pastor':
        return '목사';
      case 'member':
        return '성도';
      default:
        return role;
    }
  }
}