import 'package:dio/dio.dart';

import '../../core/network/dio_error_message.dart';
import '../models/chat_message_dto.dart';
import '../models/paged_chat_result.dart';
import '../models/send_chat_message_request.dart';

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<PagedChatResult> getConversation(
    String peerUsername, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final encoded = Uri.encodeComponent(peerUsername);
      final res = await _dio.get<Map<String, dynamic>>(
        '/chat/conversations/$encoded',
        queryParameters: {'page': page, 'size': size},
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return PagedChatResult.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<ChatMessageDto> sendMessage(SendChatMessageRequest request) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/chat/messages',
        data: request.toJson(),
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ChatMessageDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }
}
