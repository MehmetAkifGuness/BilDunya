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

/// [chat_view.dart] içindeki `_parseStoryReply` ile aynı mantık (önizleme metni tutarlı olsun).
(String?, String) _parseStoryReplyPrefix(String raw) {
  final re = RegExp(r'^\[REPLY:([^\]]*)\]\s*');
  final m = re.firstMatch(raw);
  if (m == null) return (null, raw);
  final title = (m.group(1) ?? '').trim();
  final body = raw.substring(m.end);
  if (title.isEmpty) return (null, raw);
  return (title, body);
}

// ─────────────────────────────────────────────────────────────────────────────
// Ana Widget
// ─────────────────────────────────────────────────────────────────────────────

class ChatInboxView extends StatefulWidget {
  const ChatInboxView({super.key});

  @override
  State<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends State<ChatInboxView> {
  final Set<String> _dismissedKeys = {};
  String _inboxSearchQuery = '';

  static String _rowKey(ConversationSummaryDto c) =>
      '${c.id ?? 'x'}_${c.otherUsername ?? ''}';

  // ── Yeni sohbet açma dialogu ──────────────────────────────────────────────
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
            peerDisplayName: username,
          )..init(),
          child: const ChatView(),
        ),
      ),
    );
    if (context.mounted) {
      unawaited(context.read<ChatInboxProvider>().load());
      setState(() {
        _dismissedKeys.clear();
        _inboxSearchQuery = '';
      });
    }
  }

  // ── Mevcut konuşmayı açma ─────────────────────────────────────────────────
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
            relatedContentLabel: relatedLabel.isEmpty ? null : relatedLabel,
            relatedContentId: c.relatedContentId,
          )..init(),
          child: const ChatView(),
        ),
      ),
    );

    if (context.mounted) {
      await context.read<ChatInboxProvider>().load();
      setState(() {
        _dismissedKeys.clear();
        _inboxSearchQuery = '';
      });
    }
  }

  // ── Yenile ───────────────────────────────────────────────────────────────
  Future<void> _reloadInbox(BuildContext context) async {
    await context.read<ChatInboxProvider>().load();
    if (mounted) {
      setState(() {
        _dismissedKeys.clear();
      });
    }
  }

  bool _conversationMatchesSearch(ConversationSummaryDto c) {
    final q = _inboxSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    final title = _ConversationTile.displayName(c).toLowerCase();
    if (title.contains(q)) return true;
    final peer = (c.otherUsername ?? '').trim().toLowerCase();
    if (peer.contains(q)) return true;
    final last = (c.lastMessage ?? '').toLowerCase();
    if (last.contains(q)) return true;
    return false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isAuthenticated) {
          return Scaffold(
            backgroundColor: AppColors.surfaceContainerLowest,
            appBar: _buildAppBar(context, enabled: false),
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
            // ── Yükleniyor (ilk açılış) ───────────────────────────────────
            if (p.loading && p.conversations.isEmpty) {
              return Scaffold(
                backgroundColor: AppColors.surfaceContainerLowest,
                appBar: _buildAppBar(context, enabled: false),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            // ── Hata (ve liste hâlâ boş) ──────────────────────────────────
            if (p.error != null && p.conversations.isEmpty) {
              return Scaffold(
                backgroundColor: AppColors.surfaceContainerLowest,
                appBar: _buildAppBar(
                  context,
                  enabled: !p.loading,
                  onNewChat: () => _promptAndOpenChat(context),
                  onRefresh: () => _reloadInbox(context),
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.error,
                              ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed:
                              p.loading ? null : () => _reloadInbox(context),
                          child: const Text('Yeniden dene'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // ── Boş liste ────────────────────────────────────────────────
            if (!p.loading && p.error == null && p.conversations.isEmpty) {
              return Scaffold(
                backgroundColor: AppColors.surfaceContainerLowest,
                appBar: _buildAppBar(
                  context,
                  enabled: true,
                  onNewChat: () => _promptAndOpenChat(context),
                  onRefresh: () => _reloadInbox(context),
                ),
                body: const Center(
                  child: Text(
                    'Henüz sohbet yok',
                    style: TextStyle(color: AppColors.secondary),
                  ),
                ),
              );
            }

            // ── Veri var ─────────────────────────────────────────────────
            final visible = p.conversations
                .where((c) => !_dismissedKeys.contains(_rowKey(c)))
                .where(_conversationMatchesSearch)
                .toList();

            return Scaffold(
              backgroundColor: AppColors.surfaceContainerLowest,
              appBar: _buildAppBar(
                context,
                enabled: !p.loading,
                onNewChat: () => _promptAndOpenChat(context),
                onRefresh: () => _reloadInbox(context),
              ),
              body: RefreshIndicator(
                color: AppColors.primaryContainer,
                onRefresh: () => _reloadInbox(context),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: 1 + visible.length,
                  separatorBuilder: (_, index) => SizedBox(
                    height: index == 0 ? 14 : 4,
                  ),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _InboxSearchBar(
                        onChanged: (v) =>
                            setState(() => _inboxSearchQuery = v),
                      );
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
                      onDismissed: (_) {
                        debugPrint('Inbox dismiss: conversationKey=$key');
                        setState(() => _dismissedKeys.add(key));
                      },
                      child: _ConversationTile(
                        conversation: c,
                        myUsername: myUsername,
                        onTap: () => _openConversation(context, c),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── AppBar yardımcısı ─────────────────────────────────────────────────────
  AppBar _buildAppBar(
    BuildContext context, {
    required bool enabled,
    VoidCallback? onNewChat,
    VoidCallback? onRefresh,
  }) {
    return AppBar(
      backgroundColor: AppColors.surfaceContainerLowest,
      foregroundColor: AppColors.onSurface,
      title: const Text('Mesajlar'),
      actions: [
        IconButton(
          tooltip: 'Yeni sohbet',
          onPressed: enabled ? onNewChat : null,
          icon: const Icon(Symbols.add_comment),
        ),
        IconButton(
          tooltip: 'Yenile',
          onPressed: enabled ? onRefresh : null,
          icon: const Icon(Symbols.refresh),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arama Çubuğu
// ─────────────────────────────────────────────────────────────────────────────

class _InboxSearchBar extends StatefulWidget {
  const _InboxSearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

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
      onChanged: widget.onChanged,
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

// ─────────────────────────────────────────────────────────────────────────────
// Sohbet Satırı
// ─────────────────────────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.myUsername,
    required this.onTap,
  });

  final ConversationSummaryDto conversation;
  final String? myUsername;
  final VoidCallback onTap;

  // ── Yardımcı metodlar ─────────────────────────────────────────────────────

  /// Arama ve liste için görünen isim (inbox ile aynı kurallar).
  static String displayName(ConversationSummaryDto c) {
    final full = (c.otherFullName ?? '').trim();
    if (full.isNotEmpty) return full;
    final peer = (c.otherUsername ?? '').trim();
    return peer.isNotEmpty ? peer : '?';
  }

  String _displayName(ConversationSummaryDto c) => displayName(c);

  /// Sunucu göndereni ile bildirmezse güvenli tarafta kal: `[REPLY:…]` öneki
  /// her iki tarafta da olabileceğinden, buna göre "benim" sanmak yanlış olur.
  bool _lastMessageIsMine(ConversationSummaryDto c) {
    final me = (myUsername ?? '').trim().toLowerCase();
    if (me.isEmpty) return false;
    final sender = (c.lastMessageSenderUsername ?? '').trim().toLowerCase();
    if (sender.isEmpty) return false;
    return sender == me;
  }

  /// Ham son mesajı parse ederek görüntülenecek metni döndürür.
  /// Gönderici bensem başına "Siz: " ekler.
  String _subtitle(ConversationSummaryDto c) {
    final raw = (c.lastMessage ?? '').trim();
    if (raw.isEmpty) return 'Henüz mesaj yok';
    final (replyTitle, body) = _parseStoryReplyPrefix(raw);
    final shown = replyTitle == null ? raw : body.trim().isNotEmpty ? body.trim() : raw;
    if (_lastMessageIsMine(c)) return 'Siz: $shown';
    return shown;
  }

  /// Son mesaj benden geldiyse çift tik, başkasındansa tek tik.
  /// "Henüz mesaj yok" ise ikon yok.
  IconData? _tickIcon(ConversationSummaryDto c) {
    final raw = (c.lastMessage ?? '').trim();
    if (raw.isEmpty) return null;
    return _lastMessageIsMine(c) ? Symbols.done_all : Symbols.check;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final title = _displayName(c);
    final subtitle = _subtitle(c);
    final time = formatDmTime(c.lastMessageAt);
    final hasUnread = (c.unreadCount ?? 0) > 0;
    final tickIcon = _tickIcon(c);

    // ── Metin stilleri ────────────────────────────────────────────────────
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar (Stack ile okunmadı noktası) ───────────────────
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CircleAvatar(
                        backgroundColor:
                            AppColors.primaryContainer.withValues(alpha: 0.35),
                        child: Text(
                          title.isNotEmpty ? title[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
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

              const SizedBox(width: 12),

              // ── İçerik ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Kullanıcı adı + saat
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: nameStyle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(time, style: timeStyle),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Tick ikonu + son mesaj
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (tickIcon != null) ...[
                          Icon(
                            tickIcon,
                            size: 14,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 3),
                        ],
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: msgStyle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
