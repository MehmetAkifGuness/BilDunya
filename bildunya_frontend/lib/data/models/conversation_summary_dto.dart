/// [com.bildunya.dto.ConversationSummaryDto]
class ConversationSummaryDto {
  const ConversationSummaryDto({
    this.id,
    this.otherUserId,
    this.otherUsername,
    this.otherFullName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount,
    this.relatedContentId,
    this.relatedContentLabel,
  });

  final int? id;
  final int? otherUserId;
  final String? otherUsername;
  final String? otherFullName;
  final String? lastMessage;
  final String? lastMessageAt;
  final int? unreadCount;
  final int? relatedContentId;
  final String? relatedContentLabel;

  factory ConversationSummaryDto.fromJson(Map<String, dynamic> json) {
    return ConversationSummaryDto(
      id: (json['id'] as num?)?.toInt(),
      otherUserId: (json['other_user_id'] as num?)?.toInt() ??
          (json['otherUserId'] as num?)?.toInt(),
      otherUsername: json['other_username'] as String? ??
          json['otherUsername'] as String?,
      otherFullName: json['other_full_name'] as String? ??
          json['otherFullName'] as String?,
      lastMessage:
          json['last_message'] as String? ?? json['lastMessage'] as String?,
      lastMessageAt: json['last_message_at'] as String? ??
          json['lastMessageAt'] as String?,
      unreadCount: (json['unread_count'] as num?)?.toInt() ??
          (json['unreadCount'] as num?)?.toInt(),
      relatedContentId: (json['related_content_id'] as num?)?.toInt() ??
          (json['relatedContentId'] as num?)?.toInt(),
      relatedContentLabel: json['related_content_label'] as String? ??
          json['relatedContentLabel'] as String?,
    );
  }
}

