/// [com.bildunya.dto.SendMessageRequest]
class SendMessageRequest {
  const SendMessageRequest({
    required this.conversationId,
    required this.content,
  });

  final int conversationId;
  final String content;

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'content': content,
      };
}

