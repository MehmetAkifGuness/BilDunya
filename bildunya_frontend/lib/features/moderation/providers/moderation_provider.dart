import 'package:flutter/foundation.dart';

import '../../../data/models/content_dto.dart';
import '../../../data/repositories/content_repository.dart';

class ModerationProvider extends ChangeNotifier {
  ModerationProvider(this._repository);

  static const List<String> supportedStatuses = <String>[
    'PENDING',
    'REJECTED',
    'APPROVED',
  ];

  final ContentRepository _repository;

  List<ContentDto> queue = [];
  bool loading = false;
  bool acting = false;
  String selectedStatus = 'PENDING';
  String? error;

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
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> approve(int contentId) async {
    if (acting) return null;

    acting = true;
    notifyListeners();
    try {
      await _repository.approveContent(contentId: contentId);
      await loadQueue(status: selectedStatus);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      acting = false;
      notifyListeners();
    }
  }

  Future<String?> reject(int contentId, {String? rejectionReason}) async {
    if (acting) return null;

    acting = true;
    notifyListeners();
    try {
      await _repository.rejectContent(
        contentId: contentId,
        rejectionReason: rejectionReason,
      );
      await loadQueue(status: selectedStatus);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      acting = false;
      notifyListeners();
    }
  }
}
