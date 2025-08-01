class Church {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? pastorName;
  final String? subscriptionStatus;
  final DateTime? subscriptionEndDate;
  final int? memberLimit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Church({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.pastorName,
    this.subscriptionStatus,
    this.subscriptionEndDate,
    this.memberLimit,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  factory Church.fromJson(Map<String, dynamic> json) {
    return Church(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      pastorName: json['pastor_name'] as String?,
      subscriptionStatus: json['subscription_status'] as String?,
      subscriptionEndDate: json['subscription_end_date'] != null 
          ? DateTime.parse(json['subscription_end_date'] as String)
          : null,
      memberLimit: json['member_limit'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'pastor_name': pastorName,
      'subscription_status': subscriptionStatus,
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      'member_limit': memberLimit,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Church(id: $id, name: $name, pastorName: $pastorName, phone: $phone, address: $address)';
  }
}

class ChurchCreateRequest {
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? pastorName;
  final String? subscriptionStatus;
  final DateTime? subscriptionEndDate;
  final int? memberLimit;

  ChurchCreateRequest({
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.pastorName,
    this.subscriptionStatus,
    this.subscriptionEndDate,
    this.memberLimit,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'pastor_name': pastorName,
      'subscription_status': subscriptionStatus,
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      'member_limit': memberLimit,
    };
  }
}

class ChurchUpdateRequest {
  final String? name;
  final String? address;
  final String? phone;
  final String? email;
  final String? pastorName;
  final String? subscriptionStatus;
  final DateTime? subscriptionEndDate;
  final int? memberLimit;
  final bool? isActive;

  ChurchUpdateRequest({
    this.name,
    this.address,
    this.phone,
    this.email,
    this.pastorName,
    this.subscriptionStatus,
    this.subscriptionEndDate,
    this.memberLimit,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (address != null) data['address'] = address;
    if (phone != null) data['phone'] = phone;
    if (email != null) data['email'] = email;
    if (pastorName != null) data['pastor_name'] = pastorName;
    if (subscriptionStatus != null) data['subscription_status'] = subscriptionStatus;
    if (subscriptionEndDate != null) data['subscription_end_date'] = subscriptionEndDate!.toIso8601String();
    if (memberLimit != null) data['member_limit'] = memberLimit;
    if (isActive != null) data['is_active'] = isActive;
    return data;
  }
}
