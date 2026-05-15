import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../utils/token_storage.dart';
import 'failure.dart';

/// Configures and provides the singleton Dio instance.
class ApiClient {
  // Use 10.0.2.2 for Android emulator to reach host localhost.
  // Use localhost for iOS simulator.
  static String get _baseUrl {
    // Use your PC's IP address for physical device testing.
    // Ensure your phone is connected to the same Wi-Fi network as your PC.
    return 'https://fa67-197-63-206-127.ngrok-free.app';
  }

  final Dio dio;
  final TokenStorage _tokenStorage; 

  String get baseUrl => _baseUrl;

  ApiClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage,
        dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 20),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.addAll([
      _AuthInterceptor(tokenStorage: _tokenStorage, dio: dio),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {
          // Only log in debug mode, never log sensitive data.
          assert(() {
            // ignore: avoid_print
            print(obj);
            return true;
          }());
        },
      ),
    ]);
  }
}

/// Attaches JWT token to requests and handles 401 refresh.
class _AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final Dio _dio;
  bool _isRefreshing = false;

  _AuthInterceptor({required TokenStorage tokenStorage, required Dio dio})
      : _tokenStorage = tokenStorage,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await _tokenStorage.getRefreshToken();
        if (refreshToken == null) {
          _isRefreshing = false;
          return handler.next(err);
        }

        // Attempt token refresh.
        final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
        final response = await refreshDio.post(
          ApiEndpoints.refreshToken,
          data: {'refreshToken': refreshToken},
        );

        final newAccess = response.data['data']['accessToken'] as String;
        final newRefresh = response.data['data']['refreshToken'] as String;
        await _tokenStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh,
        );

        // Retry the original request with the new token.
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retryResponse = await _dio.fetch(retryOptions);
        _isRefreshing = false;
        return handler.resolve(retryResponse);
      } catch (_) {
        _isRefreshing = false;
        await _tokenStorage.clearAll();
        return handler.next(err);
      }
    }
    handler.next(err);
  }
}

/// Maps DioException to typed Failure.
Failure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkFailure('Connection error: ${e.message ?? "Server is unreachable. Make sure the backend is running."}');
    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Server error';
      List<String>? errors;

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          message = data['message'] as String;
        } else if (data['title'] != null) {
          message = data['title'] as String;
        }

        if (data['errors'] is Map) {
          errors = [];
          for (final value in (data['errors'] as Map).values) {
            if (value is List) {
              errors.addAll(value.map((e) => e.toString()));
            } else {
              errors.add(value.toString());
            }
          }
          if (errors.isNotEmpty && (message == 'Server error' || message.contains('validation errors'))) {
            message = errors.first; // Show the first specific error to the user
          }
        } else if (data['errors'] is List) {
          errors = (data['errors'] as List).cast<String>();
          if (errors.isNotEmpty && message == 'Server error') {
            message = errors.first;
          }
        }
      }

      if (statusCode == 401) return const AuthFailure();
      if (statusCode == 404) return NotFoundFailure(message);
      if (statusCode == 503) return ServerFailure(message, statusCode: 503);
      if (statusCode == 422 || statusCode == 400) {
        return ValidationFailure(message, fieldErrors: null);
      }
      return ServerFailure(message, statusCode: statusCode, errors: errors);
    default:
      return const UnknownFailure();
  }
}
