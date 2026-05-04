import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_config.dart';
import '../constants/secure_keys.dart';

/// Her istekte JWT ekler, 401'de refresh token ile erişim token'ı yeniler.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: SecureKeys.accessToken);
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
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;
    final alreadyRetried = requestOptions.extra['retried'] == true;

    // Backend bazen yetkisiz istekler için 401 yerine 403 döndürebiliyor.
    // Refresh denemesini her iki durumda da yap.
    if ((statusCode != 401 && statusCode != 403) ||
        alreadyRetried ||
        _isAuthPath(requestOptions.path)) {
      handler.next(err);
      return;
    }

    final refreshedToken = await _tryRefreshToken();
    if (refreshedToken == null || refreshedToken.isEmpty) {
      handler.next(err);
      return;
    }

    try {
      requestOptions.headers['Authorization'] = 'Bearer $refreshedToken';
      requestOptions.extra['retried'] = true;

      final retryDio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            Headers.acceptHeader: Headers.jsonContentType,
          },
        ),
      );

      final retryResponse = await retryDio.fetch(requestOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _isAuthPath(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout');
  }

  Future<String?> _tryRefreshToken() async {
    final refreshToken = await _storage.read(key: SecureKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          Headers.acceptHeader: Headers.jsonContentType,
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
    );

    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final body = res.data;
      if (body == null) return null;

      final newAccessToken = body['access_token'] as String?;
      final newRefreshToken = body['refresh_token'] as String?;
      if (newAccessToken == null || newAccessToken.isEmpty) return null;

      await _storage.write(key: SecureKeys.accessToken, value: newAccessToken);
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _storage.write(
          key: SecureKeys.refreshToken,
          value: newRefreshToken,
        );
      }
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }
}
