import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Please check your internet connection.',
          statusCode: dioException.response?.statusCode,
        );

      case DioExceptionType.badResponse:
        final response = dioException.response;
        final statusCode = response?.statusCode;
        final data = response?.data;

        String extractedMessage = 'An unexpected error occurred.';
        dynamic errorsList;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('detail')) {
            final detail = data['detail'];
            if (detail is String) {
              extractedMessage = detail;
            } else if (detail is List) {
              // Pydantic validation error list
              extractedMessage = detail.isNotEmpty && detail[0] is Map && detail[0].containsKey('msg')
                  ? detail[0]['msg'].toString()
                  : 'Validation error occurred.';
              errorsList = detail;
            }
          } else if (data.containsKey('errors')) {
            errorsList = data['errors'];
            extractedMessage = 'Request validation failed.';
          }
        }

        if (statusCode == 401) {
          return ApiException(
            message: extractedMessage.isNotEmpty ? extractedMessage : 'Invalid credentials or session expired.',
            statusCode: 401,
          );
        } else if (statusCode == 403) {
          return ApiException(
            message: extractedMessage.isNotEmpty ? extractedMessage : 'Access denied.',
            statusCode: 403,
          );
        } else if (statusCode == 404) {
          return ApiException(
            message: extractedMessage.isNotEmpty ? extractedMessage : 'Requested resource was not found.',
            statusCode: 404,
          );
        } else if (statusCode == 409) {
          return ApiException(
            message: extractedMessage,
            statusCode: 409,
          );
        } else if (statusCode == 422) {
          return ApiException(
            message: extractedMessage,
            statusCode: 422,
            errors: errorsList,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ApiException(
            message: 'Server error. Please try again later.',
            statusCode: statusCode,
          );
        }

        return ApiException(
          message: extractedMessage,
          statusCode: statusCode,
          errors: errorsList,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Cannot connect to server. Please check your network.',
        );

      case DioExceptionType.cancel:
        return ApiException(message: 'Request was cancelled.');

      default:
        return ApiException(
          message: dioException.message ?? 'An unexpected network error occurred.',
        );
    }
  }

  @override
  String toString() => message;
}

