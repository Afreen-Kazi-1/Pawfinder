import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage tokenStorage;
  bool _isRefreshing = false;

  ApiClient({
    Dio? customDio,
    required this.tokenStorage,
    String? baseUrl,
  }) : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? ApiConstants.baseUrl,
                connectTimeout: ApiConstants.connectTimeout,
                receiveTimeout: ApiConstants.receiveTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Exclude auth routes from automatic token attachment
          final path = options.path;
          final isAuthEndpoint = path.contains(ApiConstants.login) ||
              path.contains(ApiConstants.register) ||
              path.contains(ApiConstants.refresh);

          if (!isAuthEndpoint) {
            final token = await tokenStorage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Automatic 401 token refresh logic
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains(ApiConstants.login) &&
              !error.requestOptions.path.contains(ApiConstants.refresh)) {
            if (!_isRefreshing) {
              _isRefreshing = true;
              final refreshToken = await tokenStorage.getRefreshToken();
              if (refreshToken != null && refreshToken.isNotEmpty) {
                try {
                  // Create isolated dio without interceptors for refresh call
                  final refreshDio = Dio(
                    BaseOptions(
                      baseUrl: dio.options.baseUrl,
                      headers: {'Content-Type': 'application/json'},
                    ),
                  );

                  final response = await refreshDio.post(
                    ApiConstants.refresh,
                    data: {'refresh_token': refreshToken},
                  );

                  if (response.statusCode == 200) {
                    final newAccessToken = response.data['access_token'];
                    final newRefreshToken = response.data['refresh_token'];

                    await tokenStorage.saveTokens(
                      accessToken: newAccessToken,
                      refreshToken: newRefreshToken,
                    );

                    _isRefreshing = false;

                    // Retry original request with new token
                    final retryOptions = error.requestOptions;
                    retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';

                    final clonedResponse = await dio.fetch(retryOptions);
                    return handler.resolve(clonedResponse);
                  }
                } catch (refreshErr) {
                  _isRefreshing = false;
                  await tokenStorage.clearTokens();
                  return handler.next(error);
                }
              }
              _isRefreshing = false;
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Generic Request Handlers wrapping Dio exceptions into ApiException
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

