import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/member_service.dart';
import '../models/member.dart';
import '../resource/color_style_new.dart';
import '../resource/text_style_new.dart';
import '../widgets/member_detail_modal.dart';
import '../components/index.dart' hide IconButton;
import '../constants/member_positions.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with SingleTickerProviderStateMixin {
  final MemberService _memberService = MemberService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  List<Member> allMembers = [];
  List<Member> filteredMembers = [];
  bool isLoading = true;

  // 주소록 탭 목록 (백엔드 정책에 따라)
  final List<String> tabs = MemberPosition.addressBookTabs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _tabController.addListener(_filterMembers); // 탭 변경 시 필터링
    _loadMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers({String? search}) async {
    print('📁 MEMBERS_SCREEN: _loadMembers 시작');
    setState(() => isLoading = true);

    try {
      // 백엔드 API에서 교인 목록 가져오기
      print('📁 MEMBERS_SCREEN: getMembers API 호출 시작');
      final response = await _memberService.getMembers(
        search: search?.isNotEmpty == true ? search : null,
        limit: 1000,
      );

      print('📁 MEMBERS_SCREEN: API 응답 - success: ${response.success}');
      print('📁 MEMBERS_SCREEN: API 응답 - message: "${response.message}"');

      if (response.success && response.data != null) {
        allMembers = response.data!;
        print('📁 MEMBERS_SCREEN: 받은 교인 수: ${allMembers.length}');

        // 처음 5명 상세 정보 로그
        for (int i = 0; i < allMembers.length && i < 5; i++) {
          final member = allMembers[i];
          print(
              '📁 MEMBERS_SCREEN: [$i] ID: ${member.id}, 이름: ${member.name}, 전화: ${member.phone}');
        }

        _filterMembers();
      } else {
        print('📁 MEMBERS_SCREEN: API 응답 실패 - ${response.message}');
        throw Exception(response.message);
      }

      setState(() => isLoading = false);
      print('📁 MEMBERS_SCREEN: _loadMembers 완료');
    } catch (e) {
      print('📁 MEMBERS_SCREEN: _loadMembers 예외 - $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('교인 정보 로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterMembers() {
    String query = _searchController.text.toLowerCase();
    int currentTab = _tabController.index;

    setState(() {
      // allMembers가 비어있는 경우 빈 리스트 반환
      if (allMembers.isEmpty) {
        filteredMembers = [];
        return;
      }

      List<Member> baseList = allMembers;

      // 탭에 따른 필터링 (position_category 사용)
      if (currentTab == 0) {
        // 전체 탭
        baseList = List.from(allMembers);
      } else {
        // 선택된 카테고리로 필터링
        final selectedCategory = MemberPosition.addressBookCategories[currentTab - 1];
        baseList = allMembers.where((m) {
          // positionCategory가 없으면 클라이언트 측에서 계산
          final category = m.positionCategory ??
              MemberPosition.getPositionCategory(m.position, m.birthdate);
          return category == selectedCategory;
        }).toList();
      }

      // 검색 필터링
      if (query.isNotEmpty) {
        filteredMembers = baseList.where((member) {
          return member.name.toLowerCase().contains(query) ||
              member.phone.contains(query) ||
              member.positionLabel.toLowerCase().contains(query);
        }).toList();
      } else {
        filteredMembers = List.from(baseList);
      }

      // 가나다 순으로 정렬
      filteredMembers.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewAppColor.neutral100,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10.h),
          // 검색창
          Container(
            padding: EdgeInsets.all(16.r),
            color: Colors.transparent,
            child: Container(
              width: 350.w,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                gradient: LinearGradient(
                  colors: [
                    NewAppColor.primary600,
                    NewAppColor.primary600.withValues(alpha: 0.7),
                    NewAppColor.primary600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                margin: EdgeInsets.all(1.r), // 그라디언트 보더 두께
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11.r),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    SizedBox(width: 16.w),
                    Icon(
                      Icons.search,
                      size: 20.r,
                      color: NewAppColor.neutral500,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '이름 또는 전화번호로 검색',
                          hintStyle: const FigmaTextStyles().body2.copyWith(
                                color: NewAppColor.neutral500,
                              ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const FigmaTextStyles().body2.copyWith(
                              color: NewAppColor.neutral900,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 탭바
          Container(
            height: 56.h,
            margin: EdgeInsets.symmetric(horizontal: 22.w),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: NewAppColor.neutral200,
                  width: 2.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tabs.length, (index) {
                final isSelected = _tabController.index == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _tabController.animateTo(index);
                      _filterMembers();
                    },
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        border: isSelected
                            ? Border(
                                bottom: BorderSide(
                                  color: NewAppColor.primary600,
                                  width: 2.0,
                                ),
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          tabs[index],
                          style: const FigmaTextStyles().title4.copyWith(
                                color: isSelected
                                    ? NewAppColor.primary600
                                    : NewAppColor.neutral400,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 교인 목록
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (tabIndex) {
                return _buildMemberList();
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: NewAppColor.primary600),
            SizedBox(height: 16.h),
            Text(
              '교인 정보를 불러오는 중...',
              style: const FigmaTextStyles().body2.copyWith(
                    color: NewAppColor.neutral500,
                  ),
            ),
          ],
        ),
      );
    }

    if (filteredMembers.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadMembers(),
        color: NewAppColor.primary600,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 300.h,
            child: Center(
              child: SizedBox(
                width: 272.w,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.h,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(),
                      child: SvgPicture.asset(
                        'assets/icons/members_empty.svg',
                        width: 48.w,
                        height: 48.h,
                        colorFilter: ColorFilter.mode(
                          NewAppColor.neutral800,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '교인 정보가 없습니다',
                            textAlign: TextAlign.center,
                            style: FigmaTextStyles().title3.copyWith(
                                  color: NewAppColor.neutral800,
                                ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            '다른 카테고리를 선택하거나 검색어를 변경해보세요',
                            textAlign: TextAlign.center,
                            style: FigmaTextStyles().body2.copyWith(
                                  color: NewAppColor.neutral500,
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadMembers(),
      color: NewAppColor.primary600,
      child: ListView.separated(
        padding: EdgeInsets.all(20.w),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredMembers.length,
        separatorBuilder: (context, index) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          // 안전한 인덱스 체크 추가
          if (index >= filteredMembers.length) {
            return const SizedBox.shrink();
          }
          final member = filteredMembers[index];
          return _buildMemberCard(member);
        },
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return GestureDetector(
      onTap: () => _showMemberDetail(member),
      child: Container(
        width: double.infinity,
        height: 76.h,
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16.w,
              top: 7.h,
              child: SizedBox(
                width: 253.w,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 42.w,
                      height: 42.h,
                      decoration: ShapeDecoration(
                        image: member.fullProfilePhotoUrl != null &&
                                member.fullProfilePhotoUrl!.isNotEmpty
                            ? DecorationImage(
                                image:
                                    NetworkImage(member.fullProfilePhotoUrl!),
                                fit: BoxFit.fill,
                              )
                            : null,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: NewAppColor.neutral300,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: member.fullProfilePhotoUrl == null ||
                              member.fullProfilePhotoUrl!.isEmpty
                          ? Center(
                              child: Text(
                                member.name.isNotEmpty ? member.name[0] : '?',
                                style: TextStyle(
                                  color: NewAppColor.neutral900,
                                  fontSize: 16.sp,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 16.w),
                    SizedBox(
                      width: 195.w,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 195.w,
                                  child: Text(
                                    member.name,
                                    style: TextStyle(
                                      color: NewAppColor.neutral900,
                                      fontSize: 16.sp,
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                      height: 1.50,
                                      letterSpacing: -0.40,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 195.w,
                                  child: Text(
                                    member.phone,
                                    style: TextStyle(
                                      color: NewAppColor.neutral600,
                                      fontSize: 13.sp,
                                      fontFamily: 'Pretendard Variable',
                                      fontWeight: FontWeight.w400,
                                      height: 1.38,
                                      letterSpacing: -0.33,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          SizedBox(
                            width: 195.w,
                            child: Text(
                              member.positionLabel,
                              style: TextStyle(
                                color: NewAppColor.neutral600,
                                fontSize: 11.sp,
                                fontFamily: 'Pretendard Variable',
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                                letterSpacing: -0.28,
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
            Positioned(
              left: 269.w,
              top: 24.h,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28.w,
                    height: 28.h,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: NewAppColor.success200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.phone,
                        color: NewAppColor.success600,
                        size: 16.sp,
                      ),
                      onPressed: () => _makePhoneCall(member.phone),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Container(
                    width: 28.w,
                    height: 28.h,
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: NewAppColor.primary200,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.chat_bubble,
                        color: NewAppColor.primary600,
                        size: 16.sp,
                      ),
                      onPressed: () => _sendMessage(member.phone),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog() {
    // 교인 추가 다이얼로그
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('교인 추가'),
        content: const Text('교인 추가 기능은 준비 중입니다.'),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.ghost,
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      // 전화번호에서 하이픈, 공백 등 제거
      String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

      if (cleanedPhone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('유효하지 않은 전화번호입니다')),
          );
        }
        return;
      }

      // 전화 권한 확인 (선택적)
      try {
        PermissionStatus phonePermission = await Permission.phone.status;
        if (phonePermission.isDenied) {
          await Permission.phone.request();
        }
      } catch (e) {
        // 권한 오류는 무시하고 계속 진행
      }

      final Uri phoneUri = Uri(scheme: 'tel', path: cleanedPhone);

      try {
        // 먼저 일반적인 방법 시도
        bool canLaunch = await canLaunchUrl(phoneUri);

        if (canLaunch) {
          await launchUrl(phoneUri);
        } else {
          // canLaunchUrl이 false라도 LaunchMode.externalApplication으로 시도
          await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('전화 앱을 열 수 없습니다')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화번호가 없습니다')),
        );
      }
    }
  }

  Future<void> _sendMessage(String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      // 전화번호에서 하이픈, 공백 등 제거
      String cleanedPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');

      if (cleanedPhone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('유효하지 않은 전화번호입니다')),
          );
        }
        return;
      }

      final Uri smsUri = Uri(scheme: 'sms', path: cleanedPhone);

      try {
        // 먼저 일반적인 방법 시도
        bool canLaunch = await canLaunchUrl(smsUri);

        if (canLaunch) {
          await launchUrl(smsUri);
        } else {
          // canLaunchUrl이 false라도 LaunchMode.externalApplication으로 시도
          await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('메시지 앱을 열 수 없습니다')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('전화번호가 없습니다')),
        );
      }
    }
  }

  void _showMemberDetail(Member member) {
    showDialog(
      context: context,
      builder: (context) => MemberDetailModal(member: member),
    );
  }
}
