import 'package:flutter/foundation.dart';

import '../../../data/models/content_dto.dart';
import '../../../data/models/page_response.dart';
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
          _contentRepository.getUserContent(
            userId: id,
            page: 0,
            size: 100,
          ),
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
}
