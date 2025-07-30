import '../models/api_response.dart';
import '../models/calendar_model.dart';
import 'api_service.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  final ApiService _apiService = ApiService();

  /// 일정 목록 조회
  Future<ApiResponse<List<CalendarEvent>>> getEvents({
    int skip = 0,
    int limit = 100,
    String? startDate,
    String? endDate,
    String? eventType,
  }) async {
    String query = '?skip=$skip&limit=$limit';
    if (startDate != null) query += '&start_date=$startDate';
    if (endDate != null) query += '&end_date=$endDate';
    if (eventType != null) query += '&event_type=$eventType';

    final response = await _apiService.get<List<dynamic>>(
      '/calendar/$query',
    );

    if (response.success && response.data != null) {
      final events = response.data!
          .map((json) => CalendarEvent.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse<List<CalendarEvent>>(
        success: true,
        message: response.message,
        data: events,
      );
    }

    return ApiResponse<List<CalendarEvent>>(
      success: false,
      message: response.message,
      data: null,
    );
  }

  /// 새 일정 생성
  Future<ApiResponse<CalendarEvent>> createEvent({
    required String title,
    String? description,
    required String eventType,
    required String eventDate,
    String? eventTime,
    bool isRecurring = false,
  }) async {
    final body = {
      'title': title,
      if (description != null) 'description': description,
      'event_type': eventType,
      'event_date': eventDate,
      if (eventTime != null) 'event_time': eventTime,
      'is_recurring': isRecurring,
    };

    return await _apiService.post<CalendarEvent>(
      '/calendar/',
      body: body,
      fromJson: (json) => CalendarEvent.fromJson(json),
    );
  }

  /// 일정 수정
  Future<ApiResponse<CalendarEvent>> updateEvent({
    required int eventId,
    String? title,
    String? description,
    String? eventType,
    String? eventDate,
    String? eventTime,
    bool? isRecurring,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (eventType != null) body['event_type'] = eventType;
    if (eventDate != null) body['event_date'] = eventDate;
    if (eventTime != null) body['event_time'] = eventTime;
    if (isRecurring != null) body['is_recurring'] = isRecurring;

    return await _apiService.put<CalendarEvent>(
      '/calendar/$eventId',
      body: body,
      fromJson: (json) => CalendarEvent.fromJson(json),
    );
  }

  /// 일정 삭제
  Future<ApiResponse<void>> deleteEvent(int eventId) async {
    return await _apiService.delete<void>('/calendar/$eventId');
  }

  /// 다가오는 생일 조회
  Future<ApiResponse<List<BirthdayEvent>>> getUpcomingBirthdays({
    int daysAhead = 30,
  }) async {
    final response = await _apiService.get<List<dynamic>>(
      '/calendar/birthdays?days_ahead=$daysAhead',
    );

    if (response.success && response.data != null) {
      final birthdays = response.data!
          .map((json) => BirthdayEvent.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse<List<BirthdayEvent>>(
        success: true,
        message: response.message,
        data: birthdays,
      );
    }

    return ApiResponse<List<BirthdayEvent>>(
      success: false,
      message: response.message,
      data: null,
    );
  }

  /// 생일 일정 자동 생성
  Future<ApiResponse<void>> createBirthdayEvents() async {
    return await _apiService.post<void>('/calendar/birthdays/create-events');
  }
}
