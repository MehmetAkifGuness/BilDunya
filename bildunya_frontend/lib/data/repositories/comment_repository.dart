import 'package:dio/dio.dart';

import '../../core/network/dio_error_message.dart';
import '../models/comment_dto.dart';
import '../models/create_comment_request.dart';
import '../models/paged_comment_result.dart';

class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  Future<PagedCommentResult> listComments(
    int contentId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/contents/$contentId/comments',
        queryParameters: {'page': page, 'size': size},
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return PagedCommentResult.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<CommentDto> createComment(
    int contentId,
    CreateCommentRequest request,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/contents/$contentId/comments',
        data: request.toJson(),
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return CommentDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }
}
