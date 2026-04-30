import 'chat_message_dto.dart';

/// Spring `Page<ChatMessageDto>`.
class PagedChatResult {
  const PagedChatResult({
    required this.content,
    this.totalElements,
    this.totalPages,
    this.number,
    this.size,
  });

  final List<ChatMessageDto> content;
  final int? totalElements;
  final int? totalPages;
  final int? number;
  final int? size;

  factory PagedChatResult.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    final list = <ChatMessageDto>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(ChatMessageDto.fromJson(e));
        }
      }
    }
    return PagedChatResult(
      content: list,
      totalElements: (json['totalElements'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      number: (json['number'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );
  }
}
