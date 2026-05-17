import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';

/// ApiService — Dio HTTP client pre-configured for KiryanaAI backend.
/// Currently not connected to any backend.
/// Replace base URL and add auth interceptor when backend is ready.
class ApiService {
  static ApiService? _instance;
  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  factory ApiService() {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  Dio get client => _dio;

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // TODO: Add auth token here when backend is ready
          // final token = TokenStorage.getToken();
          // if (token != null) {
          //   options.headers['Authorization'] = 'Bearer $token';
          // }
          handler.next(options);
        },
        onResponse: (response, handler) {
          handler.next(response);
        },
        onError: (error, handler) {
          // Centralized error handling
          _handleError(error);
          handler.next(error);
        },
      ),
    );

    // Logging in debug mode
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint('[API] $obj'),
      ),
    );
  }

  void _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        debugPrint('[API Error] Connection timeout');
        break;
      case DioExceptionType.badResponse:
        debugPrint('[API Error] Bad response: ${error.response?.statusCode}');
        break;
      case DioExceptionType.connectionError:
        debugPrint('[API Error] No internet connection');
        break;
      default:
        debugPrint('[API Error] ${error.message}');
    }
  }
}
