class BugReport {
  final int? id;
  final int userId;
  final int churchId;
  final String issueType;
  final String description;
  final String? appVersion;
  final String? platform;
  final String? osVersion;
  final String? deviceModel;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BugReport({
    this.id,
    required this.userId,
    required this.churchId,
    required this.issueType,
    required this.description,
    this.appVersion,
    this.platform,
    this.osVersion,
    this.deviceModel,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  factory BugReport.fromJson(Map<String, dynamic> json) {
    return BugReport(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      churchId: json['church_id'] ?? 0,
      issueType: json['issue_type'] ?? '',
      description: json['description'] ?? '',
      appVersion: json['app_version'],
      platform: json['platform'],
      osVersion: json['os_version'],
      deviceModel: json['device_model'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'church_id': churchId,
      'issue_type': issueType,
      'description': description,
      if (appVersion != null) 'app_version': appVersion,
      if (platform != null) 'platform': platform,
      if (osVersion != null) 'os_version': osVersion,
      if (deviceModel != null) 'device_model': deviceModel,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BugReport(id: $id, issueType: $issueType, status: $status)';
  }
}
