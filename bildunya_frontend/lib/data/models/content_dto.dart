import 'user_dto.dart';

/// [com.bildunya.dto.ContentDto] ile uyumlu JSON (Jackson snake_case).
class ContentDto {
  const ContentDto({
    this.id,
    this.description,
    this.contentType,
    this.fileUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    this.isVerified,
    this.verificationStatus,
    this.viewCount,
    this.shareType,
    this.tags,
    this.user,
    this.createdAt,
  });

  final int? id;
  final String? description;
  final String? contentType;
  final String? fileUrl;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool? isVerified;
  final String? verificationStatus;
  final int? viewCount;
  final String? shareType;
  final String? tags;
  final UserDto? user;
  final String? createdAt;

  factory ContentDto.fromJson(Map<String, dynamic> json) {
    return ContentDto(
      id: (json['id'] as num?)?.toInt(),
      description: json['description'] as String?,
      contentType: json['content_type'] as String? ?? json['contentType'] as String?,
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName:
          json['location_name'] as String? ?? json['locationName'] as String?,
      isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool?,
      verificationStatus: json['verification_status'] as String? ??
          json['verificationStatus'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt() ??
          (json['viewCount'] as num?)?.toInt(),
      shareType: json['share_type'] as String? ?? json['shareType'] as String?,
      tags: json['tags'] as String?,
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt:
          json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }
}
