import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../data/models/chat_message_dto.dart';
import '../../../data/models/send_chat_message_request.dart';
import '../../../data/models/send_message_request.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required ChatRepository repository,
    required this.myUsername,
    int? conversationId,
    required this.peerUsername,
    required this.peerDisplayName,
    this.relatedContentLabel,
    this.relatedContentId,
    this.relatedContentFileUrl,
  })  : _repository = repository,
        _conversationId = conversationId {
    if (relatedContentId != null) {
      activeReplyContentId = relatedContentId;
      activeReplyFileUrl = relatedContentFileUrl;
      activeReplyLabel = relatedContentLabel;
    }
  }

  final ChatRepository _repository;
  final String myUsername;
  int? _conversationId;
  final String peerUsername;
  final String peerDisplayName;

  /// Mekan detayından açıldıysa, ilişkili gönderi başlığı / özeti.
  final String? relatedContentLabel;

  /// Bağlamsal sohbet: ilişkili içerik kimliği (detay sayfasına yönlendirme için).
  final int? relatedContentId;

  /// Sunucudan gelen ham `fileUrl` (görsel yolu); tam URL için `ApiConfig.resolveFileUrl`.
  final String? relatedContentFileUrl;

  /// Geçici "story yanıtı" bağlamı; composer önizlemesi için. Başarılı gönderimde sıfırlanır.
  int? activeReplyContentId;
  String? activeReplyFileUrl;
  String? activeReplyLabel;

  final List<ChatMessageDto> messages = [];
  bool loading = false;
  bool sending = false;
  String? error;
  StompClient? _stomp;
  StompUnsubscribe? _unsub;
  bool _historyLoadRetrying = false;

  int? get conversationId => _conversationId;

  Future<void> init() async {
    await loadHistory();
    _connectStomp();
  }

  Future<void> loadHistory() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      if (_conversationId != null) {
        final page = await _repository.getConversationMessages(
          _conversationId!,
          size: 100,
        );
        final list = List<ChatMessageDto>.from(page.content);
        list.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
        messages
          ..clear()
          ..addAll(list);
        try {
          await _repository.markConversationAsRead(_conversationId!);
        } catch (_) {}
      } else {
        final page = await _repository.getConversation(
          peerUsername,
          size: 100,
        );
        final list = List<ChatMessageDto>.from(page.content);
        list.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
        messages
          ..clear()
          ..addAll(list);

        for (final m in list.reversed) {
          if (m.conversationId != null) {
            _conversationId = m.conversationId;
            break;
          }
        }

        try {
          await _repository.markConversationAsReadByUsername(peerUsername);
        } catch (_) {}
      }
    } catch (e) {
      if (!_historyLoadRetrying) {
        _historyLoadRetrying = true;
        loading = false;
        notifyListeners();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await loadHistory();
        _historyLoadRetrying = false;
        return;
      }
      error = userFriendlyErrorMessage(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _connectStomp() {
    _unsub?.call();
    _stomp?.deactivate();
    _stomp = StompClient(
      config: StompConfig(
        url: ApiConfig.stompWsUrl,
        reconnectDelay: const Duration(seconds: 4),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: _onStompConnect,
        onWebSocketError: (e) => debugPrint('[Chat WS] $e'),
        onStompError: (f) => debugPrint('[Chat STOMP] ${f.body}'),
        onDebugMessage: (m) => debugPrint(m),
      ),
    );
    _stomp!.activate();
  }

  void _onStompConnect(StompFrame _) {
    _unsub?.call();
    final client = _stomp;
    if (client == null) return;
    _unsub = client.subscribe(
      destination: '/topic/chat/$myUsername',
      callback: (frame) {
        final raw = frame.body;
        if (raw == null || raw.isEmpty) return;
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final m = ChatMessageDto.fromJson(map);
          final cid = _conversationId;
          if (cid != null) {
            if (m.conversationId != cid) return;
          } else {
            final sender = m.senderUsername;
            final receiver = m.receiverUsername;
            final isBetween = (sender == myUsername && receiver == peerUsername) ||
                (sender == peerUsername && receiver == myUsername);
            if (!isBetween) return;
            if (m.conversationId != null) {
              _conversationId = m.conversationId;
            }
          }
          if (messages.any((x) => x.id != null && x.id == m.id)) return;
          messages.add(m);
          messages.sort(
            (a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''),
          );
          notifyListeners();
          if (m.senderUsername != myUsername) {
            final currentCid = _conversationId;
            if (currentCid != null) {
              unawaited(_repository.markConversationAsRead(currentCid));
            } else {
              unawaited(_repository.markConversationAsReadByUsername(peerUsername));
            }
          }
        } catch (e) {
          debugPrint('[Chat] parse frame: $e');
        }
      },
    );
    notifyListeners();
  }

  Future<String?> send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return 'Mesaj boş olamaz.';
    sending = true;
    notifyListeners();
    try {
      final replyLabel = (activeReplyLabel ?? '').trim();
      final outbound = replyLabel.isNotEmpty ? '[REPLY:$replyLabel] $t' : t;

      final cid = _conversationId;
      final ChatMessageDto m;
      if (cid != null) {
        m = await _repository.sendMessageToConversation(
          SendMessageRequest(conversationId: cid, content: outbound),
        );
      } else {
        m = await _repository.sendMessage(
          SendChatMessageRequest(receiverUsername: peerUsername, text: outbound),
        );
        if (m.conversationId != null) {
          _conversationId = m.conversationId;
        }
      }
      if (!messages.any((x) => x.id != null && x.id == m.id)) {
        messages.add(m);
        messages.sort(
          (a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''),
        );
      }
      _clearActiveReply();
      notifyListeners();
      return null;
    } catch (e) {
      return userFriendlyErrorMessage(e);
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  void _clearActiveReply() {
    activeReplyContentId = null;
    activeReplyFileUrl = null;
    activeReplyLabel = null;
  }

  @override
  void dispose() {
    _unsub?.call();
    _stomp?.deactivate();
    super.dispose();
  }
}
