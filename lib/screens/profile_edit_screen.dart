import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      print('📝 PROFILE_EDIT: 사용자 데이터 로드 시작');
      // 사용자 정보를 DB에서 강제로 새로 가져오기
      final response = await _authService.getCurrentUser(forceRefresh: true);

      print(
          '📝 PROFILE_EDIT: API 응답 - 성공: ${response.success}, 데이터: ${response.data}');

      if (response.success && response.data != null) {
        final userData = response.data!;
        print('📝 PROFILE_EDIT: 사용자 정보 상세:');
        print('  - 이름: ${userData.fullName}');
        print('  - 이메일: ${userData.email}');
        print('  - 전화번호: ${userData.phone}');
        print('  - 주소: ${userData.address}');

        setState(() {
          _currentUser = userData;
          _fullNameController.text = userData.fullName;
          _emailController.text = userData.email;
          _phoneController.text = userData.phone ?? '';
          _addressController.text = userData.address ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          AppToast.show(
            context,
            '사용자 정보를 불러올 수 없습니다: ${response.message}',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      print('❌ PROFILE_EDIT: 데이터 로드 오류: $e');
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
    setState(() {
      _isSaving = true;
    });

    try {
      // 실제 사용자 정보 업데이트 (전화번호, 주소만)
      final response = await _authService.updateUserProfile(
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      );

      if (mounted) {
        if (response.success) {
          print('✅ PROFILE_EDIT: 프로필 업데이트 성공, 화면 새로고침');
          // 업데이트된 정보로 화면 새로고침
          await _loadUserData();

          if (mounted) {
            AppToast.show(
              context,
              '개인정보가 성공적으로 수정되었습니다.',
              type: ToastType.success,
            );
            Navigator.pop(context);
          }
        } else {
          print('❌ PROFILE_EDIT: 프로필 업데이트 실패 - ${response.message}');
          if (mounted) {
            AppToast.show(
              context,
              response.message,
              type: ToastType.error,
            );
          }
        }
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
        backgroundColor: NewAppColor.neutral100,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              LucideIcons.chevronLeft,
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
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              '저장',
              style: const FigmaTextStyles().body1.copyWith(
                    color: _isSaving
                        ? NewAppColor.neutral400
                        : NewAppColor.skyPrimary,
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
                      _buildReadOnlyField(
                        label: '이름',
                        value: _fullNameController.text,
                      ),
                      SizedBox(height: 16.h),
                      _buildReadOnlyField(
                        label: '이메일',
                        value: _emailController.text,
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
