/// [com.bildunya.dto.SendChatMessageRequest]
class SendChatMessageRequest {
  const SendChatMessageRequest({
    required this.receiverUsername,
    required this.text,
  });

  final String receiverUsername;
  final String text;

  Map<String, dynamic> toJson() => {
        'receiverUsername': receiverUsername,
        'text': text,
      };
}
