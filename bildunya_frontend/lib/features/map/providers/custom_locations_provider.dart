import 'package:flutter/foundation.dart';

import '../../../core/utils/user_friendly_error.dart';
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
      nearbyError = userFriendlyErrorMessage(e);
    } finally {
      loadingNearby = false;
      notifyListeners();
    }
  }

  Future<CustomLocationDto?> createCustomLocation({
    required CreateCustomLocationRequest request,
    List<String>? imagePaths,
  }) async {
    creating = true;
    notifyListeners();
    try {
      final paths = (imagePaths ?? const <String>[])
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (paths.isNotEmpty) {
        if (paths.length == 1) {
          return await _repository.createWithFile(
            request: request,
            filePath: paths.first,
          );
        }
        return await _repository.createWithFiles(
          request: request,
          filePaths: paths,
        );
      }
      return await _repository.create(request: request);
    } finally {
      creating = false;
      notifyListeners();
    }
  }

  Future<CustomLocationDto?> addPhotos({
    required int locationId,
    required List<String> imagePaths,
  }) async {
    final paths =
        imagePaths.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (paths.isEmpty) return null;

    creating = true;
    notifyListeners();
    try {
      final updated = await _repository.addPhotos(
        id: locationId,
        filePaths: paths,
      );
      nearby = [
        for (final l in nearby)
          if (l.id == updated.id) updated else l,
      ];
      return updated;
    } finally {
      creating = false;
      notifyListeners();
    }
  }
}
