import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_config.dart';
import '../../core/constants/popular_locations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/user_friendly_error.dart';
import '../../core/widgets/content_verification_badge.dart';
import '../../data/models/content_dto.dart';
import '../../data/models/custom_location_dto.dart';
import '../auth/providers/auth_provider.dart';
import '../content/providers/contents_provider.dart';
import '../content/screens/content_detail_view.dart';
import 'providers/custom_locations_provider.dart';
import 'screens/custom_location_gallery_view.dart';
import 'widgets/create_custom_location_sheet.dart';
import 'widgets/create_content_pin_sheet.dart';

enum _MapChip { none, historic, nature }

enum _PinLayer { all, popular, custom }

enum _CreatePinKind { location, photo }

sealed class _MapPin {
  const _MapPin();

  String get key;
  LatLng get point;
  String get title;
  String get subtitle;
  String get imageUrl;
}

final class _ContentPin extends _MapPin {
  const _ContentPin(this.content);

  final ContentDto content;

  @override
  String get key => 'content:${content.id}';

  @override
  LatLng get point => LatLng(content.latitude!, content.longitude!);

  @override
  String get title => content.locationName?.trim().isNotEmpty == true
      ? content.locationName!.trim()
      : 'Keşif';

  @override
  String get subtitle {
    final d = content.description?.trim();
    if (d != null && d.isNotEmpty) return d;
    final t = content.tags?.trim();
    return (t != null && t.isNotEmpty) ? t : 'Yakınındaki bir paylaşım';
  }

  @override
  String get imageUrl => ApiConfig.resolveFileUrl(content.fileUrl);
}

final class _PopularPin extends _MapPin {
  const _PopularPin(this.location);

  final PopularLocation location;

  @override
  String get key => 'popular:${location.name}';

  @override
  LatLng get point => LatLng(location.latitude, location.longitude);

  @override
  String get title => location.name;

  @override
  String get subtitle => location.description;

  @override
  String get imageUrl => '';
}

final class _CustomPin extends _MapPin {
  const _CustomPin(this.location);

  final CustomLocationDto location;

  @override
  String get key => 'custom:${location.id}';

  @override
  LatLng get point => LatLng(location.latitude!, location.longitude!);

  @override
  String get title => (location.name ?? 'Konum').trim().isEmpty
      ? 'Konum'
      : location.name!.trim();

  @override
  String get subtitle {
    final d = location.description?.trim();
    if (d != null && d.isNotEmpty) return d;
    final tags = location.tags ?? const <String>[];
    return tags.isNotEmpty ? tags.join(', ') : 'Kullanıcı konumu';
  }

  @override
  String get imageUrl => ApiConfig.resolveFileUrl(location.imageUrl);
}

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
  late CustomLocationsProvider _customLocations;
  _MapChip _chip = _MapChip.none;
  _PinLayer _layer = _PinLayer.all;
  _MapPin? _selected;
  LatLng? _pendingPoint;
  bool _awaitingPinPlacement = false;

  final Distance _distance = const Distance();
  final Map<String, List<String>> _pinImageCache = <String, List<String>>{};
  final Map<String, Future<List<String>>> _pinImageInFlight =
      <String, Future<List<String>>>{};
  final Set<String> _pinImageLoading = <String>{};
  final Map<String, String> _pinImageError = <String, String>{};

  @override
  void initState() {
    super.initState();
    _contents = context.read<ContentsProvider>();
    _customLocations = context.read<CustomLocationsProvider>();
    _contents.addListener(_onDataChanged);
    _customLocations.addListener(_onDataChanged);
    _searchController.addListener(() {
      if (!mounted) return;
      final before = _selected?.key;
      setState(() => _ensureSelection(_filteredPins()));
      _prefetchIfSelectionChanged(before, _selected);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _contents.loadNearby(
          latitude: MapView._defaultCenter.latitude,
          longitude: MapView._defaultCenter.longitude,
          radiusKm: 40,
        ),
        _customLocations.loadNearby(
          latitude: MapView._defaultCenter.latitude,
          longitude: MapView._defaultCenter.longitude,
          radiusKm: 40,
        ),
      ]);
    });
  }

  @override
  void dispose() {
    _contents.removeListener(_onDataChanged);
    _customLocations.removeListener(_onDataChanged);
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    final before = _selected?.key;
    setState(() => _ensureSelection(_filteredPins()));
    _prefetchIfSelectionChanged(before, _selected);
  }

  void _prefetchIfSelectionChanged(String? beforeKey, _MapPin? next) {
    final nextKey = next?.key;
    if (nextKey == null || nextKey == beforeKey) return;
    final n = next;
    if (n == null) return;
    if (n is _CustomPin) return;
    unawaited(_ensurePinImagesLoaded(n));
  }

  void _selectPin(_MapPin pin) {
    final before = _selected?.key;
    setState(() => _selected = pin);
    _prefetchIfSelectionChanged(before, _selected);
  }

  double _pinExploreRadiusKm(_MapPin pin) {
    return switch (pin) {
      // We fetch a slightly larger area, then post-filter by a tighter radius
      // so other nearby places don't leak into the pin gallery.
      _PopularPin() => 8,
      _ContentPin() => 3,
      _CustomPin() => 3,
    };
  }

  double _pinImageMatchRadiusKm(_MapPin pin) {
    return switch (pin) {
      _PopularPin() => 0.75,
      _ContentPin() => 0.08,
      _CustomPin() => 0.08,
    };
  }

  bool _isImageContent(ContentDto c) {
    final type = (c.contentType ?? '').trim().toUpperCase();
    if (type == 'VIDEO' || type == 'TEXT') return false;
    final url = (c.fileUrl ?? '').toLowerCase();
    if (url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.m4v') ||
        url.endsWith('.webm')) {
      return false;
    }
    return true;
  }

  Future<List<String>> _ensurePinImagesLoaded(_MapPin pin) {
    final key = pin.key;
    final cached = _pinImageCache[key];
    if (cached != null) return Future.value(cached);

    final inflight = _pinImageInFlight[key];
    if (inflight != null) return inflight;

    _pinImageError.remove(key);
    _pinImageLoading.add(key);
    if (mounted) setState(() {});

    final future = _loadPinImages(pin).whenComplete(() {
      _pinImageInFlight.remove(key);
    });
    _pinImageInFlight[key] = future;
    return future;
  }

  Future<List<String>> _loadPinImages(_MapPin pin) async {
    final key = pin.key;
    try {
      final radiusKm = _pinExploreRadiusKm(pin);
      final list = await _contents.fetchNearbyOnce(
        latitude: pin.point.latitude,
        longitude: pin.point.longitude,
        radiusKm: radiusKm,
        size: 50,
        sortBy: 'created_at',
      );
      if (!mounted) return const <String>[];

      final candidates = <(double km, String url)>[];
      final seen = <String>{};
      final matchRadiusKm = _pinImageMatchRadiusKm(pin);
      for (final c in list) {
        if (c.latitude == null || c.longitude == null) continue;
        if (!_isImageContent(c)) continue;
        final url = ApiConfig.resolveFileUrl(c.fileUrl);
        if (url.isEmpty) continue;
        if (!seen.add(url)) continue;
        final km = _distance.as(
          LengthUnit.Kilometer,
          pin.point,
          LatLng(c.latitude!, c.longitude!),
        );
        if (km > matchRadiusKm) continue;
        candidates.add((km, url));
      }

      candidates.sort((a, b) => a.$1.compareTo(b.$1));
      final urls = candidates.map((x) => x.$2).toList(growable: false);

      _pinImageCache[key] = urls;
      _pinImageError.remove(key);
      return urls;
    } catch (e) {
      _pinImageCache[key] = const <String>[];
      _pinImageError[key] = userFriendlyErrorMessage(e);
      return const <String>[];
    } finally {
      _pinImageLoading.remove(key);
      if (mounted) setState(() {});
    }
  }

  Future<void> _openExploreGallery(_MapPin pin, {int initialIndex = 0}) async {
    final urls = await _ensurePinImagesLoaded(pin);
    if (!mounted) return;
    if (urls.isEmpty) {
      showAppSnackBar(context, 'Bu pine ait görsel bulunamadı.');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CustomLocationGalleryView(
          title: pin.title,
          imageUrls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  List<ContentDto> _filteredContents(List<ContentDto> raw) {
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

  void _ensureSelection(List<_MapPin> pins) {
    if (pins.isEmpty) {
      _selected = null;
      return;
    }
    final sel = _selected;
    if (sel == null) {
      _selected = pins.first;
      return;
    }

    for (final p in pins) {
      if (p.key == sel.key) {
        _selected = p;
        return;
      }
    }

    _selected = pins.first;
  }

  void _openDetail(_ContentPin pin) {
    final id = pin.content.id;
    if (id == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ContentDetailView(
          args: ContentDetailArgs(contentId: id, preview: pin.content),
        ),
      ),
    );
  }

  void _setChip(_MapChip next) {
    final before = _selected?.key;
    setState(() {
      if (_chip == next) {
        _chip = _MapChip.none;
      } else {
        _chip = next;
      }
      _ensureSelection(_filteredPins());
    });
    _prefetchIfSelectionChanged(before, _selected);
  }

  void _setLayer(_PinLayer next) {
    final before = _selected?.key;
    setState(() {
      _layer = next;
      _ensureSelection(_filteredPins());
    });
    _prefetchIfSelectionChanged(before, _selected);
  }

  bool _matchesQuery(_MapPin pin, String q) {
    final lower = q.toLowerCase();
    if (pin.title.toLowerCase().contains(lower)) return true;
    if (pin.subtitle.toLowerCase().contains(lower)) return true;

    if (pin is _ContentPin) {
      final tags = (pin.content.tags ?? '').toLowerCase();
      return tags.contains(lower);
    }
    if (pin is _PopularPin) {
      return pin.location.tags.any((t) => t.toLowerCase().contains(lower));
    }
    if (pin is _CustomPin) {
      final tags = pin.location.tags ?? const <String>[];
      return tags.any((t) => t.toLowerCase().contains(lower));
    }
    return false;
  }

  String _pinSemanticsLabel(_MapPin pin) {
    final type = switch (pin) {
      _ContentPin() => 'İçerik pini',
      _PopularPin() => 'Popüler konum',
      _CustomPin() => 'Özel pin',
    };
    final t = pin.title.trim().isNotEmpty ? pin.title.trim() : 'Pin';
    return '$type: $t';
  }

  List<_MapPin> _filteredPins() {
    final q = _searchController.text.trim();

    final pins = <_MapPin>[];

    if (_layer == _PinLayer.all) {
      final contents = _filteredContents(_contents.nearby);
      pins.addAll(contents.map(_ContentPin.new));
      pins.addAll(popularLocations.map(_PopularPin.new));
      final custom = _customLocations.nearby
          .where(
            (c) => c.latitude != null && c.longitude != null && c.id != null,
          )
          .toList();
      pins.addAll(custom.map(_CustomPin.new));
    } else if (_layer == _PinLayer.popular) {
      pins.addAll(popularLocations.map(_PopularPin.new));
    } else {
      final custom = _customLocations.nearby
          .where(
            (c) => c.latitude != null && c.longitude != null && c.id != null,
          )
          .toList();
      pins.addAll(custom.map(_CustomPin.new));
    }

    if (q.isEmpty) return pins;
    return pins.where((p) => _matchesQuery(p, q)).toList();
  }

  Future<void> _handleAddPinAt(LatLng point) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAppSnackBar(
        context,
        'Konum eklemek için giriş yapın.',
        isError: true,
      );
      return;
    }
    setState(() {
      _awaitingPinPlacement = false;
      _pendingPoint = point;
    });

    final kind = await showModalBottomSheet<_CreatePinKind>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Symbols.place),
                  title: const Text('Pin (mekan) oluştur'),
                  subtitle: const Text('Ad + açıklama, opsiyonel fotoğraf'),
                  onTap: () =>
                      Navigator.of(context).pop(_CreatePinKind.location),
                ),
                ListTile(
                  leading: const Icon(Symbols.add_a_photo),
                  title: const Text('Bu noktaya fotoğraf ekle'),
                  subtitle: const Text('İçerik paylaşımı oluşturur'),
                  onTap: () => Navigator.of(context).pop(_CreatePinKind.photo),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (kind == null) {
      setState(() {
        _pendingPoint = null;
      });
      return;
    }

    final bool? created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (context) => kind == _CreatePinKind.location
          ? CreateCustomLocationSheet(point: point)
          : CreateContentPinSheet(point: point),
    );

    if (!mounted) return;
    setState(() => _pendingPoint = null);

    if (created == true) {
      showAppSnackBar(context, 'Pin başarıyla eklendi!');
      if (kind == _CreatePinKind.location) {
        await _customLocations.loadNearby(
          latitude: point.latitude,
          longitude: point.longitude,
          radiusKm: 40,
        );
      } else {
        await _contents.loadNearby(
          latitude: point.latitude,
          longitude: point.longitude,
          radiusKm: 40,
        );
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!_awaitingPinPlacement) return;
    unawaited(_handleAddPinAt(point));
  }

  void _onMapLongPress(TapPosition tapPosition, LatLng point) {
    unawaited(_handleAddPinAt(point));
  }

  void _togglePinPlacementMode() {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      showAppSnackBar(
        context,
        'Konum eklemek için giriş yapın.',
        isError: true,
      );
      return;
    }
    setState(() {
      _awaitingPinPlacement = !_awaitingPinPlacement;
    });
    if (_awaitingPinPlacement) {
      showAppSnackBar(
        context,
        'Haritada istediğiniz noktaya dokunun (veya uzun basın).',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom + 88;
    final pins = _filteredPins();
    final loading = _contents.loadingNearby || _customLocations.loadingNearby;

    final combinedError = pins.isEmpty
        ? (_contents.nearbyError ?? _customLocations.nearbyError)
        : null;

    final markers = <Marker>[
      for (final pin in pins)
        Marker(
          width: 46,
          height: 46,
          point: pin.point,
          child: Semantics(
            button: true,
            label: _pinSemanticsLabel(pin),
            hint: 'Detayları görmek için dokunun.',
            child: GestureDetector(
              onTap: () => _selectPin(pin),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: pin is _CustomPin
                      ? AppColors.primaryContainer
                      : (_selected?.key == pin.key
                            ? AppColors.primaryContainer
                            : AppColors.surfaceContainer),
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
                  pin is _CustomPin ? Symbols.star : Symbols.location_on,
                  size: 26,
                  color: pin is _CustomPin
                      ? AppColors.onPrimary
                      : (_selected?.key == pin.key
                            ? AppColors.onPrimary
                            : AppColors.primaryContainer),
                ),
              ),
            ),
          ),
        ),
      if (_pendingPoint != null)
        Marker(
          width: 46,
          height: 46,
          point: _pendingPoint!,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryContainer, width: 3),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black45,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Symbols.add_location_alt,
              size: 26,
              color: AppColors.primaryContainer,
            ),
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'map_add_pin_fab',
        onPressed: _togglePinPlacementMode,
        icon: Icon(
          _awaitingPinPlacement ? Symbols.close : Symbols.add_location_alt,
        ),
        label: Text(_awaitingPinPlacement ? 'İptal' : 'Pin ekle'),
      ),
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
                onTap: _onMapTap,
                onLongPress: _onMapLongPress,
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
                    if (_awaitingPinPlacement)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: AppColors.primaryContainer.withValues(
                            alpha: 0.35,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Symbols.touch_app,
                                  size: 18,
                                  color: AppColors.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Pin eklemek için haritada bir noktaya dokunun veya uzun basın.',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _LayerChip(
                            label: 'TÜMÜ',
                            selected: _layer == _PinLayer.all,
                            onTap: () => _setLayer(_PinLayer.all),
                          ),
                          const SizedBox(width: 8),
                          _LayerChip(
                            label: 'POPÜLER',
                            selected: _layer == _PinLayer.popular,
                            onTap: () => _setLayer(_PinLayer.popular),
                          ),
                          const SizedBox(width: 8),
                          _LayerChip(
                            label: 'KULLANICI',
                            selected: _layer == _PinLayer.custom,
                            onTap: () => _setLayer(_PinLayer.custom),
                          ),
                          const SizedBox(width: 12),
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
          if (loading && pins.isEmpty)
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
              pin: _selected,
              loading: loading,
              error: combinedError,
              relatedImageUrls: _selected == null
                  ? const <String>[]
                  : (_pinImageCache[_selected!.key] ?? const <String>[]),
              relatedLoading: _selected == null
                  ? false
                  : _pinImageLoading.contains(_selected!.key),
              relatedError: _selected == null
                  ? null
                  : _pinImageError[_selected!.key],
              onOpenDetail: _selected is _ContentPin
                  ? () => _openDetail(_selected! as _ContentPin)
                  : null,
              onExplore: _selected == null
                  ? null
                  : () => _openExploreGallery(_selected!),
              onExploreAtIndex: _selected == null
                  ? null
                  : (i) => _openExploreGallery(_selected!, initialIndex: i),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.secondaryContainer
          : AppColors.surfaceContainer.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: selected ? AppColors.onSurface : AppColors.secondary,
            ),
          ),
        ),
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
    required this.pin,
    required this.loading,
    this.error,
    required this.relatedImageUrls,
    required this.relatedLoading,
    this.relatedError,
    this.onOpenDetail,
    this.onExplore,
    this.onExploreAtIndex,
  });

  final _MapPin? pin;
  final bool loading;
  final String? error;
  final List<String> relatedImageUrls;
  final bool relatedLoading;
  final String? relatedError;
  final VoidCallback? onOpenDetail;
  final VoidCallback? onExplore;
  final ValueChanged<int>? onExploreAtIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (error != null && pin == null && !loading) {
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

    if (pin == null) {
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

    final p = pin!;
    final title = p.title;
    final subtitle = p.subtitle;
    if (p is _CustomPin) {
      return _CustomPinPreviewCard(
        location: p.location,
        title: title,
        subtitle: subtitle,
      );
    }

    final url = p.imageUrl;
    final isContent = p is _ContentPin;
    final related = relatedImageUrls;
    final previewImageUrl = url.isNotEmpty
        ? url
        : (related.isNotEmpty ? related.first : '');

    return Material(
      elevation: 10,
      color: AppColors.surfaceContainer.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onOpenDetail,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: previewImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: previewImageUrl,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                  const SizedBox(height: 6),
                  if (p case final _ContentPin contentPin) ...[
                    ContentVerificationBadge(
                      verificationStatus: contentPin.content.verificationStatus,
                      isVerified: contentPin.content.isVerified,
                      rejectionReason: contentPin.content.rejectionReason,
                      compact: true,
                    ),
                    const SizedBox(height: 4),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        p is _PopularPin
                            ? 'Sistem konumu'
                            : (p is _CustomPin
                                  ? 'Özel pin'
                                  : 'Kullanıcı konumu'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.secondary,
                      height: 1.35,
                    ),
                  ),
                  if (relatedError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      relatedError!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ] else if (relatedLoading && related.isEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Görseller yükleniyor…',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ] else if (related.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: related.length > 6 ? 6 : related.length,
                        separatorBuilder: (context, _) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final u = related[i];
                          return InkWell(
                            onTap: onExploreAtIndex == null
                                ? null
                                : () => onExploreAtIndex!.call(i),
                            borderRadius: BorderRadius.circular(10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: u,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: ColoredBox(
                                    color: AppColors.surfaceVariant,
                                    child: Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: ColoredBox(
                                        color: AppColors.surfaceVariant,
                                        child: Icon(
                                          Symbols.broken_image,
                                          color: AppColors.secondary,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (onExplore != null)
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
                          isContent ? 'KEŞFET' : 'KEŞFET',
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

class _CustomPinPreviewCard extends StatefulWidget {
  const _CustomPinPreviewCard({
    required this.location,
    required this.title,
    required this.subtitle,
  });

  final CustomLocationDto location;
  final String title;
  final String subtitle;

  @override
  State<_CustomPinPreviewCard> createState() => _CustomPinPreviewCardState();
}

class _CustomPinPreviewCardState extends State<_CustomPinPreviewCard> {
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();
  int _active = 0;

  @override
  void didUpdateWidget(covariant _CustomPinPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.id != widget.location.id) {
      _active = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } else {
      final maxIndex = _photos.length - 1;
      if (maxIndex >= 0 && _active > maxIndex) {
        _active = maxIndex;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _photos {
    final raw = widget.location.photoUrls ?? const <String>[];
    final out = <String>[];
    final seen = <String>{};
    for (final p in raw) {
      final t = p.trim();
      if (t.isEmpty) continue;
      if (!seen.add(t)) continue;
      out.add(ApiConfig.resolveFileUrl(t));
    }
    return out;
  }

  Future<void> _addPhotos() async {
    final locId = widget.location.id;
    if (locId == null) return;

    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (!mounted) return;
      if (files.isEmpty) return;

      final provider = context.read<CustomLocationsProvider>();
      await provider.addPhotos(
        locationId: locId,
        imagePaths: files.map((e) => e.path).toList(),
      );

      if (!mounted) return;
      showAppSnackBar(context, 'Fotoğraflar eklendi.');
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, userFriendlyErrorMessage(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = _photos;
    final auth = context.watch<AuthProvider>();
    final myId = auth.user?.id;
    final isOwner =
        auth.isAuthenticated &&
        myId != null &&
        widget.location.userId != null &&
        myId == widget.location.userId;

    return Material(
      elevation: 10,
      color: AppColors.surfaceContainer.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Özel pin',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      photos.isEmpty ? '0 foto' : '${photos.length} foto',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (isOwner)
                      IconButton(
                        tooltip: 'Fotoğraf ekle',
                        onPressed:
                            context.watch<CustomLocationsProvider>().creating
                            ? null
                            : _addPhotos,
                        icon: const Icon(Symbols.add_a_photo),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (photos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  isOwner
                      ? 'Bu pine henüz fotoğraf eklemediniz.'
                      : 'Bu pine henüz fotoğraf eklenmemiş.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _active = i),
                    itemBuilder: (context, i) {
                      final url = photos[i];
                      return Semantics(
                        label: 'Fotoğraf ${i + 1} / ${photos.length}',
                        image: true,
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const ColoredBox(
                            color: AppColors.surfaceVariant,
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const ColoredBox(
                                color: AppColors.surfaceVariant,
                                child: Center(
                                  child: Icon(
                                    Symbols.broken_image,
                                    color: AppColors.secondary,
                                    size: 28,
                                  ),
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => CustomLocationGalleryView(
                      title: widget.title,
                      imageUrls: photos,
                      initialIndex: _active,
                    ),
                  ),
                );
              },
              icon: const Icon(Symbols.photo_library),
              label: const Text('Keşfet'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
            if (photos.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (context, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final selected = i == _active;
                    final url = photos[i];
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
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: selected
                                    ? AppColors.primaryContainer
                                    : AppColors.outlineVariant.withValues(
                                        alpha: 0.25,
                                      ),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
            ],
          ],
        ),
      ),
    );
  }
}
