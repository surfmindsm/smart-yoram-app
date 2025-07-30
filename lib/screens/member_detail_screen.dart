import 'package:flutter/material.dart';
import '../models/church_member.dart';

class MemberDetailScreen extends StatefulWidget {
  final ChurchMember member;
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
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _memoController;
  
  String _selectedGender = '남';
  String _selectedPosition = '일반교인';
  String _selectedStatus = '출석';
  DateTime? _selectedBirthDate;
  DateTime? _selectedBaptismDate;
  DateTime? _selectedRegistrationDate;
  
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _phoneController = TextEditingController(text: widget.member.phone);
    _emailController = TextEditingController(text: widget.member.email);
    _addressController = TextEditingController(text: widget.member.address);
    _memoController = TextEditingController();
    
    _selectedPosition = widget.member.position ?? '일반교인';
    _isEditing = widget.isEditable;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _memoController.dispose();
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
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing;
                });
              },
              icon: Icon(_isEditing ? Icons.save : Icons.edit),
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
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.grey[600],
                    ),
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
            _buildTextField('이메일', _emailController, enabled: _isEditing),
            _buildTextField('주소', _addressController, enabled: _isEditing, maxLines: 2),
            
            const SizedBox(height: 24),
            
            // 교회 정보
            _buildSectionTitle('교회 정보'),
            _buildDropdownField('직분', _selectedPosition, [
              '일반교인', '집사', '권사', '안수집사', '장로', '목사', '전도사'
            ]),
            _buildDropdownField('구역', '1구역', [
              '1구역', '2구역', '3구역', '4구역', '5구역'
            ]),
            _buildDropdownField('출석상태', _selectedStatus, [
              '출석', '등록', '휴면', '출타', '이명'
            ]),
            
            const SizedBox(height: 24),
            
            // 세례/등록 정보
            _buildSectionTitle('세례/등록 정보'),
            _buildDropdownField('세례구분', '세례', ['세례', '입교', '유아세례', '미세례']),
            _buildDateField('세례일', _selectedBaptismDate, _selectBaptismDate),
            _buildDateField('등록일', _selectedRegistrationDate, _selectRegistrationDate),
            
            const SizedBox(height: 24),
            
            // 가족 정보
            _buildSectionTitle('가족 정보'),
            _buildFamilySection(),
            
            const SizedBox(height: 24),
            
            // 봉사부서
            _buildSectionTitle('봉사부서'),
            _buildServiceDepartments(),
            
            const SizedBox(height: 24),
            
            // 메모
            _buildSectionTitle('메모'),
            _buildTextField('관리자 메모', _memoController, 
                enabled: _isEditing, maxLines: 3, maxLength: 200),
            
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('성별'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('남'),
                  value: '남',
                  groupValue: _selectedGender,
                  onChanged: _isEditing ? (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  } : null,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('여'),
                  value: '여',
                  groupValue: _selectedGender,
                  onChanged: _isEditing ? (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  } : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: value,
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item),
        )).toList(),
        onChanged: _isEditing ? (newValue) {
          setState(() {
            if (label == '직분') _selectedPosition = newValue!;
            if (label == '출석상태') _selectedStatus = newValue!;
          });
        } : null,
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
              onTap: () {
                Navigator.pop(context);
                // TODO: 갤러리 이미지 선택 구현
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 카메라 촬영 구현
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

  void _selectBaptismDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _selectedBaptismDate = date;
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

  void _saveMemberInfo() {
    // TODO: 교인 정보 저장 로직
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('교인 정보가 저장되었습니다.')),
    );
    setState(() {
      _isEditing = false;
    });
  }
}
