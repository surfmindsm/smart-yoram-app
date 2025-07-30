import '../models/api_response.dart';
import '../models/sms_model.dart';
import 'api_service.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final ApiService _apiService = ApiService();

  /// 개별 SMS 발송
  Future<ApiResponse<SmsRecord>> sendSms({
    required String recipientPhone,
    int? recipientMemberId,
    required String message,
    required String smsType,
  }) async {
    final body = {
      'recipient_phone': recipientPhone,
      if (recipientMemberId != null) 'recipient_member_id': recipientMemberId,
      'message': message,
      'sms_type': smsType,
    };

    return await _apiService.post<SmsRecord>(
      '/sms/send',
      body: body,
      fromJson: (json) => SmsRecord.fromJson(json),
    );
  }

  /// 단체 SMS 발송
  Future<ApiResponse<BulkSmsResult>> sendBulkSms({
    required List<int> recipientMemberIds,
    required String message,
    required String smsType,
  }) async {
    final body = {
      'recipient_member_ids': recipientMemberIds,
      'message': message,
      'sms_type': smsType,
    };

    return await _apiService.post<BulkSmsResult>(
      '/sms/send-bulk',
      body: body,
      fromJson: (json) => BulkSmsResult.fromJson(json),
    );
  }

  /// SMS 발송 기록 조회
  Future<ApiResponse<List<SmsRecord>>> getSmsHistory({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _apiService.get<List<dynamic>>(
      '/sms/history?skip=$skip&limit=$limit',
    );

    if (response.success && response.data != null) {
      final records = response.data!
          .map((json) => SmsRecord.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse<List<SmsRecord>>(
        success: true,
        message: response.message,
        data: records,
      );
    }

    return ApiResponse<List<SmsRecord>>(
      success: false,
      message: response.message,
      data: null,
    );
  }

  /// SMS 템플릿 조회
  Future<ApiResponse<List<SmsTemplate>>> getSmsTemplates() async {
    final response = await _apiService.get<List<dynamic>>(
      '/sms/templates',
    );

    if (response.success && response.data != null) {
      final templates = response.data!
          .map((json) => SmsTemplate.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return ApiResponse<List<SmsTemplate>>(
        success: true,
        message: response.message,
        data: templates,
      );
    }

    return ApiResponse<List<SmsTemplate>>(
      success: false,
      message: response.message,
      data: null,
    );
  }
}
