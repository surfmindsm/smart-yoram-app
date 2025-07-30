import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widget/widgets.dart';
import '../models/church_member.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  
  // 폼 컨트롤러들
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  ChurchMember? currentUser;
  bool isLoading = true;
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => isLoading = true);
    
    try {
      // 임시로 현재 사용자 데이터 생성 (실제로는 로그인된 사용자 정보를 가져와야 함)
      currentUser = ChurchMember(
        id: '1',
        name: '김성도',
        phone: '010-1234-5678',
        email: 'member@church.com',
        address: '서울시 강남구 테헤란로 123',
        position: '성도',
        district: '1구역',
        department: '청년부',
        status: '출석',
        gender: '남',
        birthDate: DateTime(1990, 5, 15),
        registrationDate: DateTime(2020, 3, 1),
      );
      
      // 컨트롤러에 데이터 설정
      _nameController.text = currentUser!.name;
      _phoneController.text = currentUser!.phone ?? '';
      _emailController.text = currentUser!.email ?? '';
      _addressController.text = currentUser!.address ?? '';
      
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
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                '저장',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: isLoading
          ? LoadingWidget()
          : currentUser == null
              ? EmptyStateWidget(
                  icon: Icons.person_off,
                  title: '사용자 정보 없음',
                  subtitle: '사용자 정보를 찾을 수 없습니다',
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileImage(),
                        const SizedBox(height: 24),
                        _buildBasicInfo(),
                        const SizedBox(height: 24),
                        _buildChurchInfo(),
                        const SizedBox(height: 24),
                        if (isEditing) _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileImage() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blue[100],
              child: currentUser!.photo != null
                  ? ClipOval(
                      child: Image.network(
                        currentUser!.photo!,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.blue[700],
                    ),
            ),
            if (isEditing)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _changeProfileImage,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          currentUser!.name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (currentUser!.position != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              currentUser!.position!,
              style: TextStyle(
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기본 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 이름
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '이름',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: isEditing,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 전화번호
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '전화번호',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              enabled: isEditing,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '전화번호를 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 이메일
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              enabled: isEditing,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.contains('@')) {
                    return '올바른 이메일 형식을 입력해주세요';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 주소
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '주소',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              enabled: isEditing,
              maxLines: 2,
            ),
            
            if (!isEditing) ...[
              const SizedBox(height: 16),
              
              // 성별
              if (currentUser!.gender != null)
                _buildInfoRow('성별', currentUser!.gender!),
              
              // 생일
              if (currentUser!.birthDate != null)
                _buildInfoRow(
                  '생일',
                  '${currentUser!.birthDate!.year}.${currentUser!.birthDate!.month.toString().padLeft(2, '0')}.${currentUser!.birthDate!.day.toString().padLeft(2, '0')}',
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChurchInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '교회 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (currentUser!.position != null)
              _buildInfoRow('직분', currentUser!.position!),
            
            if (currentUser!.district != null)
              _buildInfoRow('구역', currentUser!.district!),
            
            if (currentUser!.department != null)
              _buildInfoRow('부서', currentUser!.department!),
            
            if (currentUser!.registrationDate != null)
              _buildInfoRow(
                '등록일',
                '${currentUser!.registrationDate!.year}.${currentUser!.registrationDate!.month.toString().padLeft(2, '0')}.${currentUser!.registrationDate!.day.toString().padLeft(2, '0')}',
              ),
            
            if (currentUser!.status != null)
              _buildInfoRow('상태', currentUser!.status!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CommonButton(
          text: '저장',
          type: ButtonType.primary,
          width: double.infinity,
          onPressed: _saveProfile,
        ),
        const SizedBox(height: 12),
        CommonButton(
          text: '취소',
          type: ButtonType.secondary,
          width: double.infinity,
          onPressed: _cancelEdit,
        ),
      ],
    );
  }

  void _changeProfileImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('프로필 사진 변경'),
        content: const Text('프로필 사진 변경 기능은 준비 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // 실제로는 서버에 저장
      setState(() {
        currentUser = ChurchMember(
          id: currentUser!.id,
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          position: currentUser!.position,
          district: currentUser!.district,
          department: currentUser!.department,
          status: currentUser!.status,
          gender: currentUser!.gender,
          birthDate: currentUser!.birthDate,
          registrationDate: currentUser!.registrationDate,
        );
        isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('프로필이 저장되었습니다')),
      );
    }
  }

  void _cancelEdit() {
    setState(() {
      // 원래 데이터로 복원
      _nameController.text = currentUser!.name;
      _phoneController.text = currentUser!.phone ?? '';
      _emailController.text = currentUser!.email ?? '';
      _addressController.text = currentUser!.address ?? '';
      isEditing = false;
    });
  }
}
