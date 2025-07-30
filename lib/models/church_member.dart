class ChurchMember {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? position; // 직분
  final String? district; // 구역
  final String? department; // 부서
  final DateTime? birthDate;
  final String? gender;
  final String? status; // 등록/출석/휴면 등
  final String? photo;
  final DateTime? baptismDate; // 세례일
  final DateTime? registrationDate; // 등록일
  final List<String>? familyMembers;
  final String? notes;

  ChurchMember({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.position,
    this.district,
    this.department,
    this.birthDate,
    this.gender,
    this.status,
    this.photo,
    this.baptismDate,
    this.registrationDate,
    this.familyMembers,
    this.notes,
  });

  factory ChurchMember.fromJson(Map<String, dynamic> json) {
    return ChurchMember(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      position: json['position'],
      district: json['district'],
      department: json['department'],
      birthDate: json['birth_date'] != null ? DateTime.parse(json['birth_date']) : null,
      gender: json['gender'],
      status: json['status'],
      photo: json['photo'],
      baptismDate: json['baptism_date'] != null ? DateTime.parse(json['baptism_date']) : null,
      registrationDate: json['registration_date'] != null ? DateTime.parse(json['registration_date']) : null,
      familyMembers: json['family_members']?.cast<String>(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'position': position,
      'district': district,
      'department': department,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'status': status,
      'photo': photo,
      'baptism_date': baptismDate?.toIso8601String(),
      'registration_date': registrationDate?.toIso8601String(),
      'family_members': familyMembers,
      'notes': notes,
    };
  }
}
