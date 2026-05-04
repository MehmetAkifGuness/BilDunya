class ModerationItemDto {
  const ModerationItemDto({
    this.id,
    this.type,
    this.title,
    this.description,
    this.contentType,
    this.fileUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    this.verificationStatus,
    this.rejectionReason,
    this.userId,
    this.username,
    this.createdAt,
  });

  final int? id;
  final String? type;
  final String? title;
  final String? description;
  final String? contentType;
  final String? fileUrl;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? verificationStatus;
  final String? rejectionReason;
  final int? userId;
  final String? username;
  final String? createdAt;

  String get normalizedType {
    final raw = (type ?? 'CONTENT').trim().toUpperCase().replaceAll('-', '_');
    if (raw == 'LOCATION' || raw == 'PIN') return 'CUSTOM_LOCATION';
    return raw.isEmpty ? 'CONTENT' : raw;
  }

  String get requestType => normalizedType;

  String get displayTitle {
    final candidates = <String?>[title, locationName, description];
    for (final value in candidates) {
      final text = (value ?? '').trim();
      if (text.isNotEmpty) return text;
    }
    return normalizedType == 'CUSTOM_LOCATION' ? 'Pin' : 'Paylaşım';
  }

  factory ModerationItemDto.fromJson(Map<String, dynamic> json) {
    return ModerationItemDto(
      id: _toInt(json['id']),
      type: _toString(json['type']),
      title: _toString(json['title']),
      description: _toString(json['description']),
      contentType:
          _toString(json['content_type']) ?? _toString(json['contentType']),
      fileUrl: _toString(json['file_url']) ?? _toString(json['fileUrl']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      locationName:
          _toString(json['location_name']) ?? _toString(json['locationName']),
      verificationStatus:
          _toString(json['verification_status']) ??
          _toString(json['verificationStatus']),
      rejectionReason:
          _toString(json['rejection_reason']) ??
          _toString(json['rejectionReason']),
      userId: _toInt(json['user_id']) ?? _toInt(json['userId']),
      username: _toString(json['username']) ?? _toString(json['user_username']),
      createdAt: _toString(json['created_at']) ?? _toString(json['createdAt']),
    );
  }

  static String? _toString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class PagedModerationItemResult {
  const PagedModerationItemResult({
    required this.content,
    this.totalElements,
    this.totalPages,
    this.number,
    this.size,
  });

  final List<ModerationItemDto> content;
  final int? totalElements;
  final int? totalPages;
  final int? number;
  final int? size;

  factory PagedModerationItemResult.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    final list = <ModerationItemDto>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          try {
            list.add(
              ModerationItemDto.fromJson(Map<String, dynamic>.from(item)),
            );
          } catch (_) {
            // Keep one bad moderation row from breaking the whole admin queue.
          }
        }
      }
    }
    return PagedModerationItemResult(
      content: list,
      totalElements: (json['totalElements'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      number: (json['number'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );
  }
}
