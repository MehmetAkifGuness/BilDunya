import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/conversation_summary_dto.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_inbox_provider.dart';
import '../providers/chat_provider.dart';
import 'chat_view.dart';

class ChatInboxView extends StatelessWidget {
  const ChatInboxView({super.key});

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

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => ChangeNotifierProvider(
          create: (_) => ChatProvider(
            repository: ctx.read<ChatRepository>(),
            myUsername: me,
            conversationId: convId,
            peerUsername: peer,
            peerDisplayName: name,
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

              if (p.error != null && p.conversations.isEmpty) {
                return Scaffold(
                  backgroundColor: AppColors.surfaceContainerLowest,
                  appBar: AppBar(title: const Text('Mesajlar')),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            p.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FilledButton(
                                onPressed: p.load,
                                child: const Text('Yeniden dene'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () => _promptAndOpenChat(context),
                                icon: const Icon(Symbols.chat),
                                label: const Text('Sohbet başlat'),
                              ),
                            ],
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
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: p.conversations.length,
                    separatorBuilder: (context, _) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final c = p.conversations[i];
                      final peer = c.otherUsername ?? '';
                      final title = (c.otherFullName ?? '').trim().isNotEmpty
                          ? c.otherFullName!.trim()
                          : peer;
                      final subtitle = (c.lastMessage ?? '').trim().isNotEmpty
                          ? c.lastMessage!.trim()
                          : 'Sohbeti başlat';
                      final time = c.lastMessageAt ?? '';
                      final unread = c.unreadCount ?? 0;

                      return Material(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openConversation(context, c),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      AppColors.primaryContainer.withValues(
                                    alpha: 0.35,
                                  ),
                                  child: Text(
                                    title.isNotEmpty
                                        ? title[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.onPrimary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: unread > 0
                                                  ? FontWeight.w800
                                                  : FontWeight.w700,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.onSurfaceHint,
                                              fontWeight: unread > 0
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      time,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.secondary,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (unread > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          unread > 99 ? '99+' : '$unread',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: AppColors.onPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
