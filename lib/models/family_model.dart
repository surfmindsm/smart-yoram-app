class FamilyRelationship {
  final int id;
  final int memberId;
  final int relatedMemberId;
  final String relationshipType;
  final DateTime createdAt;
  final String? memberName;
  final String? relatedMemberName;
  final String? profilePhotoUrl;
  final String? relatedProfilePhotoUrl;

  FamilyRelationship({
    required this.id,
    required this.memberId,
    required this.relatedMemberId,
    required this.relationshipType,
    required this.createdAt,
    this.memberName,
    this.relatedMemberName,
    this.profilePhotoUrl,
    this.relatedProfilePhotoUrl,
  });

  factory FamilyRelationship.fromJson(Map<String, dynamic> json) {
    return FamilyRelationship(
      id: json['id'],
      memberId: json['member_id'],
      relatedMemberId: json['related_member_id'],
      relationshipType: json['relationship_type'],
      createdAt: DateTime.parse(json['created_at']),
      memberName: json['member_name'],
      relatedMemberName: json['related_member_name'],
      profilePhotoUrl: json['profile_photo_url'],
      relatedProfilePhotoUrl: json['related_profile_photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'related_member_id': relatedMemberId,
      'relationship_type': relationshipType,
      'created_at': createdAt.toIso8601String(),
      'member_name': memberName,
      'related_member_name': relatedMemberName,
      'profile_photo_url': profilePhotoUrl,
      'related_profile_photo_url': relatedProfilePhotoUrl,
    };
  }
}

class FamilyMember {
  final int id;
  final String name;
  final String relationshipType;
  final String? profilePhotoUrl;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final String? gender;

  FamilyMember({
    required this.id,
    required this.name,
    required this.relationshipType,
    this.profilePhotoUrl,
    this.dateOfBirth,
    this.phoneNumber,
    this.gender,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'],
      name: json['name'],
      relationshipType: json['relationship_type'],
      profilePhotoUrl: json['profile_photo_url'],
      dateOfBirth: json['date_of_birth'] != null 
        ? DateTime.parse(json['date_of_birth']) 
        : null,
      phoneNumber: json['phone_number'],
      gender: json['gender'],
    );
  }

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month || 
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }
}

class FamilyTree {
  final FamilyMember rootMember;
  final List<FamilyMember> familyMembers;

  FamilyTree({
    required this.rootMember,
    required this.familyMembers,
  });

  factory FamilyTree.fromJson(Map<String, dynamic> json) {
    return FamilyTree(
      rootMember: FamilyMember.fromJson(json['root_member']),
      familyMembers: (json['family_members'] as List)
          .map((member) => FamilyMember.fromJson(member))
          .toList(),
    );
  }

  List<FamilyMember> get parents => 
      familyMembers.where((member) => member.relationshipType == '부모').toList();
  
  List<FamilyMember> get children => 
      familyMembers.where((member) => member.relationshipType == '자녀').toList();
  
  List<FamilyMember> get spouses => 
      familyMembers.where((member) => member.relationshipType == '배우자').toList();
  
  List<FamilyMember> get siblings => 
      familyMembers.where((member) => 
          member.relationshipType == '형제' || 
          member.relationshipType == '자매').toList();
}

// 관계 타입 상수 및 유틸리티
class RelationshipType {
  static const String parent = '부모';
  static const String child = '자녀';
  static const String spouse = '배우자';
  static const String brother = '형제';
  static const String sister = '자매';
  static const String grandparent = '조부모';
  static const String grandchild = '손자녀';
  static const String uncle = '삼촌';
  static const String aunt_maternal = '이모';
  static const String aunt_paternal = '고모';
  static const String nephew_niece = '조카';

  static List<String> get all => [
    parent,
    child,
    spouse,
    brother,
    sister,
    grandparent,
    grandchild,
    uncle,
    aunt_maternal,
    aunt_paternal,
    nephew_niece,
  ];

  static String getIcon(String relationshipType) {
    switch (relationshipType) {
      case parent:
        return '👨‍👩‍👧‍👦';
      case child:
        return '👶';
      case spouse:
        return '💑';
      case brother:
        return '👨‍👦';
      case sister:
        return '👩‍👧';
      case grandparent:
        return '👴👵';
      case grandchild:
        return '👶';
      case uncle:
      case aunt_maternal:
      case aunt_paternal:
        return '👨‍👩‍👧';
      case nephew_niece:
        return '👦👧';
      default:
        return '👤';
    }
  }

  static String getReverseRelationship(String relationshipType) {
    switch (relationshipType) {
      case parent:
        return child;
      case child:
        return parent;
      case spouse:
        return spouse;
      case brother:
        return sister; // 또는 brother (성별에 따라)
      case sister:
        return brother; // 또는 sister (성별에 따라)
      case grandparent:
        return grandchild;
      case grandchild:
        return grandparent;
      case uncle:
      case aunt_maternal:
      case aunt_paternal:
        return nephew_niece;
      case nephew_niece:
        return uncle; // 또는 aunt (성별에 따라)
      default:
        return relationshipType;
    }
  }
}
