import 'package:flutter/foundation.dart';

import '../../../data/models/create_custom_location_request.dart';
import '../../../data/models/custom_location_dto.dart';
import '../../../data/repositories/custom_location_repository.dart';

class CustomLocationsProvider extends ChangeNotifier {
  CustomLocationsProvider(this._repository);

  final CustomLocationRepository _repository;

  List<CustomLocationDto> nearby = [];
  bool loadingNearby = false;
  String? nearbyError;

  bool creating = false;

  Future<void> loadNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 40,
    bool mineOnly = false,
  }) async {
    loadingNearby = true;
    nearbyError = null;
    notifyListeners();
    try {
      final page = await _repository.getNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        mineOnly: mineOnly,
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

  Future<CustomLocationDto?> createCustomLocation({
    required CreateCustomLocationRequest request,
    String? imagePath,
  }) async {
    creating = true;
    notifyListeners();
    try {
      if (imagePath != null && imagePath.trim().isNotEmpty) {
        return await _repository.createWithFile(
          request: request,
          filePath: imagePath,
        );
      }
      return await _repository.create(request: request);
    } finally {
      creating = false;
      notifyListeners();
    }
  }
}

