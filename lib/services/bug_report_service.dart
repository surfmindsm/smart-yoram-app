import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/bug_report.dart';
import '../models/api_response.dart';

class BugReportService {
  static final BugReportService _instance = BugReportService._internal();
  factory BugReportService() => _instance;
  BugReportService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// 문제 신고 제출
  Future<ApiResponse<BugReport>> submitBugReport({
    required int userId,
    required int churchId,
    required String issueType,
    required String description,
  }) async {
    try {
      // 디바이스 정보 수집
      final deviceInfo = await _getDeviceInfo();
      final appVersion = await _getAppVersion();

      // 신고 데이터 생성
      final reportData = {
        'user_id': userId,
        'church_id': churchId,
        'issue_type': issueType,
        'description': description,
        'app_version': appVersion,
        'platform': deviceInfo['platform'],
        'os_version': deviceInfo['os_version'],
        'device_model': deviceInfo['device_model'],
        'status': 'pending',
      };

      print('📝 BUG_REPORT: 문제 신고 제출 중... $reportData');

      // Supabase에 저장
      final response = await _client
          .from('bug_reports')
          .insert(reportData)
          .select()
          .single();

      print('✅ BUG_REPORT: 문제 신고 성공 - ID: ${response['id']}');

      final bugReport = BugReport.fromJson(response);

      return ApiResponse<BugReport>(
        success: true,
        message: '문제가 성공적으로 신고되었습니다.',
        data: bugReport,
      );
    } catch (e) {
      print('❌ BUG_REPORT: 문제 신고 실패 - $e');
      return ApiResponse<BugReport>(
        success: false,
        message: '문제 신고 중 오류가 발생했습니다: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 디바이스 정보 수집
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      String platform = '';
      String osVersion = '';
      String deviceModel = '';

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        platform = 'Android';
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        platform = 'iOS';
        osVersion = 'iOS ${iosInfo.systemVersion}';
        deviceModel = iosInfo.utsname.machine ?? iosInfo.model ?? 'Unknown';
      }

      return {
        'platform': platform,
        'os_version': osVersion,
        'device_model': deviceModel,
      };
    } catch (e) {
      print('⚠️ BUG_REPORT: 디바이스 정보 수집 실패 - $e');
      return {
        'platform': Platform.isAndroid ? 'Android' : 'iOS',
        'os_version': 'Unknown',
        'device_model': 'Unknown',
      };
    }
  }

  /// 앱 버전 정보 가져오기
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      print('⚠️ BUG_REPORT: 앱 버전 정보 가져오기 실패 - $e');
      return 'Unknown';
    }
  }

  /// 내 신고 목록 조회 (선택적 기능)
  Future<ApiResponse<List<BugReport>>> getMyBugReports(int userId) async {
    try {
      final response = await _client
          .from('bug_reports')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final reports = (response as List)
          .map((json) => BugReport.fromJson(json))
          .toList();

      return ApiResponse<List<BugReport>>(
        success: true,
        message: '신고 목록 조회 성공',
        data: reports,
      );
    } catch (e) {
      print('❌ BUG_REPORT: 신고 목록 조회 실패 - $e');
      return ApiResponse<List<BugReport>>(
        success: false,
        message: '신고 목록 조회 중 오류가 발생했습니다: ${e.toString()}',
        data: null,
      );
    }
  }
}
