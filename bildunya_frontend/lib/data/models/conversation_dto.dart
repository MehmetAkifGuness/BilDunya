/// [com.bildunya.dto.ConversationDto]
class ConversationDto {
  const ConversationDto({
    this.id,
    this.user1Id,
    this.user2Id,
    this.otherUserId,
    this.otherUsername,
    this.otherFullName,
    this.createdAt,
  });

  final int? id;
  final int? user1Id;
  final int? user2Id;
  final int? otherUserId;
  final String? otherUsername;
  final String? otherFullName;
  final String? createdAt;

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    return ConversationDto(
      id: (json['id'] as num?)?.toInt(),
      user1Id: (json['user1_id'] as num?)?.toInt() ??
          (json['user1Id'] as num?)?.toInt(),
      user2Id: (json['user2_id'] as num?)?.toInt() ??
          (json['user2Id'] as num?)?.toInt(),
      otherUserId: (json['other_user_id'] as num?)?.toInt() ??
          (json['otherUserId'] as num?)?.toInt(),
      otherUsername: json['other_username'] as String? ??
          json['otherUsername'] as String?,
      otherFullName: json['other_full_name'] as String? ??
          json['otherFullName'] as String?,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }
}

