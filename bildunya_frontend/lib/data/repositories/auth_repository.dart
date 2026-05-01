import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/secure_keys.dart';
import '../../core/network/dio_error_message.dart';
import '../models/auth_response.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_dto.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: request.toJson(),
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      final auth = AuthResponse.fromJson(body);
      await _persist(auth);
      return auth;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: request.toJson(),
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      final auth = AuthResponse.fromJson(body);
      await _persist(auth);
      return auth;
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<void> _persist(AuthResponse auth) async {
    await _storage.write(key: SecureKeys.accessToken, value: auth.accessToken);
    if (auth.refreshToken != null && auth.refreshToken!.isNotEmpty) {
      await _storage.write(
        key: SecureKeys.refreshToken,
        value: auth.refreshToken,
      );
    }
    if (auth.user != null) {
      await _storage.write(
        key: SecureKeys.userJson,
        value: jsonEncode(auth.user!.toJson()),
      );
    }
  }

  Future<void> logoutFromServer() async {
    final refreshToken = await _storage.read(key: SecureKeys.refreshToken);
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {
      // Local çıkış yine de yapılır.
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: SecureKeys.accessToken);
    await _storage.delete(key: SecureKeys.refreshToken);
    await _storage.delete(key: SecureKeys.userJson);
  }

  Future<String?> readToken() => _storage.read(key: SecureKeys.accessToken);

  Future<String?> readRefreshToken() =>
      _storage.read(key: SecureKeys.refreshToken);

  Future<UserDto?> readCachedUser() async {
    final raw = await _storage.read(key: SecureKeys.userJson);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
