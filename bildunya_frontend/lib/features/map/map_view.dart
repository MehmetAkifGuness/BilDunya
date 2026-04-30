import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../data/models/content_dto.dart';
import '../content/providers/contents_provider.dart';
import '../content/screens/content_detail_view.dart';

enum _MapChip { none, historic, nature }

/// Harita: arama, filtre chipleri, yakındaki içerik pinleri, Keşfet → detay.
class MapView extends StatefulWidget {
  const MapView({super.key});

  static const _defaultCenter = LatLng(38.6431, 34.8282);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();
  late ContentsProvider _contents;
  _MapChip _chip = _MapChip.none;
  ContentDto? _selected;

  @override
  void initState() {
    super.initState();
    _contents = context.read<ContentsProvider>();
    _contents.addListener(_onContentsChanged);
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _ensureSelection(_filteredPoints(_contents.nearby));
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _contents.loadNearby(
        latitude: MapView._defaultCenter.latitude,
        longitude: MapView._defaultCenter.longitude,
        radiusKm: 40,
      );
    });
  }

  @override
  void dispose() {
    _contents.removeListener(_onContentsChanged);
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onContentsChanged() {
    if (!mounted) return;
    setState(() {
      _ensureSelection(_filteredPoints(_contents.nearby));
    });
  }

  List<ContentDto> _filteredPoints(List<ContentDto> raw) {
    var list = raw
        .where((c) => c.latitude != null && c.longitude != null && c.id != null)
        .toList();
    switch (_chip) {
      case _MapChip.historic:
        list = list.where(_matchesHistoric).toList();
        break;
      case _MapChip.nature:
        list = list.where(_matchesNature).toList();
        break;
      case _MapChip.none:
        break;
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        return (c.locationName ?? '').toLowerCase().contains(q) ||
            (c.description ?? '').toLowerCase().contains(q) ||
            (c.tags ?? '').toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  bool _matchesHistoric(ContentDto c) {
    final t = (c.contentType ?? '').toUpperCase();
    if (t.contains('HIST') ||
        t.contains('CULTURE') ||
        t.contains('ARCH') ||
        t.contains('HERIT')) {
      return true;
    }
    final tags = (c.tags ?? '').toLowerCase();
    final desc = (c.description ?? '').toLowerCase();
    return tags.contains('tarih') ||
        tags.contains('heritage') ||
        tags.contains('museum') ||
        desc.contains('tarih');
  }

  bool _matchesNature(ContentDto c) {
    final t = (c.contentType ?? '').toUpperCase();
    if (t.contains('NATURE') ||
        t.contains('LAND') ||
        t.contains('OUTDOOR') ||
        t.contains('WILD')) {
      return true;
    }
    final tags = (c.tags ?? '').toLowerCase();
    final desc = (c.description ?? '').toLowerCase();
    return tags.contains('doğa') ||
        tags.contains('doga') ||
        tags.contains('nature') ||
        desc.contains('doğa') ||
        desc.contains('doga');
  }

  void _ensureSelection(List<ContentDto> points) {
    if (points.isEmpty) {
      _selected = null;
      return;
    }
    final sel = _selected;
    final ok =
        sel != null && points.any((e) => e.id != null && e.id == sel.id);
    if (!ok) {
      _selected = points.first;
    }
  }

  void _openDetail(ContentDto c) {
    final id = c.id;
    if (id == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ContentDetailView(
          args: ContentDetailArgs(contentId: id, preview: c),
        ),
      ),
    );
  }

  void _setChip(_MapChip next) {
    setState(() {
      if (_chip == next) {
        _chip = _MapChip.none;
      } else {
        _chip = next;
      }
      _ensureSelection(_filteredPoints(_contents.nearby));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom + 88;
    final nearby = _contents.nearby;
    final points = _filteredPoints(nearby);

    final markers = <Marker>[
      for (final c in points)
        Marker(
          width: 46,
          height: 46,
          point: LatLng(c.latitude!, c.longitude!),
          child: GestureDetector(
            onTap: () => setState(() => _selected = c),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _selected?.id == c.id
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainer,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surfaceContainerLowest,
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black45,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Symbols.location_on,
                size: 26,
                color: _selected?.id == c.id
                    ? AppColors.onPrimary
                    : AppColors.primaryContainer,
              ),
            ),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: MapView._defaultCenter,
                initialZoom: 12,
                minZoom: 3,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bildunya.bildunya_frontend',
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow.withValues(
                          alpha: 0.92,
                        ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 16,
                            color: Colors.black38,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Dünyayı Ara...',
                          hintStyle: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.secondary,
                          ),
                          prefixIcon: const Icon(
                            Symbols.search,
                            color: AppColors.primaryContainer,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Tarihi',
                            icon: Symbols.history_edu,
                            selected: _chip == _MapChip.historic,
                            onTap: () => _setChip(_MapChip.historic),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Doğa',
                            icon: Symbols.forest,
                            selected: _chip == _MapChip.nature,
                            onTap: () => _setChip(_MapChip.nature),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_contents.loadingNearby && points.isEmpty)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x33000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottomInset,
            child: _BottomPreviewCard(
              content: _selected,
              loading: _contents.loadingNearby,
              error: _contents.nearbyError,
              onExplore: _selected == null ? null : () => _openDetail(_selected!),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.primaryContainer
          : AppColors.surfaceContainer.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.onPrimary : AppColors.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: selected ? AppColors.onPrimary : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomPreviewCard extends StatelessWidget {
  const _BottomPreviewCard({
    required this.content,
    required this.loading,
    this.error,
    this.onExplore,
  });

  final ContentDto? content;
  final bool loading;
  final String? error;
  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (error != null && content == null && !loading) {
      return Material(
        elevation: 8,
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error!,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ),
      );
    }

    if (content == null) {
      return Material(
        elevation: 8,
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            loading
                ? 'Yakındaki keşifler yükleniyor…'
                : 'Bu bölgede gösterilecek pin yok. Filtreleri veya aramayı değiştir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.secondary,
            ),
          ),
        ),
      );
    }

    final c = content!;
    final url = ApiConfig.resolveFileUrl(c.fileUrl);
    final title = c.locationName?.trim().isNotEmpty == true
        ? c.locationName!.trim()
        : 'Keşif';
    final subtitle = c.description?.trim().isNotEmpty == true
        ? c.description!.trim()
        : (c.tags ?? 'Yakınındaki bir paylaşım');

    return Material(
      elevation: 10,
      color: AppColors.surfaceContainer.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                          child: Icon(
                            Symbols.landscape,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(
                      width: 64,
                      height: 64,
                      child: ColoredBox(
                        color: AppColors.surfaceVariant,
                        child: Icon(
                          Symbols.landscape,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.secondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: onExplore,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        'KEŞFET',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
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
