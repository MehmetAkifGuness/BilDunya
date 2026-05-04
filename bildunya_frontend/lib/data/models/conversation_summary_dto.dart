/// [com.bildunya.dto.ConversationSummaryDto]
class ConversationSummaryDto {
  const ConversationSummaryDto({
    this.id,
    this.otherUserId,
    this.otherUsername,
    this.otherFullName,
    this.lastMessage,
    this.lastMessageSenderUsername,
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
  final String? lastMessageSenderUsername;
  final String? lastMessageAt;
  final int? unreadCount;
  final int? relatedContentId;
  final String? relatedContentLabel;

  factory ConversationSummaryDto.fromJson(Map<String, dynamic> json) {
    return ConversationSummaryDto(
      id: _toInt(json['id']),
      otherUserId: _toInt(json['other_user_id']) ?? _toInt(json['otherUserId']),
      otherUsername: json['other_username'] as String? ??
          json['otherUsername'] as String?,
      otherFullName: json['other_full_name'] as String? ??
          json['otherFullName'] as String?,
      lastMessage:
          json['last_message'] as String? ?? json['lastMessage'] as String?,
      lastMessageSenderUsername:
          json['last_message_sender_username'] as String? ??
              json['lastMessageSenderUsername'] as String?,
      lastMessageAt: json['last_message_at'] as String? ??
          json['lastMessageAt'] as String?,
      unreadCount: _toInt(json['unread_count']) ?? _toInt(json['unreadCount']),
      relatedContentId: _toInt(json['related_content_id']) ??
          _toInt(json['relatedContentId']),
      relatedContentLabel: json['related_content_label'] as String? ??
          json['relatedContentLabel'] as String?,
    );
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

