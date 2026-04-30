import 'package:dio/dio.dart';

import '../../core/network/dio_error_message.dart';
import '../models/user_dto.dart';
import '../models/user_gamification_dto.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  /// `GET /users/me`
  Future<UserDto> getMe() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me');
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return UserDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  /// `GET /users/me/gamification` — rozetler ve hedefler (içerik istatistiklerinden).
  Future<UserGamificationDto> getGamification() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me/gamification');
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return UserGamificationDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }
}
