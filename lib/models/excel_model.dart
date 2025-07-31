class ExcelUploadResult {
  final String message;
  final int created;
  final int updated;
  final List<String> errors;

  ExcelUploadResult({
    required this.message,
    required this.created,
    required this.updated,
    required this.errors,
  });

  factory ExcelUploadResult.fromJson(Map<String, dynamic> json) {
    return ExcelUploadResult(
      message: json['message'] ?? '',
      created: json['created'] ?? 0,
      updated: json['updated'] ?? 0,
      errors: List<String>.from(json['errors'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'created': created,
      'updated': updated,
      'errors': errors,
    };
  }

  bool get hasErrors => errors.isNotEmpty;
  int get totalProcessed => created + updated;
  bool get isSuccess => !hasErrors && totalProcessed > 0;
}

class ExcelMemberData {
  final String name;
  final String gender;
  final String? birthdate;
  final String phone;
  final String? address;
  final String? position;
  final String? district;
  final String? memberStatus;

  ExcelMemberData({
    required this.name,
    required this.gender,
    this.birthdate,
    required this.phone,
    this.address,
    this.position,
    this.district,
    this.memberStatus,
  });

  factory ExcelMemberData.fromMap(Map<String, dynamic> map) {
    return ExcelMemberData(
      name: map['이름'] ?? map['name'] ?? '',
      gender: map['성별'] ?? map['gender'] ?? '',
      birthdate: map['생년월일'] ?? map['birthdate'],
      phone: map['전화번호'] ?? map['phone'] ?? '',
      address: map['주소'] ?? map['address'],
      position: map['직분'] ?? map['position'],
      district: map['구역'] ?? map['district'],
      memberStatus: map['상태'] ?? map['member_status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'birthdate': birthdate,
      'phone': phone,
      'address': address,
      'position': position,
      'district': district,
      'member_status': memberStatus,
    };
  }

  bool get isValid {
    return name.isNotEmpty && 
           gender.isNotEmpty && 
           phone.isNotEmpty;
  }

  List<String> get validationErrors {
    List<String> errors = [];
    
    if (name.isEmpty) {
      errors.add('이름이 필요합니다.');
    }
    
    if (gender.isEmpty) {
      errors.add('성별이 필요합니다.');
    } else if (!['남', '여', 'M', 'F', 'male', 'female'].contains(gender.toLowerCase())) {
      errors.add('성별은 "남", "여", "M", "F" 중 하나여야 합니다.');
    }
    
    if (phone.isEmpty) {
      errors.add('전화번호가 필요합니다.');
    } else if (!RegExp(r'^[\d\-\s\(\)]+$').hasMatch(phone)) {
      errors.add('전화번호 형식이 올바르지 않습니다.');
    }
    
    if (birthdate != null && birthdate!.isNotEmpty) {
      try {
        DateTime.parse(birthdate!);
      } catch (e) {
        errors.add('생년월일 형식이 올바르지 않습니다. (예: 1980-05-15)');
      }
    }
    
    return errors;
  }
}

// 엑셀 템플릿 컬럼 정의
class ExcelTemplate {
  static const List<String> memberColumns = [
    '이름',
    '성별',
    '생년월일',
    '전화번호',
    '주소',
    '직분',
    '구역',
    '상태',
  ];

  static const List<String> attendanceColumns = [
    '날짜',
    '교인명',
    '전화번호',
    '출석여부',
    '예배종류',
    '비고',
  ];

  static Map<String, String> get memberColumnDescriptions => {
    '이름': '교인 이름 (필수)',
    '성별': '남/여 또는 M/F (필수)',
    '생년월일': 'YYYY-MM-DD 형식 (예: 1980-05-15)',
    '전화번호': '010-1234-5678 형식 (필수)',
    '주소': '거주지 주소',
    '직분': '집사, 권사, 장로 등',
    '구역': '1구역, 2구역 등',
    '상태': 'active, inactive, transferred 중 하나',
  };

  static List<Map<String, String>> get sampleMemberData => [
    {
      '이름': '김철수',
      '성별': '남',
      '생년월일': '1980-05-15',
      '전화번호': '010-1234-5678',
      '주소': '서울시 강남구',
      '직분': '집사',
      '구역': '1구역',
      '상태': 'active',
    },
    {
      '이름': '이영희',
      '성별': '여',
      '생년월일': '1985-03-20',
      '전화번호': '010-9876-5432',
      '주소': '서울시 서초구',
      '직분': '권사',
      '구역': '2구역',
      '상태': 'active',
    },
  ];
}
