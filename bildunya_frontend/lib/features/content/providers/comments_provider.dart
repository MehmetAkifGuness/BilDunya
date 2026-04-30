import 'package:flutter/foundation.dart';

import '../../../data/models/comment_dto.dart';
import '../../../data/models/create_comment_request.dart';
import '../../../data/repositories/comment_repository.dart';

class CommentsProvider extends ChangeNotifier {
  CommentsProvider(this._repository, {required this.contentId});

  final CommentRepository _repository;
  final int contentId;

  List<CommentDto> comments = [];
  bool loading = false;
  bool sending = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _repository.listComments(contentId);
      comments = List<CommentDto>.from(page.content);
    } catch (e) {
      error = e.toString();
      comments = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<String?> postComment({
    required String text,
    bool isAnonymous = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'Yorum metni boş olamaz.';
    sending = true;
    notifyListeners();
    try {
      final created = await _repository.createComment(
        contentId,
        CreateCommentRequest(text: trimmed, isAnonymous: isAnonymous),
      );
      comments = [created, ...comments];
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      sending = false;
      notifyListeners();
    }
  }
}
