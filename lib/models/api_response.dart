class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  // 성공 응답 생성자
  factory ApiResponse.success(T? data, {String? message}) {
    return ApiResponse<T>(
      success: true,
      message: message ?? '성공',
      data: data,
      statusCode: 200,
    );
  }

  // 에러 응답 생성자
  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
      statusCode: statusCode ?? 400,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: fromJsonT != null && json['data'] != null 
          ? fromJsonT(json['data']) 
          : json['data'] as T?,
      statusCode: json['statusCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'statusCode': statusCode,
    };
  }

  // 편의 getter
  bool get isSuccess => success;
  bool get isError => !success;
  bool get hasData => data != null;

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data)';
  }
}
