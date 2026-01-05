import 'package:flutter/material.dart' hide IconButton;
import 'package:flutter/material.dart' as material show IconButton;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../components/index.dart';
import '../../components/admin/status_badge.dart';
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

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '상태 변경',
        content: Text(
            '${_member.name}님의 상태를 ${newStatus == 'active' ? '활성' : '비활성'}으로 변경하시겠습니까?'),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performStatusUpdate(newStatus);
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
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
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '교인 삭제',
        content: Text('${_member.name}님의 정보를 삭제하시겠습니까?\n\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete();
            },
            variant: ButtonVariant.destructive,
            child: const Text('삭제'),
          ),
        ],
      ),
    );
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
      backgroundColor: NewAppColor.neutral100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: material.IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '교인 상세',
          style: const FigmaTextStyles().title2.copyWith(
            color: NewAppColor.neutral900,
          ),
        ),
        actions: [
          material.IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: _navigateToEdit,
          ),
          material.IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadMember,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 섹션
                  _buildProfileSection(),
                  SizedBox(height: 16.h),
                  // 기본 정보 섹션
                  _buildBasicInfoSection(),
                  SizedBox(height: 16.h),
                  // 개인 및 가족 정보 섹션
                  _buildPersonalFamilyInfoSection(),
                  SizedBox(height: 16.h),
                  // 교회 정보 섹션
                  _buildChurchInfoSection(),
                  // 교회 정보 확장 섹션 (있는 경우만)
                  if (_hasChurchInfoExtended()) ...[
                    SizedBox(height: 16.h),
                    _buildChurchInfoExtendedSection(),
                  ],
                  // 직업 정보 섹션 (있는 경우만)
                  if (_hasJobInfo()) ...[
                    SizedBox(height: 16.h),
                    _buildJobInfoSection(),
                  ],
                  // 사역 정보 확장 섹션 (있는 경우만)
                  if (_hasMinistryInfoExtended()) ...[
                    SizedBox(height: 16.h),
                    _buildMinistryInfoExtendedSection(),
                  ],
                  // 자유필드 섹션 (있는 경우만)
                  if (_hasCustomFields()) ...[
                    SizedBox(height: 16.h),
                    _buildCustomFieldsSection(),
                  ],
                  // 추가 정보 섹션 (있는 경우만)
                  if (_hasAdditionalInfo()) ...[
                    SizedBox(height: 16.h),
                    _buildAdditionalInfoSection(),
                  ],
                  // 시스템 정보 섹션
                  if (_hasSystemInfo()) ...[
                    SizedBox(height: 16.h),
                    _buildSystemInfoSection(),
                  ],
                  SizedBox(height: 16.h),
                  // 관리 액션 섹션
                  _buildActionSection(),
                  SizedBox(height: 32.h),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      color: Colors.white,
      child: Column(
        children: [
          // 프로필 사진
          _buildProfileImage(),
          SizedBox(height: 16.h),
          // 이름
          Text(
            _member.name,
            style: const FigmaTextStyles().title1.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 8.h),
          // 상태 뱃지
          StatusBadge(
            status: _member.memberStatus == 'active' ? 'active' : 'inactive',
            label: _member.memberStatus == 'active' ? '활성' : '비활성',
          ),
          if (_member.district != null && _member.district!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              _member.district!,
              style: const FigmaTextStyles().body2.copyWith(
                color: NewAppColor.primary600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_member.profilePhotoUrl != null &&
        _member.profilePhotoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100.r),
        child: Image.network(
          _member.profilePhotoUrl!,
          width: 80.w,
          height: 80.h,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 80.w,
      height: 80.h,
      decoration: BoxDecoration(
        color: NewAppColor.primary200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _member.name.isNotEmpty ? _member.name[0] : '?',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.w600,
            color: NewAppColor.primary600,
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 정보',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          if (_member.nameEng != null && _member.nameEng!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.abc,
              label: '영문명',
              value: _member.nameEng!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.email != null && _member.email!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: '이메일',
              value: _member.email!,
              onTap: _sendEmail,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.phone.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: '전화번호',
              value: _member.phone,
              onTap: _makePhoneCall,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.birthdate != null) ...[
            _buildInfoRow(
              icon: Icons.cake_outlined,
              label: '생년월일',
              value:
                  '${_member.birthdate!.year}.${_member.birthdate!.month.toString().padLeft(2, '0')}.${_member.birthdate!.day.toString().padLeft(2, '0')}${_member.birthdateType != null && _member.birthdateType!.isNotEmpty ? ' (${_member.birthdateType == 'lunar' ? '음력' : '양력'})' : ''}',
            ),
            SizedBox(height: 12.h),
          ],
          _buildInfoRow(
            icon: Icons.person_outline,
            label: '성별',
            value: _getGenderDisplay(_member.gender),
          ),
          if (_member.address != null && _member.address!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: '주소',
              value: _member.address!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPersonalFamilyInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '개인 및 가족 정보',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          if (_member.maritalStatus != null &&
              _member.maritalStatus!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.favorite_outline,
              label: '결혼 상태',
              value: _member.maritalStatus!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.spouseName != null && _member.spouseName!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.people_outline,
              label: '배우자 이름',
              value: _member.spouseName!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.marriedOn != null) ...[
            _buildInfoRow(
              icon: Icons.celebration_outlined,
              label: '결혼일',
              value:
                  '${_member.marriedOn!.year}.${_member.marriedOn!.month.toString().padLeft(2, '0')}.${_member.marriedOn!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          // 자녀 정보 표시
          if (_member.children != null && _member.children!.isNotEmpty) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        color: NewAppColor.neutral100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.child_care_outlined,
                        size: 18.sp,
                        color: NewAppColor.neutral700,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '자녀',
                      style: const FigmaTextStyles().caption1.copyWith(
                        color: NewAppColor.neutral600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
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
                  if (birthdate != null && birthdate is String && birthdate.isNotEmpty) {
                    childInfo += ' - $birthdate';
                  }

                  return Padding(
                    padding: EdgeInsets.only(left: 44.w, bottom: 4.h),
                    child: Text(
                      childInfo,
                      style: const FigmaTextStyles().body1.copyWith(
                        color: NewAppColor.neutral900,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChurchInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '교회 정보',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          if (_member.positionMain != null &&
              _member.positionMain!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.star_outline,
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
              icon: Icons.info_outline,
              label: '세부 직분',
              value: _getPositionDetailDisplay(_member.positionDetail),
            ),
            SizedBox(height: 12.h),
          ],
          if (_organizationName != null && _organizationName!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.corporate_fare_outlined,
              label: '조직',
              value: _organizationName!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.department != null && _member.department!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.group_outlined,
              label: '부서',
              value: _member.department!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.appointedOn != null) ...[
            _buildInfoRow(
              icon: Icons.event_outlined,
              label: '임명일',
              value:
                  '${_member.appointedOn!.year}.${_member.appointedOn!.month.toString().padLeft(2, '0')}.${_member.appointedOn!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.ordinationChurch != null &&
              _member.ordinationChurch!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.church_outlined,
              label: '안수교회',
              value: _member.ordinationChurch!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChurchInfoExtendedSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '교회 정보 확장',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          if (_member.memberType != null && _member.memberType!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: '교인 구분',
              value: _member.memberType!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.confirmationDate != null) ...[
            _buildInfoRow(
              icon: Icons.verified_outlined,
              label: '입교일',
              value:
                  '${_member.confirmationDate!.year}.${_member.confirmationDate!.month.toString().padLeft(2, '0')}.${_member.confirmationDate!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.baptismDate != null) ...[
            _buildInfoRow(
              icon: Icons.water_drop_outlined,
              label: '세례일',
              value:
                  '${_member.baptismDate!.year}.${_member.baptismDate!.month.toString().padLeft(2, '0')}.${_member.baptismDate!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.baptismChurch != null &&
              _member.baptismChurch!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.church_outlined,
              label: '세례교회',
              value: _member.baptismChurch!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '직업 정보',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          if (_member.jobCategory != null &&
              _member.jobCategory!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.category_outlined,
              label: '직업분류',
              value: _member.jobCategory!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.jobDetail != null && _member.jobDetail!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.business_center_outlined,
              label: '구체적 업무',
              value: _member.jobDetail!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.jobPosition != null &&
              _member.jobPosition!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.badge_outlined,
              label: '직책/직위',
              value: _member.jobPosition!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.jobTitle != null && _member.jobTitle!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.work_outline,
              label: '직함',
              value: _member.jobTitle!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.workplace != null && _member.workplace!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.apartment_outlined,
              label: '직장',
              value: _member.workplace!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.workplacePhone != null &&
              _member.workplacePhone!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.phone_in_talk_outlined,
              label: '직장 전화번호',
              value: _member.workplacePhone!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinistryInfoExtendedSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사역 정보 확장',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          if (_member.ministryStartDate != null) ...[
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: '사역 시작일',
              value:
                  '${_member.ministryStartDate!.year}.${_member.ministryStartDate!.month.toString().padLeft(2, '0')}.${_member.ministryStartDate!.day.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.neighboringChurch != null &&
              _member.neighboringChurch!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.location_city_outlined,
              label: '이웃교회',
              value: _member.neighboringChurch!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.positionDecision != null &&
              _member.positionDecision!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.assignment_outlined,
              label: '직분 결정',
              value: _member.positionDecision!,
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.inviter3MemberId != null) ...[
            _buildInfoRow(
              icon: Icons.person_add_outlined,
              label: '인도자',
              value: _member.inviter3MemberId.toString(),
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.dailyActivity != null &&
              _member.dailyActivity!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.schedule_outlined,
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '커스텀 필드',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          ...fields.map((entry) {
            final isLast = entry == fields.last;
            return Column(
              children: [
                _buildInfoRow(
                  icon: Icons.label_outline,
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추가 정보',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          if (_member.specialNotes != null &&
              _member.specialNotes!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.notes_outlined,
              label: '특별 사항',
              value: _member.specialNotes!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemInfoSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '시스템 정보',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          if (_member.createdAt != null) ...[
            _buildInfoRow(
              icon: Icons.access_time_outlined,
              label: '생성일시',
              value:
                  '${_member.createdAt!.year}.${_member.createdAt!.month.toString().padLeft(2, '0')}.${_member.createdAt!.day.toString().padLeft(2, '0')} ${_member.createdAt!.hour.toString().padLeft(2, '0')}:${_member.createdAt!.minute.toString().padLeft(2, '0')}',
            ),
            SizedBox(height: 12.h),
          ],
          if (_member.updatedAt != null) ...[
            _buildInfoRow(
              icon: Icons.update_outlined,
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
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: NewAppColor.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18.sp,
                color: NewAppColor.neutral700,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const FigmaTextStyles().caption1.copyWith(
                      color: NewAppColor.neutral600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    value,
                    style: const FigmaTextStyles().body1.copyWith(
                      color: NewAppColor.neutral900,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: NewAppColor.neutral400,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '관리 작업',
            style: const FigmaTextStyles().title3.copyWith(
              color: NewAppColor.neutral900,
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: _toggleMemberStatus,
              variant: ButtonVariant.secondary,
              child: Text(
                _member.memberStatus == 'active' ? '비활성화' : '활성화',
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: _deleteMember,
              variant: ButtonVariant.destructive,
              child: const Text('교인 삭제'),
            ),
          ),
        ],
      ),
    );
  }
}