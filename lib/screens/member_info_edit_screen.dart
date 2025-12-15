import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/index.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../services/member_service.dart';
import '../services/auth_service.dart';
import '../models/member.dart';
import '../utils/location_data.dart';
import '../widgets/custom_date_picker.dart';

class MemberInfoEditScreen extends StatefulWidget {
  const MemberInfoEditScreen({super.key});

  @override
  State<MemberInfoEditScreen> createState() => _MemberInfoEditScreenState();
}

class _MemberInfoEditScreenState extends State<MemberInfoEditScreen> {
  final MemberService _memberService = MemberService();
  final AuthService _authService = AuthService();

  Member? _currentMember;
  bool _isLoading = true;
  bool _isSaving = false;

  // 기본 정보
  final TextEditingController _nameEngController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthdate;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // 교회 정보 확장
  String? _selectedMemberType;
  DateTime? _selectedConfirmationDate;
  DateTime? _selectedBaptismDate;
  final TextEditingController _baptismChurchController = TextEditingController();
  String? _selectedAgeGroup;
  String? _selectedSpiritualGrade;

  // 개인 및 가족 정보
  String? _selectedMaritalStatus;
  final TextEditingController _spouseNameController = TextEditingController();
  DateTime? _selectedMarriedOn;

  // 주소 정보
  final TextEditingController _postalCodeController = TextEditingController();
  String? _selectedRegion1; // 시/도
  String? _selectedRegion2; // 구/군
  String? _selectedRegion3; // 동/읍/면

  // 직업 정보
  String? _selectedJobCategory;
  final TextEditingController _jobDetailController = TextEditingController();
  final TextEditingController _jobPositionController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _workplaceController = TextEditingController();
  final TextEditingController _workplacePhoneController = TextEditingController();

  // 특별 사항
  final TextEditingController _specialNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  @override
  void dispose() {
    _nameEngController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _baptismChurchController.dispose();
    _spouseNameController.dispose();
    _postalCodeController.dispose();
    _jobDetailController.dispose();
    _jobPositionController.dispose();
    _jobTitleController.dispose();
    _workplaceController.dispose();
    _workplacePhoneController.dispose();
    _specialNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberData() async {
    try {
      print('📝 MEMBER_INFO_EDIT: 교인 데이터 로드 시작');

      // 현재 사용자 정보 가져오기
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        if (mounted) {
          AppToast.show(
            context,
            '사용자 정보를 불러올 수 없습니다',
            type: ToastType.error,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // user_id로 교인 정보 조회
      final memberResponse = await _memberService.getMemberByUserId(userResponse.data!.id);
      if (!memberResponse.success || memberResponse.data == null) {
        if (mounted) {
          AppToast.show(
            context,
            '교인 정보를 불러올 수 없습니다',
            type: ToastType.error,
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final member = memberResponse.data!;

      setState(() {
        _currentMember = member;

        // 기본 정보
        _nameEngController.text = member.nameEng ?? '';
        // gender가 빈 문자열이면 null로 처리 (드롭다운 오류 방지)
        _selectedGender = (member.gender.isEmpty) ? null : member.gender;
        _selectedBirthdate = member.birthdate;
        _phoneController.text = member.phone;
        _addressController.text = member.address ?? '';

        // 교회 정보 확장
        _selectedMemberType = member.memberType;
        _selectedConfirmationDate = member.confirmationDate;
        _selectedBaptismDate = member.baptismDate;
        _baptismChurchController.text = member.baptismChurch ?? '';
        _selectedAgeGroup = member.ageGroup;
        _selectedSpiritualGrade = member.spiritualGrade;

        // 개인 및 가족 정보
        _selectedMaritalStatus = member.maritalStatus;
        _spouseNameController.text = member.spouseName ?? '';
        _selectedMarriedOn = member.marriedOn;

        // 주소 정보
        _postalCodeController.text = member.postalCode ?? '';
        _selectedRegion1 = member.region1;
        _selectedRegion2 = member.region2;
        _selectedRegion3 = member.region3;

        // 직업 정보
        _selectedJobCategory = member.jobCategory;
        _jobDetailController.text = member.jobDetail ?? '';
        _jobPositionController.text = member.jobPosition ?? '';
        _jobTitleController.text = member.jobTitle ?? '';
        _workplaceController.text = member.workplace ?? '';
        _workplacePhoneController.text = member.workplacePhone ?? '';

        // 특별 사항
        _specialNotesController.text = member.specialNotes ?? '';

        _isLoading = false;
      });

      print('✅ MEMBER_INFO_EDIT: 교인 데이터 로드 완료');
    } catch (e) {
      print('❌ MEMBER_INFO_EDIT: 데이터 로드 오류: $e');
      if (mounted) {
        AppToast.show(
          context,
          '데이터를 불러오는데 실패했습니다: $e',
          type: ToastType.error,
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveMemberInfo() async {
    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> updateData = {};

      // 기본 정보
      if (_nameEngController.text.isNotEmpty) {
        updateData['name_eng'] = _nameEngController.text.trim();
      }
      if (_selectedGender != null) updateData['gender'] = _selectedGender;
      if (_selectedBirthdate != null) {
        updateData['birthdate'] = _selectedBirthdate!.toIso8601String().split('T')[0];
      }
      updateData['phone'] = _phoneController.text.trim();
      if (_addressController.text.isNotEmpty) {
        updateData['address'] = _addressController.text.trim();
      }

      // 교회 정보 확장
      if (_selectedMemberType != null) updateData['member_type'] = _selectedMemberType;
      if (_selectedConfirmationDate != null) {
        updateData['confirmation_date'] = _selectedConfirmationDate!.toIso8601String().split('T')[0];
      }
      if (_selectedBaptismDate != null) {
        updateData['baptism_date'] = _selectedBaptismDate!.toIso8601String().split('T')[0];
      }
      if (_baptismChurchController.text.isNotEmpty) {
        updateData['baptism_church'] = _baptismChurchController.text.trim();
      }
      if (_selectedAgeGroup != null) updateData['age_group'] = _selectedAgeGroup;
      if (_selectedSpiritualGrade != null) updateData['spiritual_grade'] = _selectedSpiritualGrade;

      // 개인 및 가족 정보
      if (_selectedMaritalStatus != null) updateData['marital_status'] = _selectedMaritalStatus;
      if (_spouseNameController.text.isNotEmpty) {
        updateData['spouse_name'] = _spouseNameController.text.trim();
      }
      if (_selectedMarriedOn != null) {
        updateData['married_on'] = _selectedMarriedOn!.toIso8601String().split('T')[0];
      }

      // 주소 정보
      if (_postalCodeController.text.isNotEmpty) {
        updateData['postal_code'] = _postalCodeController.text.trim();
      }
      if (_selectedRegion1 != null) updateData['region_1'] = _selectedRegion1;
      if (_selectedRegion2 != null) updateData['region_2'] = _selectedRegion2;
      if (_selectedRegion3 != null) updateData['region_3'] = _selectedRegion3;

      // 직업 정보
      if (_selectedJobCategory != null) updateData['job_category'] = _selectedJobCategory;
      if (_jobDetailController.text.isNotEmpty) {
        updateData['job_detail'] = _jobDetailController.text.trim();
      }
      if (_jobPositionController.text.isNotEmpty) {
        updateData['job_position'] = _jobPositionController.text.trim();
      }
      if (_jobTitleController.text.isNotEmpty) {
        updateData['job_title'] = _jobTitleController.text.trim();
      }
      if (_workplaceController.text.isNotEmpty) {
        updateData['workplace'] = _workplaceController.text.trim();
      }
      if (_workplacePhoneController.text.isNotEmpty) {
        updateData['workplace_phone'] = _workplacePhoneController.text.trim();
      }

      // 특별 사항
      if (_specialNotesController.text.isNotEmpty) {
        updateData['special_notes'] = _specialNotesController.text.trim();
      }

      final response = await _memberService.updateMyMemberInfo(updateData);

      if (mounted) {
        if (response.success) {
          AppToast.show(
            context,
            '개인정보가 성공적으로 수정되었습니다',
            type: ToastType.success,
          );
          Navigator.pop(context);
        } else {
          AppToast.show(
            context,
            response.message,
            type: ToastType.error,
          );
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
        setState(() => _isSaving = false);
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
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveMemberInfo,
            child: Text(
              '저장',
              style: const FigmaTextStyles().body1.copyWith(
                    color: _isSaving
                        ? NewAppColor.neutral400
                        : NewAppColor.primary600,
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
                  // 안내 문구
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: NewAppColor.primary100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16.sp,
                              color: NewAppColor.primary600,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '수정 불가 항목',
                              style: const FigmaTextStyles().body2.copyWith(
                                    color: NewAppColor.primary600,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '이름, 이메일, 직분은 수정할 수 없습니다.\n수정이 필요한 경우 교회 관리자에게 문의하세요.',
                          style: const FigmaTextStyles().caption1.copyWith(
                                color: NewAppColor.primary600,
                              ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // 수정 불가 필드 표시
                  _buildSection(
                    title: '기본 정보 (수정 불가)',
                    children: [
                      _buildReadOnlyField(
                        label: '이름',
                        value: _currentMember?.name ?? '',
                      ),
                      SizedBox(height: 16.h),
                      _buildReadOnlyField(
                        label: '이메일',
                        value: _currentMember?.email ?? '',
                      ),
                      SizedBox(height: 16.h),
                      _buildReadOnlyField(
                        label: '직분',
                        value: _currentMember?.positionLabel ?? '성도',
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // 기본 정보 (수정 가능)
                  _buildSection(
                    title: '기본 정보',
                    children: [
                      _buildInputField(
                        label: '영문명',
                        controller: _nameEngController,
                        placeholder: '영문명을 입력하세요',
                      ),
                      SizedBox(height: 16.h),
                      _buildDropdownField(
                        label: '성별',
                        value: _selectedGender,
                        items: const ['남', '여'],
                        onChanged: (value) => setState(() => _selectedGender = value),
                      ),
                      SizedBox(height: 16.h),
                      _buildDateField(
                        label: '생년월일',
                        date: _selectedBirthdate,
                        onTap: () => _selectDate(
                          context,
                          _selectedBirthdate,
                          (date) => setState(() => _selectedBirthdate = date),
                        ),
                      ),
                      SizedBox(height: 16.h),
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

                  SizedBox(height: 24.h),

                  // 교회 정보 확장
                  _buildSection(
                    title: '교회 정보',
                    children: [
                      _buildDropdownField(
                        label: '교인구분',
                        value: _selectedMemberType,
                        items: const ['정교인', '학습교인', '세례교인', '방문자'],
                        onChanged: (value) => setState(() => _selectedMemberType = value),
                      ),
                      SizedBox(height: 16.h),
                      _buildDateField(
                        label: '입교일',
                        date: _selectedConfirmationDate,
                        onTap: () => _selectDate(
                          context,
                          _selectedConfirmationDate,
                          (date) => setState(() => _selectedConfirmationDate = date),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildDateField(
                        label: '세례일',
                        date: _selectedBaptismDate,
                        onTap: () => _selectDate(
                          context,
                          _selectedBaptismDate,
                          (date) => setState(() => _selectedBaptismDate = date),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        label: '세례교회',
                        controller: _baptismChurchController,
                        placeholder: '세례받은 교회를 입력하세요',
                      ),
                      SizedBox(height: 16.h),
                      _buildDropdownField(
                        label: '나이그룹',
                        value: _selectedAgeGroup,
                        items: const ['어린이', '학생', '청년', '성인', '시니어'],
                        onChanged: (value) => setState(() => _selectedAgeGroup = value),
                      ),
                      SizedBox(height: 16.h),
                      _buildDropdownField(
                        label: '신급',
                        value: _selectedSpiritualGrade,
                        items: const ['초신자', 'B급', 'A급', '리더'],
                        onChanged: (value) => setState(() => _selectedSpiritualGrade = value),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // 개인 및 가족 정보
                  _buildSection(
                    title: '개인 및 가족 정보',
                    children: [
                      _buildDropdownField(
                        label: '결혼 상태',
                        value: _selectedMaritalStatus,
                        items: const ['미혼', '기혼', '이혼', '사별'],
                        onChanged: (value) => setState(() => _selectedMaritalStatus = value),
                      ),
                      if (_selectedMaritalStatus == '기혼') ...[
                        SizedBox(height: 16.h),
                        _buildInputField(
                          label: '배우자 이름',
                          controller: _spouseNameController,
                          placeholder: '배우자 이름을 입력하세요',
                        ),
                        SizedBox(height: 16.h),
                        _buildDateField(
                          label: '결혼일',
                          date: _selectedMarriedOn,
                          onTap: () => _selectDate(
                            context,
                            _selectedMarriedOn,
                            (date) => setState(() => _selectedMarriedOn = date),
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // 주소 정보
                  _buildSection(
                    title: '주소 정보',
                    children: [
                      _buildInputField(
                        label: '우편번호',
                        controller: _postalCodeController,
                        placeholder: '우편번호를 입력하세요',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16.h),
                      _buildDropdownField(
                        label: '시/도',
                        value: _selectedRegion1,
                        items: LocationData.getCities(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRegion1 = value;
                            _selectedRegion2 = null;
                            _selectedRegion3 = null;
                          });
                        },
                      ),
                      if (_selectedRegion1 != null) ...[
                        SizedBox(height: 16.h),
                        _buildDropdownField(
                          label: '구/군',
                          value: _selectedRegion2,
                          items: LocationData.getDistricts(_selectedRegion1!),
                          onChanged: (value) {
                            setState(() {
                              _selectedRegion2 = value;
                              _selectedRegion3 = null;
                            });
                          },
                        ),
                      ],
                      if (_selectedRegion2 != null) ...[
                        SizedBox(height: 16.h),
                        _buildInputField(
                          label: '동/읍/면',
                          controller: TextEditingController(text: _selectedRegion3 ?? ''),
                          placeholder: '동/읍/면을 입력하세요',
                          onChanged: (value) => _selectedRegion3 = value,
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // 직업 정보
                  _buildSection(
                    title: '직업 정보',
                    children: [
                      _buildDropdownField(
                        label: '직업분류',
                        value: _selectedJobCategory,
                        items: const ['사무직', '교육직', '의료진', '서비스업', '자영업', '학생', '주부', '기타'],
                        onChanged: (value) => setState(() => _selectedJobCategory = value),
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        label: '구체적 업무',
                        controller: _jobDetailController,
                        placeholder: '구체적인 업무를 입력하세요',
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        label: '직책/직위',
                        controller: _jobPositionController,
                        placeholder: '직책/직위를 입력하세요',
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        label: '직업명',
                        controller: _jobTitleController,
                        placeholder: '직업명을 입력하세요',
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        label: '직장명',
                        controller: _workplaceController,
                        placeholder: '직장명을 입력하세요',
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        label: '직장 전화번호',
                        controller: _workplacePhoneController,
                        placeholder: '직장 전화번호를 입력하세요',
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // 특별 사항
                  _buildSection(
                    title: '특별 사항',
                    children: [
                      _buildInputField(
                        label: '개인 특별사항',
                        controller: _specialNotesController,
                        placeholder: '특별히 알려드릴 사항이 있으면 입력하세요',
                        maxLines: 3,
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
    void Function(String)? onChanged,
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
          onChanged: onChanged,
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: NewAppColor.neutral100,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: NewAppColor.neutral200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                '$label을 선택하세요',
                style: const FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral400,
                    ),
              ),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const FigmaTextStyles().body1.copyWith(
                          color: NewAppColor.neutral900,
                        ),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: NewAppColor.neutral100,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: NewAppColor.neutral200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                      : '$label을 선택하세요',
                  style: const FigmaTextStyles().body1.copyWith(
                        color: date != null
                            ? NewAppColor.neutral900
                            : NewAppColor.neutral400,
                      ),
                ),
                Icon(
                  Icons.calendar_today,
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

  Future<void> _selectDate(
    BuildContext context,
    DateTime? initialDate,
    void Function(DateTime) onDateSelected,
  ) async {
    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }
}
