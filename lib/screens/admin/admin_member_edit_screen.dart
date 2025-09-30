import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/index.dart';
import '../../models/member.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/member_service.dart';
import '../../services/auth_service.dart';

/// 관리자용 교인 추가/수정 화면
class AdminMemberEditScreen extends StatefulWidget {
  final Member? member; // null이면 추가, 값이 있으면 수정

  const AdminMemberEditScreen({
    super.key,
    this.member,
  });

  @override
  State<AdminMemberEditScreen> createState() => _AdminMemberEditScreenState();
}

class _AdminMemberEditScreenState extends State<AdminMemberEditScreen> {
  final MemberService _memberService = MemberService();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _districtController;
  late TextEditingController _positionController;

  String _selectedGender = '남';
  String _selectedStatus = 'active';
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  String? _nameError;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _phoneController = TextEditingController(text: widget.member?.phone ?? '');
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _addressController =
        TextEditingController(text: widget.member?.address ?? '');
    _districtController =
        TextEditingController(text: widget.member?.district ?? '');
    _positionController =
        TextEditingController(text: widget.member?.position ?? '');

    if (widget.member != null) {
      _selectedGender = _normalizeGender(widget.member!.gender);
      _selectedStatus = widget.member!.memberStatus;
      _selectedBirthDate = widget.member!.birthdate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.member != null;

  String _normalizeGender(String gender) {
    if (gender.isEmpty) return '남';

    // 다양한 형식의 gender 값을 '남' 또는 '여'로 정규화
    switch (gender) {
      case '남':
      case '남자':
      case '남성':
      case 'M':
      case 'male':
      case 'MALE':
        return '남';
      case '여':
      case '여자':
      case '여성':
      case 'F':
      case 'female':
      case 'FEMALE':
        return '여';
      default:
        return '남'; // 기본값
    }
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _phoneError = null;
    });

    bool isValid = true;

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = '이름을 입력해주세요';
      });
      isValid = false;
    }

    if (_phoneController.text.trim().isEmpty) {
      setState(() {
        _phoneError = '전화번호를 입력해주세요';
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _saveMember() async {
    if (!_validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        if (mounted) {
          AppToast.show(
            context,
            '사용자 정보를 가져올 수 없습니다',
            type: ToastType.error,
          );
        }
        return;
      }

      final user = userResponse.data!;

      final memberData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'district': _districtController.text.trim().isEmpty
            ? null
            : _districtController.text.trim(),
        'position': _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
        'gender': _selectedGender,
        'member_status': _selectedStatus,
        'birthdate': _selectedBirthDate?.toIso8601String().split('T')[0],
        if (!_isEditMode) 'church_id': user.churchId,
      };

      if (_isEditMode) {
        // 수정
        final response = await _memberService.updateMember(
          widget.member!.id,
          memberData,
        );

        if (response.success) {
          if (mounted) {
            AppToast.show(
              context,
              '교인 정보가 수정되었습니다',
              type: ToastType.success,
            );
            Navigator.pop(context, true); // 성공 시 true 반환
          }
        } else {
          if (mounted) {
            AppToast.show(
              context,
              response.message.isNotEmpty
                  ? response.message
                  : '교인 정보 수정에 실패했습니다',
              type: ToastType.error,
            );
          }
        }
      } else {
        // 추가
        final response = await _memberService.createMember(memberData);

        if (response.success) {
          if (mounted) {
            AppToast.show(
              context,
              '교인이 추가되었습니다',
              type: ToastType.success,
            );
            Navigator.pop(context, true); // 성공 시 true 반환
          }
        } else {
          if (mounted) {
            AppToast.show(
              context,
              response.message.isNotEmpty
                  ? response.message
                  : '교인 추가에 실패했습니다',
              type: ToastType.error,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: material.IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? '교인 정보 수정' : '교인 추가',
          style: const FigmaTextStyles().title2.copyWith(
            color: NewAppColor.neutral900,
          ),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            material.IconButton(
              icon: const Icon(Icons.check, color: Colors.black),
              onPressed: _saveMember,
            ),
        ],
      ),
      body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),
              // 기본 정보 섹션
              _buildSection(
                title: '기본 정보',
                children: [
                  AppInput(
                    controller: _nameController,
                    label: '이름',
                    placeholder: '이름을 입력하세요',
                    required: true,
                    errorText: _nameError,
                  ),
                  SizedBox(height: 16.h),
                  AppInput(
                    controller: _phoneController,
                    label: '전화번호',
                    placeholder: '010-0000-0000',
                    keyboardType: TextInputType.phone,
                    required: true,
                    errorText: _phoneError,
                  ),
                  SizedBox(height: 16.h),
                  AppInput(
                    controller: _emailController,
                    label: '이메일 (선택)',
                    placeholder: 'email@example.com',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 16.h),
                  // 성별 선택
                  _buildGenderSelector(),
                  SizedBox(height: 16.h),
                  // 생년월일 선택
                  _buildBirthDateSelector(),
                ],
              ),
              SizedBox(height: 16.h),
              // 교회 정보 섹션
              _buildSection(
                title: '교회 정보',
                children: [
                  AppInput(
                    controller: _districtController,
                    label: '구역 (선택)',
                    placeholder: '예: 1구역',
                  ),
                  SizedBox(height: 16.h),
                  AppInput(
                    controller: _positionController,
                    label: '직분 (선택)',
                    placeholder: '예: 집사, 권사, 장로',
                  ),
                  SizedBox(height: 16.h),
                  // 상태 선택
                  _buildStatusSelector(),
                ],
              ),
              SizedBox(height: 16.h),
              // 추가 정보 섹션
              _buildSection(
                title: '추가 정보',
                children: [
                  AppInput(
                    controller: _addressController,
                    label: '주소 (선택)',
                    placeholder: '주소를 입력하세요',
                    maxLines: 2,
                  ),
                ],
              ),
              SizedBox(height: 32.h),
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
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '성별',
          style: const FigmaTextStyles().body2.copyWith(
            color: NewAppColor.neutral700,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption('남', '남성'),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildGenderOption('여', '여성'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String value, String label) {
    final isSelected = _selectedGender == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.primary100 : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBirthDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '생년월일 (선택)',
          style: const FigmaTextStyles().body2.copyWith(
            color: NewAppColor.neutral700,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _selectBirthDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: NewAppColor.neutral300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20.sp,
                  color: NewAppColor.neutral600,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    _selectedBirthDate != null
                        ? '${_selectedBirthDate!.year}.${_selectedBirthDate!.month.toString().padLeft(2, '0')}.${_selectedBirthDate!.day.toString().padLeft(2, '0')}'
                        : '생년월일을 선택하세요',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _selectedBirthDate != null
                          ? NewAppColor.neutral900
                          : NewAppColor.neutral500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: NewAppColor.neutral400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '상태',
          style: const FigmaTextStyles().body2.copyWith(
            color: NewAppColor.neutral700,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildStatusOption('active', '활성'),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatusOption('inactive', '비활성'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOption(String value, String label) {
    final isSelected = _selectedStatus == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = value),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? NewAppColor.primary100 : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? NewAppColor.primary600 : NewAppColor.neutral700,
            ),
          ),
        ),
      ),
    );
  }
}