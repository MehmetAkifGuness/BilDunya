import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/chat_time_format.dart';
import '../../../data/models/conversation_summary_dto.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_inbox_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_view.dart';

/// Gelen kutusu — yalnızca bu dosyadaki UI; [ChatInboxProvider] ve servisler değiştirilmez.
class ChatInboxView extends StatefulWidget {
  const ChatInboxView({super.key});

  @override
  State<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<ChatInboxView> {
  /// [Dismissible] ile kaldırılan satırlar (provider’a dokunmadan geçici gizleme).
  final Set<String> _dismissedKeys = {};

  static String _rowKey(ConversationSummaryDto c) =>
      '${c.id ?? 'x'}_${c.otherUsername ?? ''}';

  Future<void> _promptAndOpenChat(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAppSnackBar(context, 'Sohbet için giriş yapın.', isError: true);
      return;
    }
    final me = auth.user?.username;
    if (me == null || me.isEmpty) return;

    final controller = TextEditingController();
    final peer = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni sohbet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Kullanıcı adı',
            hintText: 'örn: ali123',
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Aç'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (!context.mounted) return;
    final username = (peer ?? '').trim();
    if (username.isEmpty) return;

    final display = username;
    int? convId;
    try {
      final conv =
          await context.read<ChatRepository>().openConversation(username);
      convId = conv.id;
    } catch (_) {
      convId = null;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ChangeNotifierProvider(
          create: (_) => ChatProvider(
            repository: ctx.read<ChatRepository>(),
            myUsername: me,
            conversationId: convId,
            peerUsername: username,
            peerDisplayName: display,
          )..init(),
          child: const ChatView(),
        ),
      ),
    );
    if (context.mounted) {
      unawaited(context.read<ChatInboxProvider>().load());
      setState(() => _dismissedKeys.clear());
    }
  }

  Future<void> _openConversation(
    BuildContext context,
    ConversationSummaryDto c,
  ) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAppSnackBar(context, 'Sohbet için giriş yapın.', isError: true);
      return;
    }
    final me = auth.user?.username;
    final peer = c.otherUsername;
    final convId = c.id;
    if (me == null || peer == null || peer.isEmpty) return;
    final name = (c.otherFullName ?? '').trim().isNotEmpty
        ? c.otherFullName!.trim()
        : peer;
    final relatedLabel = (c.relatedContentLabel ?? '').trim();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ChangeNotifierProvider(
          create: (_) => ChatProvider(
            repository: ctx.read<ChatRepository>(),
            myUsername: me,
            conversationId: convId,
            peerUsername: peer,
            peerDisplayName: name,
            relatedContentLabel:
                relatedLabel.isEmpty ? null : relatedLabel,
            relatedContentId: c.relatedContentId,
          )..init(),
          child: const ChatView(),
        ),
      ),
    );

    if (context.mounted) {
      await context.read<ChatInboxProvider>().load();
      setState(() => _dismissedKeys.clear());
    }
  }

  Future<void> _reloadInbox(BuildContext context) async {
    await context.read<ChatInboxProvider>().load();
    if (mounted) setState(() => _dismissedKeys.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return Scaffold(
            backgroundColor: AppColors.surfaceContainerLowest,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceContainerLowest,
              foregroundColor: AppColors.onSurface,
              title: const Text('Mesajlar'),
            ),
            body: Center(
              child: Text(
                'Mesajlar için giriş yapın.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondary,
                    ),
              ),
            ),
          );
        }

        final myUsername = auth.user?.username;

        return Consumer<ChatInboxProvider>(
          builder: (context, p, _) {
            final visible = p.conversations
                .where((c) => !_dismissedKeys.contains(_rowKey(c)))
                .toList();

            if (p.loading && p.conversations.isEmpty) {
              return Scaffold(
                backgroundColor: AppColors.surfaceContainerLowest,
                appBar: AppBar(
                  backgroundColor: AppColors.surfaceContainerLowest,
                  foregroundColor: AppColors.onSurface,
                  title: const Text('Mesajlar'),
                  actions: [
                    IconButton(
                      tooltip: 'Yeni sohbet',
                      onPressed: null,
                      icon: const Icon(Symbols.add_comment),
                    ),
                    IconButton(
                      tooltip: 'Yenile',
                      onPressed: null,
                      icon: const Icon(Symbols.refresh),
                    ),
                  ],
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            return Scaffold(
              backgroundColor: AppColors.surfaceContainerLowest,
              appBar: AppBar(
                backgroundColor: AppColors.surfaceContainerLowest,
                foregroundColor: AppColors.onSurface,
                title: const Text('Mesajlar'),
                actions: [
                  IconButton(
                    tooltip: 'Yeni sohbet',
                    onPressed: () => _promptAndOpenChat(context),
                    icon: const Icon(Symbols.add_comment),
                  ),
                  IconButton(
                    tooltip: 'Yenile',
                    onPressed: p.loading
                        ? null
                        : () => _reloadInbox(context),
                    icon: const Icon(Symbols.refresh),
                  ),
                ],
              ),
              body: RefreshIndicator(
                color: AppColors.primaryContainer,
                onRefresh: () => _reloadInbox(context),
                child: _InboxScrollBody(
                  p: p,
                  visible: visible,
                  myUsername: myUsername,
                  onDismissedRow: (key) {
                    debugPrint('Inbox dismiss: conversationKey=$key');
                    setState(() => _dismissedKeys.add(key));
                  },
                  onOpenChat: (c) => _openConversation(context, c),
                  onRetry: () => _reloadInbox(context),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _InboxScrollBody extends StatelessWidget {
  const _InboxScrollBody({
    required this.p,
    required this.visible,
    required this.myUsername,
    required this.onDismissedRow,
    required this.onOpenChat,
    required this.onRetry,
  });

  final ChatInboxProvider p;
  final List<ConversationSummaryDto> visible;
  final String? myUsername;
  final void Function(String key) onDismissedRow;
  final void Function(ConversationSummaryDto c) onOpenChat;
  final VoidCallback onRetry;

  static String _rowKey(ConversationSummaryDto c) =>
      '${c.id ?? 'x'}_${c.otherUsername ?? ''}';

  @override
  Widget build(BuildContext context) {
    const physics = AlwaysScrollableScrollPhysics();
    const pad = EdgeInsets.fromLTRB(16, 8, 16, 24);

    if (p.error != null && p.conversations.isEmpty) {
      return ListView(
        physics: physics,
        padding: pad,
        children: [
          const SizedBox(height: 80),
          Text(
            p.error!,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: 20),
          Center(
            child: FilledButton(
              onPressed: p.loading ? null : onRetry,
              child: const Text('Yeniden dene'),
            ),
          ),
        ],
      );
    }

    if (!p.loading && p.error == null && p.conversations.isEmpty) {
      return ListView(
        physics: physics,
        padding: pad,
        children: [
          const _InboxSearchBar(),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Henüz sohbet yok',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondary,
                  ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: physics,
      padding: pad,
      itemCount: 1 + visible.length,
      separatorBuilder: (context, index) {
        if (index == 0) {
          return const SizedBox(height: 14);
        }
        return const SizedBox(height: 4);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return const _InboxSearchBar();
        }
        final c = visible[index - 1];
        final key = _rowKey(c);
        return Dismissible(
          key: ValueKey<String>('dismiss_$key'),
          direction: DismissDirection.endToStart,
          background: const SizedBox.shrink(),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: const Icon(
              Symbols.delete,
              color: AppColors.onError,
              size: 28,
            ),
          ),
          onDismissed: (_) => onDismissedRow(key),
          child: _ConversationTile(
            conversation: c,
            myUsername: myUsername,
            onTap: () => onOpenChat(c),
          ),
        );
      },
    );
  }
}

class _InboxSearchBar extends StatefulWidget {
  const _InboxSearchBar();

  @override
  State<_InboxSearchBar> createState() => _InboxSearchBarState();
}

class _InboxSearchBarState extends State<_InboxSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _controller,
      style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
      cursorColor: AppColors.primaryContainer,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Ara...',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.onSurfaceHint,
        ),
        prefixIcon: const Icon(
          Symbols.search,
          color: AppColors.secondary,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
          borderSide: BorderSide(
            color: AppColors.primaryContainer.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.myUsername,
    required this.onTap,
  });

  final ConversationSummaryDto conversation;
  final String? myUsername;
  final VoidCallback onTap;

  static final RegExp _replyTag = RegExp(r'^\[REPLY:[^\]]+\]\s*');

  String _displayName(ConversationSummaryDto c) {
    final peer = c.otherUsername ?? '';
    final full = (c.otherFullName ?? '').trim();
    if (full.isNotEmpty) return full;
    return peer.isNotEmpty ? peer : '?';
  }

  String _subtitle(String? myUsername, ConversationSummaryDto c) {
    final raw = (c.lastMessage ?? '').trim();
    if (raw.isEmpty) return 'Henüz mesaj yok';
    final body = raw.replaceFirst(_replyTag, '').trim();
    final shown = body.isNotEmpty ? body : raw;
    if (_lastMessageIsMine(myUsername, c)) {
      return 'Siz: $shown';
    }
    return shown;
  }

  bool _lastMessageIsMine(String? myUsername, ConversationSummaryDto c) {
    final me = (myUsername ?? '').trim().toLowerCase();
    if (me.isEmpty) return false;
    final sender = (c.lastMessageSenderUsername ?? '').trim().toLowerCase();
    if (sender.isNotEmpty) {
      return sender == me;
    }
    final last = (c.lastMessage ?? '').trim();
    return last.startsWith('[REPLY:');
  }

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final title = _displayName(c);
    final subtitle = _subtitle(myUsername, c);
    final time = formatDmTime(c.lastMessageAt);
    final unread = c.unreadCount ?? 0;
    final hasUnread = unread > 0;

    final nameStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w500,
          color: hasUnread ? AppColors.onSurface : AppColors.secondary,
        );
    final msgStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w500,
          color: hasUnread ? AppColors.onSurface : AppColors.secondary,
          height: 1.3,
        );
    final timeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
          color: hasUnread ? AppColors.onSurface : AppColors.secondary,
        );

    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        onTap: onTap,
        leading: SizedBox(
          width: 52,
          height: 52,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (hasUnread)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceContainerLowest,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: nameStyle,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: msgStyle,
        ),
        trailing: SizedBox(
          width: 52,
          child: Align(
            alignment: Alignment.topRight,
            child: Text(
              time,
              style: timeStyle,
            ),
          ),
        ),
      ),
    );
  }
}
