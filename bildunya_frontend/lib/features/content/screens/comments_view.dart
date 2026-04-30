import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/models/comment_dto.dart';
import '../../../data/models/content_dto.dart';
import '../providers/comments_provider.dart';

class CommentsViewArgs {
  const CommentsViewArgs({required this.contentId, this.preview});

  final int contentId;
  final ContentDto? preview;
}

/// Yorumlar: lokasyon özeti, liste, alt alan (code.html Screen 2).
class CommentsView extends StatefulWidget {
  const CommentsView({super.key, required this.args});

  final CommentsViewArgs args;

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView> {
  final _textController = TextEditingController();
  bool _anonymous = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send(CommentsProvider p) async {
    final err = await p.postComment(
      text: _textController.text,
      isAnonymous: _anonymous,
    );
    if (!mounted) return;
    if (err != null) {
      showAppSnackBar(context, err, isError: true);
    } else {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = widget.args.preview;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Yorumlar',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.primaryContainer,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<CommentsProvider>(
        builder: (context, p, _) {
          if (p.loading && p.comments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (p.error != null && p.comments.isEmpty) {
            return Center(
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
                      onPressed: p.load,
                      child: const Text('Yeniden dene'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    if (preview != null) _LocationSummaryCard(preview: preview),
                    if (preview != null) const SizedBox(height: 16),
                    ...p.comments.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CommentTile(comment: c),
                        )),
                  ],
                ),
              ),
              _CommentComposer(
                controller: _textController,
                anonymous: _anonymous,
                onAnonymousChanged: (v) => setState(() => _anonymous = v),
                sending: p.sending,
                onSend: () => _send(p),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LocationSummaryCard extends StatelessWidget {
  const _LocationSummaryCard({required this.preview});

  final ContentDto preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = ApiConfig.resolveFileUrl(preview.fileUrl);

    return Material(
      color: AppColors.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const SizedBox(
                        width: 64,
                        height: 64,
                        child: ColoredBox(
                          color: AppColors.surfaceVariant,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => const SizedBox(
                        width: 64,
                        height: 64,
                        child: ColoredBox(
                          color: AppColors.surfaceVariant,
                          child: Icon(Symbols.image, color: AppColors.secondary),
                        ),
                      ),
                    )
                  : const SizedBox(
                      width: 64,
                      height: 64,
                      child: ColoredBox(
                        color: AppColors.surfaceVariant,
                        child: Icon(Symbols.image, color: AppColors.secondary),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview.locationName?.trim().isNotEmpty == true
                        ? preview.locationName!.trim()
                        : 'Konum',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < 4;
                      return Icon(
                        i == 4 ? Symbols.star_half : Symbols.star,
                        size: 18,
                        fill: filled ? 1 : 0,
                        color: AppColors.primaryContainer,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final CommentDto comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = comment;
    final name = (c.isAnonymous == true)
        ? 'Anonim'
        : (c.user?.displayName ?? 'Kullanıcı');
    final isAnon = c.isAnonymous == true;

    return Material(
      color: AppColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.primaryContainer.withValues(alpha: 0.85),
              width: 2,
            ),
          ),
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isAnon
                      ? AppColors.primaryContainer.withValues(alpha: 0.2)
                      : AppColors.secondaryContainer,
                  child: Icon(
                    Symbols.person,
                    size: 18,
                    color: isAnon
                        ? AppColors.primaryContainer
                        : AppColors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  c.createdAt ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              c.text ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.anonymous,
    required this.onAnonymousChanged,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool anonymous;
  final ValueChanged<bool> onAnonymousChanged;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.surfaceContainerLowest,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Anonim gönder',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Switch(
                    value: anonymous,
                    onChanged: sending ? null : onAnonymousChanged,
                    activeThumbColor: AppColors.primaryContainer,
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !sending,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Bir yorum yaz...',
                        hintStyle: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceContainerHigh,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: sending ? null : onSend,
                    icon: sending
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
            ],
          ),
        ),
      ),
    );
  }
}
