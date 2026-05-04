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
    this.rejectionReason,
    this.exifData,
    this.viewCount,
    this.likeCount,
    this.likedByCurrentUser,
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
  final String? rejectionReason;
  final String? exifData;
  final int? viewCount;
  final int? likeCount;
  final bool? likedByCurrentUser;
  final String? shareType;
  final String? tags;
  final UserDto? user;
  final String? createdAt;

  factory ContentDto.fromJson(Map<String, dynamic> json) {
    return ContentDto(
      id: (json['id'] as num?)?.toInt(),
      description: json['description'] as String?,
      contentType:
          json['content_type'] as String? ?? json['contentType'] as String?,
      fileUrl: json['file_url'] as String? ?? json['fileUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName:
          json['location_name'] as String? ?? json['locationName'] as String?,
      isVerified: json['is_verified'] as bool? ?? json['isVerified'] as bool?,
      verificationStatus:
          json['verification_status'] as String? ??
          json['verificationStatus'] as String?,
      rejectionReason:
          json['rejection_reason'] as String? ??
          json['rejectionReason'] as String?,
      exifData: json['exif_data'] as String? ?? json['exifData'] as String?,
      viewCount:
          (json['view_count'] as num?)?.toInt() ??
          (json['viewCount'] as num?)?.toInt(),
      likeCount:
          (json['like_count'] as num?)?.toInt() ??
          (json['likeCount'] as num?)?.toInt(),
      likedByCurrentUser:
          json['liked_by_current_user'] as bool? ??
          json['likedByCurrentUser'] as bool?,
      shareType: json['share_type'] as String? ?? json['shareType'] as String?,
      tags: json['tags'] as String?,
      user: json['user'] != null
          ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }

  int get safeLikeCount => likeCount ?? 0;

  bool get isLikedByCurrentUser => likedByCurrentUser ?? false;

  ContentDto copyWith({
    int? id,
    String? description,
    String? contentType,
    String? fileUrl,
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isVerified,
    String? verificationStatus,
    String? rejectionReason,
    String? exifData,
    int? viewCount,
    int? likeCount,
    bool? likedByCurrentUser,
    String? shareType,
    String? tags,
    UserDto? user,
    String? createdAt,
  }) {
    return ContentDto(
      id: id ?? this.id,
      description: description ?? this.description,
      contentType: contentType ?? this.contentType,
      fileUrl: fileUrl ?? this.fileUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      exifData: exifData ?? this.exifData,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      shareType: shareType ?? this.shareType,
      tags: tags ?? this.tags,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
