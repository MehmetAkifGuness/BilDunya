import 'package:flutter/foundation.dart';

import '../../../data/models/content_dto.dart';
import '../../../data/models/page_response.dart';
import '../../../data/models/update_profile_request.dart';
import '../../../data/models/user_dto.dart';
import '../../../data/models/user_gamification_dto.dart';
import '../../../data/repositories/content_repository.dart';
import '../../../data/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._profileRepository, this._contentRepository);

  final ProfileRepository _profileRepository;
  final ContentRepository _contentRepository;

  UserDto? user;
  List<ContentDto> myContents = [];
  UserGamificationDto? gamification;
  bool loading = false;
  bool updatingAnonymous = false;
  bool updatingProfile = false;
  String? error;

  /// Sunucudaki toplam paylaşım (grid’de en fazla 100 öğe olabilir).
  int get postCount => gamification?.totalPosts ?? myContents.length;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final me = await _profileRepository.getMe();
      user = me;
      final id = me.id;
      if (id != null) {
        final results = await Future.wait([
          _contentRepository.getUserContent(userId: id, page: 0, size: 100),
          _profileRepository.getGamification(),
        ]);
        myContents = List<ContentDto>.from(
          (results[0] as PagedContentResult).content,
        );
        gamification = results[1] as UserGamificationDto;
      } else {
        myContents = [];
        gamification = await _profileRepository.getGamification();
      }
    } catch (e) {
      error = e.toString();
      user = null;
      myContents = [];
      gamification = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> setAnonymous(bool value) async {
    final current = user;
    if (current == null) return 'Profil yüklenemedi.';
    if (updatingAnonymous) return null;
    if (current.isAnonymous == value) return null;

    updatingAnonymous = true;
    final previous = current;
    user = UserDto(
      id: previous.id,
      username: previous.username,
      email: previous.email,
      fullName: previous.fullName,
      profilePhotoUrl: previous.profilePhotoUrl,
      bio: previous.bio,
      isAnonymous: value,
      isActive: previous.isActive,
      emailVerified: previous.emailVerified,
      role: previous.role,
      phoneNumber: previous.phoneNumber,
      locationPreferences: previous.locationPreferences,
      createdAt: previous.createdAt,
    );
    notifyListeners();

    try {
      final updated = await _profileRepository.updateMe(
        UpdateProfileRequest(isAnonymous: value),
      );
      user = updated;
      return null;
    } catch (e) {
      user = previous;
      return e.toString();
    } finally {
      updatingAnonymous = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfileInfo({
    required String fullName,
    String? bio,
    String? phoneNumber,
    String? locationPreferences,
  }) async {
    final current = user;
    if (current == null) return 'Profil yüklenemedi.';
    if (updatingProfile) return null;

    final nextFullName = fullName.trim();
    final nextBio = _trimToNull(bio);
    final nextPhone = _trimToNull(phoneNumber);
    final nextLocationPreferences = _trimToNull(locationPreferences);

    if (nextFullName.isEmpty) {
      return 'Ad soyad boş olamaz.';
    }

    updatingProfile = true;
    final previous = current;
    user = UserDto(
      id: previous.id,
      username: previous.username,
      email: previous.email,
      fullName: nextFullName,
      profilePhotoUrl: previous.profilePhotoUrl,
      bio: nextBio,
      isAnonymous: previous.isAnonymous,
      isActive: previous.isActive,
      emailVerified: previous.emailVerified,
      role: previous.role,
      phoneNumber: nextPhone,
      locationPreferences: nextLocationPreferences,
      createdAt: previous.createdAt,
    );
    notifyListeners();

    try {
      final updated = await _profileRepository.updateMe(
        UpdateProfileRequest(
          fullName: nextFullName,
          bio: nextBio,
          phoneNumber: nextPhone,
          locationPreferences: nextLocationPreferences,
        ),
      );
      user = updated;
      return null;
    } catch (e) {
      user = previous;
      return e.toString();
    } finally {
      updatingProfile = false;
      notifyListeners();
    }
  }

  static String? _trimToNull(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();
    return value.isEmpty ? null : value;
  }
}
