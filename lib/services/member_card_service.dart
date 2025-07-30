import '../models/api_response.dart';
import '../models/member_card_model.dart';
import 'api_service.dart';

class MemberCardService {
  static final MemberCardService _instance = MemberCardService._internal();
  factory MemberCardService() => _instance;
  MemberCardService._internal();

  final ApiService _apiService = ApiService();

  /// 교인증 데이터 조회
  Future<ApiResponse<MemberCard>> getMemberCard(int memberId) async {
    return await _apiService.get<MemberCard>(
      '/member-card/$memberId/card',
      fromJson: (json) => MemberCard.fromJson(json),
    );
  }

  /// 모바일 교인증 HTML 조회
  Future<ApiResponse<String>> getMemberCardHtml(int memberId) async {
    return await _apiService.get<String>(
      '/member-card/$memberId/card/html',
    );
  }

  /// 교인증 QR 코드 재생성
  Future<ApiResponse<MemberCardQRCode>> regenerateQRCode(int memberId) async {
    return await _apiService.post<MemberCardQRCode>(
      '/member-card/$memberId/card/regenerate-qr',
      fromJson: (json) => MemberCardQRCode.fromJson(json),
    );
  }
}
