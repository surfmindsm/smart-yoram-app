import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/api_response.dart';
import '../models/excel_model.dart';
import '../config/supabase_config.dart';
import 'api_service.dart';

class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  final ApiService _apiService = ApiService();

  /// 교인 명단 엑셀 업로드
  Future<ApiResponse<ExcelUploadResult>> uploadMembersExcel(File file) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/excel/members/upload');
      final request = http.MultipartRequest('POST', url);
      
      // 인증 헤더 추가
      if (_apiService.token != null) {
        request.headers['Authorization'] = 'Bearer ${_apiService.token}';
      }

      // 파일 추가
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 성공 응답 처리
        return ApiResponse<ExcelUploadResult>(
          success: true,
          message: '엑셀 업로드가 완료되었습니다.',
          data: ExcelUploadResult.fromJson({
            'message': '업로드 완료',
            'created': 0,
            'updated': 0,
            'errors': [],
          }),
        );
      } else {
        return ApiResponse<ExcelUploadResult>(
          success: false,
          message: '엑셀 업로드에 실패했습니다.',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<ExcelUploadResult>(
        success: false,
        message: '엑셀 업로드 오류: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 교인 명단 엑셀 다운로드
  Future<ApiResponse<Uint8List>> downloadMembersExcel() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/excel/members/download');
      final headers = <String, String>{};
      
      if (_apiService.token != null) {
        headers['Authorization'] = 'Bearer ${_apiService.token}';
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<Uint8List>(
          success: true,
          message: '엑셀 다운로드가 완료되었습니다.',
          data: response.bodyBytes,
        );
      } else {
        return ApiResponse<Uint8List>(
          success: false,
          message: '엑셀 다운로드에 실패했습니다.',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Uint8List>(
        success: false,
        message: '엑셀 다운로드 오류: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 엑셀 업로드 템플릿 다운로드
  Future<ApiResponse<Uint8List>> downloadMembersTemplate() async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/excel/members/template');
      final headers = <String, String>{};
      
      if (_apiService.token != null) {
        headers['Authorization'] = 'Bearer ${_apiService.token}';
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<Uint8List>(
          success: true,
          message: '템플릿 다운로드가 완료되었습니다.',
          data: response.bodyBytes,
        );
      } else {
        return ApiResponse<Uint8List>(
          success: false,
          message: '템플릿 다운로드에 실패했습니다.',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Uint8List>(
        success: false,
        message: '템플릿 다운로드 오류: ${e.toString()}',
        data: null,
      );
    }
  }

  /// 출석 기록 엑셀 다운로드
  Future<ApiResponse<Uint8List>> downloadAttendanceExcel({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String query = '';
      if (startDate != null) query += 'start_date=$startDate';
      if (endDate != null) {
        if (query.isNotEmpty) query += '&';
        query += 'end_date=$endDate';
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/excel/attendance/download${query.isNotEmpty ? '?$query' : ''}');
      final headers = <String, String>{};
      
      if (_apiService.token != null) {
        headers['Authorization'] = 'Bearer ${_apiService.token}';
      }

      final response = await http.get(url, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse<Uint8List>(
          success: true,
          message: '출석기록 다운로드가 완료되었습니다.',
          data: response.bodyBytes,
        );
      } else {
        return ApiResponse<Uint8List>(
          success: false,
          message: '출석기록 다운로드에 실패했습니다.',
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<Uint8List>(
        success: false,
        message: '출석기록 다운로드 오류: ${e.toString()}',
        data: null,
      );
    }
  }
}
