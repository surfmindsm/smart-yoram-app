import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/member.dart';
import '../services/member_service.dart';

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
  late TextEditingController _addressController;
  
  String _selectedGender = '남';
  String _selectedPosition = '성도';
  String _selectedStatus = 'active';
  String _selectedDistrict = '';
  DateTime? _selectedBirthDate;
  DateTime? _selectedRegistrationDate;
  
  bool _isEditing = false;
  bool _isSaving = false;
  File? _selectedImage;
  
  final List<String> _genderOptions = ['남', '여'];
  final List<String> _positionOptions = ['교역자', '장로', '권사', '집사', '성도'];
  final List<String> _statusOptions = ['active', 'inactive', 'transferred'];
  final List<String> _districtOptions = ['1구역', '2구역', '3구역', '4구역', '5구역'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phoneNumber);
    _addressController = TextEditingController(text: widget.member.address ?? '');
    
    _selectedGender = widget.member.gender;
    _selectedPosition = widget.member.position ?? '성도';
    _selectedStatus = widget.member.memberStatus;
    _selectedDistrict = widget.member.district ?? '1구역';
    _selectedBirthDate = widget.member.dateOfBirth;
    _selectedRegistrationDate = widget.member.registrationDate;
    _isEditing = widget.isEditable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.name),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (!widget.isEditable)
            IconButton(
              onPressed: _isSaving ? null : () async {
                if (_isEditing) {
                  await _saveMemberInfo();
                } else {
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
              icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isEditing ? Icons.save : Icons.edit),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 사진 섹션
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _selectedImage != null 
                        ? FileImage(_selectedImage!) as ImageProvider
                        : widget.member.fullProfilePhotoUrl != null
                            ? NetworkImage(widget.member.fullProfilePhotoUrl!) as ImageProvider
                            : null,
                    backgroundColor: Colors.grey[300],
                    child: (_selectedImage == null && widget.member.fullProfilePhotoUrl == null)
                        ? Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _selectProfileImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 기본 정보
            _buildSectionTitle('기본 정보'),
            _buildTextField('이름', _nameController, enabled: _isEditing),
            _buildGenderSelector(),
            _buildDateField('생년월일', _selectedBirthDate, _selectBirthDate),
            _buildTextField('휴대폰', _phoneController, enabled: _isEditing),
            _buildTextField('주소', _addressController, enabled: _isEditing, maxLines: 2),
            const SizedBox(height: 16),
            
            // 교회 정보
            _buildSectionTitle('교회 정보'),
            _buildDropdownField('직분', _selectedPosition, _positionOptions),
            _buildDropdownField('상태', _selectedStatus, _statusOptions),
            _buildDropdownField('구역', _selectedDistrict, _districtOptions),
            _buildDateField('등록일', _selectedRegistrationDate, _selectRegistrationDate),
            const SizedBox(height: 24),
            
            // 가족 정보
            _buildSectionTitle('가족 정보'),
            _buildFamilySection(),
            
            const SizedBox(height: 24),
            
            // 봉사부서
            _buildSectionTitle('봉사부서'),
            _buildServiceDepartments(),
            
            const SizedBox(height: 32),
            
            // 저장 버튼
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveMemberInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('저장'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          enabled: enabled,
        ),
        maxLines: maxLines,
        maxLength: maxLength,
        enabled: enabled,
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('성별', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: _genderOptions.map((gender) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Radio<String>(
                  value: gender,
                  groupValue: _selectedGender,
                  onChanged: _isEditing ? (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  } : null,
                ),
                Text(gender),
                const SizedBox(width: 24),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: items.contains(value) ? value : items.first,
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            )).toList(),
            onChanged: _isEditing ? (newValue) {
              setState(() {
                if (label == '직분') _selectedPosition = newValue!;
                else if (label == '상태') _selectedStatus = newValue!;
                else if (label == '구역') _selectedDistrict = newValue!;
              });
            } : null,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        controller: TextEditingController(
          text: date != null ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}' : '',
        ),
        readOnly: true,
        onTap: _isEditing ? onTap : null,
      ),
    );
  }

  Widget _buildFamilySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('가족 구성원'),
              if (_isEditing)
                IconButton(
                  onPressed: _addFamilyMember,
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('김아버지'),
            subtitle: Text('부 - 장로'),
            trailing: Icon(Icons.edit),
          ),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('김어머니'),
            subtitle: Text('모 - 권사'),
            trailing: Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDepartments() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('봉사부서'),
              if (_isEditing)
                IconButton(
                  onPressed: _addServiceDepartment,
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          const Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('찬양팀')),
              Chip(label: Text('교육부')),
            ],
          ),
        ],
      ),
    );
  }

  void _selectProfileImage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                  // TODO: 이미지 업로드 API 호출
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('카메라로 촬영'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                  // TODO: 이미지 업로드 API 호출
                }
              },
            ),
            if (widget.member.profilePhotoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('프로필 사진 삭제'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                  // TODO: 이미지 삭제 API 호출
                },
              ),
          ],
        ),
      ),
    );
  }

  void _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedBirthDate = date;
      });
    }
  }



  void _selectRegistrationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedRegistrationDate = date;
      });
    }
  }

  void _addFamilyMember() {
    // TODO: 가족 구성원 추가 다이얼로그
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가족 구성원 추가'),
        content: const Text('가족 구성원 추가 기능은 추후 구현 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _addServiceDepartment() {
    // TODO: 봉사부서 추가 다이얼로그
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('봉사부서 추가'),
        content: const Text('봉사부서 추가 기능은 추후 구현 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMemberInfo() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이름과 전화번호는 필수 입력 항목입니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final request = MemberUpdateRequest(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        position: _selectedPosition,
        district: _selectedDistrict,
        memberStatus: _selectedStatus,
      );
      
      final response = await _memberService.updateMember(widget.member.id, request);
      
      if (response.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('교인 정보가 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
