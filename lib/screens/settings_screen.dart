import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../components/index.dart' hide IconButton;
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';
import '../services/font_settings_service.dart';
import '../services/church_service.dart';
import '../services/bug_report_service.dart';
import '../services/member_service.dart';
import '../models/church.dart';
import '../models/user.dart';
import '../models/member.dart';
import '../utils/admin_permission_utils.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'profile_edit_screen.dart';
import 'member_info_edit_screen.dart';
import 'settings/profile_image_setup_screen.dart';

class _GroupedSettingItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _GroupedSettingItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final ChurchService _churchService = ChurchService();
  final BugReportService _bugReportService = BugReportService();
  final MemberService _memberService = MemberService();

  // 설정 값들
  bool _pushNotifications = true;
  bool _churchNotices = true;

  // 현재 사용자
  User? _currentUser;
  Member? _currentMember;
  Church? _currentChurch;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Provider를 통해 현재 글꼴 크기 가져오기
    });
  }

  Future<void> _loadCurrentUser() async {
    final userResponse = await _authService.getCurrentUser();
    if (userResponse.success && userResponse.data != null) {
      setState(() {
        _currentUser = userResponse.data;
      });

      // member 정보도 가져오기
      if (_currentUser?.id != null) {
        final memberResponse = await _memberService.getMemberByUserId(_currentUser!.id);
        if (memberResponse.success && memberResponse.data != null) {
          setState(() {
            _currentMember = memberResponse.data;
          });
        }
      }

      // 1.2.0: 프로필 카드 부제용 교회명 조회
      final churchResponse = await _churchService.getMyChurch();
      if (mounted &&
          churchResponse.success &&
          churchResponse.data != null) {
        setState(() {
          _currentChurch = churchResponse.data;
        });
      }
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
        automaticallyImplyLeading: _currentUser?.isCommunityAdmin != true,
        leading: _currentUser?.isCommunityAdmin == true
            ? null
            : IconButton(
                icon: Icon(Icons.chevron_left,
                    color: NewAppColor.textStrong, size: 24.sp),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          '마이페이지',
          style: FigmaTextStyles().subtitle1.copyWith(
                color: NewAppColor.textStrong,
                fontSize: 17.sp,
              ),
        ),
        shape: Border(
          bottom: BorderSide(color: NewAppColor.borderSoft, width: 1),
        ),
      ),
      body: Column(
        children: [
          // 메인 콘텐츠
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              children: [
                // 1.2.0 C 방향: 프로필 카드
                _buildProfileCard(),
                // 계정 섹션
                _buildGroupedSection(
                  title: '계정',
                  items: [
                    _GroupedSettingItem(
                      icon: Icons.person_outline,
                      title: '개인정보 수정',
                      subtitle: '생년월일, 전화번호, 주소, 직업 등',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MemberInfoEditScreen(),
                        ),
                      ),
                    ),
                    _GroupedSettingItem(
                      icon: Icons.photo_camera_outlined,
                      title: '프로필 이미지',
                      subtitle: '커뮤니티용 프로필 이미지 설정',
                      onTap: _showProfileImageSetup,
                    ),
                    _GroupedSettingItem(
                      icon: Icons.lock_outline,
                      title: '비밀번호 변경',
                      subtitle: '로그인 비밀번호 변경',
                      onTap: _changePassword,
                    ),
                  ],
                ),

                // 관리자 메뉴 섹션 (church_admin, system_admin, church_super_admin만 표시)
                if (_currentUser?.isChurchAdmin == true)
                  _buildAdminMenuSection(),

                SizedBox(height: 16.h),

                // 앱 설정 섹션 — 글꼴 크기 3분할 세그먼트
                Consumer<FontSettingsService>(
                  builder: (context, fontSettings, child) {
                    return _buildFontSizeSection(fontSettings);
                  },
                ),

                SizedBox(height: 16.h),

                // 알림 설정 섹션
                _buildGroupedSection(
                  title: '알림 설정',
                  items: [
                    _GroupedSettingItem(
                      icon: Icons.notifications_outlined,
                      title: '푸시 알림',
                      subtitle: '모든 푸시 알림 수신',
                      trailing: AppSwitch(
                        value: _pushNotifications,
                        onChanged: (value) =>
                            setState(() => _pushNotifications = value),
                      ),
                    ),
                    // 커뮤니티 회원은 교회 공지 알림 메뉴 제외
                    if (_currentUser?.isCommunityAdmin != true)
                      _GroupedSettingItem(
                        icon: Icons.campaign_outlined,
                        title: '교회 공지',
                        subtitle: '새로운 공지사항 알림',
                        trailing: AppSwitch(
                          value: _churchNotices,
                          onChanged: (value) =>
                              setState(() => _churchNotices = value),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 16.h),

                // 도움말 및 지원
                _buildGroupedSection(
                  title: '도움말 및 지원',
                  items: [
                    _GroupedSettingItem(
                      icon: Icons.bug_report_outlined,
                      title: '문제 신고',
                      onTap: _reportBug,
                    ),
                    _GroupedSettingItem(
                      icon: Icons.privacy_tip_outlined,
                      title: '개인정보처리방침',
                      onTap: _showPrivacyPolicy,
                    ),
                    _GroupedSettingItem(
                      icon: Icons.description_outlined,
                      title: '서비스 이용약관',
                      onTap: _showTermsOfService,
                    ),
                  ],
                ),

                // 로그아웃 — danger 톤 보더 버튼
                _buildLogoutButton(),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1.2.0 C 방향: 프로필 카드 (큰 이니셜 아바타 + 이름 + 직분 칩 + 교회/부서)
  Widget _buildProfileCard() {
    final name = _currentMember?.name ?? _currentUser?.fullName ?? '사용자';
    final initial = name.isNotEmpty ? name[0] : '?';
    final position = _currentMember?.positionLabel ?? '';
    final churchName = _currentChurch?.name ?? '';
    final department = _currentMember?.department ?? '';
    final isChurchAdmin = _currentUser?.isChurchAdmin == true;

    // 1.2.0: AppBar 하단과 명확히 분리되도록 상하 여백 확보 + 좌우는 ListView 패딩 활용
    return Padding(
      padding: EdgeInsets.only(top: 18.h, bottom: 6.h),
      child: Row(
        children: [
          // 큰 이니셜 아바타 64×64 skyTint
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: NewAppColor.skyTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: (_currentMember?.fullProfilePhotoUrl != null &&
                    _currentMember!.fullProfilePhotoUrl!.isNotEmpty)
                ? ClipOval(
                    child: Image.network(
                      _currentMember!.fullProfilePhotoUrl!,
                      width: 64.w,
                      height: 64.w,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        initial,
                        style: TextStyle(
                          color: NewAppColor.skyDeep,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  )
                : Text(
                    initial,
                    style: TextStyle(
                      color: NewAppColor.skyDeep,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Pretendard',
                    ),
                  ),
          ),
          SizedBox(width: 15.w),
          // 이름 + 직분/관리자 칩 + 교회·부서
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: NewAppColor.textStrong,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Pretendard',
                          letterSpacing: -0.36,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    // 교회 관리자면 shield 칩, 아니면 직분 칩
                    if (isChurchAdmin)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 9.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: NewAppColor.skyPrimary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.shield,
                                color: Colors.white, size: 12.sp),
                            SizedBox(width: 3.w),
                            Text(
                              '교회 관리자',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Pretendard',
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (position.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 9.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: NewAppColor.skyTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          position,
                          style: TextStyle(
                            color: NewAppColor.skyDeep,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                  ],
                ),
                if (churchName.isNotEmpty || department.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    [
                      if (churchName.isNotEmpty) churchName,
                      if (department.isNotEmpty) department,
                    ].join(' · '),
                    style: TextStyle(
                      color: NewAppColor.textTertiary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1.2.0 C 방향: 글꼴 크기 — 3분할 세그먼트 (작게/보통/크게)
  Widget _buildFontSizeSection(FontSettingsService fontSettings) {
    const sizes = ['작게', '보통', '크게'];
    final current = fontSettings.fontSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Padding(
          padding: EdgeInsets.only(left: 6.w, bottom: 8.h, top: 22.h),
          child: Text(
            '앱 설정',
            style: FigmaTextStyles().sectionHeader.copyWith(
                  color: NewAppColor.textTertiary,
                ),
          ),
        ),
        // 카드
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: NewAppColor.borderHair, width: 1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 아이콘 + 라벨
              Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: NewAppColor.borderSoft,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.text_fields_outlined,
                      size: 17.sp,
                      color: NewAppColor.textMuted,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '글꼴 크기',
                    style: TextStyle(
                      color: NewAppColor.textStrong,
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 13.h),
              // 3분할 세그먼트
              Row(
                children: List.generate(sizes.length, (i) {
                  final label = sizes[i];
                  final isSelected = current == label;
                  // 글꼴 크기에 따라 미리보기 폰트 사이즈도 차등
                  final previewSize = label == '작게'
                      ? 13.sp
                      : label == '보통'
                          ? 14.sp
                          : 15.sp;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: i < sizes.length - 1 ? 8.w : 0),
                      child: GestureDetector(
                        onTap: () => fontSettings.setFontSize(label),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 9.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? NewAppColor.skyPrimary
                                : NewAppColor.borderSoft,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : NewAppColor.textMuted,
                              fontSize: previewSize,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontFamily: 'Pretendard',
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 1.2.0 C 방향: 로그아웃 — danger 톤 보더 박스 버튼 (목업 §79)
  Widget _buildLogoutButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 6.w, bottom: 8.h, top: 22.h),
          child: Text(
            '계정 관리',
            style: FigmaTextStyles().sectionHeader.copyWith(
                  color: NewAppColor.textTertiary,
                ),
          ),
        ),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13.r),
          child: InkWell(
            onTap: _logout,
            borderRadius: BorderRadius.circular(13.r),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                    color: NewAppColor.dangerBorder, width: 1),
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    color: NewAppColor.danger700,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '로그아웃',
                    style: TextStyle(
                      color: NewAppColor.danger700,
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 1.2.0 C 방향: 관리자 메뉴 섹션 (skyDeep 라벨 + '관리자 전용' 칩 + skyTint 상하 강조 보더)
  Widget _buildAdminMenuSection() {
    // TODO: 실제 대기 건수는 API로 가져오기. 현재는 모델 단서로 0 표시.
    const int pendingPastoralCount = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더 — skyDeep + '관리자 전용' 칩
        Padding(
          padding: EdgeInsets.only(left: 6.w, bottom: 8.h, top: 22.h),
          child: Row(
            children: [
              Text(
                '관리자 메뉴',
                style: TextStyle(
                  color: NewAppColor.skyDeep,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Pretendard',
                  letterSpacing: 0.36,
                ),
              ),
              SizedBox(width: 7.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: NewAppColor.skyPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '관리자 전용',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ],
          ),
        ),
        // 그룹 컨테이너 — 상하 1.5px skyTint 보더로 강조 (목업 §109)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(width: 1.5, color: NewAppColor.skyTint),
              bottom: BorderSide(width: 1.5, color: NewAppColor.skyTint),
            ),
            borderRadius: BorderRadius.circular(14.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _buildGroupedSettingItem(
                item: _GroupedSettingItem(
                  icon: Icons.people_outline,
                  title: '교인 관리',
                  subtitle: '교인 목록 · 정보 수정 · 상태 관리',
                  onTap: () =>
                      Navigator.pushNamed(context, '/admin/members'),
                ),
                isFirst: true,
                isLast: false,
              ),
              _buildGroupedSettingItem(
                item: _GroupedSettingItem(
                  icon: Icons.favorite_outline,
                  title: '심방 신청 관리',
                  subtitle: '신청 목록 · 상태 변경 · 담당자 지정',
                  onTap: () =>
                      Navigator.pushNamed(context, '/admin/pastoral-care'),
                  trailing: pendingPastoralCount > 0
                      ? Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 1.h),
                          constraints: BoxConstraints(
                            minWidth: 20.w,
                            minHeight: 20.h,
                          ),
                          decoration: BoxDecoration(
                            color: NewAppColor.danger700,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$pendingPastoralCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        )
                      : null,
                ),
                isFirst: false,
                isLast: false,
              ),
              _buildGroupedSettingItem(
                item: _GroupedSettingItem(
                  icon: Icons.announcement_outlined,
                  title: '공지사항 관리',
                  subtitle: '공지 작성 · 수정 · 삭제',
                  onTap: () =>
                      Navigator.pushNamed(context, '/admin/notices'),
                ),
                isFirst: false,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 1.2.0 그룹 섹션
  Widget _buildGroupedSection({
    required String title,
    required List<_GroupedSettingItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더 — 12sp/700 textTertiary letter-spacing .03em
        Padding(
          padding: EdgeInsets.only(left: 6.w, bottom: 8.h, top: 22.h),
          child: Text(
            title,
            style: FigmaTextStyles().sectionHeader.copyWith(
                  color: NewAppColor.textTertiary,
                ),
          ),
        ),
        // 그룹화된 컨테이너
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: NewAppColor.borderHair, width: 1),
            borderRadius: BorderRadius.circular(14.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isFirst = index == 0;
              final isLast = index == items.length - 1;

              return _buildGroupedSettingItem(
                item: item,
                isFirst: isFirst,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 1.2.0 설정 아이템 행 (라운드 11 skyTint 아이콘 타일 + chevron)
  Widget _buildGroupedSettingItem({
    required _GroupedSettingItem item,
    required bool isFirst,
    required bool isLast,
  }) {
    return InkWell(
      onTap: item.onTap,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 58.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: !isLast
              ? Border(
                  bottom: BorderSide(
                    width: 1,
                    color: NewAppColor.borderHair,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // 아이콘 — 라운드 11 skyTint + skyDeep
            Container(
              width: 32.w,
              height: 32.h,
              decoration: BoxDecoration(
                color: NewAppColor.skyTint,
                borderRadius: BorderRadius.circular(10.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.icon,
                size: 17.sp,
                color: NewAppColor.skyDeep,
              ),
            ),
            SizedBox(width: 12.w),
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: NewAppColor.textStrong,
                      fontSize: 14.5.sp,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        color: NewAppColor.textTertiary,
                        fontSize: 12.5.sp,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // 트레일링 영역
            if (item.trailing != null) ...[
              item.trailing!,
              // tap 가능한 항목이면 trailing 옆에 chevron도 표시
              if (item.onTap != null) ...[
                SizedBox(width: 6.w),
                Icon(
                  Icons.chevron_right,
                  size: 18.sp,
                  color: NewAppColor.iconFaint,
                ),
              ],
            ] else
              Icon(
                Icons.chevron_right,
                size: 18.sp,
                color: NewAppColor.iconFaint,
              ),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '비밀번호 변경',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(
              controller: currentPasswordController,
              placeholder: '현재 비밀번호',
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            AppInput(
              controller: newPasswordController,
              placeholder: '새 비밀번호',
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            AppInput(
              controller: confirmPasswordController,
              placeholder: '새 비밀번호 확인',
              obscureText: true,
            ),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () {
              currentPasswordController.dispose();
              newPasswordController.dispose();
              confirmPasswordController.dispose();
              Navigator.pop(context);
            },
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () => _handlePasswordChange(
              currentPasswordController.text,
              newPasswordController.text,
              confirmPasswordController.text,
              currentPasswordController,
              newPasswordController,
              confirmPasswordController,
            ),
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePasswordChange(
    String currentPassword,
    String newPassword,
    String confirmPassword,
    TextEditingController currentController,
    TextEditingController newController,
    TextEditingController confirmController,
  ) async {
    // 입력값 검증
    if (currentPassword.isEmpty) {
      AppToast.show(
        context,
        '현재 비밀번호를 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    if (newPassword.isEmpty) {
      AppToast.show(
        context,
        '새 비밀번호를 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    if (newPassword.length < 6) {
      AppToast.show(
        context,
        '새 비밀번호는 6자 이상이어야 합니다.',
        type: ToastType.error,
      );
      return;
    }

    if (newPassword != confirmPassword) {
      AppToast.show(
        context,
        '새 비밀번호와 확인 비밀번호가 일치하지 않습니다.',
        type: ToastType.error,
      );
      return;
    }

    if (currentPassword == newPassword) {
      AppToast.show(
        context,
        '현재 비밀번호와 새 비밀번호가 동일합니다.',
        type: ToastType.error,
      );
      return;
    }

    // 다이얼로그 닫기
    Navigator.pop(context);

    try {
      // 비밀번호 변경 요청
      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // 컨트롤러 정리
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();

      if (mounted) {
        if (response.success) {
          AppToast.show(
            context,
            '비밀번호가 성공적으로 변경되었습니다.',
            type: ToastType.success,
          );
        } else {
          AppToast.show(
            context,
            response.message.isNotEmpty ? response.message : '비밀번호 변경에 실패했습니다.',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      // 컨트롤러 정리
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();

      if (mounted) {
        AppToast.show(
          context,
          '비밀번호 변경 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _showFontSizeOptions() {
    showDialog(
      context: context,
      builder: (context) => Consumer<FontSettingsService>(
        builder: (context, fontSettings, child) {
          return AppDialog(
            title: '글꼴 크기 설정',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: FontSettingsService.fontSizeOptions.map((option) {
                final isSelected = fontSettings.fontSize == option;
                return GestureDetector(
                  onTap: () async {
                    await fontSettings.setFontSize(option);
                    if (mounted) {
                      Navigator.pop(context);
                      AppToast.show(
                        context,
                        '글꼴 크기가 ${FontSettingsService.getFontSizeDescription(option)}로 변경되었습니다.',
                        type: ToastType.success,
                      );
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    margin: EdgeInsets.only(bottom: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? NewAppColor.primary100
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isSelected
                            ? NewAppColor.primary600
                            : NewAppColor.neutral200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? NewAppColor.primary600
                                      : NewAppColor.neutral900,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                FontSettingsService.getFontSizeDescription(
                                    option),
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isSelected
                                      ? NewAppColor.primary500
                                      : NewAppColor.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: NewAppColor.primary600,
                            size: 24.sp,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            actions: [
              AppButton(
                onPressed: () => Navigator.pop(context),
                variant: ButtonVariant.ghost,
                child: const Text('닫기'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChurchContact() async {
    print('🏛️ SETTINGS: 교회 연락처 정보 조회 시작');

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 교회 정보 가져오기
      final response = await _churchService.getMyChurch();

      if (mounted) {
        // 로딩 다이얼로그 닫기
        Navigator.pop(context);

        if (response.success && response.data != null) {
          final church = response.data!;
          print('🏛️ SETTINGS: 교회 정보 조회 성공 - ${church.name}');

          // 교회 연락처 다이얼로그 표시
          showDialog(
            context: context,
            builder: (context) => AppDialog(
              title: '${church.name} 연락처',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (church.phone != null && church.phone!.isNotEmpty)
                    Text('전화: ${church.phone}',
                        style: TextStyle(fontSize: 14.sp)),
                  if (church.phone != null && church.phone!.isNotEmpty)
                    SizedBox(height: 8.h),
                  if (church.email != null && church.email!.isNotEmpty)
                    Text('이메일: ${church.email}',
                        style: TextStyle(fontSize: 14.sp)),
                  if (church.email != null && church.email!.isNotEmpty)
                    SizedBox(height: 8.h),
                  if (church.pastorName != null &&
                      church.pastorName!.isNotEmpty)
                    Text('담임목사: ${church.pastorName}',
                        style: TextStyle(fontSize: 14.sp)),
                ],
              ),
              actions: [
                AppButton(
                  onPressed: () => Navigator.pop(context),
                  variant: ButtonVariant.ghost,
                  child: const Text('닫기'),
                ),
              ],
            ),
          );
        } else {
          print('❌ SETTINGS: 교회 정보 조회 실패 - ${response.message}');
          AppToast.show(
            context,
            '교회 정보를 불러올 수 없습니다: ${response.message}',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      print('❌ SETTINGS: 교회 연락처 조회 오류: $e');
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        AppToast.show(
          context,
          '교회 연락처 정보를 불러오는데 실패했습니다: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _showChurchLocation() async {
    print('🏛️ SETTINGS: 교회 위치 정보 조회 시작');

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 교회 정보 가져오기
      final response = await _churchService.getMyChurch();

      if (mounted) {
        // 로딩 다이얼로그 닫기
        Navigator.pop(context);

        if (response.success && response.data != null) {
          final church = response.data!;
          print('🏛️ SETTINGS: 교회 위치 정보 조회 성공 - ${church.name}');

          // 교회 위치 다이얼로그 표시
          showDialog(
            context: context,
            builder: (context) => AppDialog(
              title: '${church.name} 위치',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (church.address != null && church.address!.isNotEmpty)
                    Text(
                      '주소: ${church.address}',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  if (church.address != null && church.address!.isNotEmpty)
                    SizedBox(height: 16.h),
                  if (church.phone != null && church.phone!.isNotEmpty)
                    Text(
                      '연락처: ${church.phone}',
                      style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                    ),
                ],
              ),
              actions: [
                AppButton(
                  onPressed: () => Navigator.pop(context),
                  variant: ButtonVariant.ghost,
                  child: const Text('닫기'),
                ),
              ],
            ),
          );
        } else {
          print('❌ SETTINGS: 교회 위치 정보 조회 실패 - ${response.message}');
          AppToast.show(
            context,
            '교회 위치 정보를 불러올 수 없습니다: ${response.message}',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      print('❌ SETTINGS: 교회 위치 조회 오류: $e');
      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        AppToast.show(
          context,
          '교회 위치 정보를 불러오는데 실패했습니다: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _reportBug() {
    final issueTypeController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: '문제 신고',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppInput(
              controller: issueTypeController,
              placeholder: '문제 유형 (예: 로그인 오류, 화면 표시 문제)',
            ),
            SizedBox(height: 16.h),
            AppInput(
              controller: descriptionController,
              placeholder: '문제 설명을 자세히 입력해주세요',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          AppButton(
            onPressed: () {
              issueTypeController.dispose();
              descriptionController.dispose();
              Navigator.pop(context);
            },
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () => _handleBugReport(
              issueTypeController.text,
              descriptionController.text,
              issueTypeController,
              descriptionController,
            ),
            child: const Text('전송'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBugReport(
    String issueType,
    String description,
    TextEditingController issueTypeController,
    TextEditingController descriptionController,
  ) async {
    // 입력값 검증
    if (issueType.trim().isEmpty) {
      AppToast.show(
        context,
        '문제 유형을 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    if (description.trim().isEmpty) {
      AppToast.show(
        context,
        '문제 설명을 입력해주세요.',
        type: ToastType.error,
      );
      return;
    }

    // 사용자 정보 확인
    if (_currentUser == null) {
      AppToast.show(
        context,
        '사용자 정보를 찾을 수 없습니다.',
        type: ToastType.error,
      );
      return;
    }

    // 다이얼로그 닫기
    Navigator.pop(context);

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 문제 신고 제출
      final response = await _bugReportService.submitBugReport(
        userId: _currentUser!.id,
        churchId: _currentUser!.churchId,
        issueType: issueType.trim(),
        description: description.trim(),
      );

      // 컨트롤러 정리
      issueTypeController.dispose();
      descriptionController.dispose();

      if (mounted) {
        // 로딩 다이얼로그 닫기
        Navigator.pop(context);

        if (response.success) {
          AppToast.show(
            context,
            '문제가 성공적으로 신고되었습니다.\n빠른 시일 내에 확인하겠습니다.',
            type: ToastType.success,
          );
        } else {
          AppToast.show(
            context,
            response.message.isNotEmpty ? response.message : '문제 신고에 실패했습니다.',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      // 컨트롤러 정리
      issueTypeController.dispose();
      descriptionController.dispose();

      if (mounted) {
        // 로딩 다이얼로그 닫기
        Navigator.pop(context);

        AppToast.show(
          context,
          '문제 신고 중 오류가 발생했습니다: $e',
          type: ToastType.error,
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TermsOfServiceScreen(),
      ),
    );
  }

  void _showProfileImageSetup() async {
    if (_currentMember == null) {
      AppToast.show(
        context,
        '사용자 정보를 불러오는 중입니다. 잠시 후 다시 시도해주세요.',
        type: ToastType.error,
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileImageSetupScreen(
          member: _currentMember!,
          isFirstSetup: false,
        ),
      ),
    );

    // 프로필 이미지가 변경되었으면 다시 로드
    if (result == true) {
      _loadCurrentUser();
    }
  }

  void _logout() {
    // Settings screen의 context를 저장 (dialog context와 분리)
    final settingsContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: '로그아웃',
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(dialogContext),
            variant: ButtonVariant.ghost,
            child: const Text('취소'),
          ),
          AppButton(
            onPressed: () async {
              // 다이얼로그 먼저 닫기
              Navigator.pop(dialogContext);

              // 다음 프레임에서 로그아웃 처리 (UI 안정화)
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  // 1. FCM 토큰 비활성화 (로그아웃 전에 실행)
                  try {
                    await FCMService.instance.deactivateToken();
                    print('✅ SETTINGS: FCM 토큰 비활성화 완료');
                  } catch (fcmError) {
                    print('⚠️ SETTINGS: FCM 토큰 비활성화 실패 (계속 진행): $fcmError');
                    // FCM 토큰 비활성화 실패해도 로그아웃은 계속 진행
                  }

                  // 2. 로그아웃 처리
                  await _authService.logout();
                  print('✅ SETTINGS: 로그아웃 처리 완료');

                  // 3. 로그인 화면으로 이동 (mounted 체크)
                  if (mounted) {
                    Navigator.of(settingsContext).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                    print('✅ SETTINGS: 로그인 화면으로 이동 완료');
                  }
                } catch (e) {
                  print('❌ SETTINGS: 로그아웃 오류: $e');

                  // 에러가 발생해도 로그인 화면으로 이동 시도
                  if (mounted) {
                    try {
                      Navigator.of(settingsContext).pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    } catch (navError) {
                      print('❌ SETTINGS: 네비게이션 오류: $navError');
                    }
                  }
                }
              });
            },
            variant: ButtonVariant.destructive,
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
