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
    print('🔔 QR_SERVICE: generateQRCode 시작 - memberId: $memberId');
    try {
      final requestBody = {
        'member_id': memberId,
        'qr_type': 'attendance',
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };
      
      print('🔔 QR_SERVICE: 요청 데이터: $requestBody');
      final url = '${ApiConfig.qrCodes}generate/$memberId';
      print('🔔 QR_SERVICE: API URL: $url');
      
      final response = await _apiService.post<QRCodeInfo>(
        url,
        body: requestBody,
        fromJson: (json) => QRCodeInfo.fromJson(json),
      );
      
      print('🔔 QR_SERVICE: API 응답 - success: ${response.success}, message: ${response.message}');
      if (response.data != null) {
        print('🔔 QR_SERVICE: QR 코드 생성 성공 - code: ${response.data!.code}');
      }

      return response;
    } catch (e) {
      print('🔔 QR_SERVICE: generateQRCode 예외 - $e');
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
        '${ApiConfig.qrCodes}qr_info/$code',
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
    print('🔍 QR_SERVICE: getMemberQRCodes 시작 - memberId: $memberId');
    try {
      final url = '${ApiConfig.qrCodes}member/$memberId';
      print('🔍 QR_SERVICE: API 호출 URL: $url');
      
      final response = await _apiService.get<dynamic>(
        url,
      );
      
      print('🔍 QR_SERVICE: API 응답 - success: ${response.success}');
      print('🔍 QR_SERVICE: API 응답 - message: "${response.message}"');
      print('🔍 QR_SERVICE: API 응답 - data null 여부: ${response.data == null}');

      if (response.success && response.data != null) {
        print('🔍 QR_SERVICE: 원본 데이터 타입: ${response.data.runtimeType}');
        
        List<QRCodeInfo> qrCodes;
        
        if (response.data is List) {
          // 배열로 오는 경우 (기존 로직)
          print('🔍 QR_SERVICE: 배열 형태 데이터 - 길이: ${(response.data as List).length}');
          qrCodes = (response.data as List)
              .map((qrJson) {
                print('🔍 QR_SERVICE: QR 데이터 파싱: $qrJson');
                return QRCodeInfo.fromJson(qrJson);
              })
              .toList();
        } else if (response.data is Map) {
          // 단일 객체로 오는 경우 (현재 백엔드)
          print('🔍 QR_SERVICE: 단일 객체 형태 데이터');
          print('🔍 QR_SERVICE: QR 데이터 파싱: ${response.data}');
          final qrInfo = QRCodeInfo.fromJson(response.data as Map<String, dynamic>);
          qrCodes = [qrInfo]; // 단일 객체를 배열로 변환
        } else {
          print('🔍 QR_SERVICE: 예상치 못한 데이터 타입: ${response.data.runtimeType}');
          return ApiResponse<List<QRCodeInfo>>(
            success: false,
            message: '예상치 못한 데이터 타입: ${response.data.runtimeType}',
            data: null,
          );
        }
        
        print('🔍 QR_SERVICE: 파싱된 QR 코드 수: ${qrCodes.length}');
        for (int i = 0; i < qrCodes.length; i++) {
          final qr = qrCodes[i];
          print('🔍 QR_SERVICE: [$i] code: ${qr.code}, active: ${qr.isActive}, expires: ${qr.expiresAt}');
        }

        return ApiResponse<List<QRCodeInfo>>(
          success: true,
          message: 'QR 코드 목록 조회 성공',
          data: qrCodes,
        );
      }

      print('🔍 QR_SERVICE: API 응답 실패 또는 데이터 없음');
      return ApiResponse<List<QRCodeInfo>>(
        success: false,
        message: response.message,
        data: null,
      );
    } catch (e) {
      print('🔍 QR_SERVICE: getMemberQRCodes 예외 - $e');
      return ApiResponse<List<QRCodeInfo>>(
        success: false,
        message: '교인 QR 코드 조회 실패: ${e.toString()}',
        data: null,
      );
    }
  }
}
