import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../data/models/content_dto.dart';
import '../content/providers/contents_provider.dart';
import '../content/screens/content_detail_view.dart';

/// Doğrulanmış içerik akışı — sosyal paylaşım kartı düzeni.
class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentsProvider>().loadVerified();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contents = context.watch<ContentsProvider>();

    final loading = contents.loadingVerified && contents.verified.isEmpty;
    final empty = !contents.loadingVerified && contents.verified.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Akış',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryContainer,
        onRefresh: () => context.read<ContentsProvider>().loadVerified(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (contents.verifiedError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  contents.verifiedError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            if (!loading)
              ...contents.verified.map((c) => _FeedPostCard(content: c)),
            if (empty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'Henüz doğrulanmış paylaşım yok.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({required this.content});

  final ContentDto content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = content.user?.displayName ?? 'Zeynep Yılmaz';
    final avatarUrl = ApiConfig.resolveFileUrl(content.user?.profilePhotoUrl);
    final imageUrl = ApiConfig.resolveFileUrl(content.fileUrl);
    final body = content.description?.trim().isNotEmpty == true
        ? content.description!
        : 'Kapadokya gün batımında büyülü anlar… Peri bacaları ve sıcak hava balonlarıyla unutulmaz bir akşam.';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final id = content.id;
          if (id == null) return;
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (context) => ContentDetailView(
                args: ContentDetailArgs(contentId: id, preview: content),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surfaceVariant,
                      backgroundImage: avatarUrl.isNotEmpty
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl.isEmpty
                          ? Text(
                              author.isNotEmpty ? author[0].toUpperCase() : '?',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            content.locationName ?? 'Kapadokya · Göreme',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Symbols.more_horiz, color: AppColors.secondary),
                  ],
                ),
              ),
              if (imageUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const ColoredBox(
                      color: AppColors.surfaceVariant,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => const ColoredBox(
                      color: AppColors.surfaceVariant,
                      child: Icon(
                        Symbols.broken_image,
                        color: AppColors.secondary,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.92),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Symbols.favorite,
                          size: 20,
                          color: AppColors.secondary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${content.viewCount ?? 0}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Icon(
                          Symbols.chat_bubble,
                          size: 20,
                          color: AppColors.secondary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '12',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Symbols.share,
                          size: 20,
                          color: AppColors.secondary.withValues(alpha: 0.7),
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
