/// [com.bildunya.dto.CustomLocationDto] ile uyumlu JSON (Jackson snake_case).
class CustomLocationDto {
  const CustomLocationDto({
    this.id,
    this.userId,
    this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.photoUrls,
    this.tags,
    this.verificationStatus,
    this.createdAt,
  });

  final int? id;
  final int? userId;
  final String? name;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final List<String>? photoUrls;
  final List<String>? tags;
  final String? verificationStatus;
  final String? createdAt;

  factory CustomLocationDto.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final parsedTags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t is String && t.trim().isNotEmpty) parsedTags.add(t);
      }
    }

    final rawPhotos = json['photo_urls'] ?? json['photoUrls'];
    final parsedPhotos = <String>[];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        if (p is String && p.trim().isNotEmpty) parsedPhotos.add(p.trim());
      }
    }

    final imageUrl =
        json['image_url'] as String? ?? json['imageUrl'] as String?;
    if (parsedPhotos.isEmpty &&
        imageUrl != null &&
        imageUrl.trim().isNotEmpty) {
      parsedPhotos.add(imageUrl.trim());
    }
    return CustomLocationDto(
      id: (json['id'] as num?)?.toInt(),
      userId:
          (json['user_id'] as num?)?.toInt() ??
          (json['userId'] as num?)?.toInt(),
      name: json['name'] as String?,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrl: imageUrl,
      photoUrls: parsedPhotos,
      tags: parsedTags,
      verificationStatus:
          json['verification_status'] as String? ??
          json['verificationStatus'] as String?,
      createdAt: json['created_at'] as String? ?? json['createdAt'] as String?,
    );
  }
}
