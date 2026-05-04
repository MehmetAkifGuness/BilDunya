import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../providers/chat_provider.dart';

enum _ChatMenuAction { refresh, reconnect, copyUsername }

/// Birebir sohbet (code.html Screen 3).
class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _scroll = ScrollController();
  final _text = TextEditingController();
  late ChatProvider _chat;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    _chat.addListener(_onChatUpdate);
  }

  void _onChatUpdate() => _scrollToEnd();

  @override
  void dispose() {
    _chat.removeListener(_onChatUpdate);
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(ChatProvider p) async {
    final err = await p.send(_text.text);
    if (!mounted) return;
    if (err != null) {
      showAppSnackBar(context, err, isError: true);
    } else {
      _text.clear();
      _scrollToEnd();
    }
  }

  Future<void> _refresh() async {
    final p = context.read<ChatProvider>();
    await p.loadHistory();
    if (!mounted) return;
    final err = p.error;
    if (err != null && err.isNotEmpty) {
      showAppSnackBar(context, err, isError: true);
    } else {
      showAppSnackBar(context, 'Mesajlar güncellendi.');
    }
  }

  Future<void> _reconnect() async {
    final p = context.read<ChatProvider>();
    await p.init();
    if (!mounted) return;
    final err = p.error;
    if (err != null && err.isNotEmpty) {
      showAppSnackBar(context, err, isError: true);
    } else {
      showAppSnackBar(context, 'Bağlantı yenilendi.');
    }
  }

  void _openQuickActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceContainer,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Symbols.refresh),
                  title: const Text('Mesajları yenile'),
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(_refresh());
                  },
                ),
                ListTile(
                  leading: const Icon(Symbols.link),
                  title: const Text('Bağlantıyı yenile'),
                  subtitle: const Text('WS + geçmişi tekrar bağlar.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(_reconnect());
                  },
                ),
                ListTile(
                  leading: const Icon(Symbols.add_photo_alternate),
                  title: const Text('Dosya gönder (yakında)'),
                  subtitle: const Text('Şu an sadece metin mesajı destekleniyor.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    showAppSnackBar(
                      this.context,
                      'Dosya gönderme henüz desteklenmiyor.',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ChatProvider>(
      builder: (context, p, _) {
        if (p.loading && p.messages.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.surfaceContainerLowest,
            appBar: AppBar(
              title: Text(
                p.peerDisplayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Symbols.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (p.error != null && p.messages.isEmpty && !p.loading) {
          return Scaffold(
            backgroundColor: AppColors.surfaceContainerLowest,
            appBar: AppBar(
              title: Text(p.peerDisplayName),
              leading: IconButton(
                icon: const Icon(Symbols.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p.error!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: p.loadHistory,
                      child: const Text('Yeniden dene'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.surfaceContainerLowest,
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  child: Text(
                    p.peerDisplayName.isNotEmpty
                        ? p.peerDisplayName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.peerDisplayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Çevrimiçi',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF4ADE80),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Symbols.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              PopupMenuButton<_ChatMenuAction>(
                icon: const Icon(Symbols.more_vert),
                onSelected: (a) {
                  switch (a) {
                    case _ChatMenuAction.refresh:
                      unawaited(_refresh());
                      break;
                    case _ChatMenuAction.reconnect:
                      unawaited(_reconnect());
                      break;
                    case _ChatMenuAction.copyUsername:
                      unawaited(
                        Clipboard.setData(ClipboardData(text: p.peerUsername)),
                      );
                      showAppSnackBar(context, 'Kullanıcı adı kopyalandı.');
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ChatMenuAction.refresh,
                    child: Text('Yenile'),
                  ),
                  PopupMenuItem(
                    value: _ChatMenuAction.reconnect,
                    child: Text('Bağlantıyı yenile'),
                  ),
                  PopupMenuItem(
                    value: _ChatMenuAction.copyUsername,
                    child: Text('Kullanıcı adını kopyala'),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: p.messages.length,
                  itemBuilder: (context, i) {
                    final m = p.messages[i];
                    final mine = m.senderUsername == p.myUsername;
                    return _MessageBubble(
                      text: m.text ?? '',
                      time: m.createdAt ?? '',
                      mine: mine,
                    );
                  },
                ),
              ),
              Material(
                color: AppColors.surfaceContainerLow.withValues(alpha: 0.95),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _openQuickActions,
                          icon: const Icon(Symbols.add),
                          color: AppColors.secondary,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _text,
                            minLines: 1,
                            maxLines: 5,
                            enabled: !p.sending,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Mesaj yazın...',
                              hintStyle: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceHint,
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => _send(p),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: AppColors.onPrimary,
                          ),
                          onPressed: p.sending ? null : () => _send(p),
                          icon: p.sending
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.onPrimary,
                                  ),
                                )
                              : const Icon(Symbols.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.time,
    required this.mine,
  });

  final String text;
  final String time;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor =
        mine ? AppColors.primaryContainer : AppColors.surfaceContainer;
    final fg = mine ? AppColors.onPrimary : AppColors.onSurface;
    final align = mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: align,
          mainAxisSize: MainAxisSize.min,
          children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.8,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(mine ? 16 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fg,
                    height: 1.35,
                    fontWeight: mine ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.secondary,
                ),
              ),
              if (mine) ...[
                const SizedBox(width: 4),
                Icon(
                  Symbols.done_all,
                  size: 14,
                  color: AppColors.primaryContainer,
                ),
              ],
            ],
          ),
        ],
        ),
      ),
    );
  }
}
