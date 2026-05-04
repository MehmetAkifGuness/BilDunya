import 'package:flutter/foundation.dart';

import '../../../core/utils/user_friendly_error.dart';
import '../../../data/models/conversation_summary_dto.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatInboxProvider extends ChangeNotifier {
  ChatInboxProvider(this._repository);

  final ChatRepository _repository;

  final List<ConversationSummaryDto> conversations = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    const maxAttempts = 3;
    Object? lastFailure;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final page = await _repository.getMyConversations(size: 100);
        conversations
          ..clear()
          ..addAll(page.content);
        lastFailure = null;
        break;
      } catch (e) {
        lastFailure = e;
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 350 * (attempt + 1)),
          );
        }
      }
    }
    if (lastFailure != null) {
      error = userFriendlyErrorMessage(lastFailure);
    }
    loading = false;
    notifyListeners();
  }
}
