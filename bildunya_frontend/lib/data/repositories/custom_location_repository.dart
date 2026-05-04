import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/network/dio_error_message.dart';
import '../models/create_custom_location_request.dart';
import '../models/custom_location_dto.dart';
import '../models/paged_custom_location_result.dart';

class CustomLocationRepository {
  CustomLocationRepository(this._dio);

  final Dio _dio;

  Future<PagedCustomLocationResult> getNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 40,
    bool mineOnly = false,
    int page = 0,
    int size = 200,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/custom-locations/nearby',
        queryParameters: <String, dynamic>{
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
          'mineOnly': mineOnly,
          'page': page,
          'size': size,
        },
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return PagedCustomLocationResult.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<CustomLocationDto> create({
    required CreateCustomLocationRequest request,
  }) async {
    try {
      final payload = jsonEncode(request.toJson());
      final res = await _dio.post<Map<String, dynamic>>(
        '/custom-locations',
        data: payload,
        options: Options(contentType: Headers.jsonContentType),
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return CustomLocationDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  /// `POST /custom-locations` — multipart: `data` (JSON) + `file` (görsel).
  Future<CustomLocationDto> createWithFile({
    required CreateCustomLocationRequest request,
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
          contentType: _mediaType(name),
        ),
      });

      final res = await _dio.post<Map<String, dynamic>>(
        '/custom-locations',
        data: form,
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return CustomLocationDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  /// `POST /custom-locations` — multipart: `data` (JSON) + `files` (görseller).
  Future<CustomLocationDto> createWithFiles({
    required CreateCustomLocationRequest request,
    required List<String> filePaths,
  }) async {
    try {
      if (filePaths.isEmpty) {
        return await create(request: request);
      }

      final form = FormData();
      form.files.add(
        MapEntry(
          'data',
          MultipartFile.fromString(
            jsonEncode(request.toJson()),
            contentType: MediaType('application', 'json'),
          ),
        ),
      );

      for (final filePath in filePaths) {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Dosya bulunamadı');
        }
        final name = file.path.split(Platform.pathSeparator).last;
        form.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              filePath,
              filename: name,
              contentType: _mediaType(name),
            ),
          ),
        );
      }

      final res = await _dio.post<Map<String, dynamic>>(
        '/custom-locations',
        data: form,
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return CustomLocationDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  /// `POST /custom-locations/{id}/photos` — multipart: `files`.
  Future<CustomLocationDto> addPhotos({
    required int id,
    required List<String> filePaths,
  }) async {
    try {
      if (filePaths.isEmpty) throw Exception('En az bir fotoğraf seçin.');

      final form = FormData();
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (!await file.exists()) {
          throw Exception('Dosya bulunamadı');
        }
        final name = file.path.split(Platform.pathSeparator).last;
        form.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              filePath,
              filename: name,
              contentType: _mediaType(name),
            ),
          ),
        );
      }

      final res = await _dio.post<Map<String, dynamic>>(
        '/custom-locations/$id/photos',
        data: form,
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return CustomLocationDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/custom-locations/$id');
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  static MediaType _mediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return MediaType('image', 'heic');
    }
    return MediaType('image', 'jpeg');
  }
}
