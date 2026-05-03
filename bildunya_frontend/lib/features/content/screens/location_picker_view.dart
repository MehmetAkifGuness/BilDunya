import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/constants/popular_locations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../models/picked_location.dart';

/// Liste veya harita ile konum seçimi; sonucu `Navigator.pop` ile döner.
class LocationPickerView extends StatefulWidget {
  const LocationPickerView({super.key});

  static const String routeName = '/content/location-picker';

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  final MapController _mapController = MapController();
  final _searchController = TextEditingController();

  LatLng _mapCenter = const LatLng(38.6431, 34.8282);
  String _mapLabel = 'Harita merkezi';

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<PickedLocation> get _filteredPresets {
    final q = _searchController.text.trim().toLowerCase();

    final results = q.isEmpty
        ? popularLocations
        : popularLocations.where((p) {
            final inName = p.name.toLowerCase().contains(q);
            final inDescription = p.description.toLowerCase().contains(q);
            final inTags = p.tags.any((t) => t.toLowerCase().contains(q));
            final inCoords = '${p.latitude},${p.longitude}'.contains(q);
            return inName || inDescription || inTags || inCoords;
          }).toList();

    return results
        .map(
          (p) => PickedLocation(
            latitude: p.latitude,
            longitude: p.longitude,
            locationName: p.name,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
          'Konum ara',
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
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            child: Text(
              'Temizle',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Mekan veya bölge ara…',
              leading: const Icon(Symbols.search, color: AppColors.secondary),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Symbols.close, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
              ],
              onChanged: (_) => setState(() {}),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(
                AppColors.surfaceContainerLow,
              ),
              side: const WidgetStatePropertyAll(
                BorderSide(color: AppColors.outlineVariant),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _mapCenter,
                    initialZoom: 12,
                    onTap: (tapPosition, point) {
                      _mapController.move(point, _mapController.camera.zoom);
                      setState(() {
                        _mapCenter = point;
                        _mapLabel =
                            'Seçilen nokta (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bildunya.bildunya_frontend',
                    ),
                  ],
                ),
                Center(
                  child: Icon(
                    Symbols.location_on,
                    size: 44,
                    color: AppColors.primaryContainer,
                    shadows: const [
                      Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Haritaya dokunarak nokta seç, ardından "Bu konumu kullan" de.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop(
                  PickedLocation(
                    latitude: _mapCenter.latitude,
                    longitude: _mapCenter.longitude,
                    locationName: _mapLabel,
                  ),
                );
              },
              icon: const Icon(Symbols.check),
              label: const Text('Bu konumu kullan'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Popüler konumlar',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: _filteredPresets.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aramanızla eşleşen konum yok.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _filteredPresets.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = _filteredPresets[index];
                      return Material(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            side: BorderSide(
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          leading: Icon(
                            Symbols.place,
                            color: AppColors.primaryContainer,
                          ),
                          title: Text(
                            p.locationName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                          trailing: const Icon(
                            Symbols.chevron_right,
                            color: AppColors.secondary,
                          ),
                          onTap: () => Navigator.of(context).pop(p),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
