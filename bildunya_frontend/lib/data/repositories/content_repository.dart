import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/network/dio_error_message.dart';
import '../models/content_dto.dart';
import '../models/create_content_request.dart';
import '../models/page_response.dart';

class ContentRepository {
  ContentRepository(this._dio);

  final Dio _dio;

  Future<ContentDto> getContentById(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/contents/$id');
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ContentDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  /// `POST /contents` — multipart: `data` (JSON) + `file` (görsel).
  Future<ContentDto> createContentWithFile({
    required CreateContentRequest request,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Dosya bulunamadı');
      }
      final name = file.path.split(Platform.pathSeparator).last;
      final form = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(request.toJson()),
          contentType: MediaType('application', 'json'),
        ),
        'file': await MultipartFile.fromFile(
          filePath,
          filename: name,
          contentType: _imageMediaType(name),
        ),
      });

      final res = await _dio.post<Map<String, dynamic>>(
        '/contents',
        data: form,
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ContentDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  static MediaType _imageMediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return MediaType('image', 'heic');
    }
    return MediaType('image', 'jpeg');
  }

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
    String sortBy = 'created_at',
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
