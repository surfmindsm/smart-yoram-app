import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChurchRegistrationScreen extends StatefulWidget {
  const ChurchRegistrationScreen({super.key});

  @override
  State<ChurchRegistrationScreen> createState() => _ChurchRegistrationScreenState();
}

class _ChurchRegistrationScreenState extends State<ChurchRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _churchNameController = TextEditingController();
  final _representativeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;

  @override
  void dispose() {
    _churchNameController.dispose();
    _representativeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('교회 등록'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '교회 정보를 입력해주세요',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // 교회명
              TextFormField(
                controller: _churchNameController,
                decoration: const InputDecoration(
                  labelText: '교회명',
                  hintText: '○○교회',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.church),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '교회명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 대표자명
              TextFormField(
                controller: _representativeController,
                decoration: const InputDecoration(
                  labelText: '대표자명',
                  hintText: '담임목사님 성함',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.user),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '대표자명을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 교회 주소
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: '교회 주소',
                  hintText: '주소를 입력해주세요',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mapPin),
                  suffixIcon: Icon(LucideIcons.search),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '교회 주소를 입력해주세요';
                  }
                  return null;
                },
                onTap: () {
                  // TODO: 주소 검색 기능 구현
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주소 검색 기능은 추후 구현 예정입니다')),
                  );
                },
                readOnly: true,
              ),
              const SizedBox(height: 16),
              
              // 연락처
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: '대표 연락처',
                  hintText: '010-0000-0000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '연락처를 입력해주세요';
                  }
                  if (!RegExp(r'^01[0-9]-[0-9]{4}-[0-9]{4}$').hasMatch(value)) {
                    return '올바른 휴대폰 번호 형식이 아닙니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // 이메일
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '대표 이메일',
                  hintText: 'church@example.com',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.mail),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '올바른 이메일 형식이 아닙니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // 약관 동의
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '약관 동의',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text('서비스 이용약관 동의 (필수)'),
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text('개인정보 처리방침 동의 (필수)'),
                      value: _agreeToPrivacy,
                      onChanged: (value) {
                        setState(() {
                          _agreeToPrivacy = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 등록 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _agreeToTerms && _agreeToPrivacy ? _registerChurch : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('교회 등록하기', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _registerChurch() {
    if (_formKey.currentState!.validate()) {
      // TODO: 교회 등록 로직 구현
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('등록 완료'),
          content: const Text('교회 등록이 완료되었습니다.\n관리자 승인 후 이용 가능합니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // 등록 화면도 닫기
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}
