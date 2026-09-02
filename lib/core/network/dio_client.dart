import 'package:dio/dio.dart';

import '../constants/app_constants.dart';

/// Shared Dio HTTP client for free external APIs.
class DioClient {
  DioClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }

  final Dio _dio;

  Dio get dio => _dio;
}
