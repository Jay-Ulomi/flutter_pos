import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_constants.dart';
import 'app_constants.dart';
import 'exceptions.dart';
import 'token_manager.dart';

class ApiClient {
  late final Dio dio;
  final TokenManager tokenManager;

  ApiClient({required this.tokenManager}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(_AuthInterceptor(tokenManager, dio));
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await dio.delete(path);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'Connection timeout');
      case DioExceptionType.connectionError:
        return NetworkException(message: 'No internet connection');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        String message = 'Server error';
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? data['error'] ?? message;
        }
        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        }
        return ServerException(message: message, statusCode: statusCode);
      default:
        return ServerException(message: e.message ?? 'Unknown error');
    }
  }
}

class _AuthInterceptor extends Interceptor {
  final TokenManager _tokenManager;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this._tokenManager, this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login and refresh endpoints
    if (options.path.contains('/auth/login') ||
        options.path.contains('/auth/refresh-token')) {
      return handler.next(options);
    }

    final token = await _tokenManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/login') &&
        !err.requestOptions.path.contains('/auth/refresh-token')) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshToken = await _tokenManager.getRefreshToken();
          if (refreshToken != null) {
            final response = await _dio.post(
              ApiConstants.refreshToken,
              data: {'refreshToken': refreshToken},
            );

            if (response.statusCode == 200) {
              final data = response.data;
              final newAccessToken =
                  data['data']?['accessToken'] ?? data['accessToken'];
              final newRefreshToken =
                  data['data']?['refreshToken'] ?? data['refreshToken'];

              if (newAccessToken != null) {
                await _tokenManager.saveTokens(
                  accessToken: newAccessToken,
                  refreshToken: newRefreshToken ?? refreshToken,
                );

                // Retry the failed request
                final opts = err.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                _isRefreshing = false;

                final retryResponse = await _dio.fetch(opts);
                return handler.resolve(retryResponse);
              }
            }
          }
          _isRefreshing = false;
          await _tokenManager.clearAll();
          handler.next(err);
        } catch (e) {
          _isRefreshing = false;
          await _tokenManager.clearAll();
          handler.next(err);
        }
      } else {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }
}
