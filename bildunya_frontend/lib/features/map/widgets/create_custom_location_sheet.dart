import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/utils/app_snackbar.dart';
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

  XFile? _image;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (!mounted) return;
    if (file != null) {
      setState(() => _image = file);
    }
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
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      latitude: widget.point.latitude,
      longitude: widget.point.longitude,
      tags: _parseTags(_tags.text.trim()),
    );

    try {
      final created = await provider.createCustomLocation(
        request: req,
        imagePath: _image?.path,
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
        e.toString().replaceFirst('Exception: ', ''),
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
                    if (s.isEmpty) return 'Ad gerekli';
                    if (s.length > 200) return 'En fazla 200 karakter';
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
                    child: _image == null
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
                              File(_image!.path),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: creating ? null : _pickImage,
                        icon: const Icon(Symbols.add_a_photo),
                        label: Text(_image == null ? 'Fotoğraf seç' : 'Değiştir'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: creating ? null : _submit,
                        icon: creating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
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
