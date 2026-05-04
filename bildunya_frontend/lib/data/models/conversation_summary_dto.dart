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
      otherUsername:
          _toString(json['other_username']) ?? _toString(json['otherUsername']),
      otherFullName:
          _toString(json['other_full_name']) ??
          _toString(json['otherFullName']),
      lastMessage:
          _toString(json['last_message']) ?? _toString(json['lastMessage']),
      lastMessageSenderUsername:
          _toString(json['last_message_sender_username']) ??
          _toString(json['lastMessageSenderUsername']),
      lastMessageAt:
          _toString(json['last_message_at']) ??
          _toString(json['lastMessageAt']),
      unreadCount: _toInt(json['unread_count']) ?? _toInt(json['unreadCount']),
      relatedContentId:
          _toInt(json['related_content_id']) ??
          _toInt(json['relatedContentId']),
      relatedContentLabel:
          _toString(json['related_content_label']) ??
          _toString(json['relatedContentLabel']),
    );
  }

  static String? _toString(dynamic v) {
    if (v == null) return null;
    final text = v.toString();
    return text.trim().isEmpty ? null : text;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
