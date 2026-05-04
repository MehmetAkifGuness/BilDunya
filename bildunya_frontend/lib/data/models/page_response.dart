import 'content_dto.dart';

/// Spring `Page<ContentDto>` JSON gövdesi.
class PagedContentResult {
  const PagedContentResult({
    required this.content,
    this.totalElements,
    this.totalPages,
    this.number,
    this.size,
  });

  final List<ContentDto> content;
  final int? totalElements;
  final int? totalPages;
  final int? number;
  final int? size;

  factory PagedContentResult.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    final list = <ContentDto>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          try {
            list.add(ContentDto.fromJson(Map<String, dynamic>.from(e)));
          } catch (_) {
            // Skip malformed rows instead of breaking the whole list.
          }
        }
      }
    }
    return PagedContentResult(
      content: list,
      totalElements: (json['totalElements'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      number: (json['number'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );
  }
}
