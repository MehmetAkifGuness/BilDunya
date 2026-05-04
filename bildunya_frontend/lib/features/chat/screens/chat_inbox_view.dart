import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/conversation_summary_dto.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_inbox_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_view.dart';

class ChatInboxView extends StatelessWidget {
  const ChatInboxView({super.key});

  static final RegExp _replyTag = RegExp(r'^\[REPLY:[^\]]+\]\s*');

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
      final conv = await context.read<ChatRepository>().openConversation(username);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return Scaffold(
            backgroundColor: AppColors.surfaceContainerLowest,
            appBar: AppBar(
              title: const Text('Mesajlar'),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Mesajlar için giriş yapın.'),
              ),
            ),
          );
        }

        final myUsername = auth.user?.username;

        return ChangeNotifierProvider(
          create: (ctx) => ChatInboxProvider(ctx.read<ChatRepository>())..load(),
          child: Consumer<ChatInboxProvider>(
            builder: (context, p, _) {
              if (p.loading && p.conversations.isEmpty) {
                return const Scaffold(
                  backgroundColor: AppColors.surfaceContainerLowest,
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return Scaffold(
                backgroundColor: AppColors.surfaceContainerLowest,
                appBar: AppBar(
                  title: const Text('Mesajlar'),
                  actions: [
                    IconButton(
                      tooltip: 'Yeni sohbet',
                      onPressed: () => _promptAndOpenChat(context),
                      icon: const Icon(Symbols.add_comment),
                    ),
                    IconButton(
                      tooltip: 'Yenile',
                      onPressed: p.loading ? null : p.load,
                      icon: const Icon(Symbols.refresh),
                    ),
                  ],
                ),
                body: RefreshIndicator(
                  onRefresh: p.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                    children: [
                      const _InboxSearchBar(),
                      const SizedBox(height: 14),
                      if (p.error != null && p.conversations.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 20),
                          child: Column(
                            children: [
                              Text(
                                p.error!,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.error),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Listeyi yenilemek için aşağı çekin veya üstteki yenile simgesine dokunun.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.secondary),
                              ),
                            ],
                          ),
                        ),
                      if (p.conversations.isEmpty &&
                          p.error == null &&
                          !p.loading)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 28, 8, 16),
                          child: Text(
                            'Henüz sohbet yok. Sağ üstten yeni sohbet başlatabilirsiniz.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.secondary),
                          ),
                        ),
                      for (var i = 0; i < p.conversations.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _conversationTile(
                          context,
                          p.conversations[i],
                          myUsername,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _conversationTile(
    BuildContext context,
    ConversationSummaryDto c,
    String? myUsername,
  ) {
    final peer = c.otherUsername ?? '';
    final title = (c.otherFullName ?? '').trim().isNotEmpty
        ? c.otherFullName!.trim()
        : peer;
    final last = (c.lastMessage ?? '').trim();
    final lastFromMe = _lastMessageIsMine(myUsername, c);
    final subtitle = _conversationListSubtitle(c, myUsername);
    final contentLine = (c.relatedContentLabel ?? '').trim();
    final time = c.lastMessageAt ?? '';
    final unread = c.unreadCount ?? 0;
    final hasUnread = unread > 0;

    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w400,
          color: hasUnread ? AppColors.onSurface : AppColors.secondary,
        );

    final lastStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w400,
          color: hasUnread ? AppColors.onSurface : AppColors.secondary,
          height: 1.35,
        );

    final statusIcon = _lastMessageStatusIcon(last, lastFromMe);

    final dismissKey = ValueKey<String>(
      'conv_${c.id ?? 'x'}_${c.otherUsername ?? ''}',
    );

    return Dismissible(
      key: dismissKey,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => true,
      onDismissed: (_) {
        debugPrint('Silinecek ID: ${c.id}');
      },
      background: const ColoredBox(color: Colors.transparent),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
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
      child: Material(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openConversation(context, c),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
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
                    if (hasUnread)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceContainer,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: titleStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contentLine.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Gönderi: $contentLine',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.tertiary,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w500,
                              ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (statusIcon != null) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 1, right: 4),
                              child: Icon(
                                statusIcon,
                                size: 14,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: lastStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      time,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: hasUnread
                                ? AppColors.onSurface
                                : AppColors.secondary,
                            fontWeight:
                                hasUnread ? FontWeight.w700 : FontWeight.w400,
                          ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Son mesaj satırı: kendi mesajında `[REPLY:…]` önekini gizle ve `Siz:` ön eki ekle.
  String _conversationListSubtitle(
    ConversationSummaryDto c,
    String? myUsername,
  ) {
    final raw = (c.lastMessage ?? '').trim();
    if (raw.isEmpty) return 'Henüz mesaj yok';
    final body = _inboxStripReplyPrefix(raw);
    if (_lastMessageIsMine(myUsername, c)) {
      return 'Siz: $body';
    }
    return body;
  }

  String _inboxStripReplyPrefix(String raw) {
    final t = raw.trim();
    final stripped = t.replaceFirst(_replyTag, '').trim();
    return stripped.isNotEmpty ? stripped : t;
  }

  bool _lastMessageIsMine(String? myUsername, ConversationSummaryDto c) {
    final me = (myUsername ?? '').trim().toLowerCase();
    final sender = (c.lastMessageSenderUsername ?? '').trim().toLowerCase();
    if (me.isEmpty || sender.isEmpty) return false;
    return me == sender;
  }

  /// Durum ikonları yalnızca son mesaj bize aitse; `Siz:` önekli ham metinde çift tik.
  IconData? _lastMessageStatusIcon(String raw, bool lastFromMe) {
    if (!lastFromMe) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('Siz:')) return Symbols.done_all;
    return Symbols.check;
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
          borderSide: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.full),
          borderSide: BorderSide(
            color: AppColors.primaryContainer.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
