/// [com.bildunya.dto.ChatMessageDto]
class ChatMessageDto {
  const ChatMessageDto({
    this.id,
    this.conversationId,
    this.senderUsername,
    this.receiverUsername,
    this.text,
    this.isRead,
    this.createdAt,
  });

  final int? id;
  final int? conversationId;
  final String? senderUsername;
  final String? receiverUsername;
  final String? text;
  final bool? isRead;
  final String? createdAt;

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: (json['id'] as num?)?.toInt(),
      conversationId: (json['conversation_id'] as num?)?.toInt() ??
          (json['conversationId'] as num?)?.toInt(),
      senderUsername: json['sender_username'] as String? ??
          json['senderUsername'] as String?,
      receiverUsername: json['receiver_username'] as String? ??
          json['receiverUsername'] as String?,
      text: json['text'] as String?,
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool?,
      createdAt:
          json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }
}
