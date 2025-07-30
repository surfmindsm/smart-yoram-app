import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_response.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _accessToken;
  
  // 토큰 관리
  void setToken(String token) {
    _accessToken = token;
  }
  
  String? get token => _accessToken;
  
  void clearToken() {
    _accessToken = null;
  }
  
  bool get isAuthenticated => _accessToken != null;

  // 공통 HTTP 요청 메서드
  Future<ApiResponse<T>> _makeRequest<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      Map<String, String> requestHeaders = headers ?? ApiConfig.defaultHeaders;
      
      if (requiresAuth && _accessToken != null) {
        requestHeaders = ApiConfig.authHeaders(_accessToken!);
      }

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return _handleResponse<T>(response, fromJson);
      
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: '네트워크 오류: ${e.toString()}',
        data: null,
      );
    }
  }

  // 응답 처리
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        T? data;
        if (fromJson != null && responseData != null) {
          if (responseData is List) {
            // 리스트 데이터 처리는 별도로 처리 필요
            data = responseData as T;
          } else if (responseData is Map<String, dynamic>) {
            data = fromJson(responseData);
          }
        } else {
          data = responseData as T?;
        }
        
        return ApiResponse<T>(
          success: true,
          message: '성공',
          data: data,
        );
      } else {
        String errorMessage = '알 수 없는 오류가 발생했습니다.';
        
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['detail']?.toString() ?? 
                         responseData['message']?.toString() ?? 
                         errorMessage;
        } else if (responseData is String) {
          errorMessage = responseData;
        }
        
        return ApiResponse<T>(
          success: false,
          message: errorMessage,
          data: null,
        );
      }
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: '응답 파싱 오류: ${e.toString()}',
        data: null,
      );
    }
  }

  // 폼 데이터 POST 요청 (로그인용)
  Future<ApiResponse<T>> _makeFormRequest<T>(
    String endpoint,
    Map<String, String> formData, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      final response = await http.post(
        url,
        headers: ApiConfig.formHeaders,
        body: formData,
      );

      return _handleResponse<T>(response, fromJson);
      
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: '네트워크 오류: ${e.toString()}',
        data: null,
      );
    }
  }

  // GET 요청
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _makeRequest<T>('GET', endpoint, 
        fromJson: fromJson, requiresAuth: requiresAuth);
  }

  // POST 요청
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _makeRequest<T>('POST', endpoint, 
        body: body, fromJson: fromJson, requiresAuth: requiresAuth);
  }

  // PUT 요청
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _makeRequest<T>('PUT', endpoint, 
        body: body, fromJson: fromJson, requiresAuth: requiresAuth);
  }

  // DELETE 요청
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(Map<String, dynamic>)? fromJson,
    bool requiresAuth = true,
  }) async {
    return _makeRequest<T>('DELETE', endpoint, 
        fromJson: fromJson, requiresAuth: requiresAuth);
  }

  // 폼 데이터 POST (로그인용)
  Future<ApiResponse<T>> postForm<T>(
    String endpoint,
    Map<String, String> formData, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    return _makeFormRequest<T>(endpoint, formData, fromJson: fromJson);
  }
}
