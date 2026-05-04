import '../../../data/models/content_dto.dart';

/// `Navigator` ile açılan içerik detayı: kimlik + isteğe bağlı önizleme.
///
/// [routeName] [MaterialApp.routes] ile [ContentDetailView] arasında ortak olmalıdır.
class ContentDetailArgs {
  const ContentDetailArgs({required this.contentId, this.preview});

  static const String routeName = '/content/detail';

  final int contentId;
  final ContentDto? preview;
}
