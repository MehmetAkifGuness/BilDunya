import 'package:dio/dio.dart';

import '../../core/network/dio_error_message.dart';
import '../models/page_response.dart';

class ContentRepository {
  ContentRepository(this._dio);

  final Dio _dio;

  Future<PagedContentResult> getVerified({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/contents/verified',
        queryParameters: {'page': page, 'size': size},
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return PagedContentResult.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<PagedContentResult> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int page = 0,
    int size = 20,
    String sortBy = 'createdAt',
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/contents/nearby',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
          'page': page,
          'size': size,
          'sortBy': sortBy,
        },
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return PagedContentResult.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }
}
