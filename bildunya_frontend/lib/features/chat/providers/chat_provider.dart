import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/constants/api_config.dart';
import '../../../data/models/chat_message_dto.dart';
import '../../../data/models/send_chat_message_request.dart';
import '../../../data/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider({
    required ChatRepository repository,
    required this.myUsername,
    required this.peerUsername,
    required this.peerDisplayName,
  }) : _repository = repository;

  final ChatRepository _repository;
  final String myUsername;
  final String peerUsername;
  final String peerDisplayName;

  final List<ChatMessageDto> messages = [];
  bool loading = false;
  bool sending = false;
  String? error;
  StompClient? _stomp;
  StompUnsubscribe? _unsub;

  Future<void> init() async {
    await loadHistory();
    _connectStomp();
  }

  Future<void> loadHistory() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final page = await _repository.getConversation(peerUsername, size: 100);
      final list = List<ChatMessageDto>.from(page.content);
      list.sort((a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
      messages
        ..clear()
        ..addAll(list);
    } catch (e) {
      error = e.toString();
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
          if (!_involvesPeer(m)) return;
          if (messages.any((x) => x.id != null && x.id == m.id)) return;
          messages.add(m);
          messages.sort(
            (a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''),
          );
          notifyListeners();
        } catch (e) {
          debugPrint('[Chat] parse frame: $e');
        }
      },
    );
    notifyListeners();
  }

  bool _involvesPeer(ChatMessageDto m) {
    final s = m.senderUsername;
    final r = m.receiverUsername;
    if (s == null || r == null) return false;
    final peer = peerUsername;
    final me = myUsername;
    return (s == peer || r == peer) && (s == me || r == me);
  }

  Future<String?> send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return 'Mesaj boş olamaz.';
    sending = true;
    notifyListeners();
    try {
      final m = await _repository.sendMessage(
        SendChatMessageRequest(receiverUsername: peerUsername, text: t),
      );
      if (!messages.any((x) => x.id != null && x.id == m.id)) {
        messages.add(m);
        messages.sort(
          (a, b) => (a.createdAt ?? '').compareTo(b.createdAt ?? ''),
        );
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _unsub?.call();
    _stomp?.deactivate();
    super.dispose();
  }
}
