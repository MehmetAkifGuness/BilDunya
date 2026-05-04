import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_config.dart';
import 'auth_interceptor.dart';

abstract final class DioClient {
  static Dio create(FlutterSecureStorage storage) {
    final baseUrl = ApiConfig.baseUrl;
    final isRender = baseUrl.contains('onrender.com');
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // Render Free instance cold-start can take ~60s; keep timeouts lenient there.
        connectTimeout:
            isRender ? const Duration(seconds: 90) : const Duration(seconds: 20),
        receiveTimeout:
            isRender ? const Duration(seconds: 90) : const Duration(seconds: 30),
        headers: {
          Headers.acceptHeader: Headers.jsonContentType,
        },
      ),
    );
    dio.interceptors.add(AuthInterceptor(storage));
    return dio;
  }
}
