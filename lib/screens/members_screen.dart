import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/member_service.dart';
import '../models/member.dart';
import '../resource/color_style.dart';
import '../resource/text_style.dart';
import '../widgets/member_detail_modal.dart';
import '../components/index.dart' hide IconButton;

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

  final List<String> tabs = ['전체', '교역자', '장로', '권사', '집사', '성도'];

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

      // 탭에 따른 필터링
      switch (currentTab) {
        case 0: // 전체
          baseList = List.from(allMembers);
          break;
        case 1: // 교역자
          baseList = allMembers.where((m) => m.position == '교역자').toList();
          break;
        case 2: // 장로
          baseList = allMembers.where((m) => m.position == '장로').toList();
          break;
        case 3: // 권사
          baseList = allMembers.where((m) => m.position == '권사').toList();
          break;
        case 4: // 집사
          baseList = allMembers
              .where((m) => m.position?.contains('집사') == true)
              .toList();
          break;
        case 5: // 성도
          baseList = allMembers
              .where((m) => m.position?.contains('성도') == true)
              .toList();
          break;
      }

      // 검색 필터링
      if (query.isNotEmpty) {
        filteredMembers = baseList.where((member) {
          return member.name.toLowerCase().contains(query) ||
              member.phone.contains(query) ||
              (member.position?.toLowerCase().contains(query) ?? false);
        }).toList();
      } else {
        filteredMembers = List.from(baseList);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      // appBar: AppBar(
      //   title: Text('주소록'),
      //   titleTextStyle: AppTextStyle(
      //     color: Colors.black,
      //   ).h1(),
      //   backgroundColor: Colors.white,
      //   foregroundColor: Colors.black,
      //   elevation: 0,
      // ),backgroundColor: AppColor.background,

      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 10.h),
          // 검색창
          Container(
            padding: EdgeInsets.all(16.r),
            color: AppColor.transparent,
            child: AppInput(
              controller: _searchController,
              placeholder: '이름 또는 전화번호로 검색',
              prefixIcon: Icons.search,
            ),
          ),

          // 탭바
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: AppCard(
              variant: CardVariant.elevated,
              padding: EdgeInsets.zero,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColor.primary900,
                labelStyle:
                    AppTextStyle(color: AppColor.primary900).b2().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
                unselectedLabelColor: AppColor.secondary04,
                unselectedLabelStyle:
                    AppTextStyle(color: AppColor.secondary04).b2(),
                indicatorColor: AppColor.primary900,
                indicatorPadding: EdgeInsets.zero,
                indicatorWeight: 2.h,
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                onTap: (_) => _filterMembers(),
                tabs: tabs.map((tab) => Tab(text: tab)).toList(),
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              ),
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
            CircularProgressIndicator(color: AppColor.primary900),
            SizedBox(height: 16.h),
            Text(
              '교인 정보를 불러오는 중...',
              style: AppTextStyle(color: AppColor.secondary04).b2(),
            ),
          ],
        ),
      );
    }

    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group,
              size: 64.sp,
              color: AppColor.secondary03,
            ),
            SizedBox(height: 16.h),
            Text(
              '교인 정보가 없습니다',
              style: AppTextStyle(color: AppColor.secondary04).h3(),
            ),
            SizedBox(height: 8.h),
            Text(
              '다른 카테고리를 선택하거나 검색어를 변경해보세요',
              style: AppTextStyle(color: AppColor.secondary03).b3(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: filteredMembers.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        // 안전한 인덱스 체크 추가
        if (index >= filteredMembers.length) {
          return const SizedBox.shrink();
        }
        final member = filteredMembers[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildMemberCard(Member member) {
    return GestureDetector(
      onTap: () => _showMemberDetail(member),
      child: AppCard(
        variant: CardVariant.elevated,
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
          // 아바타
          CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColor.primary900,
            backgroundImage: member.profilePhotoUrl != null &&
                    member.profilePhotoUrl!.isNotEmpty
                ? NetworkImage(member.profilePhotoUrl!)
                : null,
            child: member.profilePhotoUrl == null ||
                    member.profilePhotoUrl!.isEmpty
                ? Text(
                    member.name.isNotEmpty ? member.name[0] : '?',
                    style: AppTextStyle(color: AppColor.white).b2().copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  )
                : null,
          ),
          SizedBox(width: 16.w),

          // 정보 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppTextStyle(color: AppColor.secondary07).b2(),
                ),
                const SizedBox(height: 4),
                Text(
                  member.phone,
                  style: AppTextStyle(color: AppColor.secondary04).b3(),
                ),
                const SizedBox(height: 4),
                Text(
                  member.position ?? '성도',
                  style: AppTextStyle(color: AppColor.secondary04).b3(),
                ),
              ],
            ),
          ),

          // 액션 버튼들
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: IconButton(
                  icon: Icon(Icons.phone, color: Colors.green, size: 20.sp),
                  onPressed: () => _makePhoneCall(member.phone),
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColor.primary900.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: IconButton(
                  icon: Icon(Icons.chat_bubble, color: AppColor.primary900, size: 20.sp),
                  onPressed: () => _sendMessage(member.phone),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
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
