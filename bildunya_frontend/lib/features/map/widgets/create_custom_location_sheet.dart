import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../data/models/create_custom_location_request.dart';
import '../providers/custom_locations_provider.dart';

class CreateCustomLocationSheet extends StatefulWidget {
  const CreateCustomLocationSheet({
    super.key,
    required this.point,
  });

  final LatLng point;

  @override
  State<CreateCustomLocationSheet> createState() =>
      _CreateCustomLocationSheetState();
}

class _CreateCustomLocationSheetState extends State<CreateCustomLocationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  final _picker = ImagePicker();

  List<XFile> _images = const [];
  int _activeImageIndex = 0;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage(
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (!mounted) return;
    if (files.isEmpty) return;

    setState(() {
      final seen = <String>{};
      final merged = <XFile>[..._images, ...files];
      _images = [
        for (final f in merged)
          if (f.path.trim().isNotEmpty && seen.add(f.path)) f,
      ].take(10).toList();
      if (_activeImageIndex >= _images.length) {
        _activeImageIndex = 0;
      }
    });
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _images.length) return;
    setState(() {
      final next = [..._images]..removeAt(index);
      _images = next;
      if (_images.isEmpty) {
        _activeImageIndex = 0;
      } else if (_activeImageIndex >= _images.length) {
        _activeImageIndex = _images.length - 1;
      }
    });
  }

  List<String> _parseTags(String raw) {
    final out = <String>[];
    for (final p in raw.split(',')) {
      final t = p.trim();
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final provider = context.read<CustomLocationsProvider>();

    final req = CreateCustomLocationRequest(
      name: _name.text.trim(),
      description: _description.text.trim(),
      latitude: widget.point.latitude,
      longitude: widget.point.longitude,
      tags: _parseTags(_tags.text.trim()),
    );

    try {
      final created = await provider.createCustomLocation(
        request: req,
        imagePaths: _images.map((e) => e.path).toList(),
      );
      if (!mounted) return;
      if (created == null) {
        showAppSnackBar(context, 'Konum oluşturulamadı.', isError: true);
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        userFriendlyErrorMessage(e),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final creating = context.watch<CustomLocationsProvider>().creating;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Yeni konum oluştur',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Seçilen nokta: ${widget.point.latitude.toStringAsFixed(5)}, ${widget.point.longitude.toStringAsFixed(5)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  enabled: !creating,
                  decoration: const InputDecoration(
                    labelText: 'Ad',
                    hintText: 'Örn. Gizli şelale',
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) {
                      return 'Pin için bir ad yazın (en az 1 karakter).';
                    }
                    if (s.length > 200) {
                      return 'Ad en fazla 200 karakter olabilir.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  enabled: !creating,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Kısa bir not...',
                  ),
                  validator: (v) {
                    final s = v?.trim() ?? '';
                    if (s.isEmpty) {
                      return 'Bu konumu tanımlayan kısa bir açıklama yazın.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tags,
                  enabled: !creating,
                  decoration: const InputDecoration(
                    labelText: 'Etiketler',
                    hintText: 'doğa, manzara, yürüyüş',
                  ),
                ),
                const SizedBox(height: 14),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: _images.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Symbols.add_photo_alternate,
                                size: 46,
                                color: AppColors.secondary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Fotoğraf ekle (opsiyonel)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            child: Image.file(
                              File(_images[_activeImageIndex].path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                if (_images.length > 1) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (context, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final selected = i == _activeImageIndex;
                        return Stack(
                          children: [
                            InkWell(
                              onTap: () =>
                                  setState(() => _activeImageIndex = i),
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
                                          : AppColors.outlineVariant.withValues(
                                              alpha: 0.35,
                                            ),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: Image.file(
                                    File(_images[i].path),
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IconButton(
                                tooltip: 'Kaldır',
                                onPressed: creating
                                    ? null
                                    : () => _removeImageAt(i),
                                icon: const Icon(Symbols.close, size: 18),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(26, 26),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: creating ? null : _pickImages,
                        icon: const Icon(Symbols.add_a_photo),
                        label: Text(
                          _images.isEmpty ? 'Fotoğraf seç' : 'Fotoğraf ekle',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: creating ? null : _submit,
                        icon: creating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : const Icon(Symbols.check),
                        label: Text(creating ? 'Kaydediliyor…' : 'Kaydet'),
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
