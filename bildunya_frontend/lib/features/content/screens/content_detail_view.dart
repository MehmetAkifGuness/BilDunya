import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../data/models/content_dto.dart';
import '../providers/contents_provider.dart';

class ContentDetailArgs {
  const ContentDetailArgs({required this.contentId, this.preview});

  final int contentId;
  final ContentDto? preview;
}

/// Tek içerik: görsel, konum, açıklama (tam sayfa).
class ContentDetailView extends StatefulWidget {
  const ContentDetailView({super.key, required this.args});

  static const String routeName = '/content/detail';

  final ContentDetailArgs args;

  @override
  State<ContentDetailView> createState() => _ContentDetailViewState();
}

class _ContentDetailViewState extends State<ContentDetailView> {
  ContentDto? _content;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _content = widget.args.preview;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dto = await context.read<ContentsProvider>().fetchContentById(
        widget.args.contentId,
      );
      if (mounted) setState(() => _content = dto);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openInExternalMap(ContentDto c) async {
    final lat = c.latitude;
    final lon = c.longitude;
    if (lat == null || lon == null) return;
    final uri = Uri.parse(
      'https://www.openstreetmap.org/?mlat=$lat&mlon=$lon&zoom=16',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _content;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Mekan detayı',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Symbols.arrow_back),
          tooltip: 'Geri',
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (c != null && c.latitude != null && c.longitude != null)
            IconButton(
              tooltip: 'Haritada aç',
              icon: const Icon(Symbols.map),
              onPressed: () => _openInExternalMap(c),
            ),
        ],
      ),
      body: _loading && c == null
          ? const Center(child: CircularProgressIndicator())
          : c == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error ?? 'İçerik yüklenemedi.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primaryContainer,
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (ApiConfig.resolveFileUrl(c.fileUrl).isNotEmpty)
                      AspectRatio(
                        aspectRatio: 1,
                        child: CachedNetworkImage(
                          imageUrl: ApiConfig.resolveFileUrl(c.fileUrl),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const ColoredBox(
                            color: AppColors.surfaceVariant,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const ColoredBox(
                                color: AppColors.surfaceVariant,
                                child: Icon(
                                  Symbols.broken_image,
                                  size: 48,
                                  color: AppColors.secondary,
                                ),
                              ),
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        color: AppColors.surfaceContainerLow,
                        child: const Icon(
                          Symbols.image,
                          size: 64,
                          color: AppColors.secondary,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(
                        children: [
                          Icon(
                            Symbols.location_on,
                            color: AppColors.primaryContainer,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              c.locationName?.trim().isNotEmpty == true
                                  ? c.locationName!
                                  : 'Konum bilgisi yok',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (c.latitude != null && c.longitude != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '${c.latitude!.toStringAsFixed(5)}, ${c.longitude!.toStringAsFixed(5)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        c.description?.trim().isNotEmpty == true
                            ? c.description!.trim()
                            : 'Açıklama yok.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.onSurface.withValues(alpha: 0.92),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.15,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.surfaceVariant,
                            child: Text(
                              (c.user?.displayName ?? 'G')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.onSurface,
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
                                  c.user?.displayName ?? 'Gezgin',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (c.createdAt != null)
                                  Text(
                                    c.createdAt!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.secondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (c.isVerified == true)
                            Chip(
                              label: const Text('Doğrulanmış'),
                              backgroundColor: AppColors.primaryContainer
                                  .withValues(alpha: 0.2),
                              labelStyle: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
