import 'package:dio/dio.dart';

import '../../core/network/dio_error_message.dart';
import '../models/chat_message_dto.dart';
import '../models/conversation_dto.dart';
import '../models/paged_conversation_result.dart';
import '../models/paged_chat_result.dart';
import '../models/send_chat_message_request.dart';
import '../models/send_message_request.dart';

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  Future<PagedConversationResult> getMyConversations({
    int page = 0,
    int size = 50,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/conversations',
        queryParameters: {'page': page, 'size': size},
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return PagedConversationResult.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<ConversationDto> openConversation(
    String otherUsername, {
    int? relatedContentId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'otherUsername': otherUsername,
        'relatedContentId': ?relatedContentId,
      };
      final res = await _dio.post<Map<String, dynamic>>(
        '/conversations',
        data: payload,
      );
      final resBody = res.data;
      if (resBody == null) throw Exception('Boş yanıt');
      return ConversationDto.fromJson(resBody);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<PagedChatResult> getConversationMessages(
    int conversationId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/conversations/$conversationId/messages',
        queryParameters: {'page': page, 'size': size},
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return PagedChatResult.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<void> markConversationAsRead(int conversationId) async {
    try {
      await _dio.post<void>('/conversations/$conversationId/read');
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<void> markConversationAsReadByUsername(String peerUsername) async {
    try {
      final encoded = Uri.encodeComponent(peerUsername);
      await _dio.post<void>('/chat/conversations/$encoded/read');
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

  Future<ChatMessageDto> sendMessageToConversation(
    SendMessageRequest request,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/messages',
        data: request.toJson(),
      );
      final body = res.data;
      if (body == null) throw Exception('Boş yanıt');
      return ChatMessageDto.fromJson(body);
    } on DioException catch (e) {
      throw Exception(dioErrorMessage(e));
    }
  }

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
