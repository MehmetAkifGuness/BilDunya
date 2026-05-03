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
    try {
      final page = await _repository.getMyConversations(size: 100);
      conversations
        ..clear()
        ..addAll(page.content);
    } catch (e) {
      error = userFriendlyErrorMessage(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
