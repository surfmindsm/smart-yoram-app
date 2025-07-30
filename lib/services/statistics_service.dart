import '../models/api_response.dart';
import '../models/statistics_model.dart';
import 'api_service.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  final ApiService _apiService = ApiService();

  /// 출석 통계 요약
  Future<ApiResponse<AttendanceSummary>> getAttendanceSummary({
    String? startDate,
    String? endDate,
    String? attendanceType,
  }) async {
    String query = '';
    if (startDate != null) query += 'start_date=$startDate';
    if (endDate != null) {
      if (query.isNotEmpty) query += '&';
      query += 'end_date=$endDate';
    }
    if (attendanceType != null) {
      if (query.isNotEmpty) query += '&';
      query += 'attendance_type=$attendanceType';
    }

    return await _apiService.get<AttendanceSummary>(
      '/statistics/attendance/summary${query.isNotEmpty ? '?$query' : ''}',
      fromJson: (json) => AttendanceSummary.fromJson(json),
    );
  }

  /// 교인별 출석 통계
  Future<ApiResponse<List<MemberAttendanceStats>>> getMemberAttendanceStats({
    String? startDate,
    String? endDate,
  }) async {
    String query = '';
    if (startDate != null) query += 'start_date=$startDate';
    if (endDate != null) {
      if (query.isNotEmpty) query += '&';
      query += 'end_date=$endDate';
    }

    final response = await _apiService.get<List<dynamic>>(
      '/statistics/attendance/by-member${query.isNotEmpty ? '?$query' : ''}',
    );

    if (response.success && response.data != null) {
      final stats = response.data!
          .map((json) => MemberAttendanceStats.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse<List<MemberAttendanceStats>>(
        success: true,
        message: response.message,
        data: stats,
      );
    }

    return ApiResponse<List<MemberAttendanceStats>>(
      success: false,
      message: response.message,
      data: null,
    );
  }

  /// 교인 인구통계
  Future<ApiResponse<MemberDemographics>> getMemberDemographics() async {
    return await _apiService.get<MemberDemographics>(
      '/statistics/members/demographics',
      fromJson: (json) => MemberDemographics.fromJson(json),
    );
  }

  /// 교인 증가 추이
  Future<ApiResponse<MemberGrowthStats>> getMemberGrowthStats({
    int months = 12,
  }) async {
    return await _apiService.get<MemberGrowthStats>(
      '/statistics/members/growth?months=$months',
      fromJson: (json) => MemberGrowthStats.fromJson(json),
    );
  }

  /// 대시보드용 전체 통계
  Future<ApiResponse<DashboardStats>> getDashboardStats() async {
    return await _apiService.get<DashboardStats>(
      '/statistics/dashboard',
      fromJson: (json) => DashboardStats.fromJson(json),
    );
  }
}
