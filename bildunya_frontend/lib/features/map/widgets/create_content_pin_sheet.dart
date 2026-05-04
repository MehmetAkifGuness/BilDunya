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
import '../../../data/models/create_content_request.dart';
import '../../content/providers/contents_provider.dart';

class CreateContentPinSheet extends StatefulWidget {
  const CreateContentPinSheet({
    super.key,
    required this.point,
  });

  final LatLng point;

  @override
  State<CreateContentPinSheet> createState() => _CreateContentPinSheetState();
}

class _CreateContentPinSheetState extends State<CreateContentPinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationName = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  final _picker = ImagePicker();

  XFile? _image;

  @override
  void dispose() {
    _locationName.dispose();
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
    if (file == null) return;
    setState(() => _image = file);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final imagePath = _image?.path.trim() ?? '';
    if (imagePath.isEmpty) {
      showAppSnackBar(context, 'Lütfen bir fotoğraf seçin.', isError: true);
      return;
    }

    final provider = context.read<ContentsProvider>();
    final req = CreateContentRequest(
      description: _description.text.trim(),
      contentType: 'IMAGE',
      latitude: widget.point.latitude,
      longitude: widget.point.longitude,
      locationName:
          _locationName.text.trim().isEmpty ? null : _locationName.text.trim(),
      shareType: 'PUBLIC',
      tags: _tags.text.trim().isEmpty ? null : _tags.text.trim(),
    );

    try {
      final err = await provider.uploadContent(
        request: req,
        mediaPath: imagePath,
      );
      if (!mounted) return;
      if (err != null) {
        showAppSnackBar(
          context,
          userFriendlyErrorMessage(err),
          isError: true,
        );
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final uploading = context.watch<ContentsProvider>().uploadingContent;
    final imagePath = _image?.path ?? '';

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
                  'Bu noktaya pin ekle',
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
                  controller: _locationName,
                  enabled: !uploading,
                  decoration: InputDecoration(
                    labelText: 'Mekan adı (opsiyonel)',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  enabled: !uploading,
                  decoration: InputDecoration(
                    labelText: 'Açıklama',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  minLines: 2,
                  maxLines: 5,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Açıklama zorunlu.';
                    if (t.length < 3) return 'En az 3 karakter.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tags,
                  enabled: !uploading,
                  decoration: InputDecoration(
                    labelText: 'Etiketler (opsiyonel, virgülle)',
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      borderSide: BorderSide(
                        color: AppColors.outlineVariant.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: SizedBox(
                    height: 190,
                    child: imagePath.isEmpty
                        ? ColoredBox(
                            color: AppColors.surfaceContainerLow,
                            child: Center(
                              child: Text(
                                'Fotoğraf seçilmedi',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          )
                        : Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: uploading ? null : _pickImage,
                        icon: const Icon(Symbols.add_a_photo),
                        label: Text(imagePath.isEmpty ? 'Fotoğraf seç' : 'Değiştir'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: uploading ? null : _submit,
                        icon: uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Symbols.check),
                        label: Text(uploading ? 'Kaydediliyor…' : 'Kaydet'),
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

