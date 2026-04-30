import 'comment_dto.dart';

/// Spring `Page<CommentDto>`.
class PagedCommentResult {
  const PagedCommentResult({
    required this.content,
    this.totalElements,
    this.totalPages,
    this.number,
    this.size,
  });

  final List<CommentDto> content;
  final int? totalElements;
  final int? totalPages;
  final int? number;
  final int? size;

  factory PagedCommentResult.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    final list = <CommentDto>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(CommentDto.fromJson(e));
        }
      }
    }
    return PagedCommentResult(
      content: list,
      totalElements: (json['totalElements'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      number: (json['number'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );
  }
}
