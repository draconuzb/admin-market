import 'package:dio/dio.dart';

/// Normalized API error carrying the backend's `{code, message}` payload.
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    final data = response?.data;
    if (data is Map && data['detail'] is Map) {
      final detail = data['detail'] as Map;
      return ApiException(
        detail['code']?.toString() ?? 'error',
        detail['message']?.toString() ?? 'Error',
        statusCode: response?.statusCode,
      );
    }
    if (data is Map && data['detail'] is String) {
      return ApiException('error', data['detail'], statusCode: response?.statusCode);
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException('network', 'Cannot reach server', statusCode: null);
    }
    return ApiException('error', e.message ?? 'Error', statusCode: response?.statusCode);
  }

  @override
  String toString() => message;
}
