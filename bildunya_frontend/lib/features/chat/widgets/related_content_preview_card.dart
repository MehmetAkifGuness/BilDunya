import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';

/// Composer üstünde, story yanıtına benzer geçici gönderi önizlemesi.
class RelatedContentPreviewCard extends StatelessWidget {
  const RelatedContentPreviewCard({
    super.key,
    required this.placeLabel,
    this.rawFileUrl,
    required this.onOpenDetail,
  });

  final String placeLabel;
  final String? rawFileUrl;
  final VoidCallback onOpenDetail;

  static const double _thumb = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = ApiConfig.resolveFileUrl(rawFileUrl);
    final title = placeLabel.trim().isNotEmpty ? placeLabel.trim() : 'Gönderi';

    return Material(
      color: AppColors.surfaceContainer.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: _thumb,
                  height: _thumb,
                  child: resolved.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: resolved,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const ColoredBox(
                            color: AppColors.surfaceVariant,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Gönderi: $title',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              Icon(
                Symbols.chevron_right,
                size: 22,
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          Symbols.image,
          size: 28,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
