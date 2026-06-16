import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/index.dart';
import '../../models/member.dart';
import '../../resource/color_style_new.dart';
import '../../resource/text_style_new.dart';
import '../../services/member_service.dart';
import '../../services/supabase_service.dart';
import 'admin_member_edit_screen.dart';

/// 관리자용 교인 상세 화면
class AdminMemberDetailScreen extends StatefulWidget {
  final Member member;

  const AdminMemberDetailScreen({
    super.key,
    required this.member,
  });

  @override
  State<AdminMemberDetailScreen> createState() =>
      _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState extends State<AdminMemberDetailScreen> {
  final MemberService _memberService = MemberService();
  late Member _member;
  bool _isLoading = false;
  String? _organizationName;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _loadOrganizationName();
  }

  Future<void> _loadOrganizationName() async {
    if (_member.organizationId == null || _member.organizationId!.isEmpty) {
      return;
    }

    try {
      final supabaseService = SupabaseService();

      // 조직 계층 구조를 breadcrumb으로 만들기
      final breadcrumbs = <String>[];
      String? currentOrgId = _member.organizationId;

      // 최대 10단계까지만 조회 (무한 루프 방지)
      for (int i = 0; i < 10 && currentOrgId != null; i++) {
        final response = await supabaseService.client
            .from('church_organizations')
            .select('name, parent_id')
            .eq('id', currentOrgId)
            .maybeSingle();

        if (response == null) break;

        final name = response['name'] as String?;
        if (name != null && name.isNotEmpty) {
          breadcrumbs.insert(0, name); // 앞에 추가 (역순으로)
        }

        currentOrgId = response['parent_id'] as String?;
      }

      if (breadcrumbs.isNotEmpty && mounted) {
        setState(() {
          _organizationName = breadcrumbs.join(' > ');
        });
      }
    } catch (e) {
      // 조직명 조회 실패는 무시 (선택적 정보이므로)
      print('조직명 조회 실패: $e');
    }
  }

  Future<void> _makePhoneCall() async {
    final phoneNumber = _member.phone;
    if (phoneNumber.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppToast.show(
          context,
          '전화를 걸 수 없습니다',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _sendEmail() async {
    final email = _member.email;
    if (email == null || email.isEmpty) return;

    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppToast.show(
          context,
          '이메일 앱을 열 수 없습니다',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _toggleMemberStatus() async {
    final newStatus = _member.memberStatus == 'active' ? 'inactive' : 'active';
    final activating = newStatus == 'active';
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '${activating ? '활성' : '비활성'} 상태로 변경할까요?',
      description: '${_member.name}님의 상태를 변경합니다.',
      confirmLabel: activating ? '활성화' : '비활성화',
      tone: activating ? AppSheetTone.sky : AppSheetTone.warning,
      icon: activating
          ? LucideIcons.circleCheck
          : LucideIcons.circlePause,
    );
    if (ok == true) await _performStatusUpdate(newStatus);
  }

  Future<void> _performStatusUpdate(String newStatus) async {
    setState(() => _isLoading = true);

    try {
      final response = await _memberService.updateMemberStatus(
        memberId: _member.id,
        status: newStatus,
      );

      if (response.success && response.data != null) {
        setState(() {
          _member = response.data!;
        });

        if (mounted) {
          AppToast.show(
            context,
            '상태가 성공적으로 변경되었습니다',
            type: ToastType.success,
          );
        }
      } else {
        if (mounted) {
          AppToast.show(
            context,
            response.message.isNotEmpty
                ? response.message
                : '상태 변경에 실패했습니다',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '상태 변경 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteMember() async {
    final ok = await AppConfirmSheet.show(
      context: context,
      title: '${_member.name}님을 삭제할까요?',
      description: '삭제한 정보는 되돌릴 수 없어요.',
      confirmLabel: '삭제',
      tone: AppSheetTone.danger,
    );
    if (ok == true) await _performDelete();
  }

  Future<void> _performDelete() async {
    setState(() => _isLoading = true);

    try {
      final response = await _memberService.deleteMember(_member.id);

      if (response.success) {
        if (mounted) {
          AppToast.show(
            context,
            '교인이 삭제되었습니다',
            type: ToastType.success,
          );
          Navigator.pop(context); // 목록으로 돌아가기
        }
      } else {
        if (mounted) {
          AppToast.show(
            context,
            response.message.isNotEmpty
                ? response.message
                : '교인 삭제에 실패했습니다',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '교인 삭제 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMemberEditScreen(member: _member),
      ),
    );

    if (result == true) {
      _loadMember(); // 수정 후 정보 새로고침
    }
  }

  Future<void> _loadMember() async {
    setState(() => _isLoading = true);

    try {
      final response = await _memberService.getMember(_member.id);

      if (response.success && response.data != null) {
        setState(() {
          _member = response.data!;
        });
        // 교인 정보가 업데이트되면 조직명도 다시 조회
        await _loadOrganizationName();
      } else {
        if (mounted) {
          AppToast.show(
            context,
            response.message.isNotEmpty
                ? response.message
                : '교인 정보를 불러오는데 실패했습니다',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          '교인 정보 조회 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getGenderDisplay(String gender) {
    if (gender.isEmpty) return '미지정';

    // 모든 가능한 gender 값 처리
    switch (gender) {
      case '남':
      case '남자':
      case '남성':
      case 'M':
      case 'male':
      case 'MALE':
        return '남성';
      case '여':
      case '여자':
      case '여성':
      case 'F':
      case 'female':
      case 'FEMALE':
        return '여성';
      default:
        return gender; // 알 수 없는 값은 그대로 표시
    }
  }

  String _getPositionMainDisplay(String? positionMain) {
    if (positionMain == null || positionMain.isEmpty) return '';

    const mainLabels = {
      'CLERGY': '교역자',
      'ELDER': '장로',
      'DEACONESS': '권사',
      'DEACON': '집사',
      'CHURCH_SCHOOL': '교회학교',
      'MEMBER': '성도',
    };

    return mainLabels[positionMain] ?? positionMain;
  }

  String _getPositionDetailDisplay(String? positionDetail) {
    if (positionDetail == null || positionDetail.isEmpty) return '';

    const detailLabels = {
      // 교역자(CLERGY) 계열
      'SENIOR_PASTOR': '담임목사',
      'EMERITUS_PASTOR': '원로목사',
      'ASSOCIATE_PASTOR': '부목사',
      'COOPERATE_PASTOR': '협동목사',
      'EVANGELIST': '전도사',
      'INTERN_EVANGELIST': '전임전도사',
      'EDUCATION_EVANGELIST': '교육담당전도사',

      // 장로(ELDER) 계열
      'ACTIVE_ELDER': '시무장로',
      'EMERITUS_ELDER': '원로장로',
      'TRANSFERRED_EMERITUS_ELDER': '이명은퇴장로',

      // 권사(DEACONESS) 계열
      'HONORARY_DEACONESS': '명예권사',
      'ACTIVE_DEACONESS': '시무권사',

      // 집사(DEACON) 계열
      'HONORARY_DEACON': '명예집사',
      'PROBATIONARY_DEACON': '서리집사',
      'ACTIVE_DEACON': '집사',
      'ORDAINED_DEACON': '안수집사',

      // 교회학교(CHURCH_SCHOOL) 계열
      'INFANT': '영아부',
      'KINDERGARTEN': '유치부',
      'YOUNG_CHILDREN': '유년부',
      'ELEMENTARY': '초등부',
      'JUNIOR': '소년부',
      'MIDDLE_SCHOOL': '중등부',
      'HIGH_SCHOOL': '고등부',
      'YOUTH': '청년부',

      // 기타(MEMBER) 계열
      'TEACHER': '교사',
      'STUDENT': '학생',
    };

    return detailLabels[positionDetail] ?? positionDetail;
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
        centerTitle: false,
        titleSpacing: 0,
        leading: material.IconButton(
          icon: Icon(LucideIcons.chevronLeft,
              color: NewAppColor.textStrong, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '교인 상세',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        actions: [
          material.IconButton(
            icon: Icon(LucideIcons.pencil,
                color: NewAppColor.textStrong, size: 20.sp),
            onPressed: _navigateToEdit,
          ),
          material.IconButton(
            icon: Icon(LucideIcons.refreshCw,
                color: NewAppColor.textStrong, size: 20.sp),
            onPressed: _loadMember,
          ),
        ],
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: NewAppColor.skyPrimary))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(),
                  SizedBox(height: 12.h),
                  _buildBasicInfoSection(),
                  SizedBox(height: 12.h),
                  if (_hasPersonalFamily()) ...[
                    _buildPersonalFamilyInfoSection(),
                    SizedBox(height: 12.h),
                  ],
                  _buildChurchInfoSection(),
                  if (_hasChurchInfoExtended()) ...[
                    SizedBox(height: 12.h),
                    _buildChurchInfoExtendedSection(),
                  ],
                  if (_hasJobInfo()) ...[
                    SizedBox(height: 12.h),
                    _buildJobInfoSection(),
                  ],
                  if (_hasMinistryInfoExtended()) ...[
                    SizedBox(height: 12.h),
                    _buildMinistryInfoExtendedSection(),
                  ],
                  if (_hasCustomFields()) ...[
                    SizedBox(height: 12.h),
                    _buildCustomFieldsSection(),
                  ],
                  if (_hasAdditionalInfo()) ...[
                    SizedBox(height: 12.h),
                    _buildAdditionalInfoSection(),
                  ],
                  if (_hasSystemInfo()) ...[
                    SizedBox(height: 12.h),
                    _buildSystemInfoSection(),
                  ],
                  SizedBox(height: 18.h),
                  _buildActionSection(),
                ],
              ),
            ),
    );
  }

  bool _hasPersonalFamily() {
    return (_member.maritalStatus != null &&
            _member.maritalStatus!.isNotEmpty) ||
        (_member.spouseName != null && _member.spouseName!.isNotEmpty) ||
        _member.marriedOn != null ||
        (_member.children != null && _member.children!.isNotEmpty);
  }

  // 1.2.0 표준 카드 셸 — borderHair 1px + radius 14
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair),
      ),
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 18.h),
      child: child,
    );
  }

  // 1.2.0 표준 섹션 헤더
  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Text(
        title,
        style: TextStyle(
          color: NewAppColor.textStrong,
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final isActive = _member.memberStatus == 'active';
    final positionLabel = _getPositionMainDisplay(_member.positionMain);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: NewAppColor.borderHair),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 22.h),
      child: Column(
        children: [
          _buildProfileImage(),
          SizedBox(height: 14.h),
          Text(
            _member.name,
            style: TextStyle(
              color: NewAppColor.textStrong,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'Pretendard',
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            alignment: WrapAlignment.center,
            children: [
              // 상태 칩
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isActive
                      ? NewAppColor.successBg
                      : NewAppColor.borderSoft,
                  borderRadius: BorderRadius.circular(999.r),
                ),
                child: Text(
                  isActive ? '활성' : '비활성',
                  style: TextStyle(
                    color: isActive
                        ? NewAppColor.success700
                        : NewAppColor.textMuted,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
              if (positionLabel.isNotEmpty)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: NewAppColor.skyTint,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    positionLabel,
                    style: TextStyle(
                      color: NewAppColor.skyDeep,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              if (_member.district != null && _member.district!.isNotEmpty)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: NewAppColor.borderSoft,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    _member.district!,
                    style: TextStyle(
                      color: NewAppColor.textSecondary,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_member.profilePhotoUrl != null &&
        _member.profilePhotoUrl!.isNotEmpty) {
      return Container(
        width: 88.w,
        height: 88.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: NewAppColor.borderHair, width: 1),
        ),
        child: ClipOval(
          child: Image.network(
            _member.profilePhotoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildDefaultAvatar(),
          ),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 88.w,
      height: 88.w,
      decoration: BoxDecoration(
        color: NewAppColor.skyTint,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _member.name.isNotEmpty ? _member.name[0] : '?',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.w700,
            color: NewAppColor.skyDeep,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('기본 정보'),
          if (_member.nameEng != null && _member.nameEng!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.caseSensitive,
              label: '영문명',
              value: _member.nameEng!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.email != null && _member.email!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.mail,
              label: '이메일',
              value: _member.email!,
              onTap: _sendEmail,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.phone.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.phone,
              label: '전화번호',
              value: _member.phone,
              onTap: _makePhoneCall,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.birthdate != null) ...[
            _buildInfoRow(
              icon: LucideIcons.cake,
              label: '생년월일',
              value:
                  '${_member.birthdate!.year}.${_member.birthdate!.month.toString().padLeft(2, '0')}.${_member.birthdate!.day.toString().padLeft(2, '0')}${_member.birthdateType != null && _member.birthdateType!.isNotEmpty ? ' (${_member.birthdateType == 'lunar' ? '음력' : '양력'})' : ''}',
            ),
            SizedBox(height: 12.h),
          ],
          _buildInfoRow(
            icon: LucideIcons.user,
            label: '성별',
            value: _getGenderDisplay(_member.gender),
          ),
          if (_member.address != null && _member.address!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: LucideIcons.mapPin,
              label: '주소',
              value: _member.address!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalFamilyInfoSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('개인 및 가족 정보'),
          if (_member.maritalStatus != null &&
              _member.maritalStatus!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.heart,
              label: '결혼 상태',
              value: _member.maritalStatus!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.spouseName != null && _member.spouseName!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.users,
              label: '배우자 이름',
              value: _member.spouseName!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.marriedOn != null) ...[
            _buildInfoRow(
              icon: LucideIcons.partyPopper,
              label: '결혼일',
              value:
                  '${_member.marriedOn!.year}.${_member.marriedOn!.month.toString().padLeft(2, '0')}.${_member.marriedOn!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          // 자녀 정보 표시
          if (_member.children != null && _member.children!.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: NewAppColor.borderSoft,
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.baby,
                    size: 16.sp,
                    color: NewAppColor.textTertiary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '자녀',
                        style: TextStyle(
                          color: NewAppColor.textMuted,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      SizedBox(height: 3.h),
                      ...(_member.children!).asMap().entries.map((entry) {
                        final index = entry.key;
                        final child = entry.value;
                        final name = child['name'] ?? '';
                        final gender = child['gender'] ?? '';
                        final birthdate = child['birthdate'];

                        String childInfo = '${index + 1}. $name';
                        if (gender.isNotEmpty) {
                          childInfo += ' ($gender)';
                        }
                        if (birthdate != null &&
                            birthdate is String &&
                            birthdate.isNotEmpty) {
                          childInfo += ' · $birthdate';
                        }

                        return Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(
                            childInfo,
                            style: TextStyle(
                              color: NewAppColor.textStrong,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                              height: 1.4,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChurchInfoSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('교회 정보'),
          if (_member.positionMain != null &&
              _member.positionMain!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.star,
              label: '주 직분',
              value: _getPositionMainDisplay(_member.positionMain),
            ),
            SizedBox(height: 12.h),
          ],
          // 주 직분이 교역자, 장로, 권사, 집사, 교회학교인 경우 세부 직분 표시
          if (_member.positionMain != null &&
              _member.positionMain!.isNotEmpty &&
              ['CLERGY', 'ELDER', 'DEACONESS', 'DEACON', 'CHURCH_SCHOOL']
                  .contains(_member.positionMain) &&
              _member.positionDetail != null &&
              _member.positionDetail!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.info,
              label: '세부 직분',
              value: _getPositionDetailDisplay(_member.positionDetail),
            ),
            SizedBox(height: 12.h),
          ],
          if (_organizationName != null && _organizationName!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.building2,
              label: '조직',
              value: _organizationName!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.department != null && _member.department!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.users,
              label: '부서',
              value: _member.department!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.appointedOn != null) ...[
            _buildInfoRow(
              icon: LucideIcons.calendar,
              label: '임명일',
              value:
                  '${_member.appointedOn!.year}.${_member.appointedOn!.month.toString().padLeft(2, '0')}.${_member.appointedOn!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.ordinationChurch != null &&
              _member.ordinationChurch!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.church,
              label: '안수교회',
              value: _member.ordinationChurch!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChurchInfoExtendedSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('교회 정보 확장'),
          if (_member.memberType != null && _member.memberType!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.badge,
              label: '교인 구분',
              value: _member.memberType!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.confirmationDate != null) ...[
            _buildInfoRow(
              icon: LucideIcons.badgeCheck,
              label: '입교일',
              value:
                  '${_member.confirmationDate!.year}.${_member.confirmationDate!.month.toString().padLeft(2, '0')}.${_member.confirmationDate!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.baptismDate != null) ...[
            _buildInfoRow(
              icon: LucideIcons.droplet,
              label: '세례일',
              value:
                  '${_member.baptismDate!.year}.${_member.baptismDate!.month.toString().padLeft(2, '0')}.${_member.baptismDate!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.baptismChurch != null &&
              _member.baptismChurch!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.church,
              label: '세례교회',
              value: _member.baptismChurch!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobInfoSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('직업 정보'),
          if (_member.jobCategory != null &&
              _member.jobCategory!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.layoutGrid,
              label: '직업분류',
              value: _member.jobCategory!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.jobDetail != null && _member.jobDetail!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.briefcase,
              label: '구체적 업무',
              value: _member.jobDetail!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.jobPosition != null &&
              _member.jobPosition!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.badge,
              label: '직책/직위',
              value: _member.jobPosition!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.jobTitle != null && _member.jobTitle!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.briefcase,
              label: '직함',
              value: _member.jobTitle!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.workplace != null && _member.workplace!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.building,
              label: '직장',
              value: _member.workplace!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.workplacePhone != null &&
              _member.workplacePhone!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.phoneCall,
              label: '직장 전화번호',
              value: _member.workplacePhone!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinistryInfoExtendedSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('사역 정보 확장'),
          if (_member.ministryStartDate != null) ...[
            _buildInfoRow(
              icon: LucideIcons.calendarDays,
              label: '사역 시작일',
              value:
                  '${_member.ministryStartDate!.year}.${_member.ministryStartDate!.month.toString().padLeft(2, '0')}.${_member.ministryStartDate!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.neighboringChurch != null &&
              _member.neighboringChurch!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.building,
              label: '이웃교회',
              value: _member.neighboringChurch!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.positionDecision != null &&
              _member.positionDecision!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.clipboardList,
              label: '직분 결정',
              value: _member.positionDecision!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.inviter3MemberId != null) ...[
            _buildInfoRow(
              icon: LucideIcons.userPlus,
              label: '인도자',
              value: _member.inviter3MemberId.toString(),
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.dailyActivity != null &&
              _member.dailyActivity!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.clock,
              label: '일상 활동',
              value: _member.dailyActivity!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomFieldsSection() {
    final fields = <MapEntry<int, String>>[];

    if (_member.customField1 != null && _member.customField1!.isNotEmpty) {
      fields.add(MapEntry(1, _member.customField1!));
    }
    if (_member.customField2 != null && _member.customField2!.isNotEmpty) {
      fields.add(MapEntry(2, _member.customField2!));
    }
    if (_member.customField3 != null && _member.customField3!.isNotEmpty) {
      fields.add(MapEntry(3, _member.customField3!));
    }
    if (_member.customField4 != null && _member.customField4!.isNotEmpty) {
      fields.add(MapEntry(4, _member.customField4!));
    }
    if (_member.customField5 != null && _member.customField5!.isNotEmpty) {
      fields.add(MapEntry(5, _member.customField5!));
    }
    if (_member.customField6 != null && _member.customField6!.isNotEmpty) {
      fields.add(MapEntry(6, _member.customField6!));
    }
    if (_member.customField7 != null && _member.customField7!.isNotEmpty) {
      fields.add(MapEntry(7, _member.customField7!));
    }
    if (_member.customField8 != null && _member.customField8!.isNotEmpty) {
      fields.add(MapEntry(8, _member.customField8!));
    }
    if (_member.customField9 != null && _member.customField9!.isNotEmpty) {
      fields.add(MapEntry(9, _member.customField9!));
    }
    if (_member.customField10 != null && _member.customField10!.isNotEmpty) {
      fields.add(MapEntry(10, _member.customField10!));
    }
    if (_member.customField11 != null && _member.customField11!.isNotEmpty) {
      fields.add(MapEntry(11, _member.customField11!));
    }
    if (_member.customField12 != null && _member.customField12!.isNotEmpty) {
      fields.add(MapEntry(12, _member.customField12!));
    }

    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('커스텀 필드'),
          ...fields.map((entry) {
            final isLast = entry == fields.last;
            return Column(
              children: [
                _buildInfoRow(
                  icon: LucideIcons.tag,
                  label: '필드 ${entry.key}',
                  value: entry.value,
                ),
                if (!isLast) SizedBox(height: 12.h),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('추가 정보'),
          if (_member.specialNotes != null &&
              _member.specialNotes!.isNotEmpty) ...[
            _buildInfoRow(
              icon: LucideIcons.stickyNote,
              label: '특별 사항',
              value: _member.specialNotes!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemInfoSection() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('시스템 정보'),
          if (_member.createdAt != null) ...[
            _buildInfoRow(
              icon: LucideIcons.clock,
              label: '생성일시',
              value:
                  '${_member.createdAt!.year}.${_member.createdAt!.month.toString().padLeft(2, '0')}.${_member.createdAt!.day.toString().padLeft(2, '0')} ${_member.createdAt!.hour.toString().padLeft(2, '0')}:${_member.createdAt!.minute.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.updatedAt != null) ...[
            _buildInfoRow(
              icon: LucideIcons.refreshCw,
              label: '수정일시',
              value:
                  '${_member.updatedAt!.year}.${_member.updatedAt!.month.toString().padLeft(2, '0')}.${_member.updatedAt!.day.toString().padLeft(2, '0')} ${_member.updatedAt!.hour.toString().padLeft(2, '0')}:${_member.updatedAt!.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ],
      ),
    );
  }

  bool _hasChurchInfoExtended() {
    return (_member.memberType != null && _member.memberType!.isNotEmpty) ||
        _member.confirmationDate != null ||
        _member.baptismDate != null ||
        (_member.baptismChurch != null && _member.baptismChurch!.isNotEmpty);
  }

  bool _hasJobInfo() {
    return (_member.jobCategory != null && _member.jobCategory!.isNotEmpty) ||
        (_member.jobDetail != null && _member.jobDetail!.isNotEmpty) ||
        (_member.jobPosition != null && _member.jobPosition!.isNotEmpty) ||
        (_member.jobTitle != null && _member.jobTitle!.isNotEmpty) ||
        (_member.workplace != null && _member.workplace!.isNotEmpty) ||
        (_member.workplacePhone != null && _member.workplacePhone!.isNotEmpty);
  }

  bool _hasMinistryInfoExtended() {
    return _member.ministryStartDate != null ||
        (_member.neighboringChurch != null &&
            _member.neighboringChurch!.isNotEmpty) ||
        (_member.positionDecision != null &&
            _member.positionDecision!.isNotEmpty) ||
        _member.inviter3MemberId != null ||
        (_member.dailyActivity != null && _member.dailyActivity!.isNotEmpty);
  }

  bool _hasCustomFields() {
    return (_member.customField1 != null && _member.customField1!.isNotEmpty) ||
        (_member.customField2 != null && _member.customField2!.isNotEmpty) ||
        (_member.customField3 != null && _member.customField3!.isNotEmpty) ||
        (_member.customField4 != null && _member.customField4!.isNotEmpty) ||
        (_member.customField5 != null && _member.customField5!.isNotEmpty) ||
        (_member.customField6 != null && _member.customField6!.isNotEmpty) ||
        (_member.customField7 != null && _member.customField7!.isNotEmpty) ||
        (_member.customField8 != null && _member.customField8!.isNotEmpty) ||
        (_member.customField9 != null && _member.customField9!.isNotEmpty) ||
        (_member.customField10 != null &&
            _member.customField10!.isNotEmpty) ||
        (_member.customField11 != null &&
            _member.customField11!.isNotEmpty) ||
        (_member.customField12 != null && _member.customField12!.isNotEmpty);
  }

  bool _hasAdditionalInfo() {
    return _member.specialNotes != null && _member.specialNotes!.isNotEmpty;
  }

  bool _hasSystemInfo() {
    return _member.createdAt != null || _member.updatedAt != null;
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color: NewAppColor.borderSoft,
              borderRadius: BorderRadius.circular(9.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 16.sp,
              color: NewAppColor.textTertiary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: NewAppColor.textMuted,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  value,
                  style: TextStyle(
                    color: NewAppColor.textStrong,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            SizedBox(width: 8.w),
            Icon(
              LucideIcons.chevronRight,
              size: 16.sp,
              color: NewAppColor.textTertiary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    final isActive = _member.memberStatus == 'active';
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('관리 작업'),
          GestureDetector(
            onTap: _toggleMemberStatus,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: NewAppColor.borderSoft,
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isActive
                        ? LucideIcons.circlePause
                        : LucideIcons.circleCheck,
                    size: 16.sp,
                    color: NewAppColor.textSecondary,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    isActive ? '비활성화' : '활성화',
                    style: TextStyle(
                      color: NewAppColor.textSecondary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: _deleteMember,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: NewAppColor.dangerBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.trash2,
                      size: 16.sp, color: NewAppColor.danger700),
                  SizedBox(width: 6.w),
                  Text(
                    '교인 삭제',
                    style: TextStyle(
                      color: NewAppColor.danger700,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}