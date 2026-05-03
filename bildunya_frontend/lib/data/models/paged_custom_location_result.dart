import 'custom_location_dto.dart';

/// Spring `Page<CustomLocationDto>` JSON gövdesi.
class PagedCustomLocationResult {
  const PagedCustomLocationResult({
    required this.content,
    this.totalElements,
    this.totalPages,
    this.number,
    this.size,
  });

  final List<CustomLocationDto> content;
  final int? totalElements;
  final int? totalPages;
  final int? number;
  final int? size;

  factory PagedCustomLocationResult.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    final list = <CustomLocationDto>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(CustomLocationDto.fromJson(e));
        }
      }
    }
    return PagedCustomLocationResult(
      content: list,
      totalElements: (json['totalElements'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      number: (json['number'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );
  }
}
