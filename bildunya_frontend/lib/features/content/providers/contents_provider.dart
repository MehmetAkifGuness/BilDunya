import 'package:flutter/foundation.dart';

import '../../../data/models/content_dto.dart';
import '../../../data/models/create_content_request.dart';
import '../../../data/repositories/content_repository.dart';

class ContentsProvider extends ChangeNotifier {
  ContentsProvider(this._repository);

  final ContentRepository _repository;

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

  Future<ContentDto> fetchContentById(int id) => _repository.getContentById(id);

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
      await loadNearby(latitude: 38.6431, longitude: 34.8282, radiusKm: 40);
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
      nearbyError = e.toString();
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
}
