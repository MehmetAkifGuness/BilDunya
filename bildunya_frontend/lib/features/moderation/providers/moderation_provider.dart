import 'package:flutter/foundation.dart';

import '../../../core/utils/user_friendly_error.dart';
import '../../../data/models/moderation_item_dto.dart';
import '../../../data/repositories/content_repository.dart';

class ModerationProvider extends ChangeNotifier {
  ModerationProvider(this._repository);

  static const List<String> supportedStatuses = <String>[
    'PENDING',
    'REJECTED',
    'APPROVED',
  ];

  final ContentRepository _repository;

  List<ModerationItemDto> queue = [];
  bool loading = false;
  final Set<String> actingKeys = <String>{};
  String selectedStatus = 'PENDING';
  String? error;

  bool get acting => actingKeys.isNotEmpty;

  bool isActingOn(ModerationItemDto item) => actingKeys.contains(_keyFor(item));

  Future<void> loadQueue({String? status}) async {
    if (status != null && status.trim().isNotEmpty) {
      selectedStatus = status.trim().toUpperCase();
    }

    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _repository.getModerationQueue(
        verificationStatus: selectedStatus,
      );
      queue = page.content;
    } catch (e) {
      queue = [];
      error = userFriendlyErrorMessage(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> approve(ModerationItemDto item) async {
    if (acting) return null;
    final id = item.id;
    if (id == null) return 'İçerik kimliği bulunamadı.';
    final key = _keyFor(item);
    if (actingKeys.contains(key)) return null;

    actingKeys.add(key);
    notifyListeners();
    try {
      await _repository.approveModerationItem(type: item.requestType, id: id);
      _removeFromQueue(key);
      return null;
    } catch (e) {
      return userFriendlyErrorMessage(e);
    } finally {
      actingKeys.remove(key);
      notifyListeners();
    }
  }

  Future<String?> reject(
    ModerationItemDto item, {
    String? rejectionReason,
  }) async {
    if (acting) return null;
    final id = item.id;
    if (id == null) return 'İçerik kimliği bulunamadı.';
    final key = _keyFor(item);
    if (actingKeys.contains(key)) return null;

    actingKeys.add(key);
    notifyListeners();
    try {
      await _repository.rejectModerationItem(
        type: item.requestType,
        id: id,
        rejectionReason: rejectionReason,
      );
      _removeFromQueue(key);
      return null;
    } catch (e) {
      return userFriendlyErrorMessage(e);
    } finally {
      actingKeys.remove(key);
      notifyListeners();
    }
  }

  static String _keyFor(ModerationItemDto item) {
    return '${item.normalizedType}:${item.id ?? 'x'}';
  }

  void _removeFromQueue(String key) {
    queue = queue.where((item) => _keyFor(item) != key).toList();
  }
}
