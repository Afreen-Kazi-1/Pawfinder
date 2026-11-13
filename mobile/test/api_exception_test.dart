import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawfinder/core/network/api_exception.dart';

void main() {
  group('ApiException Tests', () {
    test('Handles timeout exceptions properly', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.message, contains('timed out'));
    });

    test('Handles 401 unauthorized response', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'detail': 'Invalid credentials'},
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, 401);
      expect(apiException.message, 'Invalid credentials');
    });

    test('Handles 422 validation errors with Pydantic format', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 422,
          data: {
            'detail': [
              {'loc': ['body', 'email'], 'msg': 'value is not a valid email address'}
            ]
          },
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, 422);
      expect(apiException.message, 'value is not a valid email address');
      expect(apiException.errors, isNotNull);
    });

    test('Handles 409 conflict error', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 409,
          data: {'detail': 'Email is already registered'},
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, 409);
      expect(apiException.message, 'Email is already registered');
    });

    test('Handles 500 server error', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.statusCode, 500);
      expect(apiException.message, contains('Server error'));
    });

    test('Handles connection error', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionError,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.message, contains('Cannot connect to server'));
    });
  });
}

