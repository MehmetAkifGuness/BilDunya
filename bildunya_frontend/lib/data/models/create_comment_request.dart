/// [com.bildunya.dto.CreateCommentRequest]
class CreateCommentRequest {
  const CreateCommentRequest({
    required this.text,
    this.parentCommentId,
    this.isAnonymous = false,
  });

  final String text;
  final int? parentCommentId;
  final bool isAnonymous;

  Map<String, dynamic> toJson() => {
        'text': text,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
        'isAnonymous': isAnonymous,
      };
}
