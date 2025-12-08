import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class AppVersionService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 현재 앱의 버전 정보를 가져옵니다
  Future<String> getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('❌ APP_VERSION: Failed to get current version: $e');
      return '0.0.0';
    }
  }

  /// 현재 플랫폼을 가져옵니다
  String getCurrentPlatform() {
    if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    }
    return 'unknown';
  }

  /// 버전을 비교합니다 (semantic versioning)
  /// 반환값: -1 (v1 < v2), 0 (v1 == v2), 1 (v1 > v2)
  int compareVersions(String v1, String v2) {
    try {
      final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

      for (int i = 0; i < maxLength; i++) {
        final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
        final v2Part = i < v2Parts.length ? v2Parts[i] : 0;

        if (v1Part < v2Part) return -1;
        if (v1Part > v2Part) return 1;
      }

      return 0;
    } catch (e) {
      print('❌ APP_VERSION: Failed to compare versions: $e');
      return 0;
    }
  }

  /// Supabase에서 버전 정보를 가져옵니다
  Future<ApiResponse<AppVersion>> getVersionInfo() async {
    try {
      print('🔍 APP_VERSION: Fetching version info from Supabase...');

      final platform = getCurrentPlatform();
      print('📱 APP_VERSION: Current platform: $platform');

      final response = await _supabase
          .from('app_versions')
          .select()
          .eq('platform', platform)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        print('⚠️ APP_VERSION: No version info found for platform: $platform');
        return ApiResponse(
          success: false,
          message: 'No version info found for current platform',
        );
      }

      final versionInfo = AppVersion.fromJson(response);
      print('✅ APP_VERSION: Version info fetched successfully');
      print('   Min version: ${versionInfo.minVersion}');
      print('   Latest version: ${versionInfo.latestVersion}');

      return ApiResponse(
        success: true,
        message: 'Version info fetched successfully',
        data: versionInfo,
      );
    } catch (e) {
      print('❌ APP_VERSION: Failed to fetch version info: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to fetch version info: $e',
      );
    }
  }

  /// 버전 체크를 수행하고 업데이트 필요 여부를 반환합니다
  Future<VersionCheckResult> checkVersion() async {
    try {
      print('🔍 APP_VERSION: Starting version check...');

      // 1. 현재 앱 버전 가져오기
      final currentVersion = await getCurrentVersion();
      print('📱 APP_VERSION: Current app version: $currentVersion');

      // 2. Supabase에서 버전 정보 가져오기
      final versionInfoResponse = await getVersionInfo();
      if (!versionInfoResponse.success || versionInfoResponse.data == null) {
        print('⚠️ APP_VERSION: Failed to get version info, assuming no update needed');
        return VersionCheckResult(
          updateType: UpdateType.none,
          currentVersion: currentVersion,
        );
      }

      final versionInfo = versionInfoResponse.data!;

      // 3. 최소 버전과 비교 (강제 업데이트 체크)
      final minVersionComparison = compareVersions(currentVersion, versionInfo.minVersion);
      if (minVersionComparison < 0) {
        print('⚠️ APP_VERSION: Force update required');
        print('   Current: $currentVersion, Min required: ${versionInfo.minVersion}');
        return VersionCheckResult(
          updateType: UpdateType.required,
          versionInfo: versionInfo,
          currentVersion: currentVersion,
        );
      }

      // 4. 최신 버전과 비교 (선택적 업데이트 체크)
      final latestVersionComparison = compareVersions(currentVersion, versionInfo.latestVersion);
      if (latestVersionComparison < 0) {
        print('ℹ️ APP_VERSION: Optional update available');
        print('   Current: $currentVersion, Latest: ${versionInfo.latestVersion}');
        return VersionCheckResult(
          updateType: UpdateType.optional,
          versionInfo: versionInfo,
          currentVersion: currentVersion,
        );
      }

      // 5. 업데이트 필요 없음
      print('✅ APP_VERSION: App is up to date');
      return VersionCheckResult(
        updateType: UpdateType.none,
        versionInfo: versionInfo,
        currentVersion: currentVersion,
      );
    } catch (e) {
      print('❌ APP_VERSION: Version check failed: $e');
      final currentVersion = await getCurrentVersion();
      return VersionCheckResult(
        updateType: UpdateType.none,
        currentVersion: currentVersion,
      );
    }
  }
}
