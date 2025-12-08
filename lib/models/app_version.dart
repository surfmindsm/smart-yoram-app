class AppVersion {
  final int id;
  final String platform;
  final String minVersion;
  final String latestVersion;
  final String storeUrl;
  final String? updateMessage;
  final String? forceUpdateMessage;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppVersion({
    required this.id,
    required this.platform,
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    this.updateMessage,
    this.forceUpdateMessage,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      id: json['id'] as int,
      platform: json['platform'] as String,
      minVersion: json['min_version'] as String,
      latestVersion: json['latest_version'] as String,
      storeUrl: json['store_url'] as String,
      updateMessage: json['update_message'] as String?,
      forceUpdateMessage: json['force_update_message'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'min_version': minVersion,
      'latest_version': latestVersion,
      'store_url': storeUrl,
      'update_message': updateMessage,
      'force_update_message': forceUpdateMessage,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AppVersion(platform: $platform, minVersion: $minVersion, latestVersion: $latestVersion)';
  }
}

enum UpdateType {
  none, // 업데이트 필요 없음
  optional, // 선택적 업데이트 (소프트 업데이트)
  required, // 필수 업데이트 (강제 업데이트)
}

class VersionCheckResult {
  final UpdateType updateType;
  final AppVersion? versionInfo;
  final String currentVersion;

  const VersionCheckResult({
    required this.updateType,
    this.versionInfo,
    required this.currentVersion,
  });

  bool get needsUpdate => updateType != UpdateType.none;
  bool get isForceUpdate => updateType == UpdateType.required;
  bool get isOptionalUpdate => updateType == UpdateType.optional;

  String get updateMessage {
    if (versionInfo == null) return '';
    if (isForceUpdate) {
      return versionInfo!.forceUpdateMessage ??
          '필수 업데이트가 있습니다. 계속 사용하려면 앱을 업데이트해주세요.';
    }
    return versionInfo!.updateMessage ??
        '새로운 버전이 출시되었습니다. 업데이트하시겠습니까?';
  }

  @override
  String toString() {
    return 'VersionCheckResult(updateType: $updateType, currentVersion: $currentVersion)';
  }
}
