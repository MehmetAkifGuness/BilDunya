import 'package:flutter/foundation.dart';

import '../../../core/utils/user_friendly_error.dart';
import '../../../data/models/content_dto.dart';
import '../../../data/models/create_content_request.dart';
import '../../../data/repositories/content_repository.dart';

class ContentsProvider extends ChangeNotifier {
  ContentsProvider(this._repository);

  final ContentRepository _repository;
  final Set<int> _likeLoadingIds = <int>{};

  List<ContentDto> nearby = [];
  List<ContentDto> verified = [];
  List<ContentDto> recommended = [];

  bool loadingNearby = false;
  bool loadingVerified = false;
  bool loadingRecommended = false;
  String? nearbyError;
  String? verifiedError;
  String? recommendedError;

  bool uploadingContent = false;

  bool isLikeLoading(int? contentId) =>
      contentId != null && _likeLoadingIds.contains(contentId);

  Future<ContentDto> fetchContentById(int id) => _repository.getContentById(id);

  Future<ToggleLikeResult> toggleLike(ContentDto content) async {
    final id = content.id;
    if (id == null) {
      return ToggleLikeResult(content: content, error: 'İçerik kimliği yok.');
    }
    if (_likeLoadingIds.contains(id)) {
      return ToggleLikeResult(content: content);
    }

    final original = _findContent(id) ?? content;
    final wasLiked = original.isLikedByCurrentUser;
    final nextCount = (original.safeLikeCount + (wasLiked ? -1 : 1))
        .clamp(0, 1 << 31)
        .toInt();
    final optimistic = original.copyWith(
      likedByCurrentUser: !wasLiked,
      likeCount: nextCount,
    );

    _likeLoadingIds.add(id);
    _replaceContent(id, optimistic);
    notifyListeners();

    try {
      final updated = await _repository.toggleLike(contentId: id);
      _replaceContent(id, updated);
      return ToggleLikeResult(content: updated);
    } catch (e) {
      _replaceContent(id, original);
      return ToggleLikeResult(
        content: original,
        error: userFriendlyErrorMessage(e),
      );
    } finally {
      _likeLoadingIds.remove(id);
      notifyListeners();
    }
  }

  Future<String?> uploadContent({
    required CreateContentRequest request,
    required String mediaPath,
  }) async {
    uploadingContent = true;
    notifyListeners();
    try {
      await _repository.createContentWithFile(
        request: request,
        filePath: mediaPath,
      );
      await loadVerified();
      await loadRecommended();
      await loadNearby(
        latitude: request.latitude,
        longitude: request.longitude,
        radiusKm: 40,
      );
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      uploadingContent = false;
      notifyListeners();
    }
  }

  Future<void> loadNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
  }) async {
    loadingNearby = true;
    nearbyError = null;
    notifyListeners();
    try {
      final page = await _repository.getNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
      nearby = page.content;
    } catch (e) {
      nearbyError = userFriendlyErrorMessage(e);
      nearby = [];
    } finally {
      loadingNearby = false;
      notifyListeners();
    }
  }

  /// One-shot nearby fetch without mutating provider state.
  Future<List<ContentDto>> fetchNearbyOnce({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    int page = 0,
    int size = 50,
    String sortBy = 'created_at',
  }) async {
    final pageResult = await _repository.getNearby(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      page: page,
      size: size,
      sortBy: sortBy,
    );
    return pageResult.content;
  }

  Future<void> loadVerified() async {
    loadingVerified = true;
    verifiedError = null;
    notifyListeners();
    try {
      final page = await _repository.getVerified();
      verified = page.content;
    } catch (e) {
      verifiedError = e.toString();
      verified = [];
    } finally {
      loadingVerified = false;
      notifyListeners();
    }
  }

  Future<void> loadRecommended() async {
    loadingRecommended = true;
    recommendedError = null;
    notifyListeners();
    try {
      final page = await _repository.getRecommended();
      recommended = page.content;
    } catch (e) {
      recommendedError = e.toString();
      recommended = [];
    } finally {
      loadingRecommended = false;
      notifyListeners();
    }
  }

  ContentDto? _findContent(int id) {
    for (final list in [nearby, verified, recommended]) {
      for (final content in list) {
        if (content.id == id) return content;
      }
    }
    return null;
  }

  void _replaceContent(int id, ContentDto next) {
    nearby = _replaceInList(nearby, id, next);
    verified = _replaceInList(verified, id, next);
    recommended = _replaceInList(recommended, id, next);
  }

  static List<ContentDto> _replaceInList(
    List<ContentDto> source,
    int id,
    ContentDto next,
  ) {
    var changed = false;
    final result = <ContentDto>[];
    for (final content in source) {
      if (content.id == id) {
        result.add(next);
        changed = true;
      } else {
        result.add(content);
      }
    }
    return changed ? result : source;
  }
}

class ToggleLikeResult {
  const ToggleLikeResult({required this.content, this.error});

  final ContentDto content;
  final String? error;
}
