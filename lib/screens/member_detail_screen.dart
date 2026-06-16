import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:io';
import '../components/index.dart' hide IconButton;
import '../models/member.dart';
import '../services/member_service.dart';
import '../constants/member_positions.dart';
import '../widgets/custom_date_picker.dart';
import '../resource/color_style_new.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member;
  final bool isEditable;

  const MemberDetailScreen({
    super.key,
    required this.member,
    this.isEditable = false,
  });

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  final MemberService _memberService = MemberService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  String _selectedGender = '남';
  String _selectedPosition = 'MEMBER';
  String _selectedStatus = 'active';
  String _selectedDistrict = '';
  DateTime? _selectedBirthDate;
  String _selectedBirthdateType = '양력';
  DateTime? _selectedRegistrationDate;

  bool _isEditing = false;
  bool _isSaving = false;
  File? _selectedImage;

  final List<String> _genderOptions = ['남', '여'];
  final List<Map<String, String>> _statusOptions = [
    {'value': 'active', 'label': '활동'},
    {'value': 'inactive', 'label': '비활동'},
    {'value': 'transferred', 'label': '이동'},
  ];
  final List<String> _districtOptions = ['1구역', '2구역', '3구역', '4구역', '5구역'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phone);

    _selectedGender = widget.member.gender;
    _selectedPosition = widget.member.position ?? 'MEMBER';
    _selectedStatus = widget.member.memberStatus;
    _selectedDistrict = widget.member.district ?? '1구역';
    _selectedBirthDate = widget.member.birthdate;
    _selectedBirthdateType = widget.member.birthdateType ?? '양력';
    _selectedRegistrationDate = widget.member.registrationDate;
    _isEditing = widget.isEditable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.member.name,
          style: TextStyle(
            color: NewAppColor.textStrong,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: NewAppColor.textStrong,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, size: 26.sp, color: NewAppColor.textStrong),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!widget.isEditable)
            IconButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      if (_isEditing) {
                        await _saveMemberInfo();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
              icon: _isSaving
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: NewAppColor.skyPrimary,
                      ),
                    )
                  : Icon(
                      _isEditing ? LucideIcons.save : LucideIcons.pencil,
                      color: NewAppColor.textStrong,
                      size: 22.sp,
                    ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: NewAppColor.borderHair),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 사진
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110.w,
                    height: 110.w,
                    decoration: BoxDecoration(
                      color: NewAppColor.borderSoft,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : widget.member.fullProfilePhotoUrl != null
                              ? Image.network(
                                  widget.member.fullProfilePhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    LucideIcons.user,
                                    size: 54.sp,
                                    color: NewAppColor.textTertiary,
                                  ),
                                )
                              : Icon(
                                  LucideIcons.user,
                                  size: 54.sp,
                                  color: NewAppColor.textTertiary,
                                ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _selectProfileImage,
                        child: Container(
                          width: 34.w,
                          height: 34.w,
                          decoration: BoxDecoration(
                            color: NewAppColor.skyPrimary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            LucideIcons.camera,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

            _buildSectionTitle('기본 정보'),
            AppInput(
              label: '이름',
              controller: _nameController,
              disabled: !_isEditing,
              required: true,
            ),
            SizedBox(height: 14.h),
            _buildGenderSelector(),
            SizedBox(height: 14.h),
            _buildBirthdateField(),
            SizedBox(height: 14.h),
            AppInput(
              label: '휴대폰',
              controller: _phoneController,
              disabled: !_isEditing,
              required: true,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 22.h),

            _buildSectionTitle('교회 정보'),
            _buildPositionSelector(),
            SizedBox(height: 14.h),
            _buildStatusSelector(),
            SizedBox(height: 14.h),
            _buildDistrictSelector(),
            SizedBox(height: 14.h),
            _buildRegistrationDateField(),
            SizedBox(height: 22.h),

            _buildSectionTitle('가족 정보'),
            _buildFamilySection(),
            SizedBox(height: 22.h),

            _buildSectionTitle('봉사부서'),
            _buildServiceDepartments(),

            SizedBox(height: 32.h),

            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _saveMemberInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NewAppColor.skyPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          color: NewAppColor.textStrong,
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: NewAppColor.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
          if (required) ...[
            SizedBox(width: 3.w),
            Text(
              '*',
              style: TextStyle(
                color: NewAppColor.danger700,
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('성별'),
        Row(
          children: _genderOptions.map((gender) {
            final selected = _selectedGender == gender;
            return Expanded(
              child: GestureDetector(
                onTap: _isEditing
                    ? () => setState(() => _selectedGender = gender)
                    : null,
                child: Container(
                  margin: EdgeInsets.only(
                    right: gender == _genderOptions.first ? 8.w : 0,
                  ),
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  decoration: BoxDecoration(
                    color: selected ? NewAppColor.skyTint : Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: selected
                          ? NewAppColor.skyPrimary
                          : NewAppColor.borderHair,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      gender,
                      style: TextStyle(
                        color: selected
                            ? NewAppColor.skyDeep
                            : NewAppColor.textSecondary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelector({
    required String label,
    required String displayValue,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              color: disabled ? NewAppColor.canvasAlt : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: NewAppColor.borderHair),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      color: disabled
                          ? NewAppColor.textTertiary
                          : NewAppColor.textStrong,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 18.sp,
                  color: NewAppColor.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionSelector() {
    final List<Map<String, dynamic>> availableOptions =
        List<Map<String, dynamic>>.from(MemberPosition.userOptions);
    final bool isCurrentInOptions = MemberPosition.userOptions
        .any((o) => o['value'] == _selectedPosition);
    if (!isCurrentInOptions) {
      final option = MemberPosition.detailOptions.firstWhere(
        (o) => o['value'] == _selectedPosition,
        orElse: () => {'value': 'MEMBER', 'label': '성도'},
      );
      availableOptions.insert(1, option);
    }
    final currentLabel = (availableOptions.firstWhere(
      (o) => o['value'] == _selectedPosition,
      orElse: () => {'label': '성도'},
    )['label'] as String?) ?? '성도';

    return _buildSelector(
      label: '직분',
      displayValue: currentLabel,
      onTap: _isEditing
          ? () => _showSelectSheet(
                title: '직분 선택',
                items: availableOptions
                    .map((o) => _SelectOption(
                          o['value'] as String,
                          o['label'] as String,
                        ))
                    .toList(),
                selectedValue: _selectedPosition,
                onSelected: (v) => setState(() => _selectedPosition = v),
              )
          : null,
    );
  }

  Widget _buildStatusSelector() {
    final currentLabel = _statusOptions.firstWhere(
      (o) => o['value'] == _selectedStatus,
      orElse: () => {'label': '활동'},
    )['label']!;
    return _buildSelector(
      label: '상태',
      displayValue: currentLabel,
      onTap: _isEditing
          ? () => _showSelectSheet(
                title: '상태 선택',
                items: _statusOptions
                    .map((o) => _SelectOption(o['value']!, o['label']!))
                    .toList(),
                selectedValue: _selectedStatus,
                onSelected: (v) => setState(() => _selectedStatus = v),
              )
          : null,
    );
  }

  Widget _buildDistrictSelector() {
    return _buildSelector(
      label: '구역',
      displayValue: _selectedDistrict,
      onTap: _isEditing
          ? () => _showSelectSheet(
                title: '구역 선택',
                items: _districtOptions
                    .map((d) => _SelectOption(d, d))
                    .toList(),
                selectedValue: _selectedDistrict,
                onSelected: (v) => setState(() => _selectedDistrict = v),
              )
          : null,
    );
  }

  Widget _buildBirthdateField() {
    final dateText = _selectedBirthDate != null
        ? '${_selectedBirthDate!.year}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')} ($_selectedBirthdateType)'
        : '선택';
    return _buildSelector(
      label: '생년월일',
      displayValue: dateText,
      onTap: _isEditing ? _selectBirthDate : null,
    );
  }

  Widget _buildRegistrationDateField() {
    final dateText = _selectedRegistrationDate != null
        ? '${_selectedRegistrationDate!.year}-${_selectedRegistrationDate!.month.toString().padLeft(2, '0')}-${_selectedRegistrationDate!.day.toString().padLeft(2, '0')}'
        : '선택';
    return _buildSelector(
      label: '등록일',
      displayValue: dateText,
      onTap: _isEditing ? _selectRegistrationDate : null,
    );
  }

  Widget _buildFamilySection() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '가족 구성원',
                style: TextStyle(
                  color: NewAppColor.textStrong,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
              if (_isEditing)
                GestureDetector(
                  onTap: _addFamilyMember,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: NewAppColor.skyTint,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      LucideIcons.plus,
                      size: 16.sp,
                      color: NewAppColor.skyPrimary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          _buildFamilyRow('김아버지', '부 · 장로'),
          _buildFamilyRow('김어머니', '모 · 권사'),
        ],
      ),
    );
  }

  Widget _buildFamilyRow(String name, String role) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: NewAppColor.borderSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.user,
              size: 18.sp,
              color: NewAppColor.textTertiary,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  role,
                  style: TextStyle(
                    color: NewAppColor.textMuted,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),
          if (_isEditing)
            Icon(
              LucideIcons.pencil,
              size: 16.sp,
              color: NewAppColor.textTertiary,
            ),
        ],
      ),
    );
  }

  Widget _buildServiceDepartments() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '봉사부서',
                style: TextStyle(
                  color: NewAppColor.textStrong,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
              if (_isEditing)
                GestureDetector(
                  onTap: _addServiceDepartment,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: NewAppColor.skyTint,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      LucideIcons.plus,
                      size: 16.sp,
                      color: NewAppColor.skyPrimary,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: ['찬양팀', '교육부'].map((dept) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: NewAppColor.skyTint,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  dept,
                  style: TextStyle(
                    color: NewAppColor.skyDeep,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showSelectSheet({
    required String title,
    required List<_SelectOption> items,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF0F172A).withOpacity(0.45),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: NewAppColor.borderStrong,
                  borderRadius: BorderRadius.circular(999.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                title,
                style: TextStyle(
                  color: NewAppColor.textStrong,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                ),
              ),
              SizedBox(height: 14.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 0.5.sh),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Container(
                    height: 1,
                    color: NewAppColor.borderHair,
                  ),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    final selected = item.value == selectedValue;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onSelected(item.value);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: selected
                                      ? NewAppColor.skyDeep
                                      : NewAppColor.textStrong,
                                  fontSize: 15.sp,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                            ),
                            if (selected)
                              Icon(
                                LucideIcons.check,
                                size: 18.sp,
                                color: NewAppColor.skyPrimary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectProfileImage() {
    AppMenuSheet.show(
      context: context,
      items: [
        AppMenuItem(
          icon: LucideIcons.image,
          label: '갤러리에서 선택',
          onTap: () async {
            final XFile? image =
                await _picker.pickImage(source: ImageSource.gallery);
            if (image != null && mounted) {
              setState(() => _selectedImage = File(image.path));
            }
          },
        ),
        AppMenuItem(
          icon: LucideIcons.camera,
          label: '카메라로 촬영',
          onTap: () async {
            final XFile? image =
                await _picker.pickImage(source: ImageSource.camera);
            if (image != null && mounted) {
              setState(() => _selectedImage = File(image.path));
            }
          },
        ),
        if (widget.member.profilePhotoUrl != null)
          AppMenuItem(
            icon: LucideIcons.trash2,
            label: '프로필 사진 삭제',
            danger: true,
            onTap: () {
              setState(() => _selectedImage = null);
            },
          ),
      ],
    );
  }

  void _selectBirthDate() async {
    final date = await showCustomDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedBirthDate = date);
  }

  void _selectRegistrationDate() async {
    final date = await showCustomDatePicker(
      context: context,
      initialDate: _selectedRegistrationDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _selectedRegistrationDate = date);
  }

  void _addFamilyMember() {
    AppToast.show(context, '가족 구성원 추가 기능은 추후 구현 예정입니다');
  }

  void _addServiceDepartment() {
    AppToast.show(context, '봉사부서 추가 기능은 추후 구현 예정입니다');
  }

  Future<void> _saveMemberInfo() async {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      AppToast.show(context, '이름과 전화번호는 필수 입력 항목입니다');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final request = MemberUpdateRequest(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        position: _selectedPosition,
        district: _selectedDistrict,
        memberStatus: _selectedStatus,
      );

      final response =
          await _memberService.updateMember(widget.member.id, request.toJson());

      if (response.success && mounted) {
        AppToast.show(context, '교인 정보가 수정되었습니다');
        setState(() => _isEditing = false);
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, '수정 실패: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _SelectOption {
  final String value;
  final String label;
  const _SelectOption(this.value, this.label);
}
