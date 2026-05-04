import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/network/dio_error_message.dart';
import '../models/content_dto.dart';
import '../models/create_content_request.dart';
import '../models/moderate_content_request.dart';
import '../models/moderation_item_dto.dart';
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
          contentType: _mediaType(name),
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

  static MediaType _mediaType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.mp4')) return MediaType('video', 'mp4');
    if (lower.endsWith('.mov')) return MediaType('video', 'quicktime');
    if (lower.endsWith('.m4v')) return MediaType('video', 'x-m4v');
    if (lower.endsWith('.webm')) return MediaType('video', 'webm');
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return MediaType('image', 'heic');
    }
    return MediaType('image', 'jpeg');
  }

  Future<PagedContentResult> getVerified({int page = 0, int size = 20}) async {
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

  Future<PagedContentResult> getRecommended({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/contents/recommended',
        queryParameters: {'page': page, 'size': size},
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return PagedContentResult.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<PagedContentResult> getUserContent({
    required int userId,
    int page = 0,
    int size = 50,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/contents/user/$userId',
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

  Future<PagedModerationItemResult> getModerationQueue({
    String verificationStatus = 'PENDING',
    int page = 0,
    int size = 20,
  }) async {
    try {
      final status = verificationStatus.trim().toUpperCase();
      final path = status == 'PENDING' ? '/moderation/pending' : '/moderation';
      final query = <String, dynamic>{'page': page, 'size': size};
      if (status != 'PENDING') {
        query['status'] = status;
      }
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return PagedModerationItemResult.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<ContentDto> moderateContent({
    required int contentId,
    required ModerateContentRequest request,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/contents/$contentId/moderation',
        data: request.toJson(),
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ContentDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<ModerationItemDto> approveModerationItem({
    required String type,
    required int id,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/moderation/$type/$id/approve',
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ModerationItemDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<ModerationItemDto> rejectModerationItem({
    required String type,
    required int id,
    String? rejectionReason,
  }) async {
    try {
      final data = <String, dynamic>{};
      final reason = rejectionReason?.trim();
      if (reason != null && reason.isNotEmpty) {
        data['rejectionReason'] = reason;
      }
      final res = await _dio.post<Map<String, dynamic>>(
        '/moderation/$type/$id/reject',
        data: data,
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ModerationItemDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<ContentDto> approveContent({required int contentId}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/moderation/$contentId/approve',
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ContentDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<ContentDto> rejectContent({
    required int contentId,
    String? rejectionReason,
  }) async {
    try {
      final data = <String, dynamic>{};
      final reason = rejectionReason?.trim();
      if (reason != null && reason.isNotEmpty) {
        data['rejectionReason'] = reason;
      }
      final res = await _dio.post<Map<String, dynamic>>(
        '/moderation/$contentId/reject',
        data: data,
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ContentDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<ContentDto> toggleLike({required int contentId}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/contents/$contentId/toggle-like',
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ContentDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }
}
