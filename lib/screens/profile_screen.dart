import 'package:flutter/material.dart';
// import.*lucide_icons.*;
import '../widget/widgets.dart';
import '../services/user_service.dart';
import '../services/member_service.dart';
import '../models/user.dart' as app_user;
import '../models/member.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  final MemberService _memberService = MemberService();
  
  app_user.User? currentUser;
  Member? currentMember;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => isLoading = true);
    
    try {
      // 현재 사용자 정보 로드
      final userResponse = await _userService.getCurrentUser();
      if (userResponse.success && userResponse.data != null) {
        currentUser = userResponse.data!;
        
        // 현재 사용자의 교인 정보 조회
        final membersResponse = await _memberService.getMembers(limit: 1000);
        if (membersResponse.success && membersResponse.data != null) {
          final members = membersResponse.data!;
          currentMember = members.firstWhere(
            (member) => member.email == currentUser!.email,
            orElse: () => Member(
              id: 0,
              name: currentUser!.fullName,
              email: currentUser!.email,
              gender: '',
              phone: '',
              churchId: currentUser!.churchId,
              memberStatus: 'active',
              createdAt: DateTime.now(),
            ),
          );
        }
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 로드 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '내 정보',
      ),
      body: isLoading
          ? LoadingWidget()
          : (currentUser == null)
              ? EmptyStateWidget(
                  icon: Icons.person_off,
                  title: '사용자 정보 없음',
                  subtitle: '사용자 정보를 찾을 수 없습니다',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 16),
                      _buildBasicInfoCard(),
                      const SizedBox(height: 16),
                      _buildChurchInfoCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue[100],
              backgroundImage: currentMember?.profilePhotoUrl != null 
                  ? NetworkImage(currentMember!.profilePhotoUrl!) 
                  : null,
              child: currentMember?.profilePhotoUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.blue)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              currentMember?.name ?? currentUser!.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (currentMember?.position != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentMember!.position!,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return InfoCardWidget(
      title: '기본 정보',
      icon: Icons.person,
      items: [
        InfoItem(
          label: '이름',
          value: currentMember?.name ?? currentUser!.fullName,
          icon: Icons.credit_card,
        ),
        InfoItem(
          label: '이메일',
          value: currentUser!.email,
          icon: Icons.email,
        ),
        if (currentMember?.phone != null && currentMember!.phone!.isNotEmpty)
          InfoItem(
            label: '전화번호',
            value: currentMember!.phone!,
            icon: Icons.phone,
          ),
        if (currentMember?.gender != null && currentMember!.gender!.isNotEmpty)
          InfoItem(
            label: '성별',
            value: _getGenderDisplayName(currentMember!.gender!),
            icon: Icons.group,
          ),
        if (currentMember?.address != null && currentMember!.address!.isNotEmpty)
          InfoItem(
            label: '주소',
            value: currentMember!.address!,
            icon: Icons.location_on,
          ),
      ],
    );
  }

  Widget _buildChurchInfoCard() {
    return InfoCardWidget(
      title: '교회 정보',
      icon: Icons.church,
      items: [
        InfoItem(
          label: '권한',
          value: _getRoleDisplayName(currentUser!.role),
          icon: Icons.security,
        ),
        InfoItem(
          label: '상태',
          value: currentMember?.memberStatus ?? 'unknown',
          icon: Icons.check_circle,
        ),
        if (currentMember?.position != null && currentMember!.position!.isNotEmpty)
          InfoItem(
            label: '직분',
            value: currentMember!.position!,
            icon: Icons.work,
          ),
        if (currentMember?.district != null && currentMember!.district!.isNotEmpty)
          InfoItem(
            label: '구역',
            value: currentMember!.district!,
            icon: Icons.location_city,
          ),
        if (currentMember?.createdAt != null)
          InfoItem(
            label: '가입일',
            value: _formatDate(currentMember!.createdAt!),
            icon: Icons.calendar_today,
          ),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return '관리자';
      case 'pastor':
        return '목회자';
      case 'member':
        return '교인';
      default:
        return '미정';
    }
  }

  String _getGenderDisplayName(String gender) {
    switch (gender.toLowerCase()) {
      case 'm':
      case 'male':
      case '남':
      case '남성':
        return '남성';
      case 'f':
      case 'female':
      case '여':
      case '여성':
        return '여성';
      default:
        return gender; // 원본 값 그대로 반환
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
