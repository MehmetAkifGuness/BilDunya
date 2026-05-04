import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_colors.dart';

class CustomLocationGalleryView extends StatefulWidget {
  const CustomLocationGalleryView({
    super.key,
    required this.title,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  final String title;
  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<CustomLocationGalleryView> createState() =>
      _CustomLocationGalleryViewState();
}

class _CustomLocationGalleryViewState extends State<CustomLocationGalleryView> {
  late final PageController _pageController =
      PageController(initialPage: _safeInitialIndex);
  late int _active = _safeInitialIndex;

  int get _safeInitialIndex {
    final max = widget.imageUrls.length - 1;
    if (max <= 0) return 0;
    if (widget.initialIndex < 0) return 0;
    if (widget.initialIndex > max) return max;
    return widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = widget.imageUrls;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${_active + 1}/${images.length}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: images.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Bu pine ait fotoğraf bulunamadı.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _active = i),
                    itemBuilder: (context, i) {
                      final url = images[i];
                      return Semantics(
                        image: true,
                        label: 'Fotoğraf ${i + 1} / ${images.length}',
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Icon(
                                Symbols.broken_image,
                                color: AppColors.secondary,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                    child: SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (context, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final selected = i == _active;
                          final url = images[i];
                          return Semantics(
                            button: true,
                            label: 'Fotoğraf ${i + 1} küçük önizleme',
                            hint: 'Seçmek için dokunun.',
                            child: InkWell(
                              onTap: () {
                                _pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primaryContainer
                                          : AppColors.outlineVariant
                                              .withValues(alpha: 0.25),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const ColoredBox(
                                      color: AppColors.surfaceVariant,
                                      child: Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child:
                                              CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const ColoredBox(
                                      color: AppColors.surfaceVariant,
                                      child: Center(
                                        child: Icon(
                                          Symbols.image_not_supported,
                                          color: AppColors.secondary,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

