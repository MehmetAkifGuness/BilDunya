import 'conversation_summary_dto.dart';

/// Spring `Page<ConversationSummaryDto>`.
class PagedConversationResult {
  const PagedConversationResult({
    required this.content,
    this.totalElements,
    this.totalPages,
    this.number,
    this.size,
  });

  final List<ConversationSummaryDto> content;
  final int? totalElements;
  final int? totalPages;
  final int? number;
  final int? size;

  factory PagedConversationResult.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    final list = <ConversationSummaryDto>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          list.add(
            ConversationSummaryDto.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return PagedConversationResult(
      content: list,
      totalElements: (json['totalElements'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      number: (json['number'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
    );
  }
}

