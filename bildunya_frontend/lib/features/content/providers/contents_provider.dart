import 'package:flutter/foundation.dart';

import '../../../data/models/content_dto.dart';
import '../../../data/repositories/content_repository.dart';

class ContentsProvider extends ChangeNotifier {
  ContentsProvider(this._repository);

  final ContentRepository _repository;

  List<ContentDto> nearby = [];
  List<ContentDto> verified = [];

  bool loadingNearby = false;
  bool loadingVerified = false;
  String? nearbyError;
  String? verifiedError;

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
}
