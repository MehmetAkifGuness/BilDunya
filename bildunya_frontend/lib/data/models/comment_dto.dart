import 'user_dto.dart';

/// [com.bildunya.dto.CommentDto] — Jackson `@JsonProperty` alanları.
class CommentDto {
  const CommentDto({
    this.id,
    this.contentId,
    this.parentCommentId,
    this.text,
    this.isAnonymous,
    this.likeCount,
    this.user,
    this.createdAt,
  });

  final int? id;
  final int? contentId;
  final int? parentCommentId;
  final String? text;
  final bool? isAnonymous;
  final int? likeCount;
  final UserDto? user;
  final String? createdAt;

  factory CommentDto.fromJson(Map<String, dynamic> json) {
    return CommentDto(
      id: (json['id'] as num?)?.toInt(),
      contentId: (json['content_id'] as num?)?.toInt() ??
          (json['contentId'] as num?)?.toInt(),
      parentCommentId: (json['parent_comment_id'] as num?)?.toInt() ??
          (json['parentCommentId'] as num?)?.toInt(),
      text: json['text'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? json['isAnonymous'] as bool?,
      likeCount: (json['like_count'] as num?)?.toInt() ??
          (json['likeCount'] as num?)?.toInt(),
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt:
          json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }
}
