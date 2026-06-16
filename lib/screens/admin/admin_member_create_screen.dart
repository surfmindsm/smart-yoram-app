import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/index.dart';
import '../../models/member.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/member_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_date_picker.dart';

/// 관리자용 교인 추가 화면
class AdminMemberCreateScreen extends StatefulWidget {
  const AdminMemberCreateScreen({super.key});

  @override
  State<AdminMemberCreateScreen> createState() =>
      _AdminMemberCreateScreenState();
}

class _AdminMemberCreateScreenState extends State<AdminMemberCreateScreen> {
  final MemberService _memberService = MemberService();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // 텍스트 컨트롤러 - 기본 정보
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nameEngController = TextEditingController();
  final TextEditingController _spouseNameController = TextEditingController();

  // 텍스트 컨트롤러 - 연락처 정보
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _region1Controller = TextEditingController();
  final TextEditingController _region2Controller = TextEditingController();
  final TextEditingController _region3Controller = TextEditingController();

  // 텍스트 컨트롤러 - 직업 정보
  final TextEditingController _jobCategoryController = TextEditingController();
  final TextEditingController _jobDetailController = TextEditingController();
  final TextEditingController _jobPositionController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _workplaceController = TextEditingController();
  final TextEditingController _workplacePhoneController = TextEditingController();

  // 텍스트 컨트롤러 - 사역 정보
  final TextEditingController _ordinationChurchController = TextEditingController();
  final TextEditingController _neighboringChurchController = TextEditingController();
  final TextEditingController _positionDecisionController = TextEditingController();
  final TextEditingController _dailyActivityController = TextEditingController();

  // 텍스트 컨트롤러 - 신앙 정보
  final TextEditingController _baptismChurchController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  // 텍스트 컨트롤러 - 커스텀 필드
  final TextEditingController _customField1Controller = TextEditingController();
  final TextEditingController _customField2Controller = TextEditingController();
  final TextEditingController _customField3Controller = TextEditingController();
  final TextEditingController _customField4Controller = TextEditingController();
  final TextEditingController _customField5Controller = TextEditingController();
  final TextEditingController _customField6Controller = TextEditingController();
  final TextEditingController _customField7Controller = TextEditingController();
  final TextEditingController _customField8Controller = TextEditingController();
  final TextEditingController _customField9Controller = TextEditingController();
  final TextEditingController _customField10Controller = TextEditingController();
  final TextEditingController _customField11Controller = TextEditingController();
  final TextEditingController _customField12Controller = TextEditingController();

  // 텍스트 컨트롤러 - 추가 정보
  final TextEditingController _specialNotesController = TextEditingController();

  // 선택 필드 - 기본 정보
  String _selectedGender = 'male';
  String? _selectedBirthdateType = 'solar';
  String? _selectedMaritalStatus;
  DateTime? _selectedBirthdate;
  DateTime? _selectedMarriedOn;

  // 선택 필드 - 사역 정보
  String? _selectedPositionMain;
  String? _selectedPositionDetail;
  String? _selectedOrganizationId;
  DateTime? _selectedAppointedOn;
  DateTime? _selectedMinistryStartDate;
  int? _selectedInviter3MemberId;

  // 조직 목록
  List<Map<String, dynamic>> _organizations = [];

  // 자녀 정보
  List<Map<String, dynamic>> _children = [];

  // 선택 필드 - 신앙 정보
  String? _selectedMemberType;
  String? _selectedAgeGroup;
  String? _selectedSpiritualGrade;
  DateTime? _selectedConfirmationDate;
  DateTime? _selectedBaptismDate;
  DateTime? _selectedLastContactDate;
  DateTime? _selectedRegistrationDate;

  // 선택 필드 - 직업 정보
  String? _selectedJobCategory;

  // 선택 필드 - 추가 정보 (레거시)
  String? _selectedPosition;
  String? _selectedDepartment;
  String _selectedStatus = 'active';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  Future<void> _loadOrganizations() async {
    try {
      final supabaseService = SupabaseService();
      final response = await supabaseService.client
          .from('church_organizations')
          .select('id, name, parent_id')
          .order('name');

      if (response != null) {
        setState(() {
          _organizations = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      print('조직 목록 조회 실패: $e');
    }
  }

  @override
  void dispose() {
    // 기본 정보
    _nameController.dispose();
    _nameEngController.dispose();
    _spouseNameController.dispose();

    // 연락처 정보
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _region1Controller.dispose();
    _region2Controller.dispose();
    _region3Controller.dispose();

    // 직업 정보
    _jobCategoryController.dispose();
    _jobDetailController.dispose();
    _jobPositionController.dispose();
    _jobTitleController.dispose();
    _workplaceController.dispose();
    _workplacePhoneController.dispose();

    // 사역 정보
    _ordinationChurchController.dispose();
    _neighboringChurchController.dispose();
    _positionDecisionController.dispose();
    _dailyActivityController.dispose();

    // 신앙 정보
    _baptismChurchController.dispose();
    _districtController.dispose();

    // 커스텀 필드
    _customField1Controller.dispose();
    _customField2Controller.dispose();
    _customField3Controller.dispose();
    _customField4Controller.dispose();
    _customField5Controller.dispose();
    _customField6Controller.dispose();
    _customField7Controller.dispose();
    _customField8Controller.dispose();
    _customField9Controller.dispose();
    _customField10Controller.dispose();
    _customField11Controller.dispose();
    _customField12Controller.dispose();

    // 추가 정보
    _specialNotesController.dispose();

    super.dispose();
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    String? counterText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: NewAppColor.textMuted,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        fontFamily: 'Pretendard',
      ),
      counterText: counterText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: NewAppColor.borderHair, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: NewAppColor.borderHair, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: NewAppColor.skyPrimary, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
    );
  }

  // 시안: 라벨 + 빨강 * 필수
  Widget _buildFieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: NewAppColor.textStrong,
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

  // 시안: 2분할 segmented chip (성별, 양력/음력 등)
  Widget _buildSegmented({
    required List<({String value, String label})> options,
    required String? selectedValue,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: options.map((opt) {
        final selected = opt.value == selectedValue;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: opt == options.last ? 0 : 8.w,
            ),
            child: GestureDetector(
              onTap: () => onChanged(opt.value),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 13.h),
                decoration: BoxDecoration(
                  color: selected ? NewAppColor.skyPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: selected
                        ? NewAppColor.skyPrimary
                        : NewAppColor.borderHair,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt.label,
                  style: TextStyle(
                    color: selected ? Colors.white : NewAppColor.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 시안: 점선 원형 아바타 + sky 카메라 버튼 (사진 업로드는 기존 미구현이라 자리만 유지)
  Widget _buildAvatarPicker() {
    return Center(
      child: SizedBox(
        width: 96.w,
        height: 96.w,
        child: Stack(
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: BoxDecoration(
                color: NewAppColor.canvasAlt,
                shape: BoxShape.circle,
                border: Border.all(
                  color: NewAppColor.borderStrong,
                  width: 1.5,
                ),
              ),
              child: Icon(
                LucideIcons.user,
                size: 42.sp,
                color: NewAppColor.iconFaint,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: NewAppColor.skyPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: NewAppColor.skyPrimary.withOpacity(0.30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.camera,
                    color: Colors.white, size: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  Future<void> _showAddChildDialog() async {
    final nameController = TextEditingController();
    DateTime? childBirthdate;
    String childGender = 'male';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '자녀 추가',
            style: FigmaTextStyles().title3.copyWith(
              color: NewAppColor.textStrong,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이름
                TextFormField(
                  controller: nameController,
                  decoration: _buildInputDecoration(
                    hintText: '자녀 이름',
                  ),
                ),
                SizedBox(height: 16.h),

                // 생년월일
                GestureDetector(
                  onTap: () async {
                    final picked = await showCustomDatePicker(
                      context: context,
                      initialDate: childBirthdate ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        childBirthdate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: NewAppColor.canvasAlt,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          childBirthdate != null
                              ? '${childBirthdate!.year}.${childBirthdate!.month.toString().padLeft(2, '0')}.${childBirthdate!.day.toString().padLeft(2, '0')}'
                              : '생년월일 선택',
                          style: FigmaTextStyles().body2.copyWith(
                                color: childBirthdate != null
                                    ? NewAppColor.textStrong
                                    : NewAppColor.textMuted,
                              ),
                        ),
                        Icon(
                          LucideIcons.calendarDays,
                          size: 20.sp,
                          color: NewAppColor.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // 성별
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('남자'),
                        value: 'male',
                        groupValue: childGender,
                        onChanged: (value) {
                          setDialogState(() {
                            childGender = value!;
                          });
                        },
                        activeColor: NewAppColor.skyPrimary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('여자'),
                        value: 'female',
                        groupValue: childGender,
                        onChanged: (value) {
                          setDialogState(() {
                            childGender = value!;
                          });
                        },
                        activeColor: NewAppColor.skyPrimary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '취소',
                style: FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  AppToast.show(
                    context,
                    '자녀 이름을 입력하세요',
                    type: ToastType.error,
                  );
                  return;
                }

                setState(() {
                  _children.add({
                    'name': nameController.text.trim(),
                    'birthdate': childBirthdate,
                    'gender': childGender,
                  });
                });

                Navigator.pop(context);
              },
              child: Text(
                '추가',
                style: FigmaTextStyles().body1.copyWith(
                  color: NewAppColor.skyPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(String fieldName) async {
    DateTime? currentValue;
    switch (fieldName) {
      case 'marriedOn':
        currentValue = _selectedMarriedOn;
        break;
      case 'appointedOn':
        currentValue = _selectedAppointedOn;
        break;
      case 'ministryStartDate':
        currentValue = _selectedMinistryStartDate;
        break;
      case 'confirmationDate':
        currentValue = _selectedConfirmationDate;
        break;
      case 'baptismDate':
        currentValue = _selectedBaptismDate;
        break;
      case 'lastContactDate':
        currentValue = _selectedLastContactDate;
        break;
      case 'registrationDate':
        currentValue = _selectedRegistrationDate;
        break;
    }

    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        switch (fieldName) {
          case 'marriedOn':
            _selectedMarriedOn = picked;
            break;
          case 'appointedOn':
            _selectedAppointedOn = picked;
            break;
          case 'ministryStartDate':
            _selectedMinistryStartDate = picked;
            break;
          case 'confirmationDate':
            _selectedConfirmationDate = picked;
            break;
          case 'baptismDate':
            _selectedBaptismDate = picked;
            break;
          case 'lastContactDate':
            _selectedLastContactDate = picked;
            break;
          case 'registrationDate':
            _selectedRegistrationDate = picked;
            break;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 이름 필수 확인
    if (_nameController.text.trim().isEmpty) {
      AppToast.show(
        context,
        '이름은 필수 입력 항목입니다',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 현재 사용자 정보 가져오기 (church_id 필요)
      final userResponse = await _authService.getCurrentUser();
      if (!userResponse.success || userResponse.data == null) {
        throw Exception('사용자 정보를 불러올 수 없습니다');
      }

      final churchId = userResponse.data!.churchId;

      // 교인 데이터 준비
      final memberData = {
        // 기본 정보
        'name': _nameController.text.trim(),
        if (_nameEngController.text.trim().isNotEmpty)
          'name_eng': _nameEngController.text.trim(),
        'gender': _selectedGender,
        if (_selectedBirthdate != null)
          'birthdate': _selectedBirthdate!.toIso8601String().split('T')[0],
        if (_selectedBirthdateType != null)
          'birthdate_type': _selectedBirthdateType,
        if (_selectedMaritalStatus != null)
          'marital_status': _selectedMaritalStatus,
        if (_spouseNameController.text.trim().isNotEmpty)
          'spouse_name': _spouseNameController.text.trim(),
        if (_selectedMarriedOn != null)
          'married_on': _selectedMarriedOn!.toIso8601String().split('T')[0],

        // 사역 정보
        if (_selectedPositionMain != null)
          'position_main': _selectedPositionMain,
        if (_selectedPositionDetail != null)
          'position_detail': _selectedPositionDetail,
        if (_selectedOrganizationId != null)
          'organization_id': _selectedOrganizationId,
        if (_selectedAppointedOn != null)
          'appointed_on': _selectedAppointedOn!.toIso8601String().split('T')[0],
        if (_ordinationChurchController.text.trim().isNotEmpty)
          'ordination_church': _ordinationChurchController.text.trim(),
        if (_selectedMinistryStartDate != null)
          'ministry_start_date':
              _selectedMinistryStartDate!.toIso8601String().split('T')[0],
        if (_neighboringChurchController.text.trim().isNotEmpty)
          'neighboring_church': _neighboringChurchController.text.trim(),
        if (_positionDecisionController.text.trim().isNotEmpty)
          'position_decision': _positionDecisionController.text.trim(),
        if (_dailyActivityController.text.trim().isNotEmpty)
          'daily_activity': _dailyActivityController.text.trim(),
        if (_selectedInviter3MemberId != null)
          'inviter_3_member_id': _selectedInviter3MemberId,

        // 신앙 정보
        if (_selectedMemberType != null) 'member_type': _selectedMemberType,
        if (_selectedAgeGroup != null) 'age_group': _selectedAgeGroup,
        if (_selectedSpiritualGrade != null)
          'spiritual_grade': _selectedSpiritualGrade,
        if (_selectedConfirmationDate != null)
          'confirmation_date':
              _selectedConfirmationDate!.toIso8601String().split('T')[0],
        if (_selectedBaptismDate != null)
          'baptism_date': _selectedBaptismDate!.toIso8601String().split('T')[0],
        if (_baptismChurchController.text.trim().isNotEmpty)
          'baptism_church': _baptismChurchController.text.trim(),
        if (_districtController.text.trim().isNotEmpty)
          'district': _districtController.text.trim(),
        if (_selectedLastContactDate != null)
          'last_contact_date':
              _selectedLastContactDate!.toIso8601String().split('T')[0],
        if (_selectedRegistrationDate != null)
          'registration_date':
              _selectedRegistrationDate!.toIso8601String().split('T')[0],

        // 연락처 정보
        if (_phoneController.text.trim().isNotEmpty)
          'phone': _phoneController.text.trim(),
        if (_emailController.text.trim().isNotEmpty)
          'email': _emailController.text.trim(),
        if (_addressController.text.trim().isNotEmpty)
          'address': _addressController.text.trim(),

        // 직업 정보
        if (_selectedJobCategory != null)
          'job_category': _selectedJobCategory,
        if (_jobDetailController.text.trim().isNotEmpty)
          'job_detail': _jobDetailController.text.trim(),
        if (_jobPositionController.text.trim().isNotEmpty)
          'job_position': _jobPositionController.text.trim(),
        if (_jobTitleController.text.trim().isNotEmpty)
          'job_title': _jobTitleController.text.trim(),
        if (_workplaceController.text.trim().isNotEmpty)
          'workplace': _workplaceController.text.trim(),
        if (_workplacePhoneController.text.trim().isNotEmpty)
          'workplace_phone': _workplacePhoneController.text.trim(),

        // 커스텀 필드
        if (_customField1Controller.text.trim().isNotEmpty)
          'custom_field_1': _customField1Controller.text.trim(),
        if (_customField2Controller.text.trim().isNotEmpty)
          'custom_field_2': _customField2Controller.text.trim(),
        if (_customField3Controller.text.trim().isNotEmpty)
          'custom_field_3': _customField3Controller.text.trim(),
        if (_customField4Controller.text.trim().isNotEmpty)
          'custom_field_4': _customField4Controller.text.trim(),
        if (_customField5Controller.text.trim().isNotEmpty)
          'custom_field_5': _customField5Controller.text.trim(),
        if (_customField6Controller.text.trim().isNotEmpty)
          'custom_field_6': _customField6Controller.text.trim(),
        if (_customField7Controller.text.trim().isNotEmpty)
          'custom_field_7': _customField7Controller.text.trim(),
        if (_customField8Controller.text.trim().isNotEmpty)
          'custom_field_8': _customField8Controller.text.trim(),
        if (_customField9Controller.text.trim().isNotEmpty)
          'custom_field_9': _customField9Controller.text.trim(),
        if (_customField10Controller.text.trim().isNotEmpty)
          'custom_field_10': _customField10Controller.text.trim(),
        if (_customField11Controller.text.trim().isNotEmpty)
          'custom_field_11': _customField11Controller.text.trim(),
        if (_customField12Controller.text.trim().isNotEmpty)
          'custom_field_12': _customField12Controller.text.trim(),

        // 추가 정보 (레거시)
        if (_selectedPosition != null) 'position': _selectedPosition,
        if (_selectedDepartment != null) 'department': _selectedDepartment,
        if (_specialNotesController.text.trim().isNotEmpty)
          'special_notes': _specialNotesController.text.trim(),

        // 시스템 필드
        'church_id': churchId,
        'member_status': _selectedStatus,

        // 자녀 정보
        if (_children.isNotEmpty)
          'children': _children.map((child) {
            return {
              'name': child['name'],
              'gender': child['gender'],
              if (child['birthdate'] != null)
                'birthdate': (child['birthdate'] as DateTime).toIso8601String().split('T')[0],
            };
          }).toList(),
      };

      final response = await _memberService.createMember(memberData);

      if (response.success && response.data != null) {
        if (mounted) {
          AppToast.show(
            context,
            '교인이 성공적으로 추가되었습니다',
            type: ToastType.success,
          );
          Navigator.pop(context, true); // true를 반환하여 목록 새로고침
        }
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '교인 추가 실패: ${e.toString()}',
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
      backgroundColor: NewAppColor.canvasAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: material.IconButton(
          icon: Icon(LucideIcons.x,
              color: NewAppColor.textStrong, size: 22.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '교인 추가',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 14.w),
            ),
            child: Text(
              '저장',
              style: TextStyle(
                color: NewAppColor.skyPrimary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarPicker(),
                    SizedBox(height: 24.h),
                    // 기본 정보 섹션
                    _buildSectionTitle('기본 정보'),
                    SizedBox(height: 12.h),
                    _buildBasicInfoSection(),

                    SizedBox(height: 24.h),

                    // 개인 및 가족 정보 섹션
                    _buildSectionTitle('개인 및 가족 정보'),
                    SizedBox(height: 16.h),
                    _buildFamilyInfoSection(),

                    SizedBox(height: 24.h),

                    // 교회 정보 섹션
                    _buildSectionTitle('교회 정보'),
                    SizedBox(height: 16.h),
                    _buildMinistryInfoSection(),

                    SizedBox(height: 24.h),

                    // 교회 정보 확장 섹션
                    _buildSectionTitle('교회 정보 확장'),
                    SizedBox(height: 16.h),
                    _buildChurchExtendedInfoSection(),

                    SizedBox(height: 24.h),

                    // 직업 정보 섹션
                    _buildSectionTitle('직업 정보'),
                    SizedBox(height: 16.h),
                    _buildJobInfoSection(),

                    SizedBox(height: 24.h),

                    // 사역 정보 확장 섹션
                    _buildSectionTitle('사역 정보 확장'),
                    SizedBox(height: 16.h),
                    _buildMinistryExtendedInfoSection(),

                    SizedBox(height: 24.h),

                    // 자유필드 섹션
                    _buildSectionTitle('자유필드'),
                    SizedBox(height: 16.h),
                    _buildCustomFieldsSection(),

                    SizedBox(height: 24.h),

                    // 추가 정보 섹션
                    _buildSectionTitle('추가 정보'),
                    SizedBox(height: 12.h),
                    _buildAdditionalInfoSection(),

                    SizedBox(height: 18.h),
                    _buildHintFooter(),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
            // 하단 액션 바
            Container(
              padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
              decoration: BoxDecoration(
                color: NewAppColor.canvasAlt,
                border: Border(
                  top: BorderSide(color: NewAppColor.borderHair, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: GestureDetector(
                  onTap: _isLoading ? null : _submitForm,
                  behavior: HitTestBehavior.opaque,
                  child: Opacity(
                    opacity: _isLoading ? 0.5 : 1.0,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      decoration: BoxDecoration(
                        color: NewAppColor.skyPrimary,
                        borderRadius: BorderRadius.circular(13.r),
                        boxShadow: [
                          BoxShadow(
                            color: NewAppColor.skyPrimary.withOpacity(0.30),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              '교인 추가',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                    ),
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
      padding: EdgeInsets.only(left: 2.w),
      child: Text(
        title,
        style: TextStyle(
          color: NewAppColor.textTertiary,
          fontSize: 12.5.sp,
          fontWeight: FontWeight.w700,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  // 시안: 하단 안내문 (정보 아이콘 + 회색 문구)
  Widget _buildHintFooter() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info,
              size: 14.sp, color: NewAppColor.textTertiary),
          SizedBox(width: 7.w),
          Expanded(
            child: Text(
              '입력한 이메일로 초대 메일이 발송되며, 교인이 직접 가입을 완료합니다.',
              style: TextStyle(
                color: NewAppColor.textTertiary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이름 (필수)
          TextFormField(
            controller: _nameController,
            decoration: _buildInputDecoration(
              hintText: '이름 *',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '이름은 필수 입력 항목입니다';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),

          // 영문명
          TextFormField(
            controller: _nameEngController,
            decoration: _buildInputDecoration(
              hintText: '영문명',
            ),
          ),
          SizedBox(height: 16.h),

          // 이메일
          TextFormField(
            controller: _emailController,
            decoration: _buildInputDecoration(
              hintText: '이메일',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16.h),

          // 전화번호
          TextFormField(
            controller: _phoneController,
            decoration: _buildInputDecoration(
              hintText: '전화번호',
            ),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 16.h),

          // 생년월일 구분 (양력/음력)
          _buildFieldLabel('생년월일 구분'),
          _buildSegmented(
            options: const [
              (value: 'solar', label: '양력'),
              (value: 'lunar', label: '음력'),
            ],
            selectedValue: _selectedBirthdateType,
            onChanged: (v) => setState(() => _selectedBirthdateType = v),
          ),
          SizedBox(height: 16.h),

          // 생년월일 선택
          GestureDetector(
            onTap: _selectBirthdate,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: NewAppColor.canvasAlt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedBirthdate != null
                        ? '${_selectedBirthdate!.year}.${_selectedBirthdate!.month.toString().padLeft(2, '0')}.${_selectedBirthdate!.day.toString().padLeft(2, '0')}'
                        : '생년월일',
                    style: FigmaTextStyles().body2.copyWith(
                          color: _selectedBirthdate != null
                              ? NewAppColor.textStrong
                              : NewAppColor.textMuted,
                        ),
                  ),
                  Icon(
                    LucideIcons.calendarDays,
                    size: 20.sp,
                    color: NewAppColor.textMuted,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 성별 선택
          _buildFieldLabel('성별'),
          _buildSegmented(
            options: const [
              (value: 'female', label: '여'),
              (value: 'male', label: '남'),
            ],
            selectedValue: _selectedGender,
            onChanged: (v) => setState(() => _selectedGender = v),
          ),
          SizedBox(height: 16.h),

          // 주소
          TextFormField(
            controller: _addressController,
            decoration: _buildInputDecoration(
              hintText: '주소',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 결혼 상태 선택
          DropdownButtonFormField<String>(
            value: _selectedMaritalStatus,
            decoration: _buildInputDecoration(
              hintText: '상태 선택',
            ),
            items: const [
              DropdownMenuItem(value: 'single', child: Text('미혼')),
              DropdownMenuItem(value: 'married', child: Text('기혼')),
              DropdownMenuItem(value: 'divorced', child: Text('이혼')),
              DropdownMenuItem(value: 'widowed', child: Text('사별')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMaritalStatus = value;
              });
            },
          ),

          // 배우자 이름 (기혼인 경우)
          if (_selectedMaritalStatus == 'married') ...[
            SizedBox(height: 16.h),
            TextFormField(
              controller: _spouseNameController,
              decoration: _buildInputDecoration(
                hintText: '배우자 이름',
              ),
            ),
            SizedBox(height: 16.h),
            // 결혼일
            GestureDetector(
              onTap: () => _selectDate('marriedOn'),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: NewAppColor.canvasAlt,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedMarriedOn != null
                          ? '${_selectedMarriedOn!.year}.${_selectedMarriedOn!.month.toString().padLeft(2, '0')}.${_selectedMarriedOn!.day.toString().padLeft(2, '0')}'
                          : '결혼일 선택',
                      style: FigmaTextStyles().body2.copyWith(
                            color: _selectedMarriedOn != null
                                ? NewAppColor.textStrong
                                : NewAppColor.textMuted,
                          ),
                    ),
                    Icon(
                      LucideIcons.calendarDays,
                      size: 20.sp,
                      color: NewAppColor.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 자녀 정보 (기혼, 이혼, 사별인 경우)
          if (_selectedMaritalStatus == 'married' ||
              _selectedMaritalStatus == 'divorced' ||
              _selectedMaritalStatus == 'widowed') ...[
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '자녀 정보',
                  style: FigmaTextStyles().body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: NewAppColor.textStrong,
                  ),
                ),
                material.IconButton(
                  onPressed: () => _showAddChildDialog(),
                  icon: Icon(
                    LucideIcons.plus,
                    size: 20.sp,
                    color: NewAppColor.skyPrimary,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (_children.isEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                alignment: Alignment.center,
                child: Text(
                  '자녀 정보를 추가하려면 위의 버튼을 클릭하세요.',
                  style: FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.textMuted,
                  ),
                ),
              )
            else
              ..._children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: NewAppColor.canvasAlt,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: NewAppColor.borderHair,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child['name'] ?? '',
                              style: FigmaTextStyles().body1.copyWith(
                                fontWeight: FontWeight.w600,
                                color: NewAppColor.textStrong,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '${child['gender'] == 'male' ? '남' : '여'} · ${child['birthdate'] != null ? '${(child['birthdate'] as DateTime).year}.${(child['birthdate'] as DateTime).month.toString().padLeft(2, '0')}.${(child['birthdate'] as DateTime).day.toString().padLeft(2, '0')}' : '생년월일 미입력'}',
                              style: FigmaTextStyles().body2.copyWith(
                                color: NewAppColor.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      material.IconButton(
                        onPressed: () {
                          setState(() {
                            _children.removeAt(index);
                          });
                        },
                        icon: Icon(
                          LucideIcons.trash2,
                          size: 18.sp,
                          color: NewAppColor.danger700,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildJobInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 직업분류 (드롭다운)
          DropdownButtonFormField<String?>(
            value: _selectedJobCategory,
            decoration: _buildInputDecoration(
              hintText: '분류 선택',
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('분류 선택')),
              DropdownMenuItem<String?>(value: 'IT', child: Text('IT/기술')),
              DropdownMenuItem<String?>(value: 'EDUCATION', child: Text('교육')),
              DropdownMenuItem<String?>(value: 'MEDICAL', child: Text('의료')),
              DropdownMenuItem<String?>(value: 'FINANCE', child: Text('금융')),
              DropdownMenuItem<String?>(value: 'MANUFACTURING', child: Text('제조')),
              DropdownMenuItem<String?>(value: 'SERVICE', child: Text('서비스')),
              DropdownMenuItem<String?>(value: 'CONSTRUCTION', child: Text('건설')),
              DropdownMenuItem<String?>(value: 'SALES', child: Text('영업/판매')),
              DropdownMenuItem<String?>(value: 'GOVERNMENT', child: Text('공무원')),
              DropdownMenuItem<String?>(value: 'PROFESSIONAL', child: Text('전문직')),
              DropdownMenuItem<String?>(value: 'SELF_EMPLOYED', child: Text('자영업')),
              DropdownMenuItem<String?>(value: 'STUDENT', child: Text('학생')),
              DropdownMenuItem<String?>(value: 'HOMEMAKER', child: Text('주부')),
              DropdownMenuItem<String?>(value: 'RETIRED', child: Text('은퇴')),
              DropdownMenuItem<String?>(value: 'UNEMPLOYED', child: Text('무직')),
              DropdownMenuItem<String?>(value: 'OTHER', child: Text('기타')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedJobCategory = value;
              });
            },
          ),
          SizedBox(height: 16.h),

          // 구체적 업무
          TextFormField(
            controller: _jobDetailController,
            decoration: _buildInputDecoration(
              hintText: '소프트웨어 개발, 초등학교 교사 등',
            ),
          ),
          SizedBox(height: 16.h),

          // 직책/직위
          TextFormField(
            controller: _jobPositionController,
            decoration: _buildInputDecoration(
              hintText: '팀장, 과장, 원장 등',
            ),
          ),
          SizedBox(height: 16.h),

          // 직업명
          TextFormField(
            controller: _jobTitleController,
            decoration: _buildInputDecoration(
              hintText: '회사원, 교사 등',
            ),
          ),
          SizedBox(height: 16.h),

          // 직장명
          TextFormField(
            controller: _workplaceController,
            decoration: _buildInputDecoration(
              hintText: '삼성전자',
            ),
          ),
          SizedBox(height: 16.h),

          // 직장 전화번호
          TextFormField(
            controller: _workplacePhoneController,
            decoration: _buildInputDecoration(
              hintText: '02-1234-5678',
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildMinistryExtendedInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사역 시작일
          GestureDetector(
            onTap: () => _selectDate('ministryStartDate'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: NewAppColor.canvasAlt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedMinistryStartDate != null
                        ? '${_selectedMinistryStartDate!.year}.${_selectedMinistryStartDate!.month.toString().padLeft(2, '0')}.${_selectedMinistryStartDate!.day.toString().padLeft(2, '0')}'
                        : '사역 시작일 선택',
                    style: FigmaTextStyles().body2.copyWith(
                          color: _selectedMinistryStartDate != null
                              ? NewAppColor.textStrong
                              : NewAppColor.textMuted,
                        ),
                  ),
                  Icon(
                    LucideIcons.calendarDays,
                    size: 20.sp,
                    color: NewAppColor.textMuted,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 이웃교회
          TextFormField(
            controller: _neighboringChurchController,
            decoration: _buildInputDecoration(
              hintText: '은혜교회, 사랑교회 등',
            ),
          ),
          SizedBox(height: 16.h),

          // 직분 결정
          TextFormField(
            controller: _positionDecisionController,
            decoration: _buildInputDecoration(
              hintText: '장로 추천, 권사 임명 등',
            ),
          ),
          SizedBox(height: 16.h),

          // 인도자
          DropdownButtonFormField<int?>(
            value: _selectedInviter3MemberId,
            decoration: _buildInputDecoration(
              hintText: '없음',
            ),
            items: const [
              DropdownMenuItem<int?>(value: null, child: Text('없음')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedInviter3MemberId = value;
              });
            },
          ),
          SizedBox(height: 16.h),

          // 일상 활동
          TextFormField(
            controller: _dailyActivityController,
            decoration: _buildInputDecoration(
              hintText: '새벽기도 참석, 구역모임 리더 등',
            ),
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildMinistryInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 직분 대분류
          DropdownButtonFormField<String?>(
            value: _selectedPositionMain,
            decoration: _buildInputDecoration(
              hintText: '직분 대분류',
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('직분 대분류')),
              DropdownMenuItem<String?>(value: 'CLERGY', child: Text('교역자')),
              DropdownMenuItem<String?>(value: 'ELDER', child: Text('장로')),
              DropdownMenuItem<String?>(value: 'DEACONESS', child: Text('권사')),
              DropdownMenuItem<String?>(value: 'DEACON', child: Text('집사')),
              DropdownMenuItem<String?>(value: 'CHURCH_SCHOOL', child: Text('교회학교')),
              DropdownMenuItem<String?>(value: 'MEMBER', child: Text('성도')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPositionMain = value;
                _selectedPositionDetail = null; // 대분류 변경 시 세부 직분 초기화
              });
            },
          ),

          // 세부 직분 (직분 대분류가 선택된 경우에만 표시)
          if (_selectedPositionMain != null) ...[
            SizedBox(height: 16.h),
            DropdownButtonFormField<String?>(
              value: _selectedPositionDetail,
              decoration: _buildInputDecoration(
                hintText: '세부 직분 선택',
              ),
              items: _getPositionDetailItems(),
              onChanged: (value) {
                setState(() {
                  _selectedPositionDetail = value;
                });
              },
            ),
          ],
          SizedBox(height: 16.h),

          // 조직
          DropdownButtonFormField<String?>(
            value: _selectedOrganizationId,
            decoration: _buildInputDecoration(
              hintText: '조직',
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('조직')),
              ..._organizations.map((org) => DropdownMenuItem<String?>(
                    value: org['id'] as String,
                    child: Text(org['name'] as String),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedOrganizationId = value;
              });
            },
          ),
          SizedBox(height: 16.h),

          // 부서
          DropdownButtonFormField<String?>(
            value: _selectedDepartment,
            decoration: _buildInputDecoration(
              hintText: '부서',
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('부서')),
              DropdownMenuItem<String?>(value: 'WORSHIP', child: Text('예배부')),
              DropdownMenuItem<String?>(value: 'EDUCATION', child: Text('교육부')),
              DropdownMenuItem<String?>(value: 'MISSION', child: Text('선교부')),
              DropdownMenuItem<String?>(value: 'YOUTH', child: Text('청년부')),
              DropdownMenuItem<String?>(value: 'CHILDREN', child: Text('아동부')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedDepartment = value;
              });
            },
          ),
          SizedBox(height: 16.h),

          // 임명일
          GestureDetector(
            onTap: () => _selectDate('appointedOn'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: NewAppColor.canvasAlt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedAppointedOn != null
                        ? '${_selectedAppointedOn!.year}.${_selectedAppointedOn!.month.toString().padLeft(2, '0')}.${_selectedAppointedOn!.day.toString().padLeft(2, '0')}'
                        : '임명일 선택',
                    style: FigmaTextStyles().body2.copyWith(
                          color: _selectedAppointedOn != null
                              ? NewAppColor.textStrong
                              : NewAppColor.textMuted,
                        ),
                  ),
                  Icon(
                    LucideIcons.calendarDays,
                    size: 20.sp,
                    color: NewAppColor.textMuted,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 안수교회
          TextFormField(
            controller: _ordinationChurchController,
            decoration: _buildInputDecoration(
              hintText: '안수받은 교회',
            ),
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String?>> _getPositionDetailItems() {
    const emptyOption = DropdownMenuItem<String?>(value: null, child: Text('세부 직분 선택'));

    if (_selectedPositionMain == null) {
      return [emptyOption];
    }

    List<DropdownMenuItem<String?>> items = [emptyOption];

    switch (_selectedPositionMain) {
      case 'CLERGY':
        items.addAll(const [
          DropdownMenuItem(value: 'SENIOR_PASTOR', child: Text('담임목사')),
          DropdownMenuItem(value: 'EMERITUS_PASTOR', child: Text('원로목사')),
          DropdownMenuItem(value: 'ASSOCIATE_PASTOR', child: Text('부목사')),
          DropdownMenuItem(value: 'COOPERATE_PASTOR', child: Text('협동목사')),
          DropdownMenuItem(value: 'EVANGELIST', child: Text('전도사')),
          DropdownMenuItem(value: 'INTERN_EVANGELIST', child: Text('전임전도사')),
          DropdownMenuItem(value: 'EDUCATION_EVANGELIST', child: Text('교육담당전도사')),
        ]);
        break;
      case 'ELDER':
        items.addAll(const [
          DropdownMenuItem(value: 'ACTIVE_ELDER', child: Text('시무장로')),
          DropdownMenuItem(value: 'EMERITUS_ELDER', child: Text('원로장로')),
          DropdownMenuItem(value: 'TRANSFERRED_EMERITUS_ELDER', child: Text('이명은퇴장로')),
        ]);
        break;
      case 'DEACONESS':
        items.addAll(const [
          DropdownMenuItem(value: 'HONORARY_DEACONESS', child: Text('명예권사')),
          DropdownMenuItem(value: 'ACTIVE_DEACONESS', child: Text('시무권사')),
        ]);
        break;
      case 'DEACON':
        items.addAll(const [
          DropdownMenuItem(value: 'HONORARY_DEACON', child: Text('명예집사')),
          DropdownMenuItem(value: 'PROBATIONARY_DEACON', child: Text('서리집사')),
          DropdownMenuItem(value: 'ACTIVE_DEACON', child: Text('집사')),
          DropdownMenuItem(value: 'ORDAINED_DEACON', child: Text('안수집사')),
        ]);
        break;
      case 'CHURCH_SCHOOL':
        items.addAll(const [
          DropdownMenuItem(value: 'INFANT', child: Text('영아부')),
          DropdownMenuItem(value: 'KINDERGARTEN', child: Text('유치부')),
          DropdownMenuItem(value: 'YOUNG_CHILDREN', child: Text('유년부')),
          DropdownMenuItem(value: 'ELEMENTARY', child: Text('초등부')),
          DropdownMenuItem(value: 'JUNIOR', child: Text('소년부')),
          DropdownMenuItem(value: 'MIDDLE_SCHOOL', child: Text('중등부')),
          DropdownMenuItem(value: 'HIGH_SCHOOL', child: Text('고등부')),
          DropdownMenuItem(value: 'YOUTH', child: Text('청년부')),
        ]);
        break;
      case 'MEMBER':
        items.addAll(const [
          DropdownMenuItem(value: 'TEACHER', child: Text('교사')),
          DropdownMenuItem(value: 'STUDENT', child: Text('학생')),
        ]);
        break;
    }

    return items;
  }

  Widget _buildChurchExtendedInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 교인구분
          DropdownButtonFormField<String>(
            value: _selectedMemberType,
            decoration: _buildInputDecoration(
              hintText: '구분 선택',
            ),
            items: const [
              DropdownMenuItem(value: 'seeker', child: Text('구도자')),
              DropdownMenuItem(value: 'new_family', child: Text('새가족')),
              DropdownMenuItem(value: 'member', child: Text('등록교인')),
              DropdownMenuItem(value: 'transferred', child: Text('이명교인')),
              DropdownMenuItem(value: 'visiting', child: Text('방문교인')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedMemberType = value;
              });
            },
          ),
          SizedBox(height: 16.h),

          // 입교일
          GestureDetector(
            onTap: () => _selectDate('confirmationDate'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: NewAppColor.canvasAlt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedConfirmationDate != null
                        ? '${_selectedConfirmationDate!.year}.${_selectedConfirmationDate!.month.toString().padLeft(2, '0')}.${_selectedConfirmationDate!.day.toString().padLeft(2, '0')}'
                        : '입교일 선택',
                    style: FigmaTextStyles().body2.copyWith(
                          color: _selectedConfirmationDate != null
                              ? NewAppColor.textStrong
                              : NewAppColor.textMuted,
                        ),
                  ),
                  Icon(
                    LucideIcons.calendarDays,
                    size: 20.sp,
                    color: NewAppColor.textMuted,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 세례일
          GestureDetector(
            onTap: () => _selectDate('baptismDate'),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: NewAppColor.canvasAlt,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedBaptismDate != null
                        ? '${_selectedBaptismDate!.year}.${_selectedBaptismDate!.month.toString().padLeft(2, '0')}.${_selectedBaptismDate!.day.toString().padLeft(2, '0')}'
                        : '세례일 선택',
                    style: FigmaTextStyles().body2.copyWith(
                          color: _selectedBaptismDate != null
                              ? NewAppColor.textStrong
                              : NewAppColor.textMuted,
                        ),
                  ),
                  Icon(
                    LucideIcons.calendarDays,
                    size: 20.sp,
                    color: NewAppColor.textMuted,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // 세례교회
          TextFormField(
            controller: _baptismChurchController,
            decoration: _buildInputDecoration(
              hintText: '세례받은 교회',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFieldsSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 자유필드 1
          TextFormField(
            controller: _customField1Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 1',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 2
          TextFormField(
            controller: _customField2Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 2',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 3
          TextFormField(
            controller: _customField3Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 3',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 4
          TextFormField(
            controller: _customField4Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 4',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 5
          TextFormField(
            controller: _customField5Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 5',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 6
          TextFormField(
            controller: _customField6Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 6',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 7
          TextFormField(
            controller: _customField7Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 7',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 8
          TextFormField(
            controller: _customField8Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 8',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 9
          TextFormField(
            controller: _customField9Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 9',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 10
          TextFormField(
            controller: _customField10Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 10',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 11
          TextFormField(
            controller: _customField11Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 11',
            ),
          ),
          SizedBox(height: 16.h),

          // 자유필드 12
          TextFormField(
            controller: _customField12Controller,
            decoration: _buildInputDecoration(
              hintText: '자유필드 12',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 특별 사항
          TextFormField(
            controller: _specialNotesController,
            decoration: _buildInputDecoration(
              hintText: '특별 사항',
            ),
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}
