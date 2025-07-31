import '../config/api_config.dart';
import '../models/api_response.dart';
import '../models/qr_code.dart';
import 'api_service.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final ApiService _apiService = ApiService();

  // 교인의 QR 코드 생성
  Future<ApiResponse<QRCodeInfo>> generateQRCode(int memberId) async {
    try {
      final requestBody = {
        'qr_type': 'attendance',
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };
      
      final response = await _apiService.post<QRCodeInfo>(
        '${ApiConfig.qrCodes}generate/$memberId',
        body: requestBody,
        fromJson: (json) => QRCodeInfo.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<QRCodeInfo>(
        success: false,
        message: 'QR 코드 생성 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // QR 코드 정보 조회
  Future<ApiResponse<QRCodeInfo>> getQRCodeInfo(String code) async {
    try {
      final response = await _apiService.get<QRCodeInfo>(
        '${ApiConfig.qrCodes}$code',
        fromJson: (json) => QRCodeInfo.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<QRCodeInfo>(
        success: false,
        message: 'QR 코드 정보 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // QR 코드 스캔 및 출석 체크
  Future<ApiResponse<QRScanResult>> scanQRCode(
    String code, {
    String attendanceType = '주일예배',
  }) async {
    try {
      final response = await _apiService.post<QRScanResult>(
        '${ApiConfig.qrCodes}verify/$code?attendance_type=${Uri.encodeComponent(attendanceType)}',
        fromJson: (json) => QRScanResult.fromJson(json),
      );

      return response;
    } catch (e) {
      return ApiResponse<QRScanResult>(
        success: false,
        message: 'QR 코드 스캔 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // QR 코드 이미지 URL 가져오기
  String getQRCodeImageUrl(String code) {
    return '${ApiConfig.baseUrl}${ApiConfig.qrCodes}$code/image';
  }

  // QR 코드 비활성화
  Future<ApiResponse<void>> deactivateQRCode(String code) async {
    try {
      final response = await _apiService.post<void>(
        '${ApiConfig.qrCodes}$code/deactivate',
      );

      return response;
    } catch (e) {
      return ApiResponse<void>(
        success: false,
        message: 'QR 코드 비활성화 실패: ${e.toString()}',
        data: null,
      );
    }
  }

  // 교인의 모든 QR 코드 조회
  Future<ApiResponse<List<QRCodeInfo>>> getMemberQRCodes(int memberId) async {
    try {
      final response = await _apiService.get<List<dynamic>>(
        '${ApiConfig.qrCodes}member/$memberId',
      );

      if (response.success && response.data != null) {
        final List<QRCodeInfo> qrCodes = (response.data as List)
            .map((qrJson) => QRCodeInfo.fromJson(qrJson))
            .toList();

        return ApiResponse<List<QRCodeInfo>>(
          success: true,
          message: 'QR 코드 목록 조회 성공',
          data: qrCodes,
        );
      }

      return ApiResponse<List<QRCodeInfo>>(
        success: false,
        message: response.message,
        data: null,
      );
    } catch (e) {
      return ApiResponse<List<QRCodeInfo>>(
        success: false,
        message: '교인 QR 코드 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }
}
